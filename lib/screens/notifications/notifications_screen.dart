import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/notifications/notification_item.dart';

/// 通知センター画面
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _offset = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _offset += _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return _buildLoginPrompt(isDark);
    }

    final params = NotificationsParams(
      userId: currentUser.id,
      limit: _pageSize,
      offset: _offset,
    );
    final notificationsAsync = ref.watch(notificationsProvider(params));

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanMapColors.cardDark : Colors.white,
        elevation: 0,
        title: const Text(
          '通知',
          style: WanMapTypography.heading2,
        ),
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) {
              if (notifications.any((n) => !n.isRead)) {
                return TextButton(
                  onPressed: () async {
                    final service = ref.read(notificationServiceProvider);
                    await service.markAllAsRead(userId: currentUser.id);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadNotificationsCountProvider);
                  },
                  child: const Text('すべて既読'),
                );
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty && _offset == 0) {
            return _buildEmptyState(isDark);
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _offset = 0;
              });
              ref.invalidate(notificationsProvider);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(WanMapSpacing.medium),
              itemCount: notifications.length + 1,
              itemBuilder: (context, index) {
                if (index == notifications.length) {
                  return _buildLoadingIndicator();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: WanMapSpacing.small),
                  child: NotificationItem(
                    notification: notifications[index],
                    onTap: () async {
                      // 既読にする
                      final service = ref.read(notificationServiceProvider);
                      await service.markAsRead(
                        userId: currentUser.id,
                        notificationId: notifications[index].notificationId,
                      );
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadNotificationsCountProvider);

                      // 通知タイプに応じて画面遷移
                      _handleNotificationTap(
                        context,
                        notifications[index],
                      );
                    },
                    onDelete: () async {
                      final service = ref.read(notificationServiceProvider);
                      await service.deleteNotification(
                        userId: currentUser.id,
                        notificationId: notifications[index].notificationId,
                      );
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadNotificationsCountProvider);
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(isDark, error.toString()),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, dynamic notification) {
    switch (notification.type) {
      case 'new_follower':
        if (notification.actorId != null) {
          Navigator.pushNamed(
            context,
            '/user_profile',
            arguments: notification.actorId,
          );
        }
        break;
      case 'pin_liked':
      case 'pin_commented':
        if (notification.targetId != null) {
          // ピン詳細画面へ遷移
          // TODO: ピン詳細画面実装後に追加
        }
        break;
      case 'new_pin':
        if (notification.targetId != null) {
          // ルート詳細画面へ遷移
          Navigator.pushNamed(
            context,
            '/route_detail',
            arguments: notification.targetId,
          );
        }
        break;
      default:
        break;
    }
  }

  Widget _buildLoginPrompt(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Text(
            'ログインが必要です',
            style: WanMapTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanMapSpacing.medium),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WanMapColors.accent,
            ),
            child: const Text('ログイン'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Text(
            '通知はありません',
            style: WanMapTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.red.shade300 : Colors.red,
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Text(
            'エラーが発生しました',
            style: WanMapTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanMapSpacing.small),
          Text(
            error,
            style: WanMapTypography.caption.copyWith(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(WanMapSpacing.medium),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
