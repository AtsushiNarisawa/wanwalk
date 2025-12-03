import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import '../../../providers/gps_provider_riverpod.dart';
import '../../../providers/official_route_provider.dart';
import '../../../providers/area_provider.dart';
import '../../../models/area.dart';
import '../../outing/area_list_screen.dart';
import '../../outing/route_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  /// 現在地を取得
  Future<void> _initializeLocation() async {
    final gpsState = ref.read(gpsProviderRiverpod);
    if (gpsState.currentLocation != null) {
      setState(() {
        _currentLocation = gpsState.currentLocation;
      });
      _mapController.move(_currentLocation!, 13.0);
    }
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

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.explore, color: WanMapColors.accent, size: 28),
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
      body: Stack(
        children: [
          // 地図表示
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
          
          // FAB: おでかけ散歩開始
          Positioned(
            right: WanMapSpacing.lg,
            bottom: WanMapSpacing.lg,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AreaListScreen()),
                );
              },
              backgroundColor: WanMapColors.accent,
              elevation: 8,
              icon: const Icon(Icons.explore, size: 28, color: Colors.white),
              label: Text(
                'おでかけ散歩',
                style: WanMapTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
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
}
