import 'dart:convert';
import 'dart:typed_data';
import 'package:latlong2/latlong.dart';

/// ルートスポットのタイプ
enum RouteSpotType {
  start('start', 'スタート'),
  landscape('landscape', '景観'),
  photoSpot('photo_spot', 'フォトスポット'),
  facility('facility', '施設'),
  end('end', 'ゴール');

  const RouteSpotType(this.value, this.label);

  final String value;
  final String label;

  static RouteSpotType fromString(String value) {
    switch (value) {
      case 'start':
        return RouteSpotType.start;
      case 'landscape':
        return RouteSpotType.landscape;
      case 'photo_spot':
        return RouteSpotType.photoSpot;
      case 'facility':
        return RouteSpotType.facility;
      case 'end':
        return RouteSpotType.end;
      default:
        return RouteSpotType.start;
    }
  }
}

/// ルート上のスポット情報（出会えるポイント）
class RouteSpot {
  final String id;
  final String routeId;
  final int spotOrder;
  final RouteSpotType spotType;
  final String name;
  final String? description;
  final LatLng location;
  final int distanceFromStart; // メートル
  final int estimatedTimeFromStart; // 分
  final String? landscapeFeature; // 景観の特徴
  final List<String>? activitySuggestions; // できること（複数選択肢）
  final Map<String, dynamic>? seasonalNotes; // 季節の見どころ
  final String? facilityType; // 施設タイプ（カフェ、トイレなど）
  final bool? petFriendly; // ペット同伴可能か
  final String? openingHours; // 営業時間
  final bool isOptional; // 立ち寄り任意
  final String? tips; // 参考情報
  final DateTime createdAt;
  final DateTime updatedAt;

  RouteSpot({
    required this.id,
    required this.routeId,
    required this.spotOrder,
    required this.spotType,
    required this.name,
    this.description,
    required this.location,
    required this.distanceFromStart,
    required this.estimatedTimeFromStart,
    this.landscapeFeature,
    this.activitySuggestions,
    this.seasonalNotes,
    this.facilityType,
    this.petFriendly,
    this.openingHours,
    required this.isOptional,
    this.tips,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Supabaseから取得したJSONをRouteSportオブジェクトに変換
  factory RouteSpot.fromJson(Map<String, dynamic> json) {
    return RouteSpot(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      spotOrder: json['spot_order'] as int,
      spotType: RouteSpotType.fromString(json['spot_type'] as String),
      name: json['name'] as String,
      description: json['description'] as String?,
      location: _parsePostGISPoint(json['location']),
      distanceFromStart: json['distance_from_start'] as int,
      estimatedTimeFromStart: json['estimated_time_from_start'] as int,
      landscapeFeature: json['landscape_feature'] as String?,
      activitySuggestions: json['activity_suggestions'] != null
          ? (json['activity_suggestions'] as List).map((e) => e as String).toList()
          : null,
      seasonalNotes: json['seasonal_notes'] != null
          ? json['seasonal_notes'] as Map<String, dynamic>
          : null,
      facilityType: json['facility_type'] as String?,
      petFriendly: json['pet_friendly'] as bool?,
      openingHours: json['opening_hours'] as String?,
      isOptional: json['is_optional'] as bool? ?? false,
      tips: json['tips'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// PostGISのPOINT型をLatLngに変換
  /// 例: "POINT(139.1071 35.2328)" → LatLng(35.2328, 139.1071)
  /// WKB形式（16進数バイナリ）: "0101000020E6100000..." → LatLng
  /// GeoJSON形式: {"type":"Point","coordinates":[139.0272,35.1993]}
  /// 注意: PostGISは経度,緯度の順番だが、LatLngは緯度,経度の順番
  static LatLng _parsePostGISPoint(dynamic pointData) {
    if (pointData == null) {
      throw ArgumentError('Point data is null');
    }

    // すでにMapの場合（GeoJSON形式）
    if (pointData is Map) {
      final coords = pointData['coordinates'] as List;
      return LatLng(
        (coords[1] as num).toDouble(), // 緯度
        (coords[0] as num).toDouble(), // 経度
      );
    }

    // 文字列の場合
    if (pointData is String) {
      // WKB形式（16進数バイナリ）の場合
      if (pointData.startsWith('01') && pointData.length > 20) {
        return _parseWKBPoint(pointData);
      }
      
      // GeoJSON文字列の場合
      if (pointData.contains('"type"') && pointData.contains('"coordinates"')) {
        try {
          final Map<String, dynamic> geoJson = json.decode(pointData);
          final coords = geoJson['coordinates'] as List;
          return LatLng(
            (coords[1] as num).toDouble(), // 緯度
            (coords[0] as num).toDouble(), // 経度
          );
        } catch (e) {
          print('❌ Failed to parse GeoJSON string: $e');
        }
      }
      
      // WKT形式の場合: "POINT(139.1071 35.2328)"
      final coordsMatch = RegExp(r'POINT\(([0-9.\-]+)\s+([0-9.\-]+)\)').firstMatch(pointData);
      if (coordsMatch != null) {
        final lon = double.parse(coordsMatch.group(1)!);
        final lat = double.parse(coordsMatch.group(2)!);
        return LatLng(lat, lon);
      }
    }

    throw ArgumentError('Invalid PostGIS Point format: $pointData');
  }

  /// WKB形式（Well-Known Binary）のPOINTをパース
  /// フォーマット: 0101000020E6100000 + 16バイト（経度8バイト+緯度8バイト）
  static LatLng _parseWKBPoint(String wkbHex) {
    try {
      // WKBヘッダーをスキップ（最初の20文字 = 10バイト）
      // フォーマット: バイトオーダー(1) + 型(4) + SRID(4) = 9バイト → 18文字
      // 実際には20文字スキップで座標データ開始
      final coordsHex = wkbHex.substring(18);
      
      // 経度（最初の8バイト = 16文字）
      final lonHex = coordsHex.substring(0, 16);
      // 緯度（次の8バイト = 16文字）
      final latHex = coordsHex.substring(16, 32);
      
      // リトルエンディアンのdouble値に変換
      final lon = _hexToDouble(lonHex);
      final lat = _hexToDouble(latHex);
      
      return LatLng(lat, lon);
    } catch (e) {
      throw ArgumentError('Failed to parse WKB Point: $wkbHex, error: $e');
    }
  }

  /// 16進数文字列をdoubleに変換（リトルエンディアン）
  static double _hexToDouble(String hex) {
    // 16進数文字列を2文字ずつバイトに変換（リトルエンディアン順）
    final byteData = ByteData(8);
    for (int i = 0; i < 8; i++) {
      final byteHex = hex.substring(i * 2, i * 2 + 2);
      byteData.setUint8(i, int.parse(byteHex, radix: 16));
    }
    return byteData.getFloat64(0, Endian.little);
  }

  /// RouteSpotオブジェクトをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_id': routeId,
      'spot_order': spotOrder,
      'spot_type': spotType.value,
      'name': name,
      'description': description,
      'location': {
        'type': 'Point',
        'coordinates': [location.longitude, location.latitude],
      },
      'distance_from_start': distanceFromStart,
      'estimated_time_from_start': estimatedTimeFromStart,
      'landscape_feature': landscapeFeature,
      'activity_suggestions': activitySuggestions,
      'seasonal_notes': seasonalNotes,
      'facility_type': facilityType,
      'pet_friendly': petFriendly,
      'opening_hours': openingHours,
      'is_optional': isOptional,
      'tips': tips,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 距離をフォーマット（例：400m）
  String get formattedDistance {
    if (distanceFromStart >= 1000) {
      return '${(distanceFromStart / 1000).toStringAsFixed(1)}km';
    } else {
      return '${distanceFromStart}m';
    }
  }

  /// 所要時間をフォーマット（例：8分）
  String get formattedTime {
    if (estimatedTimeFromStart >= 60) {
      final hours = estimatedTimeFromStart ~/ 60;
      final minutes = estimatedTimeFromStart % 60;
      if (minutes > 0) {
        return '$hours時間$minutes分';
      } else {
        return '$hours時間';
      }
    } else {
      return '$estimatedTimeFromStart分';
    }
  }

  @override
  String toString() =>
      'RouteSpot(id: $id, name: $name, type: ${spotType.label}, order: $spotOrder)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteSpot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
