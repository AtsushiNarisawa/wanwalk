import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/push_notification_provider.dart';
import '../../services/notification_permission_service.dart';
import '../../utils/logger.dart';
import 'morning_reminder_settings_screen.dart';

/// 通知設定画面（B1 §3.2）。
///
/// 種別 3 種 ON/OFF + 朝散歩リマインドの時刻設定 + システム設定アプリへの導線。
///
/// 値の永続化:
/// - `notification_preferences` テーブル（Supabase RPC）
/// - 初回オープン時に SELECT し、未レコードならデフォルト値（朝 6:00 / 全 ON）。
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _morningEnabled = true;
  TimeOfDay _morningTime = const TimeOfDay(hour: 6, minute: 0);
  bool _communityEnabled = true;
  bool _officialEnabled = true;
  NotificationPermissionState _osState = NotificationPermissionState.unknown;
  // OS 状態の取得自体に失敗した場合は true。unknown（notDetermined）と区別し、
  // granted/denied ユーザーへの「通知がオフになっています」誤表示を防ぐ。
  bool _osSyncFailed = false;
  bool _requestingOsPermission = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 設定アプリで通知を切り替えてアプリに戻ってきた場合に表示を追従させる。
  /// （iOS は通知許可の変更でプロセスを kill しないため resumed で再同期が必要）
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final service = ref.read(notificationPermissionServiceProvider);
    final push = ref.read(pushNotificationServiceProvider);
    unawaited(() async {
      try {
        final wasGranted = _osState == NotificationPermissionState.granted;
        final newState = await service.syncFromOs();
        if (!wasGranted && newState == NotificationPermissionState.granted) {
          // 設定アプリ経由で許可された → トークン登録（未ログイン時は内部でスキップ）
          await push.registerCurrentDeviceToken();
        }
        if (!mounted) return;
        setState(() {
          _osState = newState;
          _osSyncFailed = false;
        });
        ref.invalidate(notificationPermissionStateProvider);
        ref.invalidate(shouldShowRecoveryBannerProvider);
      } catch (e) {
        appLog('[NotifSettings] resumed sync failed: $e');
      }
    }());
  }

  Future<void> _loadInitial() async {
    try {
      try {
        final permState =
            await ref.read(notificationPermissionServiceProvider).syncFromOs();
        _osState = permState;
      } catch (e) {
        // Firebase 未初期化等で OS 状態が取れないセッションでは通知バナー類を出さない
        _osSyncFailed = true;
        appLog('[NotifSettings] syncFromOs failed: $e');
      }

      final user = _supabase.auth.currentUser;
      if (user != null) {
        final rows = await _supabase
            .from('notification_preferences')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        if (rows != null) {
          _morningEnabled = (rows['morning_reminder_enabled'] as bool?) ?? true;
          _communityEnabled = (rows['community_enabled'] as bool?) ?? true;
          _officialEnabled = (rows['official_announcement_enabled'] as bool?) ?? true;
          final timeStr = rows['morning_reminder_time'] as String?;
          if (timeStr != null) {
            _morningTime = _parseTime(timeStr) ?? _morningTime;
          }
        }
      }
    } catch (e) {
      appLog('[NotifSettings] load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  TimeOfDay? _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _savePreferences({
    bool? morningEnabled,
    TimeOfDay? morningTime,
    bool? communityEnabled,
    bool? officialEnabled,
  }) async {
    if (_supabase.auth.currentUser == null) return;
    try {
      await _supabase.rpc(
        'update_notification_preferences',
        params: {
          'p_morning_reminder_enabled': morningEnabled,
          'p_morning_reminder_time':
              morningTime != null ? _formatTime(morningTime) : null,
          'p_community_enabled': communityEnabled,
          'p_official_announcement_enabled': officialEnabled,
        },
      );
    } catch (e) {
      appLog('[NotifSettings] save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('申し訳ありません、設定を保存できませんでした'),
          ),
        );
      }
    }
  }

  Future<void> _openSystemSettings() async {
    final uri = Uri.parse('app-settings:');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // 失敗時の救済はサイレント（既に設定アプリが開いている前提）
    }
  }

  /// 未決定（notDetermined）の既存ユーザー向けに OS 許可ダイアログを発火する。
  ///
  /// オンボーディング（PrePermissionScreen）を通らなかった / 「あとで」した
  /// ユーザーが後から通知をオンにできる唯一の導線（Build 48）。
  Future<void> _requestOsPermission() async {
    if (_requestingOsPermission) return;
    setState(() => _requestingOsPermission = true);
    // await 中に画面が pop されても許可成立時の副作用（計測・トークン登録）を
    // 完遂できるよう、ref 依存のサービスは async gap の前に捕捉しておく。
    final service = ref.read(notificationPermissionServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final push = ref.read(pushNotificationServiceProvider);
    try {
      final granted = await service.requestOsPermission();

      // permission_result 計測（type: notification はこの導線が初出）。
      unawaited(
          analytics.logPermissionResult(type: 'notification', granted: granted));

      if (granted) {
        // 許可されたら即トークン登録（PrePermissionScreen と同一パターン。
        // 未ログイン時はサービス内の currentUser ガードでスキップされる）
        await push.registerCurrentDeviceToken();
      }

      final newState = await service.currentState();
      if (!mounted) return;

      // ホームのリカバリバナー等、許可状態を見ている表示判定を最新化
      ref.invalidate(notificationPermissionStateProvider);
      ref.invalidate(shouldShowRecoveryBannerProvider);

      setState(() {
        _osState = newState;
        _osSyncFailed = false;
      });
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知をオンにしました')),
        );
      }
    } catch (e) {
      appLog('[NotifSettings] requestOsPermission failed: $e');
    } finally {
      if (mounted) setState(() => _requestingOsPermission = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? WanWalkColors.backgroundDark
        : WanWalkColors.backgroundLight;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? WanWalkColors.cardDark : Colors.white,
        elevation: 0,
        title: const Text('通知', style: WanWalkTypography.heading2),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (!_osSyncFailed &&
                    (_osState == NotificationPermissionState.unknown ||
                        _osState == NotificationPermissionState.prePromptDeferred))
                  _OsEnableNotice(
                    onEnable: _requestOsPermission,
                    requesting: _requestingOsPermission,
                    isDark: isDark,
                  ),
                if (_osState == NotificationPermissionState.denied)
                  _OsDeniedNotice(onOpenSettings: _openSystemSettings, isDark: isDark),
                _Section(title: '通知の種類', isDark: isDark),
                _Card(
                  isDark: isDark,
                  children: [
                    SwitchListTile(
                      title: const Text('朝の散歩リマインド',
                          style: WanWalkTypography.body),
                      subtitle: Text(
                        '毎朝 ${_morningTime.format(context)} にお届け',
                        style: WanWalkTypography.caption,
                      ),
                      value: _morningEnabled,
                      activeColor: WanWalkColors.primary,
                      onChanged: (v) async {
                        setState(() => _morningEnabled = v);
                        await _savePreferences(morningEnabled: v);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('時刻とモードを変更',
                          style: WanWalkTypography.body),
                      subtitle: const Text(
                        '日の出に合わせる / 時刻指定 / 配信頻度',
                        style: WanWalkTypography.caption,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: _morningEnabled,
                      onTap: _morningEnabled
                          ? () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MorningReminderSettingsScreen(),
                                ),
                              );
                              if (mounted) _loadInitial();
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('コミュニティ通知',
                          style: WanWalkTypography.body),
                      subtitle: const Text(
                        'いいね・コメントなど',
                        style: WanWalkTypography.caption,
                      ),
                      value: _communityEnabled,
                      activeColor: WanWalkColors.primary,
                      onChanged: (v) async {
                        setState(() => _communityEnabled = v);
                        await _savePreferences(communityEnabled: v);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('公式お知らせ',
                          style: WanWalkTypography.body),
                      subtitle: const Text(
                        '新しいルート・季節情報など',
                        style: WanWalkTypography.caption,
                      ),
                      value: _officialEnabled,
                      activeColor: WanWalkColors.primary,
                      onChanged: (v) async {
                        setState(() => _officialEnabled = v);
                        await _savePreferences(officialEnabled: v);
                      },
                    ),
                  ],
                ),
                _Section(title: 'システム', isDark: isDark),
                _Card(
                  isDark: isDark,
                  children: [
                    ListTile(
                      title: const Text('システム通知の設定',
                          style: WanWalkTypography.body),
                      subtitle: const Text(
                        'iOSの設定アプリで通知の表示方法を調整できます',
                        style: WanWalkTypography.caption,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openSystemSettings,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: WanWalkTypography.caption.copyWith(
          color: isDark
              ? WanWalkColors.textSecondaryDark
              : WanWalkColors.textSecondaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.isDark, required this.children});
  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}

class _OsEnableNotice extends StatelessWidget {
  const _OsEnableNotice({
    required this.onEnable,
    required this.requesting,
    required this.isDark,
  });
  final VoidCallback onEnable;
  final bool requesting;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WanWalkColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '通知がオフになっています',
            style: WanWalkTypography.bodyMedium.copyWith(
              color: WanWalkColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '通知をオンにすると、朝のお散歩タイムや大切なお知らせをお届けできます',
            style: WanWalkTypography.caption,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: requesting ? null : onEnable,
              child: requesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '通知をオンにする',
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: WanWalkColors.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OsDeniedNotice extends StatelessWidget {
  const _OsDeniedNotice({required this.onOpenSettings, required this.isDark});
  final VoidCallback onOpenSettings;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WanWalkColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'iOSの通知がオフになっています',
            style: WanWalkTypography.bodyMedium.copyWith(
              color: WanWalkColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '設定アプリから通知を有効にすると、朝のお散歩タイムをお届けできます',
            style: WanWalkTypography.caption,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenSettings,
              child: Text(
                '設定アプリを開く',
                style: WanWalkTypography.bodyMedium.copyWith(
                  color: WanWalkColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
