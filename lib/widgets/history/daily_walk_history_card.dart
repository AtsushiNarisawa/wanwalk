import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../models/walk_history.dart';

/// 日常散歩履歴カード（シンプル、小さい表示）
class DailyWalkHistoryCard extends StatelessWidget {
  final DailyWalkHistory history;
  final VoidCallback onTap;

  const DailyWalkHistoryCard({
    super.key,
    required this.history,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: WanWalkSpacing.sm),
        padding: const EdgeInsets.all(WanWalkSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? WanWalkColors.textSecondaryDark.withOpacity(0.1)
                : WanWalkColors.textSecondaryLight.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // アイコン
            Container(
              padding: const EdgeInsets.all(WanWalkSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? WanWalkColors.backgroundDark
                    : WanWalkColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                PhosphorIcons.dog(),
                color: isDark
                    ? WanWalkColors.textSecondaryDark
                    : WanWalkColors.textSecondaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: WanWalkSpacing.md),

            // 情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日時
                  Text(
                    _formatDate(history.walkedAt),
                    style: WanWalkTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanWalkColors.textPrimaryDark
                          : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: WanWalkSpacing.xs),

                  // 統計
                  Row(
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 14,
                        color: isDark
                            ? WanWalkColors.textSecondaryDark
                            : WanWalkColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanWalkSpacing.xs),
                      Text(
                        history.formattedDistance,
                        style: WanWalkTypography.caption.copyWith(
                          color: isDark
                              ? WanWalkColors.textSecondaryDark
                              : WanWalkColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: WanWalkSpacing.md),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDark
                            ? WanWalkColors.textSecondaryDark
                            : WanWalkColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanWalkSpacing.xs),
                      Text(
                        history.formattedDuration,
                        style: WanWalkTypography.caption.copyWith(
                          color: isDark
                              ? WanWalkColors.textSecondaryDark
                              : WanWalkColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 矢印アイコン
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) {
      return '今日 ${DateFormat('HH:mm').format(date)}';
    } else if (compareDate == yesterday) {
      return '昨日 ${DateFormat('HH:mm').format(date)}';
    } else if (now.difference(date).inDays < 7) {
      final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
      final weekday = weekdays[date.weekday - 1];
      return '$weekday曜日 ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('M月d日(E)', 'ja').format(date);
    }
  }
}
