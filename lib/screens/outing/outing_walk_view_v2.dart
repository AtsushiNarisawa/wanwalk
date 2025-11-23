import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/home_provider.dart';
import '../../widgets/home/recommended_route_card.dart';
import '../../widgets/home/trending_route_card.dart';
import '../../widgets/home/recent_memory_card.dart';
import 'area_list_screen.dart';
import 'route_detail_screen.dart';
import '../history/walk_history_screen.dart';
import '../history/walk_detail_screen.dart';

/// Outing Walk View V2（Phase 4対応版）
/// - おすすめルート（大きく表示）
/// - 人気急上昇ルート（横スクロール）
/// - 最近の思い出写真（グリッド表示）
/// - エリア別ボタン
/// - クイックアクション
class OutingWalkViewV2 extends ConsumerWidget {
  const OutingWalkViewV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // 全てのプロバイダーをリフレッシュ
        ref.invalidate(recommendedRoutesProvider);
        ref.invalidate(trendingRoutesProvider);
        ref.invalidate(recentMemoriesProvider);
        ref.invalidate(areasListProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: WanMapSpacing.md),

            // 🎯 今日のおすすめルート
            _buildRecommendedSection(context, ref, userId, isDark),

            const SizedBox(height: WanMapSpacing.xxxl),

            // 🔥 人気急上昇ルート
            _buildTrendingSection(context, ref, isDark),

            const SizedBox(height: WanMapSpacing.xxxl),

            // 📸 最近の思い出
            _buildMemoriesSection(context, ref, userId, isDark),

            const SizedBox(height: WanMapSpacing.xxxl),

            // 🗺️ エリアから探す
            _buildAreasSection(context, ref, isDark),

            const SizedBox(height: WanMapSpacing.xxxl),

            // クイックアクション
            _buildQuickActions(context, isDark),

            const SizedBox(height: WanMapSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  /// 🎯 おすすめルートセクション
  Widget _buildRecommendedSection(
    BuildContext context,
    WidgetRef ref,
    String? userId,
    bool isDark,
  ) {
    final recommendedAsync = ref.watch(recommendedRoutesProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Row(
            children: [
              Icon(
                Icons.recommend,
                color: WanMapColors.accent,
                size: 24,
              ),
              const SizedBox(width: WanMapSpacing.sm),
              Text(
                '今日のおすすめルート',
                style: WanMapTypography.headlineSmall.copyWith(
                  color: isDark
                      ? WanMapColors.textPrimaryDark
                      : WanMapColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WanMapSpacing.lg),
        recommendedAsync.when(
          data: (routes) {
            if (routes.isEmpty) {
              return _buildEmptyState(
                isDark,
                'おすすめルートがありません',
                'ルートを歩いて、おすすめを表示しましょう',
              );
            }
            // 最初の1件を大きく表示
            return RecommendedRouteCard(
              route: routes.first,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteDetailScreen(
                      routeId: routes.first.id!,
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(WanMapSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildEmptyState(
            isDark,
            '読み込みエラー',
            'おすすめルートの取得に失敗しました',
          ),
        ),
      ],
    );
  }

  /// 🔥 人気急上昇ルートセクション
  Widget _buildTrendingSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final trendingAsync = ref.watch(trendingRoutesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: WanMapSpacing.sm),
              Text(
                '人気急上昇ルート',
                style: WanMapTypography.headlineSmall.copyWith(
                  color: isDark
                      ? WanMapColors.textPrimaryDark
                      : WanMapColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WanMapSpacing.lg),
        trendingAsync.when(
          data: (routes) {
            if (routes.isEmpty) {
              return _buildEmptyState(
                isDark,
                '人気ルートがありません',
                'まだデータがありません',
              );
            }
            return SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: WanMapSpacing.lg,
                ),
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < routes.length - 1 ? WanMapSpacing.md : 0,
                    ),
                    child: TrendingRouteCard(
                      route: routes[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteDetailScreen(
                              routeId: routes[index].id!,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(WanMapSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildEmptyState(
            isDark,
            '読み込みエラー',
            '人気ルートの取得に失敗しました',
          ),
        ),
      ],
    );
  }

  /// 📸 最近の思い出セクション
  Widget _buildMemoriesSection(
    BuildContext context,
    WidgetRef ref,
    String? userId,
    bool isDark,
  ) {
    final memoriesAsync = ref.watch(recentMemoriesProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_library,
                    color: WanMapColors.accent,
                    size: 24,
                  ),
                  const SizedBox(width: WanMapSpacing.sm),
                  Text(
                    '最近の思い出',
                    style: WanMapTypography.headlineSmall.copyWith(
                      color: isDark
                          ? WanMapColors.textPrimaryDark
                          : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WalkHistoryScreen(),
                    ),
                  );
                },
                child: Text(
                  'すべて見る',
                  style: WanMapTypography.bodyMedium.copyWith(
                    color: WanMapColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WanMapSpacing.lg),
        memoriesAsync.when(
          data: (memories) {
            if (memories.isEmpty) {
              return _buildEmptyState(
                isDark,
                'まだ思い出がありません',
                'お出かけ散歩で写真を撮りましょう',
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: WanMapSpacing.sm,
                  mainAxisSpacing: WanMapSpacing.sm,
                ),
                itemCount: memories.length > 6 ? 6 : memories.length,
                itemBuilder: (context, index) {
                  return RecentMemoryCard(
                    memory: memories[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WalkDetailScreen(
                            walkId: memories[index].walkId,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(WanMapSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildEmptyState(
            isDark,
            '読み込みエラー',
            '思い出の取得に失敗しました',
          ),
        ),
      ],
    );
  }

  /// 🗺️ エリアから探すセクション
  Widget _buildAreasSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final areasAsync = ref.watch(areasListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Text(
            'エリアから探す',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: WanMapSpacing.lg),
        areasAsync.when(
          data: (areas) {
            if (areas.isEmpty) {
              return _buildEmptyState(
                isDark,
                'エリアがありません',
                'まだエリアが登録されていません',
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
              child: Wrap(
                spacing: WanMapSpacing.sm,
                runSpacing: WanMapSpacing.sm,
                children: areas.map((area) {
                  return _AreaChip(
                    name: area.name,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AreaListScreen(),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(WanMapSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildEmptyState(
            isDark,
            '読み込みエラー',
            'エリアの取得に失敗しました',
          ),
        ),
      ],
    );
  }

  /// クイックアクション
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        children: [
          _ActionButton(
            icon: Icons.explore,
            label: 'ルートを探す',
            color: WanMapColors.accent,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AreaListScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 空状態
  Widget _buildEmptyState(bool isDark, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      padding: const EdgeInsets.all(WanMapSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.explore_off,
              size: 48,
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
            const SizedBox(height: WanMapSpacing.md),
            Text(
              title,
              style: WanMapTypography.bodyLarge.copyWith(
                color: isDark
                    ? WanMapColors.textPrimaryDark
                    : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: WanMapSpacing.xs),
            Text(
              subtitle,
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// エリアチップ
class _AreaChip extends StatelessWidget {
  final String name;
  final bool isDark;
  final VoidCallback onTap;

  const _AreaChip({
    required this.name,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WanMapSpacing.lg,
          vertical: WanMapSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: WanMapColors.accent.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_city,
              color: WanMapColors.accent,
              size: 20,
            ),
            const SizedBox(width: WanMapSpacing.sm),
            Text(
              name,
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark
                    ? WanMapColors.textPrimaryDark
                    : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// アクションボタン
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(WanMapSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: WanMapSpacing.sm),
            Text(
              label,
              style: WanMapTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
