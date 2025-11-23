import 'package:flutter/material.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/route_model.dart';

/// おすすめルートカード（大きく目立つ表示）
class RecommendedRouteCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onTap;

  const RecommendedRouteCard({
    super.key,
    required this.route,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル画像
            _buildThumbnail(isDark),

            // ルート情報
            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    route.name ?? route.title,
                    style: WanMapTypography.headlineSmall.copyWith(
                      color: isDark
                          ? WanMapColors.textPrimaryDark
                          : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WanMapSpacing.sm),

                  // エリア名
                  if (route.areaName != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: WanMapColors.accent,
                        ),
                        const SizedBox(width: WanMapSpacing.xs),
                        Text(
                          route.areaName!,
                          style: WanMapTypography.bodyMedium.copyWith(
                            color: WanMapColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: WanMapSpacing.md),

                  // 統計情報
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.straighten,
                        label: route.formattedDistance,
                        isDark: isDark,
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      _InfoChip(
                        icon: Icons.access_time,
                        label: '${route.duration}分',
                        isDark: isDark,
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      _InfoChip(
                        icon: Icons.push_pin,
                        label: '${route.totalPins ?? 0}',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: WanMapSpacing.md),

                  // 評価
                  if (route.averageRating != null)
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (route.averageRating ?? 0).floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: WanMapSpacing.xs),
                        Text(
                          route.averageRating!.toStringAsFixed(1),
                          style: WanMapTypography.caption.copyWith(
                            color: isDark
                                ? WanMapColors.textSecondaryDark
                                : WanMapColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: WanMapSpacing.md),

                  // 説明文
                  if (route.description != null && route.description!.isNotEmpty)
                    Text(
                      route.description!,
                      style: WanMapTypography.bodyMedium.copyWith(
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: isDark
            ? WanMapColors.backgroundDark
            : WanMapColors.backgroundLight,
      ),
      child: route.thumbnailUrl != null
          ? ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(
                route.thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.landscape,
            size: 64,
            color: WanMapColors.accent.withOpacity(0.3),
          ),
          const SizedBox(height: WanMapSpacing.sm),
          Text(
            'ルート画像',
            style: WanMapTypography.bodyMedium.copyWith(
              color: WanMapColors.accent.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// 情報チップ
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({
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
            size: 16,
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
