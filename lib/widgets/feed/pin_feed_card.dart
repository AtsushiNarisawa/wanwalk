import 'package:flutter/material.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../models/recent_pin_post.dart';

/// コミュニティピンカード（ユーザー投稿）
class PinFeedCard extends StatelessWidget {
  final RecentPinPost pin;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onRouteTap;

  const PinFeedCard({
    super.key,
    required this.pin,
    required this.isDark,
    required this.onTap,
    this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: WanWalkSpacing.lg,
          vertical: WanWalkSpacing.sm,
        ),
        padding: const EdgeInsets.all(WanWalkSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー（アバター + 名前 + ピンタイプ）
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: WanWalkColors.accent.withValues(alpha: 0.2),
                  backgroundImage: pin.userAvatarUrl.isNotEmpty
                      ? NetworkImage(pin.userAvatarUrl)
                      : null,
                  child: pin.userAvatarUrl.isEmpty
                      ? Icon(Icons.person, size: 18, color: WanWalkColors.accent)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.userName.isNotEmpty ? pin.userName : 'WanWalkユーザー',
                        style: WanWalkTypography.bodySmall.copyWith(
                          color: isDark
                              ? WanWalkColors.textPrimaryDark
                              : WanWalkColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatRelativeTime(pin.createdAt),
                        style: WanWalkTypography.caption.copyWith(
                          color: isDark
                              ? WanWalkColors.textTertiaryDark
                              : WanWalkColors.textTertiaryLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPinTypeBadge(pin.pinType),
              ],
            ),

            const SizedBox(height: WanWalkSpacing.sm),

            // タイトル
            Text(
              pin.title,
              style: WanWalkTypography.bodyMedium.copyWith(
                color: isDark
                    ? WanWalkColors.textPrimaryDark
                    : WanWalkColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // コメント
            if (pin.comment.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                pin.comment,
                style: WanWalkTypography.bodySmall.copyWith(
                  color: isDark
                      ? WanWalkColors.textSecondaryDark
                      : WanWalkColors.textSecondaryLight,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // 写真（あれば）
            if (pin.photoUrl.isNotEmpty) ...[
              const SizedBox(height: WanWalkSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  pin.photoUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],

            // フッター（いいね + ルートリンク）
            const SizedBox(height: WanWalkSpacing.sm),
            Row(
              children: [
                Icon(Icons.favorite_border, size: 16,
                    color: isDark ? WanWalkColors.textTertiaryDark : WanWalkColors.textTertiaryLight),
                const SizedBox(width: 4),
                Text(
                  '${pin.likesCount}',
                  style: WanWalkTypography.caption.copyWith(
                    color: isDark ? WanWalkColors.textTertiaryDark : WanWalkColors.textTertiaryLight,
                  ),
                ),
                const Spacer(),
                if (onRouteTap != null)
                  GestureDetector(
                    onTap: onRouteTap,
                    child: Row(
                      children: [
                        Icon(Icons.map, size: 14, color: WanWalkColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'ルートを見る',
                          style: WanWalkTypography.caption.copyWith(
                            color: WanWalkColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinTypeBadge(String pinType) {
    Color color;
    IconData icon;
    String label;

    switch (pinType) {
      case 'scenery':
        color = Colors.blue;
        icon = Icons.landscape;
        label = '景色';
        break;
      case 'shop':
        color = Colors.orange;
        icon = Icons.store;
        label = '店舗';
        break;
      case 'facility':
        color = Colors.purple;
        icon = Icons.business;
        label = '施設';
        break;
      default:
        color = Colors.grey;
        icon = Icons.push_pin;
        label = 'ピン';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${dateTime.month}/${dateTime.day}';
  }
}
