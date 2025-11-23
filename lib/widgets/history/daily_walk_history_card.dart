import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
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
        margin: const EdgeInsets.only(bottom: WanMapSpacing.sm),
        padding: const EdgeInsets.all(WanMapSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? WanMapColors.textSecondaryDark.withOpacity(0.1)
                : WanMapColors.textSecondaryLight.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // アイコン
            Container(
              padding: const EdgeInsets.all(WanMapSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? WanMapColors.backgroundDark
                    : WanMapColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.pets,
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: WanMapSpacing.md),

            // 情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日時
                  Text(
                    _formatDate(history.walkedAt),
                    style: WanMapTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanMapColors.textPrimaryDark
                          : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: WanMapSpacing.xs),

                  // 統計
                  Row(
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 14,
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanMapSpacing.xs),
                      Text(
                        history.formattedDistance,
                        style: WanMapTypography.caption.copyWith(
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: WanMapSpacing.md),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanMapSpacing.xs),
                      Text(
                        history.formattedDuration,
                        style: WanMapTypography.caption.copyWith(
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
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
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
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
