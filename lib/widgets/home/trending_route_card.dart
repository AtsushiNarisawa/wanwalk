import 'package:flutter/material.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/route_model.dart';

/// 人気急上昇ルートカード（コンパクト横スクロール用）
class TrendingRouteCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onTap;

  const TrendingRouteCard({
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
        width: 280,
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル
            _buildThumbnail(isDark),

            // ルート情報
            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 人気バッジ
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WanMapSpacing.sm,
                      vertical: WanMapSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.red.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: WanMapSpacing.xs),
                        Text(
                          '人気急上昇',
                          style: WanMapTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: WanMapSpacing.sm),

                  // ルート名
                  Text(
                    route.name ?? route.title,
                    style: WanMapTypography.bodyLarge.copyWith(
                      color: isDark
                          ? WanMapColors.textPrimaryDark
                          : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WanMapSpacing.xs),

                  // エリア名
                  if (route.areaName != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                        const SizedBox(width: WanMapSpacing.xs),
                        Expanded(
                          child: Text(
                            route.areaName!,
                            style: WanMapTypography.caption.copyWith(
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
                  const SizedBox(height: WanMapSpacing.sm),

                  // 統計情報
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
                        route.formattedDistance,
                        style: WanMapTypography.caption.copyWith(
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      Icon(
                        Icons.push_pin,
                        size: 14,
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanMapSpacing.xs),
                      Text(
                        '${route.recentPinsCount ?? 0}件',
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
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: isDark
            ? WanMapColors.backgroundDark
            : WanMapColors.backgroundLight,
      ),
      child: route.thumbnailUrl != null
          ? ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                route.thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(isDark);
                },
              ),
            )
          : _buildPlaceholder(isDark),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.landscape,
        size: 48,
        color: isDark
            ? WanMapColors.textSecondaryDark.withOpacity(0.3)
            : WanMapColors.textSecondaryLight.withOpacity(0.3),
      ),
    );
  }
}
