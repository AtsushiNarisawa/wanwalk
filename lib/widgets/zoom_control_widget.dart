import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../config/wanmap_colors.dart';
import '../config/wanmap_spacing.dart';

/// 地図のズームコントロールウィジェット
/// 
/// + / - ボタンで地図の拡大縮小を操作
class ZoomControlWidget extends StatelessWidget {
  final MapController mapController;
  final double? currentZoom;
  final double minZoom;
  final double maxZoom;
  final double zoomStep;

  const ZoomControlWidget({
    super.key,
    required this.mapController,
    this.currentZoom,
    this.minZoom = 8.0,
    this.maxZoom = 18.0,
    this.zoomStep = 1.0,
  });

  void _zoomIn() {
    final zoom = currentZoom ?? mapController.camera.zoom;
    if (zoom < maxZoom) {
      mapController.move(
        mapController.camera.center,
        (zoom + zoomStep).clamp(minZoom, maxZoom),
      );
    }
  }

  void _zoomOut() {
    final zoom = currentZoom ?? mapController.camera.zoom;
    if (zoom > minZoom) {
      mapController.move(
        mapController.camera.center,
        (zoom - zoomStep).clamp(minZoom, maxZoom),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ズームインボタン
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _zoomIn,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add,
                  color: WanMapColors.textPrimaryLight,
                  size: 24,
                ),
              ),
            ),
          ),
          // 区切り線
          Container(
            width: 44,
            height: 1,
            color: Colors.grey[300],
          ),
          // ズームアウトボタン
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _zoomOut,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.remove,
                  color: WanMapColors.textPrimaryLight,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
