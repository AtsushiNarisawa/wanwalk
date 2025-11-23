/// ルート検索パラメータモデル
class RouteSearchParams {
  final String? query; // フルテキスト検索
  final List<String>? areaIds; // エリアフィルター
  final List<String>? difficulties; // 難易度フィルター
  final double? minDistanceKm; // 最小距離
  final double? maxDistanceKm; // 最大距離
  final int? minDurationMin; // 最小所要時間
  final int? maxDurationMin; // 最大所要時間
  final List<String>? features; // 特徴タグフィルター
  final List<String>? bestSeasons; // 季節フィルター
  final RouteSortBy sortBy; // ソート順
  final int limit; // 取得件数
  final int offset; // オフセット

  const RouteSearchParams({
    this.query,
    this.areaIds,
    this.difficulties,
    this.minDistanceKm,
    this.maxDistanceKm,
    this.minDurationMin,
    this.maxDurationMin,
    this.features,
    this.bestSeasons,
    this.sortBy = RouteSortBy.popularity,
    this.limit = 20,
    this.offset = 0,
  });

  /// フィルターが適用されているかどうか
  bool get hasFilters {
    return query != null ||
        areaIds != null ||
        difficulties != null ||
        minDistanceKm != null ||
        maxDistanceKm != null ||
        minDurationMin != null ||
        maxDurationMin != null ||
        features != null ||
        bestSeasons != null;
  }

  /// 空のパラメータ（デフォルト）
  static const RouteSearchParams empty = RouteSearchParams();

  /// copyWith
  RouteSearchParams copyWith({
    String? query,
    List<String>? areaIds,
    List<String>? difficulties,
    double? minDistanceKm,
    double? maxDistanceKm,
    int? minDurationMin,
    int? maxDurationMin,
    List<String>? features,
    List<String>? bestSeasons,
    RouteSortBy? sortBy,
    int? limit,
    int? offset,
  }) {
    return RouteSearchParams(
      query: query ?? this.query,
      areaIds: areaIds ?? this.areaIds,
      difficulties: difficulties ?? this.difficulties,
      minDistanceKm: minDistanceKm ?? this.minDistanceKm,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      minDurationMin: minDurationMin ?? this.minDurationMin,
      maxDurationMin: maxDurationMin ?? this.maxDurationMin,
      features: features ?? this.features,
      bestSeasons: bestSeasons ?? this.bestSeasons,
      sortBy: sortBy ?? this.sortBy,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Supabase RPCパラメータに変換
  Map<String, dynamic> toRpcParams(String userId) {
    return {
      'p_user_id': userId,
      if (query != null) 'p_query': query,
      if (areaIds != null) 'p_area_ids': areaIds,
      if (difficulties != null) 'p_difficulties': difficulties,
      if (minDistanceKm != null) 'p_min_distance_km': minDistanceKm,
      if (maxDistanceKm != null) 'p_max_distance_km': maxDistanceKm,
      if (minDurationMin != null) 'p_min_duration_min': minDurationMin,
      if (maxDurationMin != null) 'p_max_duration_min': maxDurationMin,
      if (features != null) 'p_features': features,
      if (bestSeasons != null) 'p_best_seasons': bestSeasons,
      'p_sort_by': sortBy.value,
      'p_limit': limit,
      'p_offset': offset,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RouteSearchParams &&
        other.query == query &&
        _listEquals(other.areaIds, areaIds) &&
        _listEquals(other.difficulties, difficulties) &&
        other.minDistanceKm == minDistanceKm &&
        other.maxDistanceKm == maxDistanceKm &&
        other.minDurationMin == minDurationMin &&
        other.maxDurationMin == maxDurationMin &&
        _listEquals(other.features, features) &&
        _listEquals(other.bestSeasons, bestSeasons) &&
        other.sortBy == sortBy &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    return Object.hash(
      query,
      areaIds,
      difficulties,
      minDistanceKm,
      maxDistanceKm,
      minDurationMin,
      maxDurationMin,
      features,
      bestSeasons,
      sortBy,
      limit,
      offset,
    );
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// ソート順
enum RouteSortBy {
  popularity('popularity', '人気順'),
  distanceAsc('distance_asc', '距離が短い順'),
  distanceDesc('distance_desc', '距離が長い順'),
  rating('rating', '評価順'),
  newest('newest', '新着順');

  const RouteSortBy(this.value, this.label);
  final String value;
  final String label;
}

/// 検索結果ルート
class SearchRouteResult {
  final String routeId;
  final String areaId;
  final String areaName;
  final String routeName;
  final String description;
  final String difficulty;
  final double distanceKm;
  final int estimatedDurationMinutes;
  final int? elevationGainM;
  final List<String> features;
  final List<String> bestSeasons;
  final int totalWalks;
  final int totalPins;
  final double? averageRating;
  final bool isFavorited;
  final String? thumbnailUrl;
  final double startLat;
  final double startLon;

  SearchRouteResult({
    required this.routeId,
    required this.areaId,
    required this.areaName,
    required this.routeName,
    required this.description,
    required this.difficulty,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    this.elevationGainM,
    required this.features,
    required this.bestSeasons,
    required this.totalWalks,
    required this.totalPins,
    this.averageRating,
    required this.isFavorited,
    this.thumbnailUrl,
    required this.startLat,
    required this.startLon,
  });

  factory SearchRouteResult.fromMap(Map<String, dynamic> map) {
    return SearchRouteResult(
      routeId: map['route_id'] as String,
      areaId: map['area_id'] as String,
      areaName: map['area_name'] as String,
      routeName: map['route_name'] as String,
      description: map['description'] as String,
      difficulty: map['difficulty'] as String,
      distanceKm: (map['distance_km'] as num).toDouble(),
      estimatedDurationMinutes: map['estimated_duration_minutes'] as int,
      elevationGainM: map['elevation_gain_m'] as int?,
      features: (map['features'] as List<dynamic>?)?.cast<String>() ?? [],
      bestSeasons: (map['best_seasons'] as List<dynamic>?)?.cast<String>() ?? [],
      totalWalks: map['total_walks'] as int,
      totalPins: map['total_pins'] as int,
      averageRating: map['average_rating'] != null
          ? (map['average_rating'] as num).toDouble()
          : null,
      isFavorited: map['is_favorited'] as bool,
      thumbnailUrl: map['thumbnail_url'] as String?,
      startLat: (map['start_lat'] as num).toDouble(),
      startLon: (map['start_lon'] as num).toDouble(),
    );
  }

  /// 難易度ラベル（日本語）
  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':
        return '簡単';
      case 'moderate':
        return '普通';
      case 'hard':
        return '難しい';
      default:
        return '不明';
    }
  }

  /// フォーマット済み距離
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)}km';

  /// フォーマット済み所要時間
  String get formattedDuration {
    final hours = estimatedDurationMinutes ~/ 60;
    final minutes = estimatedDurationMinutes % 60;
    if (hours > 0) {
      return '${hours}時間${minutes}分';
    }
    return '${minutes}分';
  }

  /// 標高ゲインラベル
  String? get elevationGainLabel {
    if (elevationGainM == null) return null;
    return '↑ ${elevationGainM}m';
  }
}
