/// ユーザー散歩プロファイルモデル（自動構築される統計情報）
class UserWalkingProfile {
  final String userId;
  final int totalDailyWalks; // Daily散歩の総回数
  final int totalOutingWalks; // Outing散歩の総回数
  final int totalPinsPosted; // 投稿したピンの総数
  final int totalLikesReceived; // 受け取ったいいねの総数
  final double totalDistanceMeters; // 累計歩行距離（メートル）
  final int totalDurationSeconds; // 累計歩行時間（秒）
  final double avgSpeedKmh; // 平均歩行速度（km/h）
  final List<String>? preferredRouteIds; // よく歩くルートID（上位3件）
  final DateTime updatedAt;

  UserWalkingProfile({
    required this.userId,
    this.totalDailyWalks = 0,
    this.totalOutingWalks = 0,
    this.totalPinsPosted = 0,
    this.totalLikesReceived = 0,
    this.totalDistanceMeters = 0.0,
    this.totalDurationSeconds = 0,
    this.avgSpeedKmh = 0.0,
    this.preferredRouteIds,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Supabaseから取得したJSONをUserWalkingProfileオブジェクトに変換
  factory UserWalkingProfile.fromJson(Map<String, dynamic> json) {
    List<String>? preferredRouteIds;
    if (json['preferred_route_ids'] != null) {
      preferredRouteIds = (json['preferred_route_ids'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return UserWalkingProfile(
      userId: json['user_id'] as String,
      totalDailyWalks: json['total_daily_walks'] as int? ?? 0,
      totalOutingWalks: json['total_outing_walks'] as int? ?? 0,
      totalPinsPosted: json['total_pins_posted'] as int? ?? 0,
      totalLikesReceived: json['total_likes_received'] as int? ?? 0,
      totalDistanceMeters: (json['total_distance_meters'] as num?)?.toDouble() ?? 0.0,
      totalDurationSeconds: json['total_duration_seconds'] as int? ?? 0,
      avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble() ?? 0.0,
      preferredRouteIds: preferredRouteIds,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// UserWalkingProfileオブジェクトをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_daily_walks': totalDailyWalks,
      'total_outing_walks': totalOutingWalks,
      'total_pins_posted': totalPinsPosted,
      'total_likes_received': totalLikesReceived,
      'total_distance_meters': totalDistanceMeters,
      'total_duration_seconds': totalDurationSeconds,
      'avg_speed_kmh': avgSpeedKmh,
      'preferred_route_ids': preferredRouteIds,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 総散歩回数
  int get totalWalks => totalDailyWalks + totalOutingWalks;

  /// 累計距離のフォーマット（例：125.5km）
  String get formattedTotalDistance {
    if (totalDistanceMeters >= 1000) {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)}km';
    } else {
      return '${totalDistanceMeters.toStringAsFixed(0)}m';
    }
  }

  /// 累計時間のフォーマット（例：45時間30分）
  String get formattedTotalDuration {
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours時間${minutes}分';
    } else {
      return '$minutes分';
    }
  }

  /// 平均速度のフォーマット（例：3.5km/h）
  String get formattedAvgSpeed {
    return '${avgSpeedKmh.toStringAsFixed(1)}km/h';
  }

  UserWalkingProfile copyWith({
    String? userId,
    int? totalDailyWalks,
    int? totalOutingWalks,
    int? totalPinsPosted,
    int? totalLikesReceived,
    double? totalDistanceMeters,
    int? totalDurationSeconds,
    double? avgSpeedKmh,
    List<String>? preferredRouteIds,
    DateTime? updatedAt,
  }) {
    return UserWalkingProfile(
      userId: userId ?? this.userId,
      totalDailyWalks: totalDailyWalks ?? this.totalDailyWalks,
      totalOutingWalks: totalOutingWalks ?? this.totalOutingWalks,
      totalPinsPosted: totalPinsPosted ?? this.totalPinsPosted,
      totalLikesReceived: totalLikesReceived ?? this.totalLikesReceived,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      preferredRouteIds: preferredRouteIds ?? this.preferredRouteIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'UserWalkingProfile(userId: $userId, totalWalks: $totalWalks)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserWalkingProfile && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
