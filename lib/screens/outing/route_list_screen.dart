import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_icons.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../providers/official_route_provider.dart';
import '../../providers/area_provider.dart';
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
    final routesAsync = ref.watch(routesByAreaProvider(areaId));
    final areaAsync = ref.watch(areaByIdProvider(areaId));
    final isHakoneSubArea = areaName.startsWith('箱根・');

    return Scaffold(
      backgroundColor: WanWalkColors.bgPrimary,
      appBar: AppBar(
        title: Text('$areaNameのルート', style: WanWalkTypography.wwH2),
        backgroundColor: WanWalkColors.bgPrimary,
        foregroundColor: WanWalkColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: routesAsync.when(
        data: (routes) {
          if (routes.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(WanWalkSpacing.s4),
            itemCount: routes.length + (isHakoneSubArea ? 1 : 0),
            itemBuilder: (context, index) {
              if (isHakoneSubArea && index == 0) {
                return areaAsync.when(
                  data: (area) {
                    if (area == null || area.description.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: WanWalkSpacing.s4),
                      child: _buildTransportInfoCard(area.description),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              }

              final routeIndex = isHakoneSubArea ? index - 1 : index;
              final route = routes[routeIndex];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: routeIndex < routes.length - 1 ? WanWalkSpacing.s3 : 0,
                ),
                child: _RouteCard(
                  route: route,
                  onTap: () {
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: WanWalkColors.accentPrimary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(WanWalkIcons.warning, size: 48, color: WanWalkColors.textSecondary),
              const SizedBox(height: WanWalkSpacing.s3),
              Text(
                'ルートの読み込みに失敗しました',
                style: WanWalkTypography.wwBody.copyWith(color: WanWalkColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportInfoCard(String description) {
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.s4),
      decoration: BoxDecoration(
        color: WanWalkColors.bgSecondary,
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
        border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: WanWalkColors.accentPrimarySoft,
              borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
            ),
            child: Icon(
              WanWalkIcons.car,
              color: WanWalkColors.accentPrimary,
              size: WanWalkIcons.sizeMd,
            ),
          ),
          const SizedBox(width: WanWalkSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '交通アクセス',
                  style: WanWalkTypography.wwH4.copyWith(color: WanWalkColors.accentPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: WanWalkTypography.wwBodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            WanWalkIcons.path,
            size: 48,
            color: WanWalkColors.textSecondary,
          ),
          const SizedBox(height: WanWalkSpacing.s3),
          Text(
            'ルートがありません',
            style: WanWalkTypography.wwBody.copyWith(color: WanWalkColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// ルートカード
class _RouteCard extends StatelessWidget {
  final OfficialRoute route;
  final VoidCallback onTap;

  const _RouteCard({
    required this.route,
    required this.onTap,
  });

  ({Color bg, Color fg}) _getDifficultyStyle() {
    switch (route.difficultyLevel) {
      case DifficultyLevel.easy:
        return (bg: WanWalkColors.levelEasy, fg: WanWalkColors.textInverse);
      case DifficultyLevel.moderate:
        return (bg: WanWalkColors.bgTertiary, fg: WanWalkColors.textSecondary);
      case DifficultyLevel.hard:
        return (bg: WanWalkColors.accentPrimaryHover, fg: WanWalkColors.textInverse);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(WanWalkSpacing.s4),
        decoration: BoxDecoration(
          color: WanWalkColors.bgPrimary,
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (route.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
                child: Image.network(
                  route.thumbnailUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 180,
                      color: WanWalkColors.accentPrimarySoft,
                      alignment: Alignment.center,
                      child: Icon(
                        WanWalkIcons.path,
                        color: WanWalkColors.accentPrimary,
                        size: 36,
                      ),
                    );
                  },
                ),
              ),
            if (route.thumbnailUrl != null)
              const SizedBox(height: WanWalkSpacing.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(route.name, style: WanWalkTypography.wwH4),
                ),
                const SizedBox(width: WanWalkSpacing.s2),
                Builder(builder: (_) {
                  final s = _getDifficultyStyle();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: s.bg,
                      borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
                    ),
                    child: Text(
                      route.difficultyLevel.label,
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: s.fg,
                        height: 1.2,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              route.description,
              style: WanWalkTypography.wwCaption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: WanWalkSpacing.s3),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _StatChip(icon: WanWalkIcons.ruler, label: route.formattedDistance),
                const SizedBox(width: WanWalkSpacing.s2),
                _StatChip(icon: WanWalkIcons.clock, label: route.formattedDuration),
                const SizedBox(width: WanWalkSpacing.s2),
                _StatChip(icon: WanWalkIcons.mapPin, label: '${route.totalPins}ピン'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: WanWalkColors.accentPrimarySoft,
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: WanWalkIcons.sizeXs, color: WanWalkColors.accentPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: WanWalkTypography.wwLabel.copyWith(
              color: WanWalkColors.accentPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
