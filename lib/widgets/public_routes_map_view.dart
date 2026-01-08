import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/area_info.dart';

/// 公開ルートマップビュー
class PublicRoutesMapView extends StatefulWidget {
  final List<RouteModel> routes;
  final Function(String routeId)? onRouteTapped;
  final String? selectedArea;

  const PublicRoutesMapView({
    super.key,
    required this.routes,
    this.onRouteTapped,
    this.selectedArea,
  });

  @override
  State<PublicRoutesMapView> createState() => _PublicRoutesMapViewState();
}

class _PublicRoutesMapViewState extends State<PublicRoutesMapView> {
  final MapController _mapController = MapController();
  bool _isExpanded = true;

  // ルートの色（全て統一）
  static const List<Color> routeColors = [
    Colors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    final displayHeight = _isExpanded ? 400.0 : 250.0;

    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            child: Row(
              children: [
                Icon(
                  Icons.map,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'マップビュー',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${widget.routes.length}件のルート',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    setState(() => _isExpanded = !_isExpanded);
                  },
                  tooltip: _isExpanded ? '折りたたむ' : '展開する',
                ),
              ],
            ),
          ),
          
          // マップ
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: displayHeight,
            child: widget.routes.isEmpty
                ? _buildEmptyState()
                : _buildMap(),
          ),
        ],
      ),
    );
  }

  /// 空の状態
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ルートがありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// マップを構築
  Widget _buildMap() {
    // マップの中心と範囲を計算
    final mapCenter = _calculateMapCenter();
    final mapBounds = _calculateMapBounds();

    // マップを範囲にフィット
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mapBounds != null && mounted) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: mapBounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    });

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mapCenter,
        initialZoom: 12.0,
        minZoom: 8.0,
        maxZoom: 16.0,
      ),
      children: [
        // タイルレイヤー
        TileLayer(
          urlTemplate: Theme.of(context).brightness == Brightness.dark
              ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.doghub.wanwalk',
        ),
        
        // ルート軌跡レイヤー
        ..._buildRoutePolylines(),
        
        // ルートマーカーレイヤー
        ..._buildRouteMarkers(),
      ],
    );
  }

  /// マップの中心を計算
  LatLng _calculateMapCenter() {
    // エリアが選択されている場合はそのエリアの中心
    if (widget.selectedArea != null) {
      final area = AreaInfo.getById(widget.selectedArea!);
      if (area != null) {
        return area.center;
      }
    }

    // ルートがある場合は最初のルートの中心
    if (widget.routes.isNotEmpty) {
      final route = widget.routes.first;
      if (route.points.isNotEmpty) {
        return route.points.first.latLng;
      }
    }

    // デフォルト: 箱根
    return const LatLng(35.25, 139.05);
  }

  /// マップの範囲を計算
  LatLngBounds? _calculateMapBounds() {
    if (widget.routes.isEmpty) return null;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final route in widget.routes) {
      for (final point in route.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
    }

    if (minLat == double.infinity) return null;

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  /// ルート軌跡ポリライン
  List<Widget> _buildRoutePolylines() {
    return widget.routes.asMap().entries.map((entry) {
      final index = entry.key;
      final route = entry.value;
      final color = routeColors[index % routeColors.length];

      return PolylineLayer(
        polylines: [
          Polyline(
            points: route.points.map((p) => p.latLng).toList(),
            color: color.withOpacity(0.7),
            strokeWidth: 3.0,
          ),
        ],
      );
    }).toList();
  }

  /// ルートマーカー
  List<Widget> _buildRouteMarkers() {
    return widget.routes.asMap().entries.map((entry) {
      final index = entry.key;
      final route = entry.value;
      
      if (route.points.isEmpty) {
        return const SizedBox.shrink();
      }

      final startPoint = route.points.first;
      final color = routeColors[index % routeColors.length];

      return MarkerLayer(
        markers: [
          Marker(
            point: startPoint.latLng,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                if (route.id != null && widget.onRouteTapped != null) {
                  widget.onRouteTapped!(route.id!);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color,
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
                  Icons.pets,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }
}
