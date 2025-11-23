import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../services/home_stats_service.dart';

/// 最近の思い出写真カード
class RecentMemoryCard extends StatelessWidget {
  final RecentMemory memory;
  final VoidCallback onTap;

  const RecentMemoryCard({
    super.key,
    required this.memory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 写真
              AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  memory.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark
                          ? WanMapColors.cardDark
                          : WanMapColors.cardLight,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // オーバーレイ（グラデーション）
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // 情報
              Positioned(
                bottom: WanMapSpacing.sm,
                left: WanMapSpacing.sm,
                right: WanMapSpacing.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ルート名
                    Text(
                      memory.routeName,
                      style: WanMapTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: WanMapSpacing.xs),

                    // 日付
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 10,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: WanMapSpacing.xs),
                        Text(
                          _formatDate(memory.walkedAt),
                          style: WanMapTypography.caption.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ピン数バッジ
              if (memory.pinCount > 0)
                Positioned(
                  top: WanMapSpacing.xs,
                  right: WanMapSpacing.xs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WanMapSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.push_pin,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${memory.pinCount}',
                          style: WanMapTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return '今日';
    } else if (difference == 1) {
      return '昨日';
    } else if (difference < 7) {
      return '${difference}日前';
    } else {
      return DateFormat('M/d').format(date);
    }
  }
}
