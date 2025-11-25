import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/official_route_provider.dart';
import '../../providers/route_pin_provider.dart';
import '../../models/official_route.dart';
import 'walking_screen.dart';

/// ルート詳細画面
/// 公式ルートの詳細情報とピン一覧を表示
class RouteDetailScreen extends ConsumerWidget {
  final String routeId;

  const RouteDetailScreen({
    super.key,
    required this.routeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routeAsync = ref.watch(routeByIdProvider(routeId));
    final pinsAsync = ref.watch(pinsByRouteProvider(routeId));

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: const Text('ルート詳細'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: routeAsync.when(
        data: (route) {
          if (route == null) {
            return const Center(child: Text('ルートが見つかりません'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 地図セクション
                _buildMapSection(route, pinsAsync, isDark),
                Padding(
                  padding: const EdgeInsets.all(WanMapSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // ルート名
                  Text(
                    route.name,
                    style: WanMapTypography.headlineMedium.copyWith(
                      color: isDark
                          ? WanMapColors.textPrimaryDark
                          : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: WanMapSpacing.xl),

                  // 統計情報
                  _buildStats(route, isDark),

                  const SizedBox(height: WanMapSpacing.xl),

                  // 説明
                  _buildDescription(route, isDark),

                  const SizedBox(height: WanMapSpacing.xl),

                  // 散歩を開始ボタン
                  _buildStartButton(context, isDark, route),

                  const SizedBox(height: WanMapSpacing.xxxl),

                  // ピンセクション
                  _buildPinsSection(context, ref, pinsAsync, isDark),
                ],
              ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  /// 地図セクション
  Widget _buildMapSection(OfficialRoute route, AsyncValue pinsAsync, bool isDark) {
    print('🗺️ Building map for route: ${route.name}');
    print('🗺️ Route line points: ${route.routeLine?.length ?? 0}');
    if (route.routeLine != null) {
      print('🗺️ First point: ${route.routeLine!.first}');
      print('🗺️ Last point: ${route.routeLine!.last}');
    }
    return Container(
      height: 300,
      color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: _calculateCenter(route),
          initialZoom: _calculateZoom(route),
          minZoom: 10.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.doghub.wanmap',
          ),
          if (route.routeLine != null && route.routeLine!.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: route.routeLine!,
                  strokeWidth: 4.0,
                  color: WanMapColors.accent,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              Marker(
                point: route.startLocation,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.flag, color: Colors.white, size: 20),
                ),
              ),
              Marker(
                point: route.endLocation,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.sports_score, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  /// ルートの中心点を計算
  LatLng _calculateCenter(OfficialRoute route) {
    if (route.routeLine == null || route.routeLine!.isEmpty) {
      return route.startLocation;
    }
    double latSum = 0;
    double lonSum = 0;
    for (var point in route.routeLine!) {
      latSum += point.latitude;
      lonSum += point.longitude;
    }
    return LatLng(
      latSum / route.routeLine!.length,
      lonSum / route.routeLine!.length,
    );
  }

  /// ルートの距離に基づいてズームレベルを計算
  double _calculateZoom(OfficialRoute route) {
    final distance = route.distanceMeters;
    if (distance < 500) return 16.0;
    if (distance < 1000) return 15.0;
    if (distance < 2000) return 14.5;
    if (distance < 5000) return 13.5;
    if (distance < 10000) return 12.5;
    return 11.0;
  }


  /// 統計情報
  Widget _buildStats(OfficialRoute route, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.straighten,
            label: '距離',
            value: route.formattedDistance,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: WanMapSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.timer,
            label: '所要時間',
            value: route.formattedDuration,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: WanMapSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.push_pin,
            label: 'ピン',
            value: '${route.totalPins}個',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  /// 説明
  Widget _buildDescription(OfficialRoute route, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ルートについて',
          style: WanMapTypography.headlineSmall.copyWith(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanMapSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(WanMapSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.description,
                style: WanMapTypography.bodyMedium.copyWith(
                  color: isDark
                      ? WanMapColors.textPrimaryDark
                      : WanMapColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: WanMapSpacing.md),
              _DifficultyBadge(
                level: route.difficultyLevel,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 散歩を開始ボタン
  Widget _buildStartButton(BuildContext context, bool isDark, OfficialRoute route) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WalkingScreen(route: route),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: WanMapColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: WanMapColors.accent.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk, size: 28),
            const SizedBox(width: WanMapSpacing.sm),
            Text(
              'このルートを歩く',
              style: WanMapTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ピンセクション
  Widget _buildPinsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue pinsAsync,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'みんなのピン',
          style: WanMapTypography.headlineSmall.copyWith(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanMapSpacing.md),
        pinsAsync.when(
          data: (pins) {
            if (pins.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(WanMapSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.push_pin_outlined,
                        size: 48,
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(height: WanMapSpacing.md),
                      Text(
                        'まだピンがありません',
                        style: WanMapTypography.bodyLarge.copyWith(
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: pins.map((pin) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: WanMapSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(WanMapSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.title,
                          style: WanMapTypography.bodyMedium.copyWith(
                            color: isDark
                                ? WanMapColors.textPrimaryDark
                                : WanMapColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: WanMapSpacing.xs),
                        Text(
                          pin.comment,
                          style: WanMapTypography.caption.copyWith(
                            color: isDark
                                ? WanMapColors.textSecondaryDark
                                : WanMapColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: WanMapSpacing.sm),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${pin.likesCount}',
                              style: WanMapTypography.caption.copyWith(
                                color: isDark
                                    ? WanMapColors.textSecondaryDark
                                    : WanMapColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(width: WanMapSpacing.md),
                            Text(
                              pin.relativeTime,
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
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('エラー: $error'),
        ),
      ],
    );
  }
}

/// 統計カード
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: WanMapColors.accent,
            size: 28,
          ),
          const SizedBox(height: WanMapSpacing.xs),
          Text(
            label,
            style: WanMapTypography.caption.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: WanMapSpacing.xs),
          Text(
            value,
            style: WanMapTypography.bodyLarge.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 難易度バッジ
class _DifficultyBadge extends StatelessWidget {
  final DifficultyLevel level;
  final bool isDark;

  const _DifficultyBadge({
    required this.level,
    required this.isDark,
  });

  Color _getColor() {
    switch (level) {
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanMapSpacing.md,
        vertical: WanMapSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getColor(),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            color: _getColor(),
            size: 20,
          ),
          const SizedBox(width: WanMapSpacing.xs),
          Text(
            '難易度: ${level.label}',
            style: WanMapTypography.bodyMedium.copyWith(
              color: _getColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: WanMapSpacing.xs),
          Text(
            '(${level.description})',
            style: WanMapTypography.caption.copyWith(
              color: _getColor(),
            ),
          ),
        ],
      ),
    );
  }
}
