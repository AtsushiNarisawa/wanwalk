import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/official_route_provider.dart';
import '../../models/official_route.dart';
import 'route_detail_screen.dart';

/// ルート一覧画面
/// 選択したエリア内の公式ルートを表示
class RouteListScreen extends ConsumerWidget {
  final String areaId;
  final String areaName;

  const RouteListScreen({
    super.key,
    required this.areaId,
    required this.areaName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routesAsync = ref.watch(routesByAreaProvider(areaId));

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: Text('$areaNameのルート'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: routesAsync.when(
        data: (routes) {
          if (routes.isEmpty) {
            return _buildEmptyState(isDark);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(WanMapSpacing.lg),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < routes.length - 1 ? WanMapSpacing.md : 0,
                ),
                child: _RouteCard(
                  route: route,
                  isDark: isDark,
                  onTap: () {
                    // ルートを選択して詳細画面へ
                    ref.read(selectedRouteIdProvider.notifier).selectRoute(route.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RouteDetailScreen(routeId: route.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
              ),
              const SizedBox(height: WanMapSpacing.md),
              Text(
                'ルートの読み込みに失敗しました',
                style: WanMapTypography.bodyLarge.copyWith(
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_outlined,
            size: 64,
            color: isDark
                ? WanMapColors.textSecondaryDark
                : WanMapColors.textSecondaryLight,
          ),
          const SizedBox(height: WanMapSpacing.md),
          Text(
            'ルートがありません',
            style: WanMapTypography.bodyLarge.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// ルートカード
class _RouteCard extends StatelessWidget {
  final OfficialRoute route;
  final bool isDark;
  final VoidCallback onTap;

  const _RouteCard({
    required this.route,
    required this.isDark,
    required this.onTap,
  });

  Color _getDifficultyColor() {
    switch (route.difficultyLevel) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.moderate:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(WanMapSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル画像
            if (route.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  route.thumbnailUrl!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
                      child: Icon(
                        Icons.image_not_supported,
                        color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                      ),
                    );
                  },
                ),
              ),
            if (route.thumbnailUrl != null)
              const SizedBox(width: WanMapSpacing.md),
            // ルート情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ルート名と難易度バッジ
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          route.name,
                          style: WanMapTypography.bodyLarge.copyWith(
                            color: isDark
                                ? WanMapColors.textPrimaryDark
                                : WanMapColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WanMapSpacing.sm,
                          vertical: WanMapSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          route.difficultyLevel.label,
                          style: WanMapTypography.caption.copyWith(
                            color: _getDifficultyColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WanMapSpacing.sm),
                  // 説明
                  Text(
                    route.description,
                    style: WanMapTypography.caption.copyWith(
                      color: isDark
                          ? WanMapColors.textSecondaryDark
                          : WanMapColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WanMapSpacing.md),
                  // 統計情報
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.straighten,
                        label: route.formattedDistance,
                        isDark: isDark,
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      _StatChip(
                        icon: Icons.timer,
                        label: route.formattedDuration,
                        isDark: isDark,
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      _StatChip(
                        icon: Icons.push_pin,
                        label: '${route.totalPins}ピン',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
        color: WanMapColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: WanMapColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: WanMapTypography.caption.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
