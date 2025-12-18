import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

/// エリア情報モデル
class AreaInfo {
  final String id;
  final String name;
  final String displayName;
  final String prefecture;
  final LatLng center;
  final LatLngBounds bounds;
  final String description;
  final String emoji;

  AreaInfo({
    required this.id,
    required this.name,
    required this.displayName,
    required this.prefecture,
    required this.center,
    required this.bounds,
    required this.description,
    required this.emoji,
  });

  /// エリア情報の初期ズームレベル
  double get defaultZoom => 12.0;

  /// エリアマスターデータ
  static final List<AreaInfo> areas = [
    // 箱根エリア（小田原含む）
    AreaInfo(
      id: 'hakone',
      name: '箱根',
      displayName: '箱根',
      prefecture: '神奈川県',
      center: const LatLng(35.25, 139.05),
      bounds: LatLngBounds(
        const LatLng(35.15, 138.95),   // 南西（小田原市を含むよう拡大）
        const LatLng(35.35, 139.15),   // 北東（箱根全域をカバー）
      ),
      description: '箱根・小田原エリアの散歩ルート',
      emoji: '🏔️',
    ),

    // 伊豆エリア
    AreaInfo(
      id: 'izu',
      name: '伊豆',
      displayName: '伊豆',
      prefecture: '静岡県',
      center: const LatLng(34.95, 139.0),
      bounds: LatLngBounds(
        const LatLng(34.8, 138.8),   // 南西
        const LatLng(35.1, 139.2),   // 北東
      ),
      description: '伊豆半島の海岸線と温泉街',
      emoji: '🏖️',
    ),

    // 那須エリア
    AreaInfo(
      id: 'nasu',
      name: '那須',
      displayName: '那須',
      prefecture: '栃木県',
      center: const LatLng(37.1, 140.0),
      bounds: LatLngBounds(
        const LatLng(37.0, 139.9),   // 南西
        const LatLng(37.2, 140.1),   // 北東
      ),
      description: '那須高原のリゾート地域',
      emoji: '♨️',
    ),

    // 軽井沢エリア
    AreaInfo(
      id: 'karuizawa',
      name: '軽井沢',
      displayName: '軽井沢',
      prefecture: '長野県',
      center: const LatLng(36.4, 138.6),
      bounds: LatLngBounds(
        const LatLng(36.3, 138.5),   // 南西
        const LatLng(36.5, 138.7),   // 北東
      ),
      description: '軽井沢の避暑地と森林散歩',
      emoji: '🌲',
    ),

    // 富士山周辺エリア
    AreaInfo(
      id: 'fuji',
      name: '富士山周辺',
      displayName: '富士',
      prefecture: '山梨県',
      center: const LatLng(35.4, 138.75),
      bounds: LatLngBounds(
        const LatLng(35.3, 138.6),   // 南西
        const LatLng(35.5, 138.9),   // 北東
      ),
      description: '富士五湖と富士山麓エリア',
      emoji: '🗻',
    ),

    // 鎌倉エリア
    AreaInfo(
      id: 'kamakura',
      name: '鎌倉',
      displayName: '鎌倉',
      prefecture: '神奈川県',
      center: const LatLng(35.35, 139.55),
      bounds: LatLngBounds(
        const LatLng(35.3, 139.5),   // 南西
        const LatLng(35.4, 139.6),   // 北東
      ),
      description: '古都鎌倉の歴史散歩ルート',
      emoji: '🏯',
    ),
  ];

  /// IDからエリア情報を取得
  static AreaInfo? getById(String id) {
    try {
      return areas.firstWhere((area) => area.id == id);
    } catch (e) {
      return null;
    }
  }

  /// すべてのエリアIDを取得
  static List<String> getAllIds() {
    return areas.map((area) => area.id).toList();
  }

  /// すべてのエリア名を取得
  static List<String> getAllNames() {
    return areas.map((area) => area.name).toList();
  }

  /// GPS座標からエリアを自動判定
  static AreaInfo? detectAreaFromCoordinate(LatLng coordinate) {
    for (final area in areas) {
      if (_isInBounds(coordinate, area.bounds)) {
        return area;
      }
    }
    return null;
  }

  /// 座標が範囲内にあるかチェック
  static bool _isInBounds(LatLng point, LatLngBounds bounds) {
    return point.latitude >= bounds.south &&
           point.latitude <= bounds.north &&
           point.longitude >= bounds.west &&
           point.longitude <= bounds.east;
  }

  @override
  String toString() => '$emoji $displayName ($prefecture)';
}
