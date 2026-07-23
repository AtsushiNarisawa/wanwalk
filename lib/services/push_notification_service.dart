import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger.dart';

/// バックグラウンド受信ハンドラ（top-level 必須）。
///
/// Firebase が isolate を新規起動して呼ぶため、Riverpod や DI を介さず最小処理に留める。
/// 配信ログ更新などのサーバ書込は EF 側で行うため、ここでは debug ログのみ。
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    appLog('[FCM] background message: id=${message.messageId} data=${message.data}');
  }
}

/// FCM プッシュ通知基盤サービス（B1）。
///
/// 設計書: docs/mvp_specs/B1_fcm_push_base.md §6.1
///
/// 責務:
/// - FCM トークン取得・登録 / Supabase RPC `register_device_token` 連携
/// - フォアグラウンド / バックグラウンド / 完全終了 から起動した通知のハンドリング
/// - 通知タップで届く `RemoteMessage` を Stream で公開（deep link はルーティング側で解決）
class PushNotificationService {
  PushNotificationService(this._supabase);

  final SupabaseClient _supabase;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final StreamController<RemoteMessage> _onMessageOpenedController =
      StreamController<RemoteMessage>.broadcast();

  /// 通知タップでアプリが起動 / 復帰した際に届く RemoteMessage。
  ///
  /// `notification_deep_link.dart` 側で listen して画面遷移を解決する。
  Stream<RemoteMessage> get onMessageOpened => _onMessageOpenedController.stream;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  StreamSubscription<AuthState>? _authSub;
  bool _initialized = false;
  bool _signInRegisterInFlight = false;

  /// アプリ起動シーケンスから呼ぶ初期化。
  ///
  /// - APNs / FCM トークン取得は OS 許可後でも空になることがあるため、許可後にも再取得する。
  /// - フォアグラウンド表示は iOS 既定では出ないため `setForegroundNotificationPresentationOptions` で heads-up を出す。
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!Platform.isIOS) {
      // v0.3: MVP は iOS only。Android は Phase 3 以降。
      if (kDebugMode) appLog('[FCM] skip init (non-iOS)');
      return;
    }

    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 初期メッセージ（完全終了状態でタップ起動）
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _onMessageOpenedController.add(initialMessage);
      }

      // バックグラウンドからの復帰
      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (kDebugMode) appLog('[FCM] opened from background: ${message.messageId}');
        _onMessageOpenedController.add(message);
      });

      // フォアグラウンド受信
      _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode) {
          appLog('[FCM] foreground: ${message.notification?.title} data=${message.data}');
        }
      });

      // トークンリフレッシュ追従
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
        // ログインユーザーがあれば即時 UPSERT。なければ次回ログイン時に拾う。
        if (_supabase.auth.currentUser != null) {
          unawaited(_registerToken(token));
        }
      });

      // ログイン確定時のトークン再登録フック。
      // - 未ログインで OS 許可 → 後からログイン（PrePermissionScreen 経路含む）
      // - ログアウト（revoke + deleteToken 済）→ 再ログイン
      // の両ケースで、次回コールド起動を待たずにプッシュ到達を回復する。
      // 購読時に BehaviorSubject がリプレイする initialSession は main.dart の
      // 起動時登録（_initPushNotifications）と重複するため signedIn のみ反応。
      // tokenRefreshed（約1時間ごと）は onTokenRefresh が別途担保するため無視。
      // onError: オフライン時のリフレッシュ失敗等が同じストリームに流れてくる
      // （supabase_flutter 内部購読と同じく握って Zone 未処理例外を防ぐ）。
      _authSub = _supabase.auth.onAuthStateChange.listen(
        (data) {
          if (data.event == AuthChangeEvent.signedIn) {
            unawaited(_registerTokenIfOsGranted());
          }
        },
        onError: (Object e) {
          if (kDebugMode) appLog('[FCM] auth stream error: $e');
        },
      );
    } catch (e, st) {
      // Firebase 初期化失敗時もアプリは起動継続（A3 観点）
      if (kDebugMode) appLog('[FCM] initialize failed: $e\n$st');
    }
  }

  /// OS 許可確定後（または既に許可済の起動時）に呼ぶ。
  ///
  /// トークンを取得して Supabase にも UPSERT。未認証なら DB 書込はスキップ。
  Future<String?> registerCurrentDeviceToken() async {
    if (!Platform.isIOS) return null;
    try {
      // APNs トークンを先に確認（iOS では FCM トークン取得の前提）
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken == null) {
        if (kDebugMode) appLog('[FCM] APNs token not ready yet');
        return null;
      }

      final token = await _messaging.getToken();
      if (token == null) return null;

      if (_supabase.auth.currentUser != null) {
        await _registerToken(token);
      }
      return token;
    } catch (e) {
      if (kDebugMode) appLog('[FCM] registerCurrentDeviceToken failed: $e');
      return null;
    }
  }

  /// signedIn フック用: OS 通知許可が granted のときだけトークン登録。
  ///
  /// ログイン直後は APNs/FCM トークンが未準備のことがある（オフライン起動後の
  /// 回線復帰直後・ログアウト時 deleteToken 後の再生成中）。その間 firebase_messaging
  /// は自動再試行せず onTokenRefresh も発火しないため、null 返却時は 3 秒 / 10 秒後に
  /// 計 2 回だけ再試行して「ログイン直後ウィンドウ」の取りこぼしを防ぐ。
  Future<void> _registerTokenIfOsGranted() async {
    if (_signInRegisterInFlight) return; // 再認証等での連続 signedIn は1本に集約
    _signInRegisterInFlight = true;
    try {
      final settings = await _messaging.getNotificationSettings();
      final status = settings.authorizationStatus;
      if (status != AuthorizationStatus.authorized &&
          status != AuthorizationStatus.provisional) {
        return;
      }
      for (final delay in const [
        Duration.zero,
        Duration(seconds: 3),
        Duration(seconds: 10),
      ]) {
        if (delay != Duration.zero) {
          await Future<void>.delayed(delay);
          // リトライ待機中にログアウトされたら中断
          if (_supabase.auth.currentUser == null) return;
        }
        final token = await registerCurrentDeviceToken();
        if (token != null) return;
      }
      if (kDebugMode) appLog('[FCM] register on signedIn gave up (token not ready)');
    } catch (e) {
      if (kDebugMode) appLog('[FCM] register on signedIn failed: $e');
    } finally {
      _signInRegisterInFlight = false;
    }
  }

  /// Supabase RPC で device_tokens を UPSERT。
  Future<void> _registerToken(String token) async {
    try {
      await _supabase.rpc(
        'register_device_token',
        params: {
          'p_fcm_token': token,
          'p_platform': 'ios',
          'p_app_version': null,
          'p_device_model': null,
          'p_timezone': 'Asia/Tokyo',
        },
      );
      if (kDebugMode) appLog('[FCM] register_device_token ok');
    } catch (e) {
      if (kDebugMode) appLog('[FCM] register_device_token failed: $e');
    }
  }

  /// ログアウト時に呼ぶ。Supabase 側で revoked_at セット。
  Future<void> revokeCurrentDeviceToken() async {
    if (!Platform.isIOS) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _supabase.rpc(
        'revoke_device_token',
        params: {'p_fcm_token': token},
      );

      // ローカルトークン破棄（次回ログイン時に再取得）
      await _messaging.deleteToken();
    } catch (e) {
      if (kDebugMode) appLog('[FCM] revoke_device_token failed: $e');
    }
  }

  /// 通知タップ→画面遷移後にクライアントから配信ログを `opened` 化。
  Future<void> logNotificationOpened(String notificationLogId) async {
    try {
      await _supabase.rpc(
        'log_notification_opened',
        params: {'p_notification_log_id': notificationLogId},
      );
    } catch (e) {
      if (kDebugMode) appLog('[FCM] log_notification_opened failed: $e');
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
    await _onMessageOpenedController.close();
  }
}
