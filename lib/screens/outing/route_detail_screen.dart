import 'package:flutter/foundation.dart';
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

                  const SizedBox(height: WanMapSpacing.xl),

                  // ギャラリーセクション
                  if (kDebugMode) {
                    print('🖼️ Gallery check: galleryImages = ${route.galleryImages}');
                    print('🖼️ Gallery check: isNull = ${route.galleryImages == null}');
                    print('🖼️ Gallery check: isEmpty = ${route.galleryImages?.isEmpty}');
                  }
                  if (route.galleryImages != null && route.galleryImages!.isNotEmpty)
                    _buildGallerySection(route, isDark),

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
    if (route.routeLine != null) {
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
            markers: _buildMarkers(route),
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
  /// ルートの境界に基づいて適切なズームレベルを計算
  double _calculateZoom(OfficialRoute route) {
    if (route.routeLine == null || route.routeLine!.isEmpty) {
      return 15.0;
    }
    
    // ルートの緯度経度の範囲を計算
    double minLat = route.routeLine!.first.latitude;
    double maxLat = route.routeLine!.first.latitude;
    double minLon = route.routeLine!.first.longitude;
    double maxLon = route.routeLine!.first.longitude;
    
    for (var point in route.routeLine!) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }
    
    // 緯度経度の差分（度）
    final latDiff = maxLat - minLat;
    final lonDiff = maxLon - minLon;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;
    
    // 差分に基づいてズームレベルを計算（経験則）
    if (maxDiff > 0.1) return 11.0;  // 約10km以上
    if (maxDiff > 0.05) return 12.5; // 約5km
    if (maxDiff > 0.02) return 13.5; // 約2km
    if (maxDiff > 0.01) return 14.5; // 約1km
    if (maxDiff > 0.005) return 15.5; // 約500m
    return 16.5; // 500m未満
  }
  /// マーカーを構築（スタート=ゴールの場合は特別表示）
  List<Marker> _buildMarkers(OfficialRoute route) {
    
    // route_lineが存在する場合は、その最初と最後の点を使用
    final actualStart = route.routeLine != null && route.routeLine!.isNotEmpty
        ? route.routeLine!.first
        : route.startLocation;
    final actualEnd = route.routeLine != null && route.routeLine!.isNotEmpty
        ? route.routeLine!.last
        : route.endLocation;
    
    
    final isSameLocation = actualStart.latitude == actualEnd.latitude &&
                           actualStart.longitude == actualEnd.longitude;

    if (isSameLocation) {
      // スタート=ゴールの場合：緑と赤の半円マーカー
      return [
        Marker(
          alignment: Alignment.center,
          point: actualStart,
          width: 40,
          height: 40,
          child: Stack(
            children: [
              // 左半分：緑（スタート）
              Positioned(
                left: 0,
                child: Container(
                  width: 20,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.flag, color: Colors.white, size: 16),
                ),
              ),
              // 右半分：赤（ゴール）
              Positioned(
                right: 0,
                child: Container(
                  width: 20,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.sports_score, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // スタート≠ゴールの場合：別々のマーカー
    return [
      // スタートマーカー
      Marker(
        alignment: Alignment.center,
        point: actualStart,
        width: 32,
        height: 32,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.flag, color: Colors.white, size: 16),
        ),
      ),
      // ゴールマーカー
      Marker(
        alignment: Alignment.center,
        point: actualEnd,
        width: 32,
        height: 32,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.sports_score, color: Colors.white, size: 16),
        ),
      ),
    ];
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

  /// ギャラリーセクション
  Widget _buildGallerySection(OfficialRoute route, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションタイトル
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Text(
            'ルートの写真',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: WanMapSpacing.md),
        // ギャラリー画像（横スクロール）
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
            itemCount: route.galleryImages!.length,
            itemBuilder: (context, index) {
              final imageUrl = route.galleryImages![index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < route.galleryImages!.length - 1
                      ? WanMapSpacing.md
                      : 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 280,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 280,
                        height: 200,
                        color: isDark
                            ? WanMapColors.surfaceDark
                            : WanMapColors.surfaceLight,
                        child: Icon(
                          Icons.image_not_supported,
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
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
