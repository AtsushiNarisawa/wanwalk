import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/badge.dart';
import '../../providers/badge_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/badges/badge_card.dart';
import '../../theme/app_colors.dart';

/// Badge List Screen
/// 
/// Displays all badges organized by category:
/// - Distance badges
/// - Area exploration badges
/// - Pin creation badges
/// - Social badges
/// - Special badges
/// 
/// Shows both locked and unlocked badges with progress statistics
class BadgeListScreen extends ConsumerStatefulWidget {
  const BadgeListScreen({super.key});

  @override
  ConsumerState<BadgeListScreen> createState() => _BadgeListScreenState();
}

class _BadgeListScreenState extends ConsumerState<BadgeListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: BadgeCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('バッジ'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.workspace_premium,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'ログインしてバッジを確認しましょう',
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

    final badgeStatisticsAsync = ref.watch(badgeStatisticsProvider(userId));
    final badgesByCategoryAsync = ref.watch(badgesByCategoryProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('バッジコレクション'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Badge Statistics Header
              badgeStatisticsAsync.when(
                data: (stats) => _buildStatisticsHeader(stats, isDark),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'エラーが発生しました',
                    style: TextStyle(color: Colors.red[300]),
                  ),
                ),
              ),
              
              // Category Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: WanMapColors.accent,
                labelColor: WanMapColors.accent,
                unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                tabs: BadgeCategory.values.map((category) {
                  return Tab(
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(category.label),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: badgesByCategoryAsync.when(
        data: (badgesByCategory) => TabBarView(
          controller: _tabController,
          children: BadgeCategory.values.map((category) {
            final badges = badgesByCategory[category] ?? [];
            return _buildBadgeGrid(badges, category, isDark);
          }).toList(),
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
                'バッジの読み込みに失敗しました',
                style: TextStyle(color: Colors.red[300]),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.invalidate(badgesByCategoryProvider(userId));
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsHeader(BadgeStatistics stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${stats.unlockedBadges}',
                style: TextStyle(
                  fontSize: 24,
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
                '${stats.totalBadges}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                '全バッジ',
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
                stats.unlockProgressPercentage,
                style: TextStyle(
                  fontSize: 24,
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
    );
  }

  Widget _buildBadgeGrid(List<Badge> badges, BadgeCategory category, bool isDark) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'このカテゴリにはバッジがありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Sort badges: unlocked first, then by tier
    final sortedBadges = [...badges];
    sortedBadges.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      return a.tier.index.compareTo(b.tier.index);
    });

    return RefreshIndicator(
      onRefresh: () async {
        final userId = ref.read(currentUserIdProvider);
        if (userId != null) {
          ref.invalidate(badgesByCategoryProvider(userId));
        }
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: sortedBadges.length,
        itemBuilder: (context, index) {
          final badge = sortedBadges[index];
          return BadgeCard(badge: badge);
        },
      ),
    );
  }

  IconData _getCategoryIcon(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.distance:
        return Icons.route;
      case BadgeCategory.area:
        return Icons.explore;
      case BadgeCategory.pins:
        return Icons.location_on;
      case BadgeCategory.social:
        return Icons.people;
      case BadgeCategory.special:
        return Icons.star;
    }
  }
}
