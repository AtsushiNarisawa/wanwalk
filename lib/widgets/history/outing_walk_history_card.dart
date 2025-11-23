import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/walk_history.dart';

/// お出かけ散歩履歴カード（写真メイン、大きい表示）
class OutingWalkHistoryCard extends StatelessWidget {
  final OutingWalkHistory history;
  final VoidCallback onTap;

  const OutingWalkHistoryCard({
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
        margin: const EdgeInsets.only(bottom: WanMapSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー（日付とエリア）
            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.md),
              child: Row(
                children: [
                  // 日付
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WanMapSpacing.sm,
                      vertical: WanMapSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: WanMapColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDate(history.walkedAt),
                      style: WanMapTypography.caption.copyWith(
                        color: WanMapColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: WanMapSpacing.sm),

                  // エリア名
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                        const SizedBox(width: WanMapSpacing.xs),
                        Expanded(
                          child: Text(
                            history.areaName,
                            style: WanMapTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? WanMapColors.textSecondaryDark
                                  : WanMapColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ルート名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.md),
              child: Text(
                history.routeName,
                style: WanMapTypography.headlineSmall.copyWith(
                  color: isDark
                      ? WanMapColors.textPrimaryDark
                      : WanMapColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: WanMapSpacing.md),

            // 写真グリッド
            if (history.photoUrls.isNotEmpty)
              _buildPhotoGrid(history.photoUrls),

            // 統計情報
            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.straighten,
                        label: history.formattedDistance,
                        isDark: isDark,
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      _StatChip(
                        icon: Icons.access_time,
                        label: history.formattedDuration,
                        isDark: isDark,
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      _StatChip(
                        icon: Icons.push_pin,
                        label: '${history.pinCount}個',
                        isDark: isDark,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(List<String> photoUrls) {
    // 最大3枚まで表示
    final displayPhotos = photoUrls.take(3).toList();
    final remainingCount = photoUrls.length - 3;

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: WanMapSpacing.md),
      child: Row(
        children: [
          // メイン写真（大きく）
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                displayPhotos[0],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPhotoPlaceholder();
                },
              ),
            ),
          ),

          // サブ写真（小さく）
          if (displayPhotos.length > 1) ...[
            const SizedBox(width: WanMapSpacing.sm),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        displayPhotos[1],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPhotoPlaceholder();
                        },
                      ),
                    ),
                  ),
                  if (displayPhotos.length > 2) ...[
                    const SizedBox(height: WanMapSpacing.sm),
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              displayPhotos[2],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPhotoPlaceholder();
                              },
                            ),
                          ),
                          // +N枚のオーバーレイ
                          if (remainingCount > 0)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '+$remainingCount',
                                    style: WanMapTypography.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: WanMapColors.accent.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.image,
          color: WanMapColors.accent.withOpacity(0.3),
          size: 48,
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
      return DateFormat('M月d日(E) HH:mm', 'ja').format(date);
    }
  }
}

/// 統計チップ
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanMapSpacing.sm,
        vertical: WanMapSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? WanMapColors.backgroundDark
            : WanMapColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark
                ? WanMapColors.textSecondaryDark
                : WanMapColors.textSecondaryLight,
          ),
          const SizedBox(width: WanMapSpacing.xs),
          Text(
            label,
            style: WanMapTypography.caption.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
