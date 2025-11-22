/// ルート実行記録モデル（ユーザーが公式ルートを歩いた履歴）
class RouteWalk {
  final String id;
  final String userId;
  final String routeId; // 所属する公式ルートID
  final DateTime walkedAt; // 実行日時
  final int? durationSeconds; // 実際にかかった時間（秒）
  final double? distanceMeters; // 実際に歩いた距離（メートル）
  final String? comment; // メモ・感想
  final DateTime createdAt;

  RouteWalk({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.walkedAt,
    this.durationSeconds,
    this.distanceMeters,
    this.comment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Supabaseから取得したJSONをRouteWalkオブジェクトに変換
  factory RouteWalk.fromJson(Map<String, dynamic> json) {
    return RouteWalk(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      routeId: json['route_id'] as String,
      walkedAt: DateTime.parse(json['walked_at'] as String),
      durationSeconds: json['duration_seconds'] as int?,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// RouteWalkオブジェクトをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'route_id': routeId,
      'walked_at': walkedAt.toIso8601String(),
      'duration_seconds': durationSeconds,
      'distance_meters': distanceMeters,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 距離をフォーマット（例：1.5km）
  String? get formattedDistance {
    if (distanceMeters == null) return null;
    if (distanceMeters! >= 1000) {
      return '${(distanceMeters! / 1000).toStringAsFixed(1)}km';
    } else {
      return '${distanceMeters!.toStringAsFixed(0)}m';
    }
  }

  /// 所要時間をフォーマット（例：1時間30分）
  String? get formattedDuration {
    if (durationSeconds == null) return null;
    final hours = durationSeconds! ~/ 3600;
    final minutes = (durationSeconds! % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours時間${minutes}分';
    } else {
      return '$minutes分';
    }
  }

  /// 日付フォーマット（例：2024年1月15日）
  String get formattedDate {
    return '${walkedAt.year}年${walkedAt.month}月${walkedAt.day}日';
  }

  RouteWalk copyWith({
    String? id,
    String? userId,
    String? routeId,
    DateTime? walkedAt,
    int? durationSeconds,
    double? distanceMeters,
    String? comment,
    DateTime? createdAt,
  }) {
    return RouteWalk(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      routeId: routeId ?? this.routeId,
      walkedAt: walkedAt ?? this.walkedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'RouteWalk(id: $id, routeId: $routeId, walkedAt: $walkedAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteWalk && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
