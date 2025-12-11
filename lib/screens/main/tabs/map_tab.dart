import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show asin, cos, pi, sin, sqrt;
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import '../../../providers/gps_provider_riverpod.dart';
import '../../../providers/official_route_provider.dart';
import '../../../providers/official_routes_screen_provider.dart';
import '../../../providers/area_provider.dart';
import '../../../models/area.dart';
import '../../../models/official_route.dart';
import '../../../widgets/zoom_control_widget.dart';
import '../../outing/area_list_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../daily/daily_walking_screen.dart';

/// MapTab - おでかけ散歩の中心（公式ルート、エリア、ピン）
/// 
/// 構成:
/// - リアルタイム地図表示
/// - 周辺の公式ルートをマーカー表示
/// - 現在地ボタン
/// - 検索ボタン
/// - FAB: おでかけ散歩開始
class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isFirstLoad = true; // 初回ロードフラグ

  @override
  void initState() {
    super.initState();
    // GPS情報は build メソッド内で ref.watch() で監視
  }

  /// 現在地に移動
  void _moveToCurrentLocation() {
    final gpsState = ref.read(gpsProviderRiverpod);
    if (gpsState.currentLocation != null) {
      _mapController.move(gpsState.currentLocation!, 15.0);
      setState(() {
        _currentLocation = gpsState.currentLocation;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('現在地を取得できませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final areasAsync = ref.watch(areasProvider);
    
    // GPS情報を監視して現在地を更新
    final gpsState = ref.watch(gpsProviderRiverpod);
    if (gpsState.currentLocation != null && _currentLocation != gpsState.currentLocation) {
      // 現在地が初めて取得された、または更新された場合
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentLocation = gpsState.currentLocation;
        });
        // 初回のみマップを現在地に移動
        if (_isFirstLoad && _currentLocation != null) {
          _mapController.move(_currentLocation!, 13.0);
          _isFirstLoad = false;
        }
      });
    }

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.map, color: WanMapColors.accent, size: 28),
            const SizedBox(width: WanMapSpacing.sm),
            Text(
              'マップ',
              style: WanMapTypography.headlineMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: '現在地',
            onPressed: _moveToCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          // 地図表示（画面の約2/3）
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? const LatLng(35.3192, 139.5503),
                    initialZoom: 13.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.doghub.wanmap',
                    ),
                    // 現在地マーカー
                    if (_currentLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    // 全エリアのルートマーカー
                    areasAsync.when(
                      data: (areas) {
                        return _buildAllRoutesMarkers(context, ref, areas);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                // ズームコントロール（右下）
                Positioned(
                  right: WanMapSpacing.lg,
                  bottom: WanMapSpacing.lg,
                  child: ZoomControlWidget(
                    mapController: _mapController,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                ),
              ],
            ),
          ),
          
          // カード領域（画面の約1/3）
          Expanded(
            child: Column(
              children: [
                // ボタングループ（カード上部に配置）
                Container(
                  padding: EdgeInsets.all(WanMapSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // お散歩ボタン（日常散歩）
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DailyWalkingScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WanMapColors.accent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: WanMapSpacing.md,
                              horizontal: WanMapSpacing.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(WanMapSpacing.md),
                            ),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.pets, size: 24),
                          label: Text(
                            'お散歩',
                            style: WanMapTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: WanMapSpacing.md),
                      
                      // お出かけ散歩ボタン（既存）
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AreaListScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WanMapColors.accent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: WanMapSpacing.md,
                              horizontal: WanMapSpacing.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(WanMapSpacing.md),
                            ),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.explore, size: 24),
                          label: Text(
                            'おでかけ散歩',
                            style: WanMapTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // おすすめルートカード領域
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final gpsState = ref.watch(gpsProviderRiverpod);
                      final routesAsync = ref.watch(officialRoutesProvider);

                      // 現在地が取得できていない場合
                      if (gpsState.currentLocation == null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_searching,
                                size: 48,
                                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                              ),
                              const SizedBox(height: WanMapSpacing.md),
                              Text(
                                '現在地を取得中...',
                                style: WanMapTypography.bodyMedium.copyWith(
                                  color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // ルートデータを取得
                      return routesAsync.when(
                        data: (allRoutes) {
                          final recommendedRoutes = _getRecommendedRoutes(
                            gpsState.currentLocation!,
                            allRoutes,
                          );
                          return _buildRecommendedRouteCards(recommendedRoutes);
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: WanMapSpacing.md),
                              Text(
                                'ルートの取得に失敗しました',
                                style: WanMapTypography.bodyMedium.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 全エリアのルートマーカーを構築
  Widget _buildAllRoutesMarkers(BuildContext context, WidgetRef ref, List<Area> areas) {
    List<Marker> allMarkers = [];
    
    // エリアごとの色を定義
    final areaColors = {
      '箱根': Colors.orange,
      '横浜': Colors.blue,
      '鎌倉': Colors.green,
    };

    for (final area in areas) {
      final routesAsync = ref.watch(routesByAreaProvider(area.id));
      
      routesAsync.whenData((routes) {
        for (final route in routes) {
          final markerColor = areaColors[area.name] ?? WanMapColors.accent;
          
          allMarkers.add(
            Marker(
              point: route.startLocation,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailScreen(routeId: route.id),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.route,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        }
      });
    }

    return MarkerLayer(markers: allMarkers);
  }

  /// デフォルトのサムネイル画像
  Widget _buildDefaultThumbnail() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: WanMapColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.route,
        size: 32,
        color: WanMapColors.accent,
      ),
    );
  }

  /// 現在地から近いおすすめルートを取得（20km以内、上位3件）
  List<Map<String, dynamic>> _getRecommendedRoutes(
    LatLng currentLocation,
    List<OfficialRoute> allRoutes,
  ) {
    final List<Map<String, dynamic>> nearbyRoutes = [];

    for (final route in allRoutes) {
      final distance = _calculateDistance(
        currentLocation,
        route.startLocation,
      );

      if (distance <= 20.0) {
        // 20km以内
        nearbyRoutes.add({
          'route': route,
          'distance': distance,
        });
      }
    }

    // 距離でソート → 上位3件取得
    nearbyRoutes.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    return nearbyRoutes.take(3).toList();
  }

  /// Haversine公式で2地点間の距離を計算（km単位）
  double _calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371.0; // 地球の半径（km）
    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final dLat = (point2.latitude - point1.latitude) * pi / 180;
    final dLon = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));

    return R * c;
  }

  /// エリアIDから日本語名を取得（ハードコーディング）
  String _getAreaName(String areaId) {
    const areaNames = {
      'hakone': '箱根',
      'yokohama': '横浜',
      'kamakura': '鎌倉',
    };
    return areaNames[areaId] ?? areaId;
  }

  /// エリア名から色を取得
  Color _getAreaColor(String areaName) {
    const areaColors = {
      '箱根': Colors.orange,
      '横浜': Colors.blue,
      '鎌倉': Colors.green,
    };
    return areaColors[areaName] ?? WanMapColors.accent;
  }

  /// おすすめルートカードを構築
  Widget _buildRecommendedRouteCards(List<Map<String, dynamic>> routes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: WanMapSpacing.md,
            vertical: WanMapSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.recommend,
                color: WanMapColors.accent,
                size: 20,
              ),
              const SizedBox(width: WanMapSpacing.xs),
              Text(
                '近くのおすすめルート',
                style: WanMapTypography.headlineSmall.copyWith(
                  color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: WanMapSpacing.xs),
              if (routes.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: WanMapSpacing.sm,
                    vertical: WanMapSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: WanMapColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${routes.length}件',
                    style: WanMapTypography.bodySmall.copyWith(
                      color: WanMapColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // ルートカードリスト または 0件メッセージ
        Expanded(
          child: routes.isEmpty
              ? _buildEmptyState(isDark)
              : _buildRouteList(routes, isDark),
        ),
      ],
    );
  }

  /// 0件の場合のUI
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(WanMapSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 64,
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
            const SizedBox(height: WanMapSpacing.md),
            Text(
              '現在地から20km以内に\nおすすめルートがありません',
              textAlign: TextAlign.center,
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: WanMapSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AreaListScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WanMapColors.accent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: WanMapSpacing.lg,
                  vertical: WanMapSpacing.md,
                ),
              ),
              icon: const Icon(Icons.list),
              label: const Text('エリア一覧を見る'),
            ),
          ],
        ),
      ),
    );
  }

  /// ルートリスト
  Widget _buildRouteList(List<Map<String, dynamic>> routes, bool isDark) {

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: WanMapSpacing.md,
        vertical: WanMapSpacing.sm,
      ),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final routeData = routes[index];
        final route = routeData['route'] as OfficialRoute;
        final distance = routeData['distance'] as double;
        final areaName = _getAreaName(route.areaId);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RouteDetailScreen(routeId: route.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: EdgeInsets.only(bottom: WanMapSpacing.md),
            padding: const EdgeInsets.all(WanMapSpacing.md),
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
              children: [
                // サムネイル
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: route.thumbnailUrl != null
                      ? Image.network(
                          route.thumbnailUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultThumbnail(),
                        )
                      : _buildDefaultThumbnail(),
                ),
                const SizedBox(width: WanMapSpacing.md),
                // ルート情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ルート名
                      Text(
                        route.name,
                        style: WanMapTypography.bodyLarge.copyWith(
                          color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: WanMapSpacing.xs),
                      // エリア名
                      Text(
                        areaName,
                        style: WanMapTypography.bodySmall.copyWith(
                          color: WanMapColors.accent,
                        ),
                      ),
                      const SizedBox(height: WanMapSpacing.xs),
                      // 距離・現在地からの距離
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 14,
                            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            route.formattedDistance,
                            style: WanMapTypography.bodySmall.copyWith(
                              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: WanMapSpacing.sm),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: WanMapColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${distance.toStringAsFixed(1)}km',
                              style: WanMapTypography.bodySmall.copyWith(
                                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
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
      },
    );
  }
}
