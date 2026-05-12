import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../config/wanwalk_colors.dart';
import '../config/wanwalk_typography.dart';
import '../providers/push_notification_provider.dart';
import '../screens/settings/notification_settings_screen.dart';

/// ホームバナー（B1 §3.3）。
///
/// 表示条件: OS で notifications が denied、かつ過去 14 日で × されていない。
/// 「設定する」→ 通知設定画面（[NotificationSettingsScreen]）に遷移。
/// 「×」→ 14 日間非表示。
class NotificationRecoveryBanner extends ConsumerWidget {
  const NotificationRecoveryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncShow = ref.watch(shouldShowRecoveryBannerProvider);
    return asyncShow.maybeWhen(
      data: (show) => show ? _buildBanner(context, ref) : const SizedBox.shrink(),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: WanWalkColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.bell(),
                size: 20,
                color: WanWalkColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '通知をオンにすると、毎朝ベストな散歩時間をお知らせします',
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: WanWalkColors.textPrimaryLight,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                      child: Text(
                        '設定する',
                        style: WanWalkTypography.bodyMedium.copyWith(
                          color: WanWalkColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: WanWalkColors.textSecondaryLight,
                tooltip: '閉じる',
                onPressed: () async {
                  await ref
                      .read(notificationPermissionServiceProvider)
                      .dismissRecoveryBanner();
                  ref.invalidate(shouldShowRecoveryBannerProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
