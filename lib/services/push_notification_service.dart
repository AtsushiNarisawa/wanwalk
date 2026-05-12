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
  bool _initialized = false;

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
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
    await _onMessageOpenedController.close();
  }
}
