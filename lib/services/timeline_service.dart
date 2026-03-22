import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

/// タイムラインアイテムモデル
class TimelineItem {
  final String pinId;
  final String routeId;
  final String routeName;
  final String areaName;
  final String pinType;
  final String title;
  final String comment;
  final int likesCount;
  final int commentsCount;
  final List<String> photoUrls;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final DateTime createdAt;
  final bool isLiked;

  TimelineItem({
    required this.pinId,
    required this.routeId,
    required this.routeName,
    required this.areaName,
    required this.pinType,
    required this.title,
    required this.comment,
    required this.likesCount,
    required this.commentsCount,
    required this.photoUrls,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.createdAt,
    required this.isLiked,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      pinId: json['pin_id']?.toString() ?? '',
      routeId: json['route_id']?.toString() ?? '',
      routeName: json['route_name']?.toString() ?? '不明なルート',
      areaName: json['area_name']?.toString() ?? '不明なエリア',
      pinType: json['pin_type']?.toString() ?? 'other',
      title: json['title']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      photoUrls: _parseStringList(json['photo_urls']),
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'ユーザー',
      userAvatarUrl: json['user_avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.whereType<String>().toList();
    return [];
  }

  bool get hasPhotos => photoUrls.isNotEmpty;

  String get pinTypeLabel {
    switch (pinType) {
      case 'scenery':
        return '景色';
      case 'shop':
        return '店舗';
      case 'encounter':
        return '出会い';
      case 'facility':
        return '施設';
      default:
        return 'その他';
    }
  }

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}ヶ月前';
    if (diff.inDays > 0) return '${diff.inDays}日前';
    if (diff.inHours > 0) return '${diff.inHours}時間前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分前';
    return 'たった今';
  }
}

/// タイムラインサービス
class TimelineService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// コミュニティタイムラインを取得
  Future<List<TimelineItem>> getCommunityTimeline({
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_community_timeline',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      if (kDebugMode) {
        appLog('📰 Timeline: ${data.length} items loaded');
      }
      return data.map((item) => TimelineItem.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        appLog('❌ Timeline error: $e');
      }
      return [];
    }
  }
}
