import 'package:latlong2/latlong.dart';

/// ホーム画面用の最新ピン投稿モデル
/// Supabase RPC `get_recent_pins` の返り値に対応
class RecentPinPost {
  final String pinId;
  final String routeId;
  final String routeName;
  final String areaId;
  final String areaName;
  final String prefecture;
  final String pinType;
  final String title;
  final String comment;
  final int likesCount;
  final int commentsCount;
  final String photoUrl; // 最初の1枚の写真URL
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final DateTime createdAt;
  final LatLng location;

  RecentPinPost({
    required this.pinId,
    required this.routeId,
    required this.routeName,
    required this.areaId,
    required this.areaName,
    required this.prefecture,
    required this.pinType,
    required this.title,
    required this.comment,
    required this.likesCount,
    required this.commentsCount,
    required this.photoUrl,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.createdAt,
    required this.location,
  });

  /// Supabase RPC `get_recent_pins` の返り値をパース
  factory RecentPinPost.fromJson(Map<String, dynamic> json) {
    return RecentPinPost(
      pinId: json['pin_id'] as String,
      routeId: json['route_id'] as String,
      routeName: json['route_name'] as String,
      areaId: json['area_id'] as String,
      areaName: json['area_name'] as String,
      prefecture: json['prefecture'] as String? ?? '',
      pinType: json['pin_type'] as String,
      title: json['title'] as String,
      comment: json['comment'] as String? ?? '',
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      photoUrl: json['photo_url'] as String? ?? '',
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Unknown User',
      userAvatarUrl: json['user_avatar_url'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      location: LatLng(
        (json['pin_lat'] as num?)?.toDouble() ?? 0.0,
        (json['pin_lon'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }

  /// 相対時間表示（例：「3日前」「2時間前」）
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 0) {
      return '${diff.inDays}日前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}時間前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }

  /// ピンの種類を日本語ラベルで返す
  String get pinTypeLabel {
    switch (pinType) {
      case 'scenery':
        return '景色';
      case 'shop':
        return '店舗';
      case 'encounter':
        return '出会い';
      case 'other':
      default:
        return 'その他';
    }
  }

  @override
  String toString() =>
      'RecentPinPost(pinId: $pinId, title: $title, areaName: $areaName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecentPinPost && other.pinId == pinId;
  }

  @override
  int get hashCode => pinId.hashCode;
}
