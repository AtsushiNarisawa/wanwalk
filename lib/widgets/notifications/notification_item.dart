import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/user_statistics.dart';

/// 通知アイテムウィジェット
class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: WanMapSpacing.medium),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(WanMapSpacing.medium),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDark ? WanMapColors.cardDark : Colors.white)
                : (isDark
                    ? WanMapColors.accent.withOpacity(0.1)
                    : WanMapColors.accent.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(12),
            border: notification.isRead
                ? null
                : Border.all(
                    color: WanMapColors.accent.withOpacity(0.3),
                    width: 1,
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // アイコン
              _buildNotificationIcon(isDark),
              const SizedBox(width: WanMapSpacing.medium),
              
              // 通知内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: WanMapTypography.heading4.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: WanMapColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.body != null) ...[
                      const SizedBox(height: WanMapSpacing.tiny),
                      Text(
                        '${notification.actorName}${notification.body}',
                        style: WanMapTypography.body.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: WanMapSpacing.tiny),
                    Text(
                      _formatTime(notification.createdAt),
                      style: WanMapTypography.caption.copyWith(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(bool isDark) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'new_follower':
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case 'pin_liked':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case 'pin_commented':
        icon = Icons.comment;
        color = Colors.green;
        break;
      case 'new_pin':
        icon = Icons.location_on;
        color = WanMapColors.accent;
        break;
      case 'route_walked':
        icon = Icons.directions_walk;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return DateFormat('M月d日').format(dateTime);
    }
  }
}
