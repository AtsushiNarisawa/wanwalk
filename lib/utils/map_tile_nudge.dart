import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// flutter_map の「初回タイル取得レース」回避ヘルパー。
///
/// 一部端末で、FlutterMap を開いた直後にタイルが取得されず
/// 「地図が青いまま／現在地ボタン等で動かすまで出ない」事象が発生する。
/// 初回レイアウトでマップサイズが確定する前に TileLayer が可視タイルを
/// 計算してしまい、その後の再取得が発火しないことが原因。
///
/// [MapOptions.onMapReady] から呼ぶと、初回フレーム確定後にカメラへ
/// 極小のズーム差を与えて [MapController.move] し、TileLayer の再計算
/// （＝初回タイル取得）を確実に発火させる。差は 1e-6 と微小なため、
/// 見た目・タイルのズーム階層（floor(zoom)）には影響しない。
void nudgeMapTiles(MapController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      final camera = controller.camera;
      controller.move(camera.center, camera.zoom + 0.000001);
    } catch (_) {
      // controller が未 attach / dispose 済みのケースは無視（害なし）。
    }
  });
}
