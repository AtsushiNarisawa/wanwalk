import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_spacing.dart';
import '../../config/wanmap_typography.dart';
import '../../providers/gps_provider_riverpod.dart';
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
    
    print('🗺️ PinLocationPicker: initState called');
    print('🗺️ Initial location: $_currentLocation');
    
    // 現在地を取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🗺️ PinLocationPicker: postFrameCallback started');
      _initializeLocation();
    });
  }

  /// 現在地を初期化
  Future<void> _initializeLocation() async {
    print('🗺️ PinLocationPicker: _initializeLocation started');
    final gpsState = ref.read(gpsProviderRiverpod);
    print('🗺️ GPS currentLocation: ${gpsState.currentLocation}');
    
    if (gpsState.currentLocation != null && mounted) {
      setState(() {
        _currentLocation = gpsState.currentLocation!;
      });
      print('🗺️ Updated location: $_currentLocation');
    } else {
      print('🗺️ Using default location: $_currentLocation');
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
          // マップ - マップタブと同じ構造
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.doghub.wanwalk',
              ),
            ],
          ),

          // 中央の十字マーカー
          Center(
            child: Icon(
              Icons.add_location_alt,
              size: 48,
              color: WanMapColors.accent,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.3),
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
