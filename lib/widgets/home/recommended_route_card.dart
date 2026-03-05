import 'package:flutter/material.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
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
        margin: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
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
              padding: const EdgeInsets.all(WanWalkSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    route.name ?? route.title,
                    style: WanWalkTypography.headlineSmall.copyWith(
                      color: isDark
                          ? WanWalkColors.textPrimaryDark
                          : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WanWalkSpacing.sm),

                  // エリア名
                  if (route.areaName != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: WanWalkColors.accent,
                        ),
                        const SizedBox(width: WanWalkSpacing.xs),
                        Text(
                          route.areaName!,
                          style: WanWalkTypography.bodyMedium.copyWith(
                            color: WanWalkColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: WanWalkSpacing.md),

                  // 統計情報
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.straighten,
                        label: route.formattedDistance,
                        isDark: isDark,
                      ),
                      const SizedBox(width: WanWalkSpacing.sm),
                      _InfoChip(
                        icon: Icons.access_time,
                        label: '${route.duration}分',
                        isDark: isDark,
                      ),
                      const SizedBox(width: WanWalkSpacing.sm),
                      _InfoChip(
                        icon: Icons.push_pin,
                        label: '${route.totalPins ?? 0}',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: WanWalkSpacing.md),

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
                        const SizedBox(width: WanWalkSpacing.xs),
                        Text(
                          route.averageRating!.toStringAsFixed(1),
                          style: WanWalkTypography.caption.copyWith(
                            color: isDark
                                ? WanWalkColors.textSecondaryDark
                                : WanWalkColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: WanWalkSpacing.md),

                  // 説明文
                  if (route.description != null && route.description!.isNotEmpty)
                    Text(
                      route.description!,
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: isDark
                            ? WanWalkColors.textSecondaryDark
                            : WanWalkColors.textSecondaryLight,
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
            ? WanWalkColors.backgroundDark
            : WanWalkColors.backgroundLight,
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
            color: WanWalkColors.accent.withOpacity(0.3),
          ),
          const SizedBox(height: WanWalkSpacing.sm),
          Text(
            'ルート画像',
            style: WanWalkTypography.bodyMedium.copyWith(
              color: WanWalkColors.accent.withOpacity(0.5),
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
        horizontal: WanWalkSpacing.sm,
        vertical: WanWalkSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? WanWalkColors.backgroundDark
            : WanWalkColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark
                ? WanWalkColors.textSecondaryDark
                : WanWalkColors.textSecondaryLight,
          ),
          const SizedBox(width: WanWalkSpacing.xs),
          Text(
            label,
            style: WanWalkTypography.caption.copyWith(
              color: isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
