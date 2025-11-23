/// ユーザー統計モデル
class UserStatistics {
  final int totalWalks; // 総散歩回数
  final int totalOutingWalks; // お出かけ散歩回数
  final double totalDistanceKm; // 総距離
  final double totalDurationHours; // 総時間
  final int areasVisited; // 訪れたエリア数
  final int routesCompleted; // 歩いたルート数
  final int pinsCreated; // 投稿ピン数
  final int pinsLikedCount; // 自分のピンが受け取ったいいね数
  final int followersCount; // フォロワー数
  final int followingCount; // フォロー中の数

  UserStatistics({
    required this.totalWalks,
    required this.totalOutingWalks,
    required this.totalDistanceKm,
    required this.totalDurationHours,
    required this.areasVisited,
    required this.routesCompleted,
    required this.pinsCreated,
    required this.pinsLikedCount,
    required this.followersCount,
    required this.followingCount,
  });

  factory UserStatistics.fromMap(Map<String, dynamic> map) {
    return UserStatistics(
      totalWalks: map['total_walks'] as int,
      totalOutingWalks: map['total_outing_walks'] as int,
      totalDistanceKm: (map['total_distance_km'] as num).toDouble(),
      totalDurationHours: (map['total_duration_hours'] as num).toDouble(),
      areasVisited: map['areas_visited'] as int,
      routesCompleted: map['routes_completed'] as int,
      pinsCreated: map['pins_created'] as int,
      pinsLikedCount: map['pins_liked_count'] as int,
      followersCount: map['followers_count'] as int,
      followingCount: map['following_count'] as int,
    );
  }

  /// 空の統計
  static UserStatistics get empty => UserStatistics(
        totalWalks: 0,
        totalOutingWalks: 0,
        totalDistanceKm: 0,
        totalDurationHours: 0,
        areasVisited: 0,
        routesCompleted: 0,
        pinsCreated: 0,
        pinsLikedCount: 0,
        followersCount: 0,
        followingCount: 0,
      );

  /// フォーマット済み総距離
  String get formattedTotalDistance {
    if (totalDistanceKm >= 1000) {
      return '${(totalDistanceKm / 1000).toStringAsFixed(1)} k km';
    } else if (totalDistanceKm >= 100) {
      return '${totalDistanceKm.toStringAsFixed(0)} km';
    } else {
      return '${totalDistanceKm.toStringAsFixed(1)} km';
    }
  }

  /// フォーマット済み総時間
  String get formattedTotalDuration {
    if (totalDurationHours >= 100) {
      return '${totalDurationHours.toStringAsFixed(0)} 時間';
    } else {
      return '${totalDurationHours.toStringAsFixed(1)} 時間';
    }
  }

  /// ユーザーレベル（総距離ベース）
  int get userLevel {
    // 10kmごとにレベルアップ
    return (totalDistanceKm / 10).floor() + 1;
  }

  /// 次のレベルまでの距離
  double get distanceToNextLevel {
    final nextLevelDistance = userLevel * 10.0;
    return nextLevelDistance - totalDistanceKm;
  }

  /// レベル進捗率（0.0 ~ 1.0）
  double get levelProgress {
    final currentLevelStart = (userLevel - 1) * 10.0;
    final nextLevelStart = userLevel * 10.0;
    final progressInLevel = totalDistanceKm - currentLevelStart;
    return progressInLevel / (nextLevelStart - currentLevelStart);
  }
}

/// お気に入りルート
class FavoriteRoute {
  final String routeId;
  final String areaName;
  final String routeName;
  final String difficulty;
  final double distanceKm;
  final int estimatedDurationMinutes;
  final int totalPins;
  final String? thumbnailUrl;
  final DateTime favoritedAt;

  FavoriteRoute({
    required this.routeId,
    required this.areaName,
    required this.routeName,
    required this.difficulty,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.totalPins,
    this.thumbnailUrl,
    required this.favoritedAt,
  });

  factory FavoriteRoute.fromMap(Map<String, dynamic> map) {
    return FavoriteRoute(
      routeId: map['route_id'] as String,
      areaName: map['area_name'] as String,
      routeName: map['route_name'] as String,
      difficulty: map['difficulty'] as String,
      distanceKm: (map['distance_km'] as num).toDouble(),
      estimatedDurationMinutes: map['estimated_duration_minutes'] as int,
      totalPins: map['total_pins'] as int,
      thumbnailUrl: map['thumbnail_url'] as String?,
      favoritedAt: DateTime.parse(map['favorited_at'] as String),
    );
  }

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

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)}km';

  String get formattedDuration {
    final hours = estimatedDurationMinutes ~/ 60;
    final minutes = estimatedDurationMinutes % 60;
    if (hours > 0) {
      return '${hours}時間${minutes}分';
    }
    return '${minutes}分';
  }
}

/// 保存したピン
class BookmarkedPin {
  final String pinId;
  final String routeId;
  final String routeName;
  final String areaName;
  final String pinType;
  final String title;
  final String? comment;
  final int likesCount;
  final List<String> photoUrls;
  final String userName;
  final DateTime bookmarkedAt;
  final double pinLat;
  final double pinLon;

  BookmarkedPin({
    required this.pinId,
    required this.routeId,
    required this.routeName,
    required this.areaName,
    required this.pinType,
    required this.title,
    this.comment,
    required this.likesCount,
    required this.photoUrls,
    required this.userName,
    required this.bookmarkedAt,
    required this.pinLat,
    required this.pinLon,
  });

  factory BookmarkedPin.fromMap(Map<String, dynamic> map) {
    return BookmarkedPin(
      pinId: map['pin_id'] as String,
      routeId: map['route_id'] as String,
      routeName: map['route_name'] as String,
      areaName: map['area_name'] as String,
      pinType: map['pin_type'] as String,
      title: map['title'] as String,
      comment: map['comment'] as String?,
      likesCount: map['likes_count'] as int,
      photoUrls: (map['photo_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      userName: map['user_name'] as String,
      bookmarkedAt: DateTime.parse(map['bookmarked_at'] as String),
      pinLat: (map['pin_lat'] as num).toDouble(),
      pinLon: (map['pin_lon'] as num).toDouble(),
    );
  }

  String get pinTypeLabel {
    switch (pinType) {
      case 'scenery':
        return '景色';
      case 'shop':
        return '店舗';
      case 'encounter':
        return '出会い';
      case 'other':
        return 'その他';
      default:
        return '不明';
    }
  }

  String? get thumbnailUrl => photoUrls.isNotEmpty ? photoUrls.first : null;
}

/// 通知
class NotificationModel {
  final String notificationId;
  final String type;
  final String? actorId;
  final String actorName;
  final String? targetId;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.type,
    this.actorId,
    required this.actorName,
    this.targetId,
    required this.title,
    this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notification_id'] as String,
      type: map['type'] as String,
      actorId: map['actor_id'] as String?,
      actorName: map['actor_name'] as String,
      targetId: map['target_id'] as String?,
      title: map['title'] as String,
      body: map['body'] as String?,
      isRead: map['is_read'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get typeLabel {
    switch (type) {
      case 'new_pin':
        return '新しいピン';
      case 'new_follower':
        return '新しいフォロワー';
      case 'pin_liked':
        return 'ピンへのいいね';
      case 'pin_commented':
        return 'ピンへのコメント';
      case 'route_walked':
        return 'ルートを歩いた';
      default:
        return '通知';
    }
  }
}
