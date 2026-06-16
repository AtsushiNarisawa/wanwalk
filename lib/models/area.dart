import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../utils/logger.dart';

/// エリアマスタモデル
/// 箱根、横浜、鎌倉などの観光・都市エリア
class Area {
  final String id;
  final String name;
  final String prefecture;
  final String description;
  final LatLng centerLocation;
  final String? heroImageUrl;
  final DateTime createdAt;

  /// URLスラッグ（Web/ディープリンクと一致する出口キー）。
  final String? slug;

  /// 粒度。region / sub / spot（AreaTier 参照）。既定は region。
  final String tier;

  /// sub を束ねる親キー（現状は 'hakone'）。region/spot は null。
  final String? groupKey;

  /// 所属する公開ルート数（get_areas_simple が返却）。
  final int routeCount;

  Area({
    required this.id,
    required this.name,
    required this.prefecture,
    required this.description,
    required this.centerLocation,
    this.heroImageUrl,
    DateTime? createdAt,
    this.slug,
    this.tier = 'region',
    this.groupKey,
    this.routeCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Supabaseから取得したJSONをAreaオブジェクトに変換
  factory Area.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      appLog('🔵 Area.fromJson: $json');
    }
    
    // RPC関数から直接longitude/latitudeを取得
    final latitude = (json['latitude'] as num?)?.toDouble() ?? 35.6762;
    final longitude = (json['longitude'] as num?)?.toDouble() ?? 139.6503;
    
    if (kDebugMode) {
      appLog('📍 Location: lat=$latitude, lon=$longitude');
    }
    
    return Area(
      id: json['id'] as String,
      name: json['name'] as String,
      prefecture: json['prefecture'] as String? ?? '',
      description: json['description'] as String? ?? '',
      centerLocation: LatLng(latitude, longitude),
      heroImageUrl: json['hero_image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      slug: json['slug'] as String?,
      tier: json['tier'] as String? ?? 'region',
      groupKey: json['group_key'] as String?,
      routeCount: (json['route_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// AreaオブジェクトをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'prefecture': prefecture,
      'description': description,
      'center_latitude': centerLocation.latitude,
      'center_longitude': centerLocation.longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Area copyWith({
    String? id,
    String? name,
    String? prefecture,
    String? description,
    LatLng? centerLocation,
    String? heroImageUrl,
    DateTime? createdAt,
    String? slug,
    String? tier,
    String? groupKey,
    int? routeCount,
  }) {
    return Area(
      id: id ?? this.id,
      name: name ?? this.name,
      prefecture: prefecture ?? this.prefecture,
      description: description ?? this.description,
      centerLocation: centerLocation ?? this.centerLocation,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      createdAt: createdAt ?? this.createdAt,
      slug: slug ?? this.slug,
      tier: tier ?? this.tier,
      groupKey: groupKey ?? this.groupKey,
      routeCount: routeCount ?? this.routeCount,
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
