import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/route_search_params.dart';
import '../../providers/route_search_provider.dart';
import '../../providers/auth_provider.dart';

/// 検索結果ルートカード
class SearchRouteCard extends ConsumerWidget {
  final SearchRouteResult route;
  final VoidCallback onTap;

  const SearchRouteCard({
    super.key,
    required this.route,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

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
                  // ルート名とお気に入りボタン
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
                      _buildFavoriteButton(ref, user?.id, isDark),
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
                  if (route.elevationGainLabel != null) ...[
                    const SizedBox(height: WanMapSpacing.tiny),
                    Text(
                      route.elevationGainLabel!,
                      style: WanMapTypography.caption.copyWith(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                  const SizedBox(height: WanMapSpacing.small),
                  // ピン数と散歩回数
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
                      const SizedBox(width: WanMapSpacing.medium),
                      Icon(
                        Icons.directions_walk,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${route.totalWalks} 回',
                        style: WanMapTypography.caption,
                      ),
                      if (route.averageRating != null) ...[
                        const SizedBox(width: WanMapSpacing.medium),
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          route.averageRating!.toStringAsFixed(1),
                          style: WanMapTypography.caption,
                        ),
                      ],
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

  Widget _buildFavoriteButton(WidgetRef ref, String? userId, bool isDark) {
    if (userId == null) return const SizedBox.shrink();

    return IconButton(
      icon: Icon(
        route.isFavorited ? Icons.favorite : Icons.favorite_border,
        color: route.isFavorited ? Colors.red : null,
      ),
      onPressed: () async {
        final service = ref.read(routeSearchServiceProvider);
        try {
          await service.toggleFavorite(
            userId: userId,
            routeId: route.routeId,
            isFavorited: route.isFavorited,
          );
          // 検索結果を再読み込み
          ref.invalidate(routeSearchResultsProvider);
        } catch (e) {
          if (kDebugMode) {
            print('Error toggling favorite: $e');
          }
        }
      },
    );
  }
}
