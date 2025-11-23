import 'package:flutter/material.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/user_statistics.dart';

/// お気に入りルートカード
class FavoriteRouteCard extends StatelessWidget {
  final FavoriteRoute route;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  const FavoriteRouteCard({
    super.key,
    required this.route,
    required this.onTap,
    required this.onUnfavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル画像
            _buildThumbnail(isDark),
            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ルート名とお気に入り解除ボタン
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          route.routeName,
                          style: WanMapTypography.heading3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                        ),
                        onPressed: onUnfavorite,
                        tooltip: 'お気に入りから削除',
                      ),
                    ],
                  ),
                  const SizedBox(height: WanMapSpacing.tiny),
                  // エリア名
                  Text(
                    route.areaName,
                    style: WanMapTypography.caption.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: WanMapSpacing.small),
                  // 統計情報
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.straighten,
                        route.formattedDistance,
                        isDark,
                      ),
                      const SizedBox(width: WanMapSpacing.small),
                      _buildInfoChip(
                        Icons.access_time,
                        route.formattedDuration,
                        isDark,
                      ),
                      const SizedBox(width: WanMapSpacing.small),
                      _buildInfoChip(
                        Icons.trending_up,
                        route.difficultyLabel,
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: WanMapSpacing.small),
                  // ピン数
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: WanMapColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${route.totalPins} ピン',
                        style: WanMapTypography.caption,
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
    if (route.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            route.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(isDark);
            },
          ),
        ),
      );
    }
    return _buildPlaceholder(isDark);
  }

  Widget _buildPlaceholder(bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          child: Icon(
            Icons.map,
            size: 48,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
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
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: WanMapTypography.caption,
          ),
        ],
      ),
    );
  }
}
