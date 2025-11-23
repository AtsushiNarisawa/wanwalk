/// ユーザープロフィールモデル
class UserProfile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int totalWalks;
  final int totalPins;
  final bool isFollowing;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.totalWalks = 0,
    this.totalPins = 0,
    this.isFollowing = false,
    this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final metaData = map['raw_user_meta_data'] as Map<String, dynamic>?;
    
    return UserProfile(
      id: map['id'] as String,
      displayName: metaData?['display_name'] as String? ?? 'Unknown User',
      avatarUrl: metaData?['avatar_url'] as String?,
      bio: metaData?['bio'] as String?,
      followersCount: map['followers_count'] as int? ?? 0,
      followingCount: map['following_count'] as int? ?? 0,
      totalWalks: map['total_walks'] as int? ?? 0,
      totalPins: map['total_pins'] as int? ?? 0,
      isFollowing: map['is_following'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// 空のプロフィール
  static UserProfile get empty => UserProfile(
        id: '',
        displayName: 'Unknown User',
      );

  /// プロフィールをコピー
  UserProfile copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? totalWalks,
    int? totalPins,
    bool? isFollowing,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      totalWalks: totalWalks ?? this.totalWalks,
      totalPins: totalPins ?? this.totalPins,
      isFollowing: isFollowing ?? this.isFollowing,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// タイムラインピン
class TimelinePin {
  final String pinId;
  final String routeId;
  final String routeName;
  final String areaName;
  final String pinType;
  final String title;
  final String? comment;
  final int likesCount;
  final List<String> photoUrls;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final double pinLat;
  final double pinLon;
  final bool isLiked;

  TimelinePin({
    required this.pinId,
    required this.routeId,
    required this.routeName,
    required this.areaName,
    required this.pinType,
    required this.title,
    this.comment,
    required this.likesCount,
    required this.photoUrls,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.pinLat,
    required this.pinLon,
    required this.isLiked,
  });

  factory TimelinePin.fromMap(Map<String, dynamic> map) {
    return TimelinePin(
      pinId: map['pin_id'] as String,
      routeId: map['route_id'] as String,
      routeName: map['route_name'] as String,
      areaName: map['area_name'] as String,
      pinType: map['pin_type'] as String,
      title: map['title'] as String,
      comment: map['comment'] as String?,
      likesCount: map['likes_count'] as int,
      photoUrls: (map['photo_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      pinLat: (map['pin_lat'] as num).toDouble(),
      pinLon: (map['pin_lon'] as num).toDouble(),
      isLiked: map['is_liked'] as bool,
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

  /// 相対時間表示（"1分前"、"3時間前"など）
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}週間前';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}ヶ月前';
    } else {
      return '${(difference.inDays / 365).floor()}年前';
    }
  }
}
