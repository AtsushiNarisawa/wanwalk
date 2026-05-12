import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/notification_permission_service.dart';
import '../services/push_notification_service.dart';

/// B1: FCM プッシュ通知基盤 Riverpod プロバイダ。
///
/// 設計書: docs/mvp_specs/B1_fcm_push_base.md §6.1
///
/// 階層:
/// - [pushNotificationServiceProvider]      — FCM SDK ラッパ（シングルトン）
/// - [notificationPermissionServiceProvider] — OS 許可 + Supabase 同期
/// - [notificationPermissionStateProvider]   — 現在の許可状態（非同期）
/// - [shouldShowRecoveryBannerProvider]      — ホームバナー表示判定

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(Supabase.instance.client);
  ref.onDispose(() => service.dispose());
  return service;
});

final notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
  return NotificationPermissionService(Supabase.instance.client);
});

/// OS 許可ダイアログの状態（unknown / prePromptDeferred / granted / denied）。
final notificationPermissionStateProvider =
    FutureProvider<NotificationPermissionState>((ref) async {
  final service = ref.watch(notificationPermissionServiceProvider);
  return service.currentState();
});

/// ホームのリカバリバナーを今出すべきか。
final shouldShowRecoveryBannerProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(notificationPermissionServiceProvider);
  return service.shouldShowRecoveryBanner();
});

/// プリ許可画面を今出すべきか（welcome 完了後の判定）。
final shouldShowPrePromptProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(notificationPermissionServiceProvider);
  return service.shouldShowPrePrompt();
});
