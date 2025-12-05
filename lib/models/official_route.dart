import 'dart:convert';
import 'dart:typed_data';
import 'package:latlong2/latlong.dart';

/// ペット情報（愛犬家向け情報）
class PetInfo {
  final String? parking;        // 駐車場情報
  final String? surface;         // 道の状態
  final String? restroom;        // トイレ
  final String? waterStation;    // 水飲み場
  final String? petFacilities;   // ペット施設
  final String? others;          // その他

  const PetInfo({
    this.parking,
    this.surface,
    this.restroom,
    this.waterStation,
    this.petFacilities,
    this.others,
  });

  /// JSONからPetInfoを生成
  factory PetInfo.fromJson(Map<String, dynamic> json) {
    return PetInfo(
      parking: json['parking'] as String?,
      surface: json['surface'] as String?,
      restroom: json['restroom'] as String?,
      waterStation: json['water_station'] as String?,
      petFacilities: json['pet_facilities'] as String?,
      others: json['others'] as String?,
    );
  }

  /// PetInfoをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'parking': parking,
      'surface': surface,
      'restroom': restroom,
      'water_station': waterStation,
      'pet_facilities': petFacilities,
      'others': others,
    };
  }

  /// いずれかの情報が存在するか
  bool get hasAnyInfo {
    return parking != null ||
        surface != null ||
        restroom != null ||
        waterStation != null ||
        petFacilities != null ||
        others != null;
  }
}

/// 難易度レベル
enum DifficultyLevel {
  easy('easy', '初級', '平坦で歩きやすい'),
  moderate('moderate', '中級', '坂道あり'),
  hard('hard', '上級', '長距離・急坂あり');

  const DifficultyLevel(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static DifficultyLevel fromString(String value) {
    switch (value) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'moderate':
        return DifficultyLevel.moderate;
      case 'hard':
        return DifficultyLevel.hard;
      default:
        return DifficultyLevel.easy;
    }
  }
}

/// 公式ルートモデル（管理者が登録した推奨ルート）
class OfficialRoute {
  final String id;
  final String areaId;
  final String name;
  final String description;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<LatLng>? routeLine; // 経路のライン（オプション）
  final double distanceMeters;
  final int estimatedMinutes;
  final DifficultyLevel difficultyLevel;
  final double? elevationGainMeters; // 標高差（メートル）
  final int totalPins; // このルートに投稿されたピンの総数
  final int totalWalks; // このルートを歩いた回数
  final String? thumbnailUrl; // ルート一覧用のサムネイル画像
  final List<String>? galleryImages; // ルート詳細用のギャラリー画像（3枚）
  final PetInfo? petInfo; // 愛犬家向け情報
  final DateTime createdAt;
  final DateTime updatedAt;

  OfficialRoute({
    required this.id,
    required this.areaId,
    required this.name,
    required this.description,
    required this.startLocation,
    required this.endLocation,
    this.routeLine,
    required this.distanceMeters,
    required this.estimatedMinutes,
    required this.difficultyLevel,
    this.elevationGainMeters,
    this.totalPins = 0,
    this.totalWalks = 0,
    this.thumbnailUrl,
    this.galleryImages,
    this.petInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Supabaseから取得したJSONをOfficialRouteオブジェクトに変換
  /// PostGISのGEOGRAPHY型はWKT形式で返されるのでパースが必要
  factory OfficialRoute.fromJson(Map<String, dynamic> json) {
    return OfficialRoute(
      id: json['id'] as String,
      areaId: json['area_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      startLocation: _parsePostGISPoint(json['start_location']),
      endLocation: _parsePostGISPoint(json['end_location']),
      routeLine: json['route_line'] != null
          ? _parsePostGISLineString(json['route_line'])
          : null,
      distanceMeters: (json['distance_meters'] as num).toDouble(),
      estimatedMinutes: json['estimated_minutes'] as int,
      difficultyLevel: DifficultyLevel.fromString(
        json['difficulty_level'] as String? ?? 'easy',
      ),
      elevationGainMeters: json['elevation_gain_meters'] != null
          ? (json['elevation_gain_meters'] as num).toDouble()
          : null,
      totalPins: json['total_pins'] as int? ?? 0,
      totalWalks: json['total_walks'] as int? ?? 0,
      thumbnailUrl: json['thumbnail_url'] as String?,
      galleryImages: json['gallery_images'] != null
          ? (json['gallery_images'] as List).map((e) => e as String).toList()
          : null,
      petInfo: json['pet_info'] != null
          ? PetInfo.fromJson(json['pet_info'] as Map<String, dynamic>)
          : null,
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
      
      // GeoJSON文字列の場合（JSON文字列として渡される場合）
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
    // 2文字ずつ（1バイト）に分割してリトルエンディアンで並び替え
    final bytes = <int>[];
    for (int i = hex.length - 2; i >= 0; i -= 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    
    // バイト列をdoubleに変換
    final buffer = bytes.sublist(0, 8);
    final byteData = ByteData(8);
    for (int i = 0; i < 8; i++) {
      byteData.setUint8(i, buffer[i]);
    }
    return byteData.getFloat64(0, Endian.little);
  }

  /// PostGISのLINESTRING型をLatLngリストに変換
  /// 例: "LINESTRING(139.1071 35.2328, 139.1080 35.2335, ...)"
  /// WKB形式: "0102000020E6100000..." → List<LatLng>
  /// GeoJSON形式: {"type":"LineString","coordinates":[[139.1071,35.2328],...]}
  static List<LatLng>? _parsePostGISLineString(dynamic lineData) {
    if (lineData == null) return null;

    // すでにMapの場合（GeoJSON形式）
    if (lineData is Map) {
      final coords = lineData['coordinates'] as List;
      return coords.map((coord) {
        final c = coord as List;
        return LatLng(
          (c[1] as num).toDouble(), // 緯度
          (c[0] as num).toDouble(), // 経度
        );
      }).toList();
    }

    // 文字列の場合
    if (lineData is String) {
      // WKB形式（16進数バイナリ）の場合
      if (lineData.startsWith('01') && lineData.length > 20) {
        return _parseWKBLineString(lineData);
      }
      
      // GeoJSON文字列の場合
      if (lineData.contains('"type"') && lineData.contains('"coordinates"')) {
        try {
          final Map<String, dynamic> geoJson = json.decode(lineData);
          final coords = geoJson['coordinates'] as List;
          return coords.map((coord) {
            final c = coord as List;
            return LatLng(
              (c[1] as num).toDouble(), // 緯度
              (c[0] as num).toDouble(), // 経度
            );
          }).toList();
        } catch (e) {
          print('❌ Failed to parse GeoJSON LineString: $e');
          return null;
        }
      }
      
      // WKT形式の場合: "LINESTRING(139.1071 35.2328, ...)"
      final coordsMatch = RegExp(r'LINESTRING\(([^)]+)\)').firstMatch(lineData);
      if (coordsMatch != null) {
        final coordsStr = coordsMatch.group(1)!;
        final pointStrs = coordsStr.split(',');
        return pointStrs.map((pointStr) {
          final parts = pointStr.trim().split(' ');
          final lon = double.parse(parts[0]);
          final lat = double.parse(parts[1]);
          return LatLng(lat, lon);
        }).toList();
      }
    }

    return null;
  }

  /// WKB形式（Well-Known Binary）のLINESTRINGをパース
  /// フォーマット: バイトオーダー(1) + 型(4) + SRID(4) + ポイント数(4) + 座標データ
  static List<LatLng> _parseWKBLineString(String wkbHex) {
    try {
      // バイトオーダー(2) + 型(8) + SRID(8) = 18文字
      // ポイント数は18文字目から8文字（4バイト）
      final numPointsHex = wkbHex.substring(18, 26);
      final numPoints = _hexToInt32(numPointsHex);
      
      // 座標データは26文字目から開始
      // 各ポイントは16バイト（32文字）= 経度8バイト + 緯度8バイト
      final points = <LatLng>[];
      for (int i = 0; i < numPoints; i++) {
        final offset = 26 + (i * 32);
        if (offset + 32 > wkbHex.length) {
          print('❌ WKB LineString: データ不足（offset=$offset, length=${wkbHex.length}）');
          break;
        }
        
        final lonHex = wkbHex.substring(offset, offset + 16);
        final latHex = wkbHex.substring(offset + 16, offset + 32);
        
        final lon = _hexToDouble(lonHex);
        final lat = _hexToDouble(latHex);
        points.add(LatLng(lat, lon));
      }
      
      return points;
    } catch (e) {
      print('❌ Failed to parse WKB LineString: $e');
      return [];
    }
  }

  /// 16進数文字列を32bit整数に変換（リトルエンディアン）
  /// 例: "05000000" → 5
  static int _hexToInt32(String hex) {
    // リトルエンディアン: 下位バイトから順に並ぶ
    // "05000000" = 05 00 00 00 (bytes) → 0x00000005 = 5
    final byteData = ByteData(4);
    for (int i = 0; i < 4; i++) {
      final byteHex = hex.substring(i * 2, i * 2 + 2);
      byteData.setUint8(i, int.parse(byteHex, radix: 16));
    }
    return byteData.getInt32(0, Endian.little);
  }

  /// OfficialRouteオブジェクトをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area_id': areaId,
      'name': name,
      'description': description,
      'start_location': {
        'type': 'Point',
        'coordinates': [startLocation.longitude, startLocation.latitude],
      },
      'end_location': {
        'type': 'Point',
        'coordinates': [endLocation.longitude, endLocation.latitude],
      },
      'route_line': routeLine != null
          ? {
              'type': 'LineString',
              'coordinates': routeLine!
                  .map((point) => [point.longitude, point.latitude])
                  .toList(),
            }
          : null,
      'distance_meters': distanceMeters,
      'estimated_minutes': estimatedMinutes,
      'difficulty_level': difficultyLevel.value,
      'total_pins': totalPins,
      'thumbnail_url': thumbnailUrl,
      'gallery_images': galleryImages,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 距離をフォーマット（例：1.5km）
  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    } else {
      return '${distanceMeters.toStringAsFixed(0)}m';
    }
  }

  /// 所要時間をフォーマット（例：1時間30分）
  String get formattedDuration {
    final hours = estimatedMinutes ~/ 60;
    final minutes = estimatedMinutes % 60;

    if (hours > 0) {
      return '$hours時間${minutes}分';
    } else {
      return '$minutes分';
    }
  }

  OfficialRoute copyWith({
    String? id,
    String? areaId,
    String? name,
    String? description,
    LatLng? startLocation,
    LatLng? endLocation,
    List<LatLng>? routeLine,
    double? distanceMeters,
    int? estimatedMinutes,
    DifficultyLevel? difficultyLevel,
    double? elevationGainMeters,
    int? totalPins,
    int? totalWalks,
    String? thumbnailUrl,
    List<String>? galleryImages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfficialRoute(
      id: id ?? this.id,
      areaId: areaId ?? this.areaId,
      name: name ?? this.name,
      description: description ?? this.description,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      routeLine: routeLine ?? this.routeLine,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      totalPins: totalPins ?? this.totalPins,
      totalWalks: totalWalks ?? this.totalWalks,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'OfficialRoute(id: $id, name: $name, areaId: $areaId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfficialRoute && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
