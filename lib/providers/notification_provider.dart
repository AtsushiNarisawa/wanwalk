import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_statistics.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

/// NotificationService プロバイダー
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(Supabase.instance.client);
});

/// 通知一覧プロバイダー
class NotificationsParams {
  final String userId;
  final int limit;
  final int offset;

  const NotificationsParams({
    required this.userId,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationsParams &&
        other.userId == userId &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(userId, limit, offset);
}

final notificationsProvider = FutureProvider.family<
    List<NotificationModel>,
    NotificationsParams>((ref, params) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getNotifications(
    userId: params.userId,
    limit: params.limit,
    offset: params.offset,
  );
});

/// 未読通知数プロバイダー
final unreadNotificationsCountProvider = FutureProvider.family<int, String>(
  (ref, userId) async {
    final service = ref.read(notificationServiceProvider);
    return await service.getUnreadCount(userId: userId);
  },
);

/// リアルタイム通知状態管理
class NotificationStateNotifier extends StateNotifier<List<NotificationModel>> {
  final NotificationService _service;
  final String _userId;
  RealtimeChannel? _channel;

  NotificationStateNotifier(this._service, this._userId) : super([]) {
    _subscribeToNotifications();
  }

  void _subscribeToNotifications() {
    _channel = _service.subscribeToNotifications(
      userId: _userId,
      onNotification: (notification) {
        // 新しい通知を先頭に追加
        state = [notification, ...state];
      },
    );
  }

  /// 通知を既読にする
  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(
        userId: _userId,
        notificationId: notificationId,
      );
      
      // 状態を更新
      state = state.map((notification) {
        if (notification.notificationId == notificationId) {
          return NotificationModel(
            notificationId: notification.notificationId,
            type: notification.type,
            actorId: notification.actorId,
            actorName: notification.actorName,
            targetId: notification.targetId,
            title: notification.title,
            body: notification.body,
            isRead: true,
            createdAt: notification.createdAt,
          );
        }
        return notification;
      }).toList();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// すべての通知を既読にする
  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead(userId: _userId);
      
      // 状態を更新
      state = state.map((notification) {
        return NotificationModel(
          notificationId: notification.notificationId,
          type: notification.type,
          actorId: notification.actorId,
          actorName: notification.actorName,
          targetId: notification.targetId,
          title: notification.title,
          body: notification.body,
          isRead: true,
          createdAt: notification.createdAt,
        );
      }).toList();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// 通知を削除
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _service.deleteNotification(
        userId: _userId,
        notificationId: notificationId,
      );
      
      // 状態を更新
      state = state.where((n) => n.notificationId != notificationId).toList();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      _service.unsubscribeFromNotifications(_channel!);
    }
    super.dispose();
  }
}

/// リアルタイム通知プロバイダー
final realtimeNotificationsProvider = StateNotifierProvider.family<
    NotificationStateNotifier,
    List<NotificationModel>,
    String>((ref, userId) {
  final service = ref.read(notificationServiceProvider);
  return NotificationStateNotifier(service, userId);
});
