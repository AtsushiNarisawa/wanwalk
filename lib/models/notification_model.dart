// ==================================================
// Notification Models for WanWalk v2
// ==================================================
// Author: AI Assistant
// Created: 2024-11-17
// Purpose: Data models for notification system
// ==================================================

/// 通知タイプ
enum NotificationType {
  like,
  system;

  static NotificationType fromString(String type) {
    switch (type) {
      case 'like':
        return NotificationType.like;
      case 'system':
        return NotificationType.system;
      default:
        throw Exception('Unknown notification type: $type');
    }
  }

  String toJson() => name;
}

/// 通知モデル
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      type: NotificationType.fromString(json['type']),
      title: json['title'],
      message: json['message'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toJson(),
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 通知をコピーして既読状態を変更
  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  /// いいね通知の場合、いいねした人のIDを取得
  String? get likerId {
    if (type == NotificationType.like && data != null) {
      return data!['liker_id'] as String?;
    }
    return null;
  }

  /// いいね通知の場合、いいねした人の名前を取得
  String? get likerUsername {
    if (type == NotificationType.like && data != null) {
      return data!['liker_username'] as String?;
    }
    return null;
  }

  /// いいね通知の場合、ルートIDを取得
  String? get routeId {
    if (type == NotificationType.like && data != null) {
      return data!['route_id'] as String?;
    }
    return null;
  }

  /// いいね通知の場合、ルートタイトルを取得
  String? get routeTitle {
    if (type == NotificationType.like && data != null) {
      return data!['route_title'] as String?;
    }
    return null;
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

  /// 通知タイプに応じたアイコン名
  String get iconName {
    switch (type) {
      case NotificationType.like:
        return 'favorite';
      case NotificationType.system:
        return 'notifications';
    }
  }

  /// 通知タイプに応じたアイコンカラー（Hex文字列）
  String get iconColor {
    switch (type) {
      case NotificationType.like:
        return '#F44336'; // Red
      case NotificationType.system:
        return '#2196F3'; // Blue
    }
  }
}

/// 通知設定モデル（将来の拡張用）
class NotificationSettings {
  final bool enableLikeNotifications;
  final bool enableSystemNotifications;
  final bool enablePushNotifications;

  NotificationSettings({
    this.enableLikeNotifications = true,
    this.enableSystemNotifications = true,
    this.enablePushNotifications = false,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enableLikeNotifications: json['enable_like_notifications'] ?? true,
      enableSystemNotifications: json['enable_system_notifications'] ?? true,
      enablePushNotifications: json['enable_push_notifications'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable_like_notifications': enableLikeNotifications,
      'enable_system_notifications': enableSystemNotifications,
      'enable_push_notifications': enablePushNotifications,
    };
  }

  NotificationSettings copyWith({
    bool? enableLikeNotifications,
    bool? enableSystemNotifications,
    bool? enablePushNotifications,
  }) {
    return NotificationSettings(
      enableLikeNotifications:
          enableLikeNotifications ?? this.enableLikeNotifications,
      enableSystemNotifications:
          enableSystemNotifications ?? this.enableSystemNotifications,
      enablePushNotifications:
          enablePushNotifications ?? this.enablePushNotifications,
    );
  }
}
