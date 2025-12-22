import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/official_route_provider.dart';
import '../../providers/route_pin_provider.dart';
import '../../providers/gps_provider_riverpod.dart';
import '../../providers/pin_like_provider.dart';
import '../../providers/pin_bookmark_provider.dart';
import '../../providers/pin_comment_provider.dart';
import '../../providers/route_spots_provider.dart';

import '../../models/official_route.dart';
import '../../models/route_spot.dart';
import '../../models/walk_mode.dart';
import 'walking_screen.dart';
import 'pin_detail_screen.dart';
import 'pin_comment_screen.dart';
import '../daily/daily_walking_screen.dart';

/// ルート詳細画面
/// 公式ルートの詳細情報とピン一覧を表示
class RouteDetailScreen extends ConsumerStatefulWidget {
  final String routeId;

  const RouteDetailScreen({
    super.key,
    required this.routeId,
  });

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  // ピンをすべて表示するかどうかの状態
  bool _showAllPins = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routeAsync = ref.watch(routeByIdProvider(widget.routeId));
    final pinsAsync = ref.watch(pinsByRouteProvider(widget.routeId));

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: const Text('ルート詳細'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: routeAsync.maybeWhen(
        data: (route) => route != null ? _buildFAB(context, isDark, route) : null,
        orElse: () => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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

                  // ルートタイムライン（スポット情報）
                  _buildRouteTimelineSection(route.id, isDark),

                  const SizedBox(height: WanMapSpacing.xl),

                  // 愛犬家向け情報
                  if (route.petInfo != null && route.petInfo!.hasAnyInfo) ...[
                    _buildPetInfoSection(route.petInfo!, isDark),
                    const SizedBox(height: WanMapSpacing.xl),
                  ],

                  // ギャラリーセクション
                  if (route.galleryImages != null && route.galleryImages!.isNotEmpty) ...[
                    _buildGallerySection(route, isDark),
                    const SizedBox(height: WanMapSpacing.xl),
                  ],

                  const SizedBox(height: WanMapSpacing.xl),

                  // ピンセクション
                  _buildPinsSection(context, ref, pinsAsync, isDark),
                  
                  // FABの高さ分のスペース確保
                  const SizedBox(height: 80),
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
          // スタート/ゴールマーカー
          MarkerLayer(
            markers: _buildMarkers(route),
          ),
          // ピンマーカー
          pinsAsync.when(
            data: (pins) {
              return MarkerLayer(
                markers: pins.map<Marker>((pin) {
                  return Marker(
                    point: pin.location,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_on,
                      color: WanMapColors.accent,
                      size: 40,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
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
    return Column(
      children: [
        // 1行目: 距離・所要時間
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.straighten,
                label: '距離',
                value: route.formattedDistance,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: WanMapSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: Icons.timer,
                label: '所要時間',
                value: route.formattedDuration,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: WanMapSpacing.sm),
        // 2行目: ピン数・総散歩回数
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.push_pin,
                label: 'ピン',
                value: '${route.totalPins}個',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: WanMapSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: Icons.directions_walk,
                label: '総散歩回数',
                value: '${route.totalWalks}回',
                isDark: isDark,
              ),
            ),
          ],
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

  /// 散歩を開始ボタン（散歩中の場合は「進行中の散歩に戻る」ボタンに変更）
  /// Floating Action Button（散歩開始ボタン）
  Widget _buildFAB(BuildContext context, bool isDark, OfficialRoute route) {
    final gpsState = ref.watch(gpsProviderRiverpod);
    final isRecording = gpsState.isRecording;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      width: double.infinity,
      height: 56,
      child: FloatingActionButton.extended(
        onPressed: () {
          if (isRecording) {
            // 散歩中の場合：進行中の散歩画面へ遷移
            _navigateToActiveWalk(context, gpsState);
          } else {
            // 散歩中でない場合：新しい散歩を開始
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WalkingScreen(route: route),
              ),
            );
          }
        },
        backgroundColor: isRecording 
            ? WanMapColors.secondary  // 散歩中は異なる色
            : WanMapColors.accent,
        elevation: 8,
        icon: Icon(
          isRecording ? Icons.my_location : Icons.directions_walk, 
          size: 28,
          color: Colors.white,
        ),
        label: Text(
          isRecording ? '進行中の散歩に戻る' : 'このルートを歩く',
          style: WanMapTypography.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 進行中の散歩画面へ遷移
  void _navigateToActiveWalk(BuildContext context, GpsState gpsState) {
    if (gpsState.walkMode == WalkMode.daily) {
      // Daily Walk画面へ遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DailyWalkingScreen(),
        ),
      );
    } else {
      // Outing Walk: マップタブから確認する案内
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('別のルートを散歩中です。画面下部のバナーから確認してください。'),
          backgroundColor: WanMapColors.secondary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// ルートタイムラインセクション（スポット情報）
  Widget _buildRouteTimelineSection(String routeId, bool isDark) {
    final spotsAsync = ref.watch(routeSpotsProvider(routeId));

    return spotsAsync.when(
      data: (spots) {
        if (spots.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🗺️ ルートタイムライン',
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
              padding: const EdgeInsets.all(WanMapSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: spots.asMap().entries.map((entry) {
                  final index = entry.key;
                  final spot = entry.value;
                  final isLast = index == spots.length - 1;

                  return _buildSpotCard(spot, isLast, isDark);
                }).toList(),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(WanMapSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        print('❌ スポット情報取得エラー: $error');
        return const SizedBox.shrink();
      },
    );
  }

  /// スポットカードの構築
  Widget _buildSpotCard(RouteSpot spot, bool isLast, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タイムライン表示（縦線とアイコン）
        Column(
          children: [
            _buildSpotIcon(spot.spotType, isDark),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: WanMapSpacing.md),
        // スポット情報
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: WanMapSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // スポット名とタイプ
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spot.name,
                        style: WanMapTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? WanMapColors.textPrimaryDark
                              : WanMapColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    if (spot.isOptional)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: WanMapColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '立ち寄り任意',
                          style: WanMapTypography.caption.copyWith(
                            color: WanMapColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // 距離と時間
                Text(
                  'スタートから ${spot.formattedDistance} • ${spot.formattedTime}',
                  style: WanMapTypography.bodySmall.copyWith(
                    color: isDark
                        ? WanMapColors.textSecondaryDark
                        : WanMapColors.textSecondaryLight,
                  ),
                ),
                // 説明
                if (spot.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    spot.description!,
                    style: WanMapTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanMapColors.textPrimaryDark
                          : WanMapColors.textPrimaryLight,
                    ),
                  ),
                ],
                // アクティビティ提案
                if (spot.activitySuggestions != null &&
                    spot.activitySuggestions!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: spot.activitySuggestions!.map((activity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity,
                          style: WanMapTypography.caption.copyWith(
                            color: Colors.blue,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                // 季節情報
                if (spot.seasonalNotes != null && spot.seasonalNotes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.green.withOpacity(0.2)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: spot.seasonalNotes!.entries.map((entry) {
                        return Text(
                          '${_getSeasonEmoji(entry.key)} ${entry.value}',
                          style: WanMapTypography.caption.copyWith(
                            color: isDark
                                ? WanMapColors.textPrimaryDark
                                : WanMapColors.textPrimaryLight,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                // 参考情報（Tips）
                if (spot.tips != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spot.tips!,
                          style: WanMapTypography.caption.copyWith(
                            color: isDark
                                ? WanMapColors.textSecondaryDark
                                : WanMapColors.textSecondaryLight,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // 施設情報（施設タイプの場合）
                if (spot.facilityType != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.store,
                        size: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        spot.facilityType!,
                        style: WanMapTypography.caption.copyWith(
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                      ),
                      if (spot.petFriendly == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '🐕 ペット同伴OK',
                            style: WanMapTypography.caption.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                // 営業時間
                if (spot.openingHours != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        spot.openingHours!,
                        style: WanMapTypography.caption.copyWith(
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// スポットタイプに応じたアイコン
  Widget _buildSpotIcon(RouteSpotType spotType, bool isDark) {
    IconData icon;
    Color color;

    switch (spotType) {
      case RouteSpotType.start:
        icon = Icons.flag;
        color = Colors.green;
        break;
      case RouteSpotType.landscape:
        icon = Icons.landscape;
        color = Colors.blue;
        break;
      case RouteSpotType.photoSpot:
        icon = Icons.camera_alt;
        color = Colors.purple;
        break;
      case RouteSpotType.facility:
        icon = Icons.store;
        color = Colors.orange;
        break;
      case RouteSpotType.end:
        icon = Icons.sports_score;
        color = Colors.red;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  /// 季節に応じた絵文字を返す
  String _getSeasonEmoji(String season) {
    switch (season) {
      case 'spring':
      case '春':
        return '🌸';
      case 'summer':
      case '夏':
        return '☀️';
      case 'autumn':
      case 'fall':
      case '秋':
        return '🍁';
      case 'winter':
      case '冬':
        return '❄️';
      default:
        return '🗓️';
    }
  }

  /// 愛犬家向け情報セクション
  /// 愛犬家向け情報セクション
  Widget _buildPetInfoSection(PetInfo petInfo, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🐕 愛犬家向け情報',
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
          padding: const EdgeInsets.all(WanMapSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 駐車場
              if (petInfo.parking != null) ...[
                _buildPetInfoItem(
                  icon: Icons.local_parking,
                  label: '駐車場',
                  value: petInfo.parking!,
                  isDark: isDark,
                ),
                const SizedBox(height: WanMapSpacing.md),
              ],
              // 道の状態
              if (petInfo.surface != null) ...[
                _buildPetInfoItem(
                  icon: Icons.landscape,
                  label: '道の状態',
                  value: petInfo.surface!,
                  isDark: isDark,
                ),
                const SizedBox(height: WanMapSpacing.md),
              ],
              // 水飲み場
              if (petInfo.waterStation != null) ...[
                _buildPetInfoItem(
                  icon: Icons.water_drop,
                  label: '水飲み場',
                  value: petInfo.waterStation!,
                  isDark: isDark,
                ),
                const SizedBox(height: WanMapSpacing.md),
              ],
              // トイレ
              if (petInfo.restroom != null) ...[
                _buildPetInfoItem(
                  icon: Icons.wc,
                  label: 'トイレ',
                  value: petInfo.restroom!,
                  isDark: isDark,
                ),
                const SizedBox(height: WanMapSpacing.md),
              ],
              // ペット施設
              if (petInfo.petFacilities != null) ...[
                _buildPetInfoItem(
                  icon: Icons.store,
                  label: 'ペット施設',
                  value: petInfo.petFacilities!,
                  isDark: isDark,
                ),
                const SizedBox(height: WanMapSpacing.md),
              ],
              // その他
              if (petInfo.others != null) ...[
                _buildPetInfoItem(
                  icon: Icons.info_outline,
                  label: 'その他',
                  value: petInfo.others!,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 愛犬家向け情報の個別アイテム
  Widget _buildPetInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: WanMapColors.accent,
          size: 24,
        ),
        const SizedBox(width: WanMapSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: WanMapTypography.bodySmall.copyWith(
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: WanMapTypography.bodyMedium.copyWith(
                  color: isDark
                      ? WanMapColors.textPrimaryDark
                      : WanMapColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
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
            // 表示するピンの数を決定
            final displayPins = _showAllPins ? pins : pins.take(3).toList();
            final hasMorePins = pins.length > 3;
            
            return Column(
              children: [
                // ピンカードリスト
                ...displayPins.map<Widget>((pin) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: WanMapSpacing.md),
                  child: GestureDetector(
                    onTap: () {
                      // ピン詳細画面へ遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PinDetailScreen(pinId: pin.id),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // サムネイル画像（固定サイズ120x120）
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: pin.hasPhotos
                                  ? Image.network(
                                      pin.photoUrls.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildDefaultPinImage(),
                                    )
                                  : _buildDefaultPinImage(),
                            ),
                          // テキスト情報
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(WanMapSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // タイトル
                                  Text(
                                    pin.title,
                                    style: WanMapTypography.bodyMedium.copyWith(
                                      color: isDark
                                          ? WanMapColors.textPrimaryDark
                                          : WanMapColors.textPrimaryLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: WanMapSpacing.xs),
                                  // コメント
                                  Text(
                                    pin.comment,
                                    style: WanMapTypography.bodySmall.copyWith(
                                      color: isDark
                                          ? WanMapColors.textSecondaryDark
                                          : WanMapColors.textSecondaryLight,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: WanMapSpacing.sm),
                                  // いいね・コメント・ブックマーク・相対時間
                                  Row(
                                    children: [
                                      _PinLikeButton(
                                        pinId: pin.id,
                                        initialLikesCount: pin.likesCount,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(width: WanMapSpacing.sm),
                                      _PinCommentButton(
                                        pinId: pin.id,
                                        pinTitle: pin.title,
                                        initialCommentsCount: pin.commentsCount,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(width: WanMapSpacing.sm),
                                      _PinBookmarkButton(
                                        pinId: pin.id,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(width: WanMapSpacing.sm),
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
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
                
                // 「もっと見る」/「閉じる」ボタン
                if (hasMorePins)
                  Padding(
                    padding: const EdgeInsets.only(top: WanMapSpacing.md),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAllPins = !_showAllPins;
                        });
                      },
                      icon: Icon(_showAllPins ? Icons.expand_less : Icons.expand_more),
                      label: Text(
                        _showAllPins 
                            ? '閉じる' 
                            : 'もっと見る (残り${pins.length - 3}件)',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WanMapColors.accent,
                        side: BorderSide(color: WanMapColors.accent),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('エラー: $error'),
        ),
      ],
    );
  }

  /// デフォルトピン画像
  Widget _buildDefaultPinImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: WanMapColors.accent.withOpacity(0.2),
      ),
      child: Icon(
        Icons.photo,
        size: 40,
        color: WanMapColors.accent,
      ),
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
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: WanMapColors.accent,
            size: 22,
          ),
          const SizedBox(height: 3.0),
          Text(
            label,
            style: WanMapTypography.caption.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 3.0),
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

/// ピンいいねボタン - 楽観的UI更新対応
class _PinLikeButton extends ConsumerStatefulWidget {
  final String pinId;
  final int initialLikesCount;
  final bool isDark;

  const _PinLikeButton({
    required this.pinId,
    required this.initialLikesCount,
    required this.isDark,
  });

  @override
  ConsumerState<_PinLikeButton> createState() => _PinLikeButtonState();
}

class _PinLikeButtonState extends ConsumerState<_PinLikeButton> {
  @override
  void initState() {
    super.initState();
    // いいね状態を初期化
    Future.microtask(() {
      ref.read(pinLikeActionsProvider).initializePinLikeState(
        widget.pinId,
        widget.initialLikesCount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = ref.watch(pinLikedStateProvider(widget.pinId));
    final likeCount = ref.watch(pinLikeCountProvider(widget.pinId));
    final actions = ref.read(pinLikeActionsProvider);

    return GestureDetector(
      onTap: () async {
        final success = await actions.toggleLike(widget.pinId);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('いいねの更新に失敗しました')),
          );
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            size: 16,
            color: isLiked ? Colors.red : (widget.isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(width: 4),
          Text(
            '$likeCount',
            style: WanMapTypography.caption.copyWith(
              color: widget.isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// ピンブックマークボタン - 楽観的UI更新対応
class _PinBookmarkButton extends ConsumerStatefulWidget {
  final String pinId;
  final bool isDark;

  const _PinBookmarkButton({
    required this.pinId,
    required this.isDark,
  });

  @override
  ConsumerState<_PinBookmarkButton> createState() => _PinBookmarkButtonState();
}

class _PinBookmarkButtonState extends ConsumerState<_PinBookmarkButton> {
  @override
  void initState() {
    super.initState();
    // ブックマーク状態を初期化
    Future.microtask(() {
      ref.read(pinBookmarkActionsProvider).initializePinBookmarkState(
        widget.pinId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBookmarked = ref.watch(pinBookmarkedStateProvider(widget.pinId));
    final actions = ref.read(pinBookmarkActionsProvider);

    return GestureDetector(
      onTap: () async {
        final success = await actions.toggleBookmark(widget.pinId);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ブックマークの更新に失敗しました')),
          );
        }
      },
      child: Icon(
        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        size: 16,
        color: isBookmarked 
            ? WanMapColors.accent 
            : (widget.isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
    );
  }
}

/// ピンコメントボタン - 楽観的UI更新対応
class _PinCommentButton extends ConsumerStatefulWidget {
  final String pinId;
  final String pinTitle;
  final int initialCommentsCount;
  final bool isDark;

  const _PinCommentButton({
    required this.pinId,
    required this.pinTitle,
    required this.initialCommentsCount,
    required this.isDark,
  });

  @override
  ConsumerState<_PinCommentButton> createState() => _PinCommentButtonState();
}

class _PinCommentButtonState extends ConsumerState<_PinCommentButton> {
  @override
  void initState() {
    super.initState();
    // コメント数を初期化
    Future.microtask(() {
      ref.read(pinCommentActionsProvider).initializeCommentCount(
        widget.pinId,
        widget.initialCommentsCount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentCount = ref.watch(pinCommentCountProvider(widget.pinId));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PinCommentScreen(
              pinId: widget.pinId,
              pinTitle: widget.pinTitle,
            ),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 16,
            color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '$commentCount',
            style: WanMapTypography.caption.copyWith(
              color: widget.isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
