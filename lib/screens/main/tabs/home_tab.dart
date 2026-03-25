import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanwalk_colors.dart';
import '../../../config/wanwalk_typography.dart';
import '../../../config/wanwalk_spacing.dart';
import '../../../providers/home_feed_provider.dart';
import '../../outing/area_list_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../outing/pin_detail_screen.dart';
import '../../../widgets/feed/walk_summary_card.dart';
import '../../../widgets/feed/route_feed_card.dart';
import '../../../widgets/feed/pin_feed_card.dart';
import '../../../widgets/feed/area_feature_card.dart';
import '../../../widgets/banners/hakone_tourism_banner.dart';

/// HomeTab - 統合フィード画面
///
/// 構成:
/// 1. 散歩サマリー（ログイン時のみ・先頭固定）
/// 2. 公式ルートカード（NEW/季節バッジ付き）
/// 3. コミュニティピンカード
/// 4. エリア特集カード
/// 5. 箱根観光バナー
/// 6. フッター
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? WanWalkColors.backgroundDark
          : WanWalkColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.pets, color: WanWalkColors.accent, size: 28),
            const SizedBox(width: WanWalkSpacing.sm),
            Text(
              'WanWalk',
              style: WanWalkTypography.headlineMedium.copyWith(
                color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ],
        ),
        actions: const [],
      ),
      body: _buildFeed(context, ref, isDark),
    );
  }

  Widget _buildFeed(BuildContext context, WidgetRef ref, bool isDark) {
    final feedAsync = ref.watch(homeFeedProvider);

    return feedAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(WanWalkSpacing.xxxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore, size: 64, color: WanWalkColors.accent.withValues(alpha: 0.5)),
                  const SizedBox(height: WanWalkSpacing.md),
                  Text(
                    'ルートを探索しよう',
                    style: WanWalkTypography.bodyLarge.copyWith(
                      color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeFeedProvider);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: WanWalkSpacing.sm, bottom: WanWalkSpacing.xxxl),
            itemCount: items.length + 3, // +1 for explore areas, +1 for banner, +1 for footer
            itemBuilder: (context, index) {
              if (index == items.length) {
                // エリアから探すセクション
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WanWalkSpacing.lg,
                    vertical: WanWalkSpacing.sm,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AreaListScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(WanWalkSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: WanWalkColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.explore, color: WanWalkColors.accent, size: 22),
                          ),
                          const SizedBox(width: WanWalkSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'エリアから探す',
                                  style: WanWalkTypography.bodyMedium.copyWith(
                                    color: isDark
                                        ? WanWalkColors.textPrimaryDark
                                        : WanWalkColors.textPrimaryLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '箱根・鎌倉・横浜など全エリアのルート一覧',
                                  style: WanWalkTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? WanWalkColors.textSecondaryDark
                                        : WanWalkColors.textSecondaryLight,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: WanWalkColors.accent,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (index == items.length + 1) {
                return HakoneTourismBanner(isDark: isDark);
              }
              if (index == items.length + 2) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: WanWalkSpacing.lg),
                  child: Center(
                    child: Text(
                      'Supported by 箱根DMO',
                      style: WanWalkTypography.caption.copyWith(
                        color: isDark ? WanWalkColors.textTertiaryDark : WanWalkColors.textTertiaryLight,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }

              final item = items[index];
              switch (item.type) {
                case FeedItemType.walkSummary:
                  return WalkSummaryCard(
                    walkCount: item.extra?['walkCount'] ?? 0,
                    totalDistanceKm: item.extra?['totalDistanceKm'] ?? '0',
                    totalMinutes: item.extra?['totalMinutes'] ?? 0,
                    isDark: isDark,
                  );

                case FeedItemType.officialRoute:
                case FeedItemType.seasonalRoute:
                  if (item.route == null) return const SizedBox.shrink();
                  return RouteFeedCard(
                    route: item.route!,
                    isDark: isDark,
                    isNew: item.extra?['isNew'] == true,
                    isSeasonal: item.type == FeedItemType.seasonalRoute,
                    seasonLabel: item.extra?['season'] != null
                        ? '${item.extra!['season']}のおすすめ'
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RouteDetailScreen(routeId: item.route!.id),
                        ),
                      );
                    },
                  );

                case FeedItemType.communityPin:
                  if (item.pin == null) return const SizedBox.shrink();
                  return PinFeedCard(
                    pin: item.pin!,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PinDetailScreen(pinId: item.pin!.pinId),
                        ),
                      );
                    },
                    onRouteTap: item.pin!.routeId != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RouteDetailScreen(routeId: item.pin!.routeId!),
                              ),
                            );
                          }
                        : null,
                  );

                case FeedItemType.areaFeature:
                  final subAreaNames = (item.extra?['subAreas'] as List?)?.cast<String>() ?? [];
                  return AreaFeatureCard(
                    areaName: item.extra?['areaName'] ?? '',
                    routeCount: item.extra?['routeCount'] ?? 0,
                    subAreas: subAreaNames,
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
              }
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48,
                color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight),
            const SizedBox(height: WanWalkSpacing.md),
            Text(
              '読み込みに失敗しました',
              style: WanWalkTypography.bodyMedium.copyWith(
                color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.md),
            ElevatedButton(
              onPressed: () => ref.invalidate(homeFeedProvider),
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}
