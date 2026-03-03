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
  // [BUG-H09 修正] ページネーションをローカルリストで蓄積する方式に変更
  final List<dynamic> _allNotifications = [];
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

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
    if (!_isLoadingMore && _hasMoreData) {
      setState(() {
        _currentPage++;
        _isLoadingMore = true;
      });
    }
  }

  void _refresh() {
    setState(() {
      _allNotifications.clear();
      _currentPage = 0;
      _isLoadingMore = false;
      _hasMoreData = true;
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
      offset: _currentPage * _pageSize,
    );
    final notificationsAsync = ref.watch(notificationsProvider(params));

    // 新しいページのデータを蓄積
    notificationsAsync.whenData((newNotifications) {
      if (_isLoadingMore || _allNotifications.isEmpty) {
        // 重複排除して追加
        final existingIds = _allNotifications.map((n) => n.notificationId).toSet();
        final uniqueNew = newNotifications.where((n) => !existingIds.contains(n.notificationId)).toList();
        if (uniqueNew.isNotEmpty) {
          _allNotifications.addAll(uniqueNew);
        }
        if (newNotifications.length < _pageSize) {
          _hasMoreData = false;
        }
        _isLoadingMore = false;
      }
    });

    // 初回ロード中
    if (_allNotifications.isEmpty && notificationsAsync.isLoading) {
      return Scaffold(
        backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
        appBar: _buildAppBar(isDark, notificationsAsync, currentUser),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // エラー（初回のみ）
    if (_allNotifications.isEmpty && notificationsAsync.hasError) {
      return Scaffold(
        backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
        appBar: _buildAppBar(isDark, notificationsAsync, currentUser),
        body: _buildErrorState(isDark, notificationsAsync.error.toString()),
      );
    }

    final notifications = _allNotifications;

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: _buildAppBar(isDark, notificationsAsync, currentUser),
      body: notifications.isEmpty
          ? _buildEmptyState(isDark)
          : RefreshIndicator(
            onRefresh: () async {
              _refresh();
              ref.invalidate(notificationsProvider);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(WanMapSpacing.medium),
              itemCount: notifications.length + (_hasMoreData ? 1 : 0),
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
                      _allNotifications.removeAt(index);
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadNotificationsCountProvider);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, AsyncValue notificationsAsync, dynamic currentUser) {
    return AppBar(
      backgroundColor: isDark ? WanMapColors.cardDark : Colors.white,
      elevation: 0,
      title: const Text(
        '通知',
        style: WanMapTypography.heading2,
      ),
      actions: [
        if (_allNotifications.any((n) => !n.isRead))
          TextButton(
            onPressed: () async {
              final service = ref.read(notificationServiceProvider);
              await service.markAllAsRead(userId: currentUser.id);
              _refresh();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationsCountProvider);
            },
            child: const Text('すべて既読'),
          ),
      ],
    );
  }

  void _handleNotificationTap(BuildContext context, dynamic notification) {
    switch (notification.type) {
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
