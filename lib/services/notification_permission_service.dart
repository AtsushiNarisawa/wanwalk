import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger.dart';

/// プリ許可・OS 許可ダイアログの状態管理（B1 §3.1 / §5.1）。
///
/// 設計書: docs/mvp_specs/B1_fcm_push_base.md
///
/// 状態モデル:
/// - `unknown`   : まだプリ許可画面も表示していない
/// - `prePromptDeferred` : プリ許可で「あとで」をタップ済（OS ダイアログ非表示）
/// - `granted`   : OS で許可
/// - `denied`    : OS で拒否
///
/// 永続化: SharedPreferences（クライアントローカル）+ Supabase `notification_permissions`。
enum NotificationPermissionState {
  unknown,
  prePromptDeferred,
  granted,
  denied,
}

class NotificationPermissionService {
  NotificationPermissionService(this._supabase);

  final SupabaseClient _supabase;

  static const _keyPrePromptShown = 'notif_pre_prompt_shown';
  static const _keyPrePromptDeferredAt = 'notif_pre_prompt_deferred_at_ms';
  static const _keyRecoveryBannerHiddenUntilMs = 'notif_recovery_hidden_until_ms';

  /// OS の最新許可状態を取得。
  Future<NotificationPermissionState> currentState() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return _mapAuthorization(settings.authorizationStatus);
  }

  /// プリ許可画面を出すべきか。
  ///
  /// - OS 許可済 / 既出 拒否は出さない
  /// - 過去 14 日以内に「あとで」されていれば出さない
  Future<bool> shouldShowPrePrompt() async {
    final state = await currentState();
    if (state == NotificationPermissionState.granted ||
        state == NotificationPermissionState.denied) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    final deferredAt = prefs.getInt(_keyPrePromptDeferredAt);
    if (deferredAt != null) {
      final deferredFor = DateTime.now().millisecondsSinceEpoch - deferredAt;
      if (deferredFor < const Duration(days: 14).inMilliseconds) {
        return false;
      }
    }
    return true;
  }

  /// プリ許可で「あとで」をタップ。
  Future<void> markPrePromptDeferred() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrePromptShown, true);
    await prefs.setInt(
      _keyPrePromptDeferredAt,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// OS 許可ダイアログを要求し、結果を Supabase にも反映。
  ///
  /// 戻り値: 許可されたか。
  Future<bool> requestOsPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrePromptShown, true);
    await prefs.remove(_keyPrePromptDeferredAt);

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final state = _mapAuthorization(settings.authorizationStatus);
    final granted = state == NotificationPermissionState.granted;
    await _syncToSupabase(granted);
    return granted;
  }

  /// アプリ起動時の状態同期（OS 設定アプリで後から変更された場合に追従）。
  Future<NotificationPermissionState> syncFromOs() async {
    final state = await currentState();
    if (state == NotificationPermissionState.granted ||
        state == NotificationPermissionState.denied) {
      await _syncToSupabase(state == NotificationPermissionState.granted,
          incrementPromptCount: false);
    }
    return state;
  }

  /// 拒否リカバリバナーを今出してよいか。
  Future<bool> shouldShowRecoveryBanner() async {
    final state = await currentState();
    if (state != NotificationPermissionState.denied) return false;
    final prefs = await SharedPreferences.getInstance();
    final hideUntil = prefs.getInt(_keyRecoveryBannerHiddenUntilMs);
    if (hideUntil != null && hideUntil > DateTime.now().millisecondsSinceEpoch) {
      return false;
    }
    return true;
  }

  /// 「× で閉じた」を 14 日間記録。
  Future<void> dismissRecoveryBanner({Duration cooldown = const Duration(days: 14)}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyRecoveryBannerHiddenUntilMs,
      DateTime.now().add(cooldown).millisecondsSinceEpoch,
    );
  }

  Future<void> _syncToSupabase(bool granted, {bool incrementPromptCount = true}) async {
    if (_supabase.auth.currentUser == null) return;
    try {
      await _supabase.rpc(
        'update_notification_permission',
        params: {'p_granted': granted},
      );
    } catch (e) {
      if (kDebugMode) appLog('[NotifPerm] update_notification_permission failed: $e');
    }
    // incrementPromptCount は RPC 側で常に +1 する。
    // syncFromOs はバックグラウンド同期目的なので、本当はカウント抑制したいが、
    // RPC 設計上は user_id 同一なら UPSERT で 1 度のみ伸びる程度。MVP では許容。
  }

  NotificationPermissionState _mapAuthorization(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return NotificationPermissionState.granted;
      case AuthorizationStatus.denied:
        return NotificationPermissionState.denied;
      case AuthorizationStatus.notDetermined:
        return NotificationPermissionState.unknown;
    }
  }
}
