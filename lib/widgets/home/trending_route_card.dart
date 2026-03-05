import 'package:flutter/material.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
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
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
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
              padding: const EdgeInsets.all(WanWalkSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 人気バッジ
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WanWalkSpacing.sm,
                      vertical: WanWalkSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: WanWalkColors.accent,
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
                        const SizedBox(width: WanWalkSpacing.xs),
                        Text(
                          '人気急上昇',
                          style: WanWalkTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: WanWalkSpacing.sm),

                  // ルート名
                  Text(
                    route.name ?? route.title,
                    style: WanWalkTypography.bodyLarge.copyWith(
                      color: isDark
                          ? WanWalkColors.textPrimaryDark
                          : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WanWalkSpacing.xs),

                  // エリア名
                  if (route.areaName != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: isDark
                              ? WanWalkColors.textSecondaryDark
                              : WanWalkColors.textSecondaryLight,
                        ),
                        const SizedBox(width: WanWalkSpacing.xs),
                        Expanded(
                          child: Text(
                            route.areaName!,
                            style: WanWalkTypography.caption.copyWith(
                              color: isDark
                                  ? WanWalkColors.textSecondaryDark
                                  : WanWalkColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: WanWalkSpacing.sm),

                  // 統計情報
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
                        route.formattedDistance,
                        style: WanWalkTypography.caption.copyWith(
                          color: isDark
                              ? WanWalkColors.textSecondaryDark
                              : WanWalkColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: WanWalkSpacing.sm),
                      Icon(
                        Icons.push_pin,
                        size: 14,
                        color: isDark
                            ? WanWalkColors.textSecondaryDark
                            : WanWalkColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanWalkSpacing.xs),
                      Text(
                        '${route.recentPinsCount ?? 0}件',
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
            ? WanWalkColors.backgroundDark
            : WanWalkColors.backgroundLight,
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
            ? WanWalkColors.textSecondaryDark.withOpacity(0.3)
            : WanWalkColors.textSecondaryLight.withOpacity(0.3),
      ),
    );
  }
}
