import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_statistics.dart';
import '../../models/badge.dart';
import '../../providers/user_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../badges/badge_list_screen.dart';

/// Statistics Dashboard Screen
/// 
/// Comprehensive statistics view with:
/// - User level and progress
/// - Total distance, walks, areas
/// - Badge collection summary
/// - Next badge to unlock
/// - Activity charts (future enhancement)
class StatisticsDashboardScreen extends ConsumerWidget {
  const StatisticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('統計'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'ログインして統計を確認しましょう',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final statisticsAsync = ref.watch(userStatisticsProvider(userId));
    final badgeStatsAsync = ref.watch(badgeStatisticsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('統計ダッシュボード'),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BadgeListScreen(),
                ),
              );
            },
            tooltip: 'バッジを見る',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userStatisticsProvider(userId));
          ref.invalidate(badgeStatisticsProvider(userId));
        },
        child: statisticsAsync.when(
          data: (statistics) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Level Card
                _buildLevelCard(statistics, isDark),
                
                const SizedBox(height: 16),
                
                // Statistics Grid
                _buildStatisticsGrid(statistics, isDark),
                
                const SizedBox(height: 16),
                
                // Badge Summary Card
                badgeStatsAsync.when(
                  data: (badgeStats) => _buildBadgeSummary(
                    context,
                    badgeStats,
                    isDark,
                  ),
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
                
                const SizedBox(height: 16),
                
                // Recent Badges (Top 3 Recently Unlocked)
                _buildRecentBadges(ref, userId, isDark),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  '統計の読み込みに失敗しました',
                  style: TextStyle(color: Colors.red[300]),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.invalidate(userStatisticsProvider(userId));
                  },
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(UserStatistics statistics, bool isDark) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'レベル',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${statistics.userLevel}',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: WanMapColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '次: Lv${statistics.userLevel + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WanMapColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    size: 32,
                    color: WanMapColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '経験値',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${(statistics.levelProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: WanMapColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: statistics.levelProgress,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(WanMapColors.accent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid(UserStatistics statistics, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.route,
          label: '総距離',
          value: statistics.formattedTotalDistance,
          color: Colors.blue,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.directions_walk,
          label: '総散歩回数',
          value: '${statistics.totalWalks}回',
          color: Colors.green,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.explore,
          label: '訪問エリア',
          value: '${statistics.areasVisited}地域',
          color: Colors.orange,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.location_on,
          label: '作成ピン',
          value: '${statistics.pinsCreated}個',
          color: Colors.red,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeSummary(
    BuildContext context,
    BadgeStatistics badgeStats,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BadgeListScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: WanMapColors.accent,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'バッジコレクション',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${badgeStats.unlockedBadges}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: WanMapColors.accent,
                        ),
                      ),
                      Text(
                        '獲得済み',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                  ),
                  Column(
                    children: [
                      Text(
                        badgeStats.unlockProgressPercentage,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: WanMapColors.accent,
                        ),
                      ),
                      Text(
                        '達成率',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: badgeStats.unlockProgress,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(WanMapColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBadges(WidgetRef ref, String userId, bool isDark) {
    final badgesAsync = ref.watch(userBadgesProvider(userId));

    return badgesAsync.when(
      data: (badges) {
        // Filter only unlocked badges and sort by unlock date
        final unlockedBadges = badges
            .where((badge) => badge.isUnlocked && badge.unlockedAt != null)
            .toList();
        
        if (unlockedBadges.isEmpty) {
          return const SizedBox.shrink();
        }

        unlockedBadges.sort((a, b) => 
          b.unlockedAt!.compareTo(a.unlockedAt!));
        
        final recentBadges = unlockedBadges.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '最近獲得したバッジ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...recentBadges.map((badge) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        badge.tierColor.withOpacity(0.3),
                        badge.tierColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    badge.icon,
                    color: badge.tierColor,
                    size: 24,
                  ),
                ),
                title: Text(
                  badge.nameJa,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _formatUnlockDate(badge.unlockedAt!),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badge.tierColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge.tier.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badge.tierColor,
                    ),
                  ),
                ),
              ),
            )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  String _formatUnlockDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}週間前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}ヶ月前';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }
}
