/// お気に入りルートモデル
class FavoriteRoute {
  final String id;
  final String userId;
  final String routeId;
  final DateTime createdAt;

  // ルート詳細情報（get_user_favorite_routesから取得）
  final String? routeName;
  final String? areaName;
  final double? distanceMeters;
  final int? estimatedMinutes;
  final String? difficultyLevel;
  final int? totalPins;

  FavoriteRoute({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.createdAt,
    this.routeName,
    this.areaName,
    this.distanceMeters,
    this.estimatedMinutes,
    this.difficultyLevel,
    this.totalPins,
  });

  /// Supabaseから取得したJSONをFavoriteRouteオブジェクトに変換
  factory FavoriteRoute.fromJson(Map<String, dynamic> json) {
    return FavoriteRoute(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      routeId: json['route_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      routeName: json['route_name'] as String?,
      areaName: json['area_name'] as String?,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      estimatedMinutes: json['estimated_minutes'] as int?,
      difficultyLevel: json['difficulty_level'] as String?,
      totalPins: json['total_pins'] as int?,
    );
  }

  /// FavoriteRouteオブジェクトをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'route_id': routeId,
      'created_at': createdAt.toIso8601String(),
      if (routeName != null) 'route_name': routeName,
      if (areaName != null) 'area_name': areaName,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
      if (totalPins != null) 'total_pins': totalPins,
    };
  }

  /// 距離を人間が読みやすい形式に変換
  String get distanceFormatted {
    if (distanceMeters == null) return '---';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.toStringAsFixed(0)}m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)}km';
  }

  /// 所要時間を人間が読みやすい形式に変換
  String get durationFormatted {
    if (estimatedMinutes == null) return '---';
    if (estimatedMinutes! < 60) {
      return '${estimatedMinutes}分';
    }
    final hours = estimatedMinutes! ~/ 60;
    final minutes = estimatedMinutes! % 60;
    return '${hours}時間${minutes}分';
  }

  /// 難易度の日本語表示
  String get difficultyLabelJa {
    switch (difficultyLevel) {
      case 'easy':
        return '初級';
      case 'moderate':
        return '中級';
      case 'hard':
        return '上級';
      default:
        return '---';
    }
  }

  @override
  String toString() => 'FavoriteRoute(id: $id, routeName: $routeName, areaName: $areaName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteRoute && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
