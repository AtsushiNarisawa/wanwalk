import 'package:latlong2/latlong.dart';

/// エリアマスタモデル
/// 箱根、横浜、鎌倉などの観光・都市エリア
class Area {
  final String id;
  final String name;
  final String description;
  final LatLng centerLocation;
  final DateTime createdAt;

  Area({
    required this.id,
    required this.name,
    required this.description,
    required this.centerLocation,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Supabaseから取得したJSONをAreaオブジェクトに変換
  factory Area.fromJson(Map<String, dynamic> json) {
    print('🔵 Area.fromJson: $json');
    
    // center_pointから座標を抽出（GEOGRAPHY型の場合）
    double latitude = 35.6762; // デフォルト値（東京）
    double longitude = 139.6503;
    
    if (json['center_point'] != null) {
      try {
        // PostGISのGEOGRAPHY型はバイナリで返ってくる
        // Supabase PostgRESTはGeoJSON形式にも対応
        final centerPoint = json['center_point'];
        
        if (centerPoint is Map) {
          // GeoJSON形式の場合
          final coordinates = centerPoint['coordinates'] as List;
          longitude = (coordinates[0] as num).toDouble();
          latitude = (coordinates[1] as num).toDouble();
        } else if (centerPoint is String) {
          // WKT形式の場合: "POINT(139.1071 35.2328)"
          if (centerPoint.startsWith('POINT(')) {
            final coords = centerPoint
                .replaceAll('POINT(', '')
                .replaceAll(')', '')
                .split(' ');
            if (coords.length == 2) {
              longitude = double.parse(coords[0]);
              latitude = double.parse(coords[1]);
            }
          }
        }
        // バイナリ形式の場合はデフォルト値を使用
        print('📍 Parsed location: lat=$latitude, lon=$longitude');
      } catch (e) {
        print('⚠️ Failed to parse center_point: $e');
      }
    }
    
    return Area(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      centerLocation: LatLng(latitude, longitude),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// AreaオブジェクトをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'center_latitude': centerLocation.latitude,
      'center_longitude': centerLocation.longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Area copyWith({
    String? id,
    String? name,
    String? description,
    LatLng? centerLocation,
    DateTime? createdAt,
  }) {
    return Area(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      centerLocation: centerLocation ?? this.centerLocation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Area(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Area && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
