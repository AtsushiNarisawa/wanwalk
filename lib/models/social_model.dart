// ==================================================
// Social Features Models for WanMap v2
// ==================================================
// Author: AI Assistant
// Created: 2024-11-17
// Purpose: Data models for follow and like features
// ==================================================

/// ユーザーフォロー関係モデル
class UserFollowModel {
  final String id;
  final String followerId; // フォローした人
  final String followingId; // フォローされた人
  final DateTime createdAt;

  UserFollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory UserFollowModel.fromJson(Map<String, dynamic> json) {
    return UserFollowModel(
      id: json['id'],
      followerId: json['follower_id'],
      followingId: json['following_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// ルートいいねモデル
class RouteLikeModel {
  final String id;
  final String userId;
  final String routeId;
  final DateTime createdAt;

  RouteLikeModel({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.createdAt,
  });

  factory RouteLikeModel.fromJson(Map<String, dynamic> json) {
    return RouteLikeModel(
      id: json['id'],
      userId: json['user_id'],
      routeId: json['route_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'route_id': routeId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// ユーザープロフィール（フォロー関連情報付き）
class UserProfileModel {
  final String id;
  final String username;
  final String? avatarUrl;
  final int followersCount;
  final int followingCount;
  final DateTime? followedAt; // このユーザーをフォローした日時（オプション）

  UserProfileModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.followersCount,
    required this.followingCount,
    this.followedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['user_id'] ?? json['id'],
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'],
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      followedAt: json['followed_at'] != null
          ? DateTime.parse(json['followed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'followers_count': followersCount,
      'following_count': followingCount,
      if (followedAt != null) 'followed_at': followedAt!.toIso8601String(),
    };
  }

  /// フォロワー表示用文字列（例: "123 フォロワー"）
  String get followersText => '$followersCount フォロワー';

  /// フォロー中表示用文字列（例: "45 フォロー中"）
  String get followingText => '$followingCount フォロー中';
}

/// タイムラインアイテム（フォロー中のユーザーのルート）
class TimelineItemModel {
  final String routeId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final double distance;
  final int duration;
  final String? area;
  final String? prefecture;
  final int likesCount;
  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;

  TimelineItemModel({
    required this.routeId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.distance,
    required this.duration,
    this.area,
    this.prefecture,
    required this.likesCount,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
  });

  factory TimelineItemModel.fromJson(Map<String, dynamic> json) {
    return TimelineItemModel(
      routeId: json['route_id'],
      title: json['title'] ?? '',
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      distance: (json['distance'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      area: json['area'],
      prefecture: json['prefecture'],
      likesCount: json['likes_count'] ?? 0,
      userId: json['user_id'],
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// 距離をキロメートルで取得
  double get distanceKm => distance / 1000;

  /// フォーマットされた距離（例: "2.5 km"）
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';

  /// フォーマットされた時間（例: "25分"）
  String get formattedDuration {
    final minutes = (duration / 60).round();
    if (minutes < 60) {
      return '$minutes分';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours時間$mins分';
  }

  /// エリア表示（例: "箱根（神奈川県）"）
  String? get areaDisplay {
    if (area == null) return null;
    if (prefecture == null) return area;
    return '$area（$prefecture）';
  }

  /// 相対時間表示（例: "2時間前"、"3日前"）
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks週間前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$monthsヶ月前';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years年前';
    }
  }
}

/// 人気ルートアイテム（いいね数順）
class PopularRouteModel {
  final String routeId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final double distance;
  final int duration;
  final String? area;
  final String? prefecture;
  final int likesCount;
  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;

  PopularRouteModel({
    required this.routeId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.distance,
    required this.duration,
    this.area,
    this.prefecture,
    required this.likesCount,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
  });

  factory PopularRouteModel.fromJson(Map<String, dynamic> json) {
    return PopularRouteModel(
      routeId: json['route_id'],
      title: json['title'] ?? '',
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      distance: (json['distance'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      area: json['area'],
      prefecture: json['prefecture'],
      likesCount: json['likes_count'] ?? 0,
      userId: json['user_id'],
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// 距離をキロメートルで取得
  double get distanceKm => distance / 1000;

  /// フォーマットされた距離
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';

  /// フォーマットされた時間
  String get formattedDuration {
    final minutes = (duration / 60).round();
    if (minutes < 60) {
      return '$minutes分';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours時間$mins分';
  }

  /// エリア表示
  String? get areaDisplay {
    if (area == null) return null;
    if (prefecture == null) return area;
    return '$area（$prefecture）';
  }

  /// いいね数表示（例: "123 いいね"）
  String get likesText => '$likesCount いいね';
}

/// いいねしたユーザー情報
class LikerModel {
  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime likedAt;

  LikerModel({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.likedAt,
  });

  factory LikerModel.fromJson(Map<String, dynamic> json) {
    return LikerModel(
      userId: json['user_id'],
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'],
      likedAt: DateTime.parse(json['liked_at']),
    );
  }

  /// 相対時間表示
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(likedAt);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${likedAt.month}/${likedAt.day}';
    }
  }
}
