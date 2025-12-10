import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/badge_provider.dart';
import '../../widgets/badges/badge_card.dart';

/// バッジ一覧画面
class BadgeListScreen extends ConsumerWidget {
  const BadgeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('バッジコレクション'),
          backgroundColor: WanMapColors.primary,
        ),
        body: const Center(
          child: Text('ユーザー情報を取得できませんでした'),
        ),
      );
    }
    
    final badgesAsync = ref.watch(userBadgesProvider(userId));
    final badgeStatsAsync = ref.watch(badgeStatisticsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('バッジコレクション'),
        backgroundColor: WanMapColors.primary,
      ),
      body: badgesAsync.when(
        data: (badges) {
          return badgeStatsAsync.when(
            data: (badgeStats) {
              final earnedBadges = badges.where((b) => b.isUnlocked).toList();
              final lockedBadges = badges.where((b) => !b.isUnlocked).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(WanMapSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 統計サマリー
                Container(
                  padding: const EdgeInsets.all(WanMapSpacing.md),
                  decoration: BoxDecoration(
                    color: WanMapColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.emoji_events,
                        label: '獲得済み',
                        value: '${badgeStats.unlockedBadges}個',
                        color: Colors.amber,
                      ),
                      _buildStatItem(
                        icon: Icons.lock,
                        label: '未獲得',
                        value: '${badgeStats.totalBadges - badgeStats.unlockedBadges}個',
                        color: Colors.grey,
                      ),
                      _buildStatItem(
                        icon: Icons.trending_up,
                        label: '達成率',
                        value: badgeStats.unlockProgressPercentage,
                        color: WanMapColors.accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WanMapSpacing.lg),

                // 獲得済みバッジ
                if (earnedBadges.isNotEmpty) ...[
                  Text(
                    '獲得済みバッジ',
                    style: WanMapTypography.titleLarge,
                  ),
                  const SizedBox(height: WanMapSpacing.md),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: WanMapSpacing.sm,
                      mainAxisSpacing: WanMapSpacing.sm,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: earnedBadges.length,
                    itemBuilder: (context, index) {
                      return BadgeCard(badge: earnedBadges[index]);
                    },
                  ),
                  const SizedBox(height: WanMapSpacing.lg),
                ],

                // 未獲得バッジ
                if (lockedBadges.isNotEmpty) ...[
                  Text(
                    '未獲得バッジ',
                    style: WanMapTypography.titleLarge,
                  ),
                  const SizedBox(height: WanMapSpacing.md),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: WanMapSpacing.sm,
                      mainAxisSpacing: WanMapSpacing.sm,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: lockedBadges.length,
                    itemBuilder: (context, index) {
                      return BadgeCard(badge: lockedBadges[index]);
                    },
                  ),
                ],
              ],
            ),
          );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: WanMapSpacing.md),
                  Text('統計エラー: $error'),
                  const SizedBox(height: WanMapSpacing.md),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(badgeStatisticsProvider(userId));
                    },
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: WanMapSpacing.md),
              Text('バッジ取得エラー: $error'),
              const SizedBox(height: WanMapSpacing.md),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(userBadgesProvider(userId));
                  ref.invalidate(badgeStatisticsProvider(userId));
                },
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: WanMapSpacing.xs),
        Text(
          value,
          style: WanMapTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: WanMapTypography.bodySmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
