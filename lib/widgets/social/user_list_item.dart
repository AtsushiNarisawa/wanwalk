import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/user_profile.dart';
import '../../providers/social_provider.dart';
import '../../providers/auth_provider.dart';

/// ユーザーリストアイテム（フォロワー・フォロー中一覧用）
class UserListItem extends ConsumerWidget {
  final UserProfile user;
  final VoidCallback onTap;

  const UserListItem({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = currentUser?.id == user.id;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(WanMapSpacing.medium),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // アバター
            CircleAvatar(
              radius: 24,
              backgroundColor: WanMapColors.accent.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: WanMapColors.accent,
              ),
            ),
            const SizedBox(width: WanMapSpacing.medium),
            
            // ユーザー情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: WanMapTypography.heading3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.bio != null) ...[
                    const SizedBox(height: WanMapSpacing.tiny),
                    Text(
                      user.bio!,
                      style: WanMapTypography.caption.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: WanMapSpacing.tiny),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.followersCount} フォロワー',
                        style: WanMapTypography.caption.copyWith(
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // フォローボタン
            if (!isOwnProfile)
              _buildFollowButton(context, ref, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context, WidgetRef ref, bool isDark) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final isFollowingAsync = ref.watch(isFollowingProvider(user.id));

    return isFollowingAsync.when(
      data: (isFollowing) {
        return SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: () async {
              final service = ref.read(socialServiceProvider);
              await service.toggleFollow(
                followerId: currentUser.id,
                followingId: user.id,
                isFollowing: isFollowing,
              );
              ref.invalidate(isFollowingProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing
                  ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                  : WanMapColors.accent,
              padding: const EdgeInsets.symmetric(
                horizontal: WanMapSpacing.medium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isFollowing ? 'フォロー中' : 'フォロー',
              style: TextStyle(
                fontSize: 12,
                color: isFollowing
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.white,
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
