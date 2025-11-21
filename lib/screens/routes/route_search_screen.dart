import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/env.dart';
import '../../config/wanmap_colors.dart';
import '../../models/route_model.dart';
import '../../providers/route_provider.dart';
import 'route_detail_screen.dart';

/// ルート検索画面
class RouteSearchScreen extends StatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  
  bool _isMapView = false;
  
  @override
  void initState() {
    super.initState();
    _loadPublicRoutes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 公開ルート一覧を読み込み
  Future<void> _loadPublicRoutes() async {
    final routeProvider = context.read<RouteProvider>();
    await routeProvider.loadPublicRoutes(includePoints: _isMapView);
  }

  /// 検索を実行
  Future<void> _search() async {
    final area = _searchController.text.trim();
    final routeProvider = context.read<RouteProvider>();
    
    await routeProvider.loadPublicRoutes(
      area: area.isEmpty ? null : area,
      includePoints: _isMapView,
    );
  }

  /// ビューを切り替え
  void _toggleView() {
    setState(() {
      _isMapView = !_isMapView;
    });
    _loadPublicRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WanMapColors.background,
      appBar: AppBar(
        title: const Text('ルート検索'),
        backgroundColor: WanMapColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: _toggleView,
            tooltip: _isMapView ? 'リスト表示' : 'マップ表示',
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'エリアで検索（例: 箱根、渋谷）',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _search();
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          
          // コンテンツ
          Expanded(
            child: Consumer<RouteProvider>(
              builder: (context, routeProvider, child) {
                if (routeProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (routeProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          routeProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPublicRoutes,
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!routeProvider.hasPublicRoutes) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.route,
                          size: 100,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '公開ルートが見つかりません',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '別の条件で検索してみてください',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // マップ表示
                if (_isMapView) {
                  return _MapView(
                    routes: routeProvider.publicRoutes,
                    mapController: _mapController,
                    onRouteTap: (route) => _navigateToDetail(route),
                  );
                }
                
                // リスト表示
                return RefreshIndicator(
                  onRefresh: _loadPublicRoutes,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: routeProvider.publicRoutes.length,
                    itemBuilder: (context, index) {
                      final route = routeProvider.publicRoutes[index];
                      return _RouteCard(
                        route: route,
                        onTap: () => _navigateToDetail(route),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ルート詳細画面に遷移
  Future<void> _navigateToDetail(RouteModel route) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteDetailScreen(routeId: route.id!),
      ),
    );
  }
}

/// ルートカード
class _RouteCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onTap;
  
  const _RouteCard({
    required this.route,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              Text(
                route.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // 説明
              if (route.description != null && route.description!.isNotEmpty)
                Text(
                  route.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              
              // 統計情報
              Row(
                children: [
                  _StatItem(
                    icon: Icons.straighten,
                    label: route.formatDistance(),
                  ),
                  const SizedBox(width: 16),
                  _StatItem(
                    icon: Icons.timer,
                    label: route.formatDuration(),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
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

/// 統計項目
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _StatItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: WanMapColors.primary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// マップ表示
class _MapView extends StatelessWidget {
  final List<RouteModel> routes;
  final MapController mapController;
  final Function(RouteModel) onRouteTap;
  
  const _MapView({
    required this.routes,
    required this.mapController,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    // 全ルートの中心点を計算
    LatLng center = const LatLng(35.6812, 139.7671); // デフォルト: 東京
    
    if (routes.isNotEmpty && routes.first.points.isNotEmpty) {
      double totalLat = 0;
      double totalLng = 0;
      int count = 0;
      
      for (final route in routes) {
        if (route.points.isNotEmpty) {
          totalLat += route.points.first.latLng.latitude;
          totalLng += route.points.first.latLng.longitude;
          count++;
        }
      }
      
      if (count > 0) {
        center = LatLng(totalLat / count, totalLng / count);
      }
    }
    
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=${Environment.thunderforestApiKey}',
          userAgentPackageName: 'com.example.wanmap',
        ),
        
        // ルートを描画
        PolylineLayer(
          polylines: routes.where((route) => route.points.isNotEmpty).map((route) {
            return Polyline(
              points: route.points.map((p) => p.latLng).toList(),
              color: WanMapColors.accent.withOpacity(0.7),
              strokeWidth: 3.0,
            );
          }).toList(),
        ),
        
        // スタート地点のマーカー
        MarkerLayer(
          markers: routes.where((route) => route.points.isNotEmpty).map((route) {
            return Marker(
              point: route.points.first.latLng,
              width: 30,
              height: 30,
              child: GestureDetector(
                onTap: () => onRouteTap(route),
                child: Container(
                  decoration: BoxDecoration(
                    color: WanMapColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.place,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// RouteDetailScreenのプレースホルダー（後で実装）
class RouteDetailScreen extends StatelessWidget {
  final String routeId;
  
  const RouteDetailScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ルート詳細'),
      ),
      body: Center(
        child: Text('Route ID: $routeId'),
      ),
    );
  }
}
