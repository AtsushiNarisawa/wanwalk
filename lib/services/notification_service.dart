import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_statistics.dart';

/// 通知サービス
class NotificationService {
  final SupabaseClient _supabase;

  NotificationService(this._supabase);

  /// 通知一覧取得
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_notifications',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => NotificationModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notifications: $e');
      }
      return [];
    }
  }

  /// 未読通知数取得
  Future<int> getUnreadCount({required String userId}) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread count: $e');
      }
      return 0;
    }
  }

  /// 通知を既読にする
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
      rethrow;
    }
  }

  /// すべての通知を既読にする
  Future<void> markAllAsRead({required String userId}) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
      rethrow;
    }
  }

  /// 通知を削除
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
      rethrow;
    }
  }

  /// すべての既読通知を削除
  Future<void> deleteAllRead({required String userId}) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .eq('is_read', true);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all read notifications: $e');
      }
      rethrow;
    }
  }

  /// 通知をリアルタイムで購読
  RealtimeChannel subscribeToNotifications({
    required String userId,
    required void Function(NotificationModel notification) onNotification,
  }) {
    final channel = _supabase.channel('notifications:$userId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final notification = NotificationModel.fromMap(
                payload.newRecord,
              );
              onNotification(notification);
            } catch (e) {
              if (kDebugMode) {
                print('Error processing notification: $e');
              }
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// リアルタイム購読を解除
  Future<void> unsubscribeFromNotifications(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
