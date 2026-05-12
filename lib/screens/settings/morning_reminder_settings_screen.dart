import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../providers/morning_reminder_provider.dart';
import '../../services/morning_reminder_service.dart';
import '../../utils/sunrise_calculator.dart';

/// 朝の散歩リマインド 詳細設定画面（B2 §3.1）。
///
/// - ON/OFF
/// - モード（おすすめ＝日の出に合わせる / 時刻を指定）
/// - 時刻指定モードでの time picker
/// - 配信頻度（毎日 / 平日のみ / 週末のみ）
class MorningReminderSettingsScreen extends ConsumerWidget {
  const MorningReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight;
    final state = ref.watch(morningReminderControllerProvider);
    final notifier = ref.read(morningReminderControllerProvider.notifier);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? WanWalkColors.cardDark : Colors.white,
        elevation: 0,
        title: const Text('朝の散歩リマインド', style: WanWalkTypography.heading2),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '申し訳ありません、設定を読み込めませんでした',
              style: WanWalkTypography.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (prefs) => _SettingsBody(
          prefs: prefs,
          notifier: notifier,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.prefs,
    required this.notifier,
    required this.isDark,
  });

  final MorningReminderPreferences prefs;
  final MorningReminderNotifier notifier;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _Section(title: '朝のリマインド', isDark: isDark),
        _Card(
          isDark: isDark,
          children: [
            SwitchListTile(
              title: const Text('毎朝の通知', style: WanWalkTypography.body),
              subtitle: Text(
                _subtitleForEnabled(prefs),
                style: WanWalkTypography.caption,
              ),
              value: prefs.enabled,
              activeColor: WanWalkColors.primary,
              onChanged: (v) => notifier.setEnabled(v),
            ),
          ],
        ),
        if (prefs.enabled) ...[
          _Section(title: '通知タイミング', isDark: isDark),
          _Card(
            isDark: isDark,
            children: [
              RadioListTile<MorningReminderMode>(
                value: MorningReminderMode.auto,
                groupValue: prefs.mode,
                onChanged: (v) {
                  if (v != null) notifier.setMode(v);
                },
                activeColor: WanWalkColors.primary,
                title: const Text('おすすめ（日の出に合わせる）',
                    style: WanWalkTypography.body),
                subtitle: Text(
                  _autoModeSubtitle(),
                  style: WanWalkTypography.caption,
                ),
              ),
              const Divider(height: 1),
              RadioListTile<MorningReminderMode>(
                value: MorningReminderMode.fixedTime,
                groupValue: prefs.mode,
                onChanged: (v) {
                  if (v != null) notifier.setMode(v);
                },
                activeColor: WanWalkColors.primary,
                title:
                    const Text('時刻を指定', style: WanWalkTypography.body),
              ),
              if (prefs.mode == MorningReminderMode.fixedTime) ...[
                const Divider(height: 1),
                ListTile(
                  title: const Text('指定時刻', style: WanWalkTypography.body),
                  trailing: Text(
                    prefs.fixedTime.format(context),
                    style: WanWalkTypography.body.copyWith(
                      color: WanWalkColors.primary,
                    ),
                  ),
                  onTap: () => _pickTime(context),
                ),
              ],
            ],
          ),
          _Section(title: '通知頻度', isDark: isDark),
          _Card(
            isDark: isDark,
            children: [
              RadioListTile<MorningReminderFrequency>(
                value: MorningReminderFrequency.daily,
                groupValue: prefs.frequency,
                onChanged: (v) {
                  if (v != null) notifier.setFrequency(v);
                },
                activeColor: WanWalkColors.primary,
                title:
                    const Text('毎日（推奨）', style: WanWalkTypography.body),
              ),
              const Divider(height: 1),
              RadioListTile<MorningReminderFrequency>(
                value: MorningReminderFrequency.weekdays,
                groupValue: prefs.frequency,
                onChanged: (v) {
                  if (v != null) notifier.setFrequency(v);
                },
                activeColor: WanWalkColors.primary,
                title:
                    const Text('平日のみ', style: WanWalkTypography.body),
              ),
              const Divider(height: 1),
              RadioListTile<MorningReminderFrequency>(
                value: MorningReminderFrequency.weekends,
                groupValue: prefs.frequency,
                onChanged: (v) {
                  if (v != null) notifier.setFrequency(v);
                },
                activeColor: WanWalkColors.primary,
                title:
                    const Text('週末のみ', style: WanWalkTypography.body),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: prefs.fixedTime,
      helpText: '朝の通知時刻',
      cancelText: '閉じる',
      confirmText: '決定',
    );
    if (picked == null) return;
    await notifier.setFixedTime(picked);
  }

  String _subtitleForEnabled(MorningReminderPreferences p) {
    if (!p.enabled) {
      return 'オフにすると朝の通知が届きません';
    }
    if (p.mode == MorningReminderMode.auto) {
      return _autoModeSubtitle();
    }
    final hh = p.fixedTime.hour.toString().padLeft(2, '0');
    final mm = p.fixedTime.minute.toString().padLeft(2, '0');
    return '毎朝 $hh:$mm にお届け';
  }

  String _autoModeSubtitle() {
    final sunrise = SunriseCalculator.sunriseFor(DateTime.now());
    final send = sunrise.add(SunriseCalculator.recommendedSendOffset);
    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '今日は ${fmt(send)} ごろ（日の出 ${fmt(sunrise)} の 30 分前）';
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
