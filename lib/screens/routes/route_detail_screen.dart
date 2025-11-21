import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/env.dart';
import '../../config/wanmap_colors.dart';
import '../../models/route_model.dart';
import '../../providers/route_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/photo_service.dart';

/// ルート詳細画面
class RouteDetailScreen extends StatefulWidget {
  final String routeId;
  
  const RouteDetailScreen({
    super.key,
    required this.routeId,
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final MapController _mapController = MapController();
  final PhotoService _photoService = PhotoService();
  List<RoutePhoto> _photos = [];
  bool _isLoadingPhotos = false;

  @override
  void initState() {
    super.initState();
    _loadRouteDetail();
    _loadPhotos();
  }

  /// ルート詳細を読み込み
  Future<void> _loadRouteDetail() async {
    final routeProvider = context.read<RouteProvider>();
    await routeProvider.getRouteDetail(widget.routeId);
  }

  /// 写真を読み込み
  Future<void> _loadPhotos() async {
    setState(() => _isLoadingPhotos = true);
    
    try {
      final photos = await _photoService.getRoutePhotos(widget.routeId);
      if (mounted) {
        setState(() {
          _photos = photos;
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPhotos = false);
      }
    }
  }

  /// ルートを削除
  Future<void> _deleteRoute(RouteModel route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ルートを削除'),
        content: Text('「${route.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final authProvider = context.read<AuthProvider>();
      final routeProvider = context.read<RouteProvider>();
      final userId = authProvider.currentUser?.id;
      
      if (userId != null) {
        final success = await routeProvider.deleteRoute(widget.routeId, userId);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ルートを削除しました'),
                backgroundColor: WanMapColors.success,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('削除に失敗しました'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WanMapColors.background,
      body: Consumer<RouteProvider>(
        builder: (context, routeProvider, child) {
          if (routeProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          final route = routeProvider.selectedRoute;
          if (route == null) {
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
                  const Text(
                    'ルート情報を取得できませんでした',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRouteDetail,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            );
          }
          
          return CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: WanMapColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    route.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                  background: route.points.isNotEmpty
                      ? FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: route.points.first.latLng,
                            initialZoom: 14.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=${Environment.thunderforestApiKey}',
                              userAgentPackageName: 'com.example.wanmap',
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: route.points.map((p) => p.latLng).toList(),
                                  color: WanMapColors.accent,
                                  strokeWidth: 4.0,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                // スタート地点
                                Marker(
                                  point: route.points.first.latLng,
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                // ゴール地点
                                Marker(
                                  point: route.points.last.latLng,
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.flag,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.map,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
                actions: [
                  // 自分のルートの場合は削除ボタンを表示
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.currentUser?.id == route.userId) {
                        return IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteRoute(route),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              
              // コンテンツ
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 統計情報
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.straighten,
                              label: '距離',
                              value: route.formatDistance(),
                              color: WanMapColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.timer,
                              label: '時間',
                              value: route.formatDuration(),
                              color: WanMapColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.location_on,
                              label: 'ポイント数',
                              value: '${route.points.length}',
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.speed,
                              label: '平均速度',
                              value: route.averageSpeed,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // 説明
                      if (route.description != null && route.description!.isNotEmpty) ...[
                        const Text(
                          '説明',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          route.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // 日時
                      const Text(
                        '記録日時',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            route.formatDate(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // 写真ギャラリー
                      const Text(
                        '写真',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (_isLoadingPhotos)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_photos.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.photo_library,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '写真がありません',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _photos.length,
                            itemBuilder: (context, index) {
                              final photo = _photos[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ClipRRectangle(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    photo.publicUrl,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
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
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 統計カード
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// ClipRRectの修正版
class ClipRRectangle extends StatelessWidget {
  final BorderRadius borderRadius;
  final Widget child;
  
  const ClipRRectangle({
    super.key,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: child,
    );
  }
}
