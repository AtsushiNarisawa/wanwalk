import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/social_provider.dart';
import '../../providers/user_statistics_provider.dart';
import '../../providers/auth_provider.dart';
import '../social/followers_screen.dart';
import '../social/following_screen.dart';

/// ユーザープロフィール画面
class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = currentUser?.id == userId;
    
    final statisticsAsync = ref.watch(userStatisticsProvider(userId));
    final isFollowingAsync = ref.watch(isFollowingProvider(userId));

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanMapColors.cardDark : Colors.white,
        elevation: 0,
        title: Text(
          isOwnProfile ? 'プロフィール' : 'ユーザー情報',
          style: WanMapTypography.heading2,
        ),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // 設定画面へ遷移
                Navigator.pushNamed(context, '/settings');
              },
            ),
        ],
      ),
      body: statisticsAsync.when(
        data: (statistics) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(
                  context,
                  ref,
                  isDark,
                  statistics,
                  isOwnProfile,
                  isFollowingAsync,
                ),
                const SizedBox(height: WanMapSpacing.medium),
                _buildStatisticsSection(isDark, statistics),
                const SizedBox(height: WanMapSpacing.medium),
                _buildRecentActivity(context, isDark, userId),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(isDark, error.toString()),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    dynamic statistics,
    bool isOwnProfile,
    AsyncValue<bool> isFollowingAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.large),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : Colors.white,
      ),
      child: Column(
        children: [
          // アバター
          CircleAvatar(
            radius: 50,
            backgroundColor: WanMapColors.accent.withOpacity(0.2),
            child: Icon(
              Icons.person,
              size: 50,
              color: WanMapColors.accent,
            ),
          ),
          const SizedBox(height: WanMapSpacing.medium),
          
          // ユーザー名
          Text(
            'ユーザー名', // TODO: 実際のユーザー名を表示
            style: WanMapTypography.heading2,
          ),
          const SizedBox(height: WanMapSpacing.tiny),
          
          // Bio
          Text(
            '愛犬と一緒に散歩を楽しんでいます！',
            style: WanMapTypography.body.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WanMapSpacing.medium),
          
          // フォロワー・フォロー中の数
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatButton(
                context,
                isDark,
                statistics.followersCount,
                'フォロワー',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowersScreen(userId: userId),
                    ),
                  );
                },
              ),
              const SizedBox(width: WanMapSpacing.large),
              _buildStatButton(
                context,
                isDark,
                statistics.followingCount,
                'フォロー中',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowingScreen(userId: userId),
                    ),
                  );
                },
              ),
            ],
          ),
          
          // フォローボタン（自分以外のプロフィール）
          if (!isOwnProfile) ...[
            const SizedBox(height: WanMapSpacing.medium),
            isFollowingAsync.when(
              data: (isFollowing) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final currentUser = ref.read(currentUserProvider);
                      if (currentUser == null) return;
                      
                      final service = ref.read(socialServiceProvider);
                      await service.toggleFollow(
                        followerId: currentUser.id,
                        followingId: userId,
                        isFollowing: isFollowing,
                      );
                      
                      // プロバイダーを無効化して再取得
                      ref.invalidate(isFollowingProvider);
                      ref.invalidate(userStatisticsProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                          : WanMapColors.accent,
                      padding: const EdgeInsets.symmetric(
                        vertical: WanMapSpacing.small,
                      ),
                    ),
                    child: Text(
                      isFollowing ? 'フォロー中' : 'フォロー',
                      style: TextStyle(
                        color: isFollowing
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatButton(
    BuildContext context,
    bool isDark,
    int count,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: WanMapTypography.heading2,
          ),
          Text(
            label,
            style: WanMapTypography.caption.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(bool isDark, dynamic statistics) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: WanMapSpacing.medium),
      padding: const EdgeInsets.all(WanMapSpacing.medium),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '散歩統計',
            style: WanMapTypography.heading3,
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  isDark,
                  Icons.directions_walk,
                  '散歩回数',
                  '${statistics.totalWalks}回',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  isDark,
                  Icons.straighten,
                  '総距離',
                  statistics.formattedTotalDistance,
                ),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.small),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  isDark,
                  Icons.location_city,
                  'エリア',
                  '${statistics.areasVisited}箇所',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  isDark,
                  Icons.location_on,
                  'ピン投稿',
                  '${statistics.pinsCreated}件',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    bool isDark,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: WanMapColors.accent,
        ),
        const SizedBox(height: WanMapSpacing.tiny),
        Text(
          label,
          style: WanMapTypography.caption.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: WanMapTypography.heading3,
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, bool isDark, String userId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: WanMapSpacing.medium),
      padding: const EdgeInsets.all(WanMapSpacing.medium),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '最近のアクティビティ',
                style: WanMapTypography.heading3,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // すべてのアクティビティを表示
                },
                child: const Text('すべて見る'),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Center(
            child: Text(
              'アクティビティはまだありません',
              style: WanMapTypography.body.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
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
}
