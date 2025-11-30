import 'package:latlong2/latlong.dart';

/// 愛犬家向け情報
class PetInfo {
  final String? parking; // 駐車場情報（例：「あり（20台・無料）」「なし」）
  final String? surface; // 道の状態（例：「コンクリート 70% / 土 30%」）
  final String? waterStation; // 水飲み場（例：「あり（スタート地点・中間地点）」）
  final String? restroom; // トイレ（例：「あり（スタート地点のみ）」）
  final String? petFacilities; // ペット施設（例：「ドッグラン、ペット同伴カフェあり」）
  final String? others; // その他（例：「リード着用必須」「大型犬が多い」）

  const PetInfo({
    this.parking,
    this.surface,
    this.waterStation,
    this.restroom,
    this.petFacilities,
    this.others,
  });

  /// JSONから変換
  factory PetInfo.fromJson(Map<String, dynamic> json) {
    return PetInfo(
      parking: json['parking'] as String?,
      surface: json['surface'] as String?,
      waterStation: json['water_station'] as String?,
      restroom: json['restroom'] as String?,
      petFacilities: json['pet_facilities'] as String?,
      others: json['others'] as String?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'parking': parking,
      'surface': surface,
      'water_station': waterStation,
      'restroom': restroom,
      'pet_facilities': petFacilities,
      'others': others,
    };
  }

  /// 情報が1つでもあるかどうか
  bool get hasAnyInfo =>
      parking != null ||
      surface != null ||
      waterStation != null ||
      restroom != null ||
      petFacilities != null ||
      others != null;
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
  final int totalPins; // このルートに投稿されたピンの総数
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
    this.totalPins = 0,
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
      totalPins: json['total_pins'] as int? ?? 0,
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
  /// 注意: PostGISは経度,緯度の順番だが、LatLngは緯度,経度の順番
  static LatLng _parsePostGISPoint(dynamic pointData) {
    if (pointData == null) {
      throw ArgumentError('Point data is null');
    }

    // すでにMapの場合（Supabaseが自動変換する場合がある）
    if (pointData is Map) {
      final coords = pointData['coordinates'] as List;
      return LatLng(
        (coords[1] as num).toDouble(), // 緯度
        (coords[0] as num).toDouble(), // 経度
      );
    }

    // WKT文字列の場合
    if (pointData is String) {
      // "POINT(139.1071 35.2328)" から座標を抽出
      final coordsMatch = RegExp(r'POINT\(([0-9.\-]+)\s+([0-9.\-]+)\)').firstMatch(pointData);
      if (coordsMatch != null) {
        final lon = double.parse(coordsMatch.group(1)!);
        final lat = double.parse(coordsMatch.group(2)!);
        return LatLng(lat, lon);
      }
    }

    throw ArgumentError('Invalid PostGIS Point format: $pointData');
  }

  /// PostGISのLINESTRING型をLatLngリストに変換
  /// 例: "LINESTRING(139.1071 35.2328, 139.1080 35.2335, ...)"
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

    // WKT文字列の場合
    if (lineData is String) {
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
      'pet_info': petInfo?.toJson(),
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
      return '$hours時間$minutes分';
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
    int? totalPins,
    String? thumbnailUrl,
    List<String>? galleryImages,
    PetInfo? petInfo,
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
      totalPins: totalPins ?? this.totalPins,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      petInfo: petInfo ?? this.petInfo,
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
