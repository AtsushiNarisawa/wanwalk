import 'package:flutter/material.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../models/official_route.dart';

/// 公式ルート紹介カード（大きな写真 + 体験ストーリー冒頭）
class RouteFeedCard extends StatelessWidget {
  final OfficialRoute route;
  final bool isDark;
  final bool isNew;
  final bool isSeasonal;
  final String? seasonLabel;
  final VoidCallback onTap;

  const RouteFeedCard({
    super.key,
    required this.route,
    required this.isDark,
    this.isNew = false,
    this.isSeasonal = false,
    this.seasonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 体験ストーリーの最初の段落を取得
    final firstParagraph = route.description
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .firstOrNull ?? route.description;
    final preview = firstParagraph.length > 100
        ? '${firstParagraph.substring(0, 100)}...'
        : firstParagraph;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: WanWalkSpacing.lg,
          vertical: WanWalkSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル写真（大きく表示）
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: route.thumbnailUrl != null
                      ? Image.network(
                          route.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
                // バッジ（新着 or 季節おすすめ）
                if (isNew || isSeasonal)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isNew ? Colors.red : WanWalkColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNew ? Icons.new_releases : Icons.wb_sunny,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isNew ? 'NEW' : (seasonLabel ?? '季節のおすすめ'),
                            style: WanWalkTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // 距離・時間バッジ
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(route.distanceMeters / 1000).toStringAsFixed(1)}km・約${route.estimatedMinutes}分',
                      style: WanWalkTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // テキスト部分
            Padding(
              padding: const EdgeInsets.all(WanWalkSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: WanWalkTypography.bodyLarge.copyWith(
                      color: isDark
                          ? WanWalkColors.textPrimaryDark
                          : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preview,
                    style: WanWalkTypography.bodySmall.copyWith(
                      color: isDark
                          ? WanWalkColors.textSecondaryDark
                          : WanWalkColors.textSecondaryLight,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'ルートを見る',
                        style: WanWalkTypography.bodySmall.copyWith(
                          color: WanWalkColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14, color: WanWalkColors.accent),
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

  Widget _photoPlaceholder() {
    return Container(
      color: WanWalkColors.accent.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.map, size: 48, color: WanWalkColors.accent.withValues(alpha: 0.3)),
      ),
    );
  }
}
