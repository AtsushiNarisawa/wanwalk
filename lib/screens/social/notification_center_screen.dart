// ==================================================
// Notification Center Screen for WanMap v2
// ==================================================
// Author: AI Assistant
// Created: 2025-01-17
// Purpose: Display user notifications with realtime updates
// ==================================================

import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupRealtimeSubscription();
  }

  /// 通知一覧を読み込み
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await _notificationService.getNotifications(
        limit: 50,
      );
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Realtime購読をセットアップ
  void _setupRealtimeSubscription() {
    _notificationService.subscribeToNotifications((newNotification) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, newNotification);
        });
      }
    });
  }

  /// 通知を既読にする
  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markAsRead(notification.id);
      
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(isRead: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('既読にできませんでした: $e')),
        );
      }
    }
  }

  /// すべての通知を既読にする
  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      if (mounted) {
        setState(() {
          _notifications = _notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('すべての通知を既読にしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  /// 通知を削除
  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _notificationService.deleteNotification(notification.id);
      
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知を削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除できませんでした: $e')),
        );
      }
    }
  }

  /// 通知タップ時の処理
  void _handleNotificationTap(NotificationModel notification) {
    // 既読にする
    _markAsRead(notification);

    // 通知タイプに応じて画面遷移
    switch (notification.type) {
      case NotificationType.follow:
        if (notification.followerId != null) {
          // TODO: ユーザープロフィール画面に遷移
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (context) => UserProfileScreen(userId: notification.followerId!),
          // ));
        }
        break;
      
      case NotificationType.like:
        if (notification.routeId != null) {
          // TODO: ルート詳細画面に遷移
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (context) => RouteDetailScreen(routeId: notification.routeId!),
          // ));
        }
        break;
      
      case NotificationType.system:
        // システム通知は何もしない（または専用画面へ遷移）
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'すべて既読',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('エラーが発生しました', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '通知はありません',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationTile(notification);
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final iconColor = _parseColor(notification.iconColor);
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(
            _getIconData(notification.iconName),
            color: iconColor,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              notification.relativeTime,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
        tileColor: notification.isRead ? null : Colors.blue[50],
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  /// Hex文字列をColorに変換
  Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) {
      buffer.write('ff'); // Alpha channel
      buffer.write(hexString.substring(1));
    } else {
      buffer.write(hexString);
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// アイコン名からIconDataを取得
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person_add':
        return Icons.person_add;
      case 'favorite':
        return Icons.favorite;
      case 'notifications':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  @override
  void dispose() {
    // Realtime購読を解除
    _notificationService.dispose();
    super.dispose();
  }
}
