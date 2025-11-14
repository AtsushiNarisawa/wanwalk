import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';
import '../../services/favorite_service.dart';
import '../../services/photo_service.dart';
import 'route_edit_screen.dart';

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
  RouteModel? _route;
  bool _isLoading = true;
  String? _errorMessage;
  final MapController _mapController = MapController();
  bool _isFavorite = false;
  bool _isFavoriteLoading = true;
  List<RoutePhoto> _photos = [];
  bool _isPhotosLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRouteDetail();
    _checkFavoriteStatus();
    _loadPhotos();
  }

  Future<void> _loadRouteDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final route = await RouteService().getRouteDetail(widget.routeId);
      
      if (route == null) {
        setState(() {
          _errorMessage = 'ルートが見つかりませんでした';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _route = route;
        _isLoading = false;
      });

      if (route.points.isNotEmpty) {
        _fitMapToBounds(route.points.map((p) => p.latLng).toList());
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'エラーが発生しました: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isFavoriteLoading = false);
      return;
    }

    final isFav = await FavoriteService().isFavorite(widget.routeId, user.id);
    setState(() {
      _isFavorite = isFav;
      _isFavoriteLoading = false;
    });
  }

  Future<void> _loadPhotos() async {
    setState(() => _isPhotosLoading = true);
    final photos = await PhotoService().getRoutePhotos(widget.routeId);
    setState(() {
      _photos = photos;
      _isPhotosLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isFavoriteLoading = true);

    bool success;
    if (_isFavorite) {
      success = await FavoriteService().removeFavorite(widget.routeId, user.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('お気に入りから削除しました')),
        );
      }
    } else {
      success = await FavoriteService().addFavorite(widget.routeId, user.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('お気に入りに追加しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    if (success) {
      setState(() => _isFavorite = !_isFavorite);
    }

    setState(() => _isFavoriteLoading = false);
  }

  void _fitMapToBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final latMargin = (maxLat - minLat) * 0.1;
    final lngMargin = (maxLng - minLng) * 0.1;

    final bounds = LatLngBounds(
      LatLng(minLat - latMargin, minLng - lngMargin),
      LatLng(maxLat + latMargin, maxLng + lngMargin),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    });
  }

  Future<void> _addPhoto() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('写真をアップロード中...')),
    );

    final file = result == 'gallery'
        ? await PhotoService().pickImageFromGallery()
        : await PhotoService().takePhoto();

    if (file == null || !mounted) return;

    final storagePath = await PhotoService().uploadPhoto(
      file: file,
      routeId: widget.routeId,
      userId: user.id,
    );

    if (!mounted) return;

    if (storagePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('写真をアップロードしました'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPhotos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('アップロードに失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ルートを削除'),
        content: const Text('このルートを削除してもよろしいですか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _deleteRoute();
    }
  }

  Future<void> _deleteRoute() async {
    if (_route == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('削除中...')),
    );

    try {
      final success = await RouteService().deleteRoute(
        _route!.id!,
        _route!.userId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ルートを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('削除に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwnRoute = _route != null && currentUser != null && _route!.userId == currentUser.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_route?.title ?? 'ルート詳細'),
        actions: [
          _isFavoriteLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                  ),
                  tooltip: _isFavorite ? 'お気に入りから削除' : 'お気に入りに追加',
                  onPressed: _toggleFavorite,
                ),
          if (isOwnRoute)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '編集',
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RouteEditScreen(route: _route!),
                  ),
                );
                
                if (result == true) {
                  _loadRouteDetail();
                }
              },
            ),
          if (isOwnRoute)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _route != null ? () => _showDeleteDialog() : null,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRouteDetail,
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                )
              : _route == null
                  ? const Center(child: Text('ルートが見つかりませんでした'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 地図
                          SizedBox(
                            height: 300,
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _route!.points.isNotEmpty
                                    ? _route!.points.first.latLng
                                    : const LatLng(35.6762, 139.6503),
                                initialZoom: 14.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.wanmap_v2',
                                ),
                                if (_route!.points.isNotEmpty)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: _route!.points.map((p) => p.latLng).toList(),
                                        color: Colors.red,
                                        strokeWidth: 4.0,
                                      ),
                                    ],
                                  ),
                                if (_route!.points.isNotEmpty)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _route!.points.first.latLng,
                                        width: 40,
                                        height: 40,
                                        child: const Icon(Icons.play_circle, color: Colors.green, size: 40),
                                      ),
                                      Marker(
                                        point: _route!.points.last.latLng,
                                        width: 40,
                                        height: 40,
                                        child: const Icon(Icons.stop_circle, color: Colors.red, size: 40),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _route!.title,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                
                                if (_route!.description != null && _route!.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      _route!.description!,
                                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                    ),
                                  ),
                                
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _StatRow(
                                          icon: Icons.straighten,
                                          label: '距離',
                                          value: '${(_route!.distance / 1000).toStringAsFixed(2)} km',
                                        ),
                                        const Divider(),
                                        _StatRow(
                                          icon: Icons.timer,
                                          label: '時間',
                                          value: _route!.formatDuration(),
                                        ),
                                        const Divider(),
                                        _StatRow(
                                          icon: Icons.calendar_today,
                                          label: '日付',
                                          value: _route!.formatDate(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // 写真ギャラリー
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '写真',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    if (isOwnRoute)
                                      TextButton.icon(
                                        onPressed: _addPhoto,
                                        icon: const Icon(Icons.add_photo_alternate),
                                        label: const Text('追加'),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                if (_isPhotosLoading)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (_photos.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        '写真がありません',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                  )
                                else
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: _photos.length,
                                    itemBuilder: (context, index) {
                                      final photo = _photos[index];
                                      return GestureDetector(
                                        onTap: () {
                                          // TODO: 写真を拡大表示
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            photo.publicUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
