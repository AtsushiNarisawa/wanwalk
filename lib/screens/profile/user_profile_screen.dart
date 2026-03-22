import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../providers/user_statistics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';


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
    final profileAsync = ref.watch(profileProvider(userId));

    return Scaffold(
      backgroundColor: isDark
          ? WanWalkColors.backgroundDark
          : WanWalkColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanWalkColors.cardDark : Colors.white,
        elevation: 0,
        title: Text(
          isOwnProfile ? 'プロフィール' : 'ユーザー情報',
          style: WanWalkTypography.heading2,
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
                  profileAsync.valueOrNull,
                ),
                const SizedBox(height: WanWalkSpacing.medium),
                _buildStatisticsSection(isDark, statistics),
                const SizedBox(height: WanWalkSpacing.medium),
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
    ProfileData? profile,
  ) {
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.large),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : Colors.white,
      ),
      child: Column(
        children: [
          // アバター
          CircleAvatar(
            radius: 50,
            backgroundColor: WanWalkColors.accent.withOpacity(0.2),
            backgroundImage: profile?.avatarUrl != null
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            child: profile?.avatarUrl == null
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: WanWalkColors.accent,
                  )
                : null,
          ),
          const SizedBox(height: WanWalkSpacing.medium),
          
          // ユーザー名
          Text(
            profile?.displayName ?? 'ユーザー',
            style: WanWalkTypography.heading2,
          ),
          const SizedBox(height: WanWalkSpacing.tiny),

          // Bio
          Text(
            profile?.bio ?? '愛犬と一緒に散歩を楽しんでいます！',
            style: WanWalkTypography.body.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WanWalkSpacing.medium),
          
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(bool isDark, dynamic statistics) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.medium),
      padding: const EdgeInsets.all(WanWalkSpacing.medium),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '散歩統計',
            style: WanWalkTypography.heading3,
          ),
          const SizedBox(height: WanWalkSpacing.medium),
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
          const SizedBox(height: WanWalkSpacing.small),
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
          color: WanWalkColors.accent,
        ),
        const SizedBox(height: WanWalkSpacing.tiny),
        Text(
          label,
          style: WanWalkTypography.caption.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: WanWalkTypography.heading3,
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, bool isDark, String userId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.medium),
      padding: const EdgeInsets.all(WanWalkSpacing.medium),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '最近のアクティビティ',
                style: WanWalkTypography.heading3,
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
          const SizedBox(height: WanWalkSpacing.medium),
          Center(
            child: Text(
              'アクティビティはまだありません',
              style: WanWalkTypography.body.copyWith(
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
          const SizedBox(height: WanWalkSpacing.medium),
          Text(
            'エラーが発生しました',
            style: WanWalkTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanWalkSpacing.small),
          Text(
            error,
            style: WanWalkTypography.caption.copyWith(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
