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
    return Area(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      centerLocation: LatLng(
        (json['center_latitude'] as num).toDouble(),
        (json['center_longitude'] as num).toDouble(),
      ),
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
