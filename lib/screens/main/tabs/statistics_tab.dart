import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_statistics.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/badge_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../badges/badge_list_screen.dart';

/// StatisticsTab - 統計ダッシュボード（タブとして統合）
/// 
/// 既存のStatisticsDashboardScreenの機能をタブに統合
class StatisticsTab extends ConsumerWidget {
  const StatisticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        backgroundColor: isDark 
            ? WanMapColors.backgroundDark 
            : WanMapColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '統計',
            style: WanMapTypography.headlineMedium.copyWith(
              color: isDark 
                  ? WanMapColors.textPrimaryDark 
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
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
      backgroundColor: isDark 
          ? WanMapColors.backgroundDark 
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '統計ダッシュボード',
          style: WanMapTypography.headlineMedium.copyWith(
            color: isDark 
                ? WanMapColors.textPrimaryDark 
                : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
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
    badgeStats,
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
            ],
          ),
        ),
      ),
    );
  }
}
