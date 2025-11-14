import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/gps_service.dart';
import '../../config/supabase_config.dart';

/// マップ画面
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final GpsService _gpsService = GpsService();
  
  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isRecording = false;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }

    /// マップ初期化
  Future<void> _initializeMap() async {
    // 現在位置を取得
    final position = await _gpsService.getCurrentPosition();
    
    if (mounted) {
      setState(() {
        _currentPosition = position ?? const LatLng(35.6762, 139.6503); // デフォルト：東京
        _isLoading = false;
      });

      // マップが構築された後に移動
      if (_currentPosition != null) {
        // 少し遅延を入れてMapControllerが完全に初期化されるのを待つ
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _mapController.move(_currentPosition!, 15.0);
        }
      }
    }
  }

  /// ルート記録開始
  Future<void> _startRecording() async {
    final success = await _gpsService.startRecording();
    
    if (success && mounted) {
      setState(() {
        _isRecording = true;
        _routePoints.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ルート記録を開始しました'),
          backgroundColor: Colors.green,
        ),
      );

      // 定期的にポイントを更新
      _startPointUpdateTimer();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('記録を開始できませんでした。位置情報の権限を確認してください。'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ルート記録停止
  void _stopRecording() {
    final userId = SupabaseConfig.userId;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログインしてください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // タイトル入力ダイアログ
    _showSaveRouteDialog(userId);
  }

  /// ルート保存ダイアログ
  void _showSaveRouteDialog(String userId) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ルートを保存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                hintText: '朝の散歩',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '説明（任意）',
                hintText: '公園を一周',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('タイトルを入力してください'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final route = _gpsService.stopRecording(
                userId: userId,
                title: title,
                description: descriptionController.text.trim(),
              );

              Navigator.pop(context);

              if (route != null && mounted) {
                setState(() {
                  _isRecording = false;
                  _routePoints.clear();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'ルートを保存しました\n距離: ${route.formatDistance()}, 時間: ${route.formatDuration()}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// ポイント更新タイマー
  void _startPointUpdateTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_isRecording && mounted) {
        setState(() {
          _routePoints = _gpsService.currentRoutePoints
              .map((point) => point.latLng)
              .toList();
        });
        _startPointUpdateTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('マップ'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        actions: [
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '記録中 (${_gpsService.currentPointCount}点)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // 地図表示
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentPosition ?? const LatLng(35.6762, 139.6503),
              zoom: 15.0,
            ),
            children: [
              // OpenStreetMapタイル
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.wanmap_v2',
              ),
              
              // 記録中のルート
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF4A90E2),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              
              // 現在位置マーカー
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 現在位置ボタン
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'current_location',
              onPressed: () async {
                final position = await _gpsService.getCurrentPosition();
                if (position != null) {
                  setState(() {
                    _currentPosition = position;
                  });
                  _mapController.move(position, 15.0);
                }
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Color(0xFF4A90E2)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        backgroundColor: _isRecording ? Colors.red : const Color(0xFF7ED321),
        icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
        label: Text(_isRecording ? '記録停止' : '記録開始'),
      ),
    );
  }
}
