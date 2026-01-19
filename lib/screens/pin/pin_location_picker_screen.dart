import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_spacing.dart';
import '../../config/wanmap_typography.dart';
import '../../providers/gps_provider_riverpod.dart';
import '../../widgets/zoom_control_widget.dart';
import '../outing/pin_create_screen.dart';

/// ピン投稿の場所選択画面
/// 
/// マップ中央に十字マーカーを表示し、
/// マップをドラッグして場所を選択する
class PinLocationPickerScreen extends ConsumerStatefulWidget {
  final String? routeId;
  final String? routeName;

  const PinLocationPickerScreen({
    super.key,
    this.routeId,
    this.routeName,
  });

  @override
  ConsumerState<PinLocationPickerScreen> createState() => _PinLocationPickerScreenState();
}

class _PinLocationPickerScreenState extends ConsumerState<PinLocationPickerScreen> {
  late final MapController _mapController;
  LatLng _currentLocation = const LatLng(35.4437, 139.6380); // デフォルト値を設定

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // 現在地を取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  /// 現在地を初期化
  Future<void> _initializeLocation() async {
    final gpsState = ref.read(gpsProviderRiverpod);
    
    if (gpsState.currentLocation != null && mounted) {
      setState(() {
        _currentLocation = gpsState.currentLocation!;
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// マップの中心座標を取得
  LatLng _getSelectedLocation() {
    return _mapController.camera.center;
  }

  /// 現在地に移動
  void _moveToCurrentLocation() {
    final gpsState = ref.read(gpsProviderRiverpod);
    if (gpsState.currentLocation != null) {
      _mapController.move(gpsState.currentLocation!, 17.0);
      setState(() {
        _currentLocation = gpsState.currentLocation!;
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

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.routeName != null ? '${widget.routeName}にピンを投稿' : 'ピンを投稿'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // マップ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 17.0, // 場所選択に適した詳細なズーム
              minZoom: 5.0,
              maxZoom: 19.0, // より詳細に見られるように上限を上げる
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.doghub.wanwalk',
              ),
            ],
          ),

          // 中央の十字マーカー（見やすい赤色 + 白い縁取り）
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 白い縁取り（外側）
                Icon(
                  Icons.add_location_alt,
                  size: 52,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
                // 赤いマーカー（内側）
                Icon(
                  Icons.add_location_alt,
                  size: 48,
                  color: Colors.red,
                ),
              ],
            ),
          ),

          // 上部ガイド
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(WanMapSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? WanMapColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: WanMapColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: WanMapSpacing.sm),
                  Expanded(
                    child: Text(
                      'マップを動かして投稿する場所を選択してください',
                      style: WanMapTypography.bodySmall.copyWith(
                        color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 右下: 現在地ボタン + ズームコントロール
          Positioned(
            right: WanMapSpacing.md,
            bottom: 90, // ボタンの上
            child: Column(
              children: [
                // 現在地ボタン（目立つ配色）
                FloatingActionButton(
                  heroTag: 'pin_location_current_location',
                  mini: true,
                  backgroundColor: WanMapColors.accent,
                  foregroundColor: Colors.white,
                  onPressed: _moveToCurrentLocation,
                  tooltip: '現在地に移動',
                  elevation: 6,
                  child: const Icon(Icons.my_location, size: 20),
                ),
                const SizedBox(height: WanMapSpacing.sm),
                // ズームコントロール
                ZoomControlWidget(
                  mapController: _mapController,
                  minZoom: 5.0,
                  maxZoom: 19.0,
                ),
              ],
            ),
          ),

          // 下部: ここに投稿ボタン
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: () {
                final selectedLocation = _getSelectedLocation();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PinCreateScreen(
                      routeId: widget.routeId ?? '',
                      location: selectedLocation,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WanMapColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 24),
                  const SizedBox(width: WanMapSpacing.sm),
                  Text(
                    'ここに投稿',
                    style: WanMapTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
