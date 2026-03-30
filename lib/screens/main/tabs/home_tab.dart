import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanwalk_colors.dart';
import '../../../config/wanwalk_typography.dart';
import '../../../config/wanwalk_spacing.dart';
import '../../../providers/home_feed_provider.dart';
import '../../../providers/area_provider.dart';
import '../../../models/area.dart';
import '../../../models/official_route.dart';
import '../../outing/area_list_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../outing/route_list_screen.dart';
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
/// 2. エリアから探す（横スクロール・箱根メイン）
/// 3. 「最新のルート」セクションタイトル
/// 4. 公式ルートカード（NEW/季節バッジ付き）
/// 5. コミュニティピンカード
/// 6. エリア特集カード
/// 7. 箱根観光バナー
/// 8. フッター
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'WanWalk',
                  style: WanWalkTypography.headlineMedium.copyWith(
                    color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '次の休日、どこ歩く？',
                  style: WanWalkTypography.caption.copyWith(
                    color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                    fontSize: 10,
                    height: 1.0,
                  ),
                ),
              ],
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
    final areasAsync = ref.watch(areasProvider);

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

        final featuredAsync = ref.watch(featuredRouteProvider);

        // 散歩サマリーがあるかどうかでオフセットを計算
        final hasSummary = items.isNotEmpty && items.first.type == FeedItemType.walkSummary;
        final summaryCount = hasSummary ? 1 : 0;
        // 挿入: エリアカード(1) + ピックアップ(1) + 最新ルートタイトル(1) = 3
        const insertedCount = 3;
        // フッター: バナー(1) + Supported(1) = 2
        const footerCount = 2;
        final totalCount = items.length + insertedCount + footerCount;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeFeedProvider);
            ref.invalidate(areasProvider);
            ref.invalidate(featuredRouteProvider);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: WanWalkSpacing.sm, bottom: WanWalkSpacing.xxxl),
            itemCount: totalCount,
            itemBuilder: (context, index) {
              // 散歩サマリー（先頭）
              if (hasSummary && index == 0) {
                final item = items[0];
                return WalkSummaryCard(
                  walkCount: item.extra?['walkCount'] ?? 0,
                  totalDistanceKm: item.extra?['totalDistanceKm'] ?? '0',
                  totalMinutes: item.extra?['totalMinutes'] ?? 0,
                  isDark: isDark,
                );
              }

              // エリアから探す
              if (index == summaryCount) {
                return _buildAreaCards(context, ref, areasAsync, isDark);
              }

              // おすすめピックアップ
              if (index == summaryCount + 1) {
                return _buildFeaturedPickup(context, featuredAsync, isDark);
              }

              // 「最新のルート」セクションタイトル
              if (index == summaryCount + 2) {
                return Padding(
                  padding: const EdgeInsets.only(
                    left: WanWalkSpacing.lg,
                    right: WanWalkSpacing.lg,
                    top: WanWalkSpacing.md,
                    bottom: WanWalkSpacing.sm,
                  ),
                  child: Text(
                    '最新のルート',
                    style: WanWalkTypography.headlineSmall.copyWith(
                      color: isDark
                          ? WanWalkColors.textPrimaryDark
                          : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              // フッター: バナー
              if (index == totalCount - 2) {
                return HakoneTourismBanner(isDark: isDark);
              }
              // フッター: Supported
              if (index == totalCount - 1) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: WanWalkSpacing.xl,
                    bottom: WanWalkSpacing.xl,
                  ),
                  child: Center(
                    child: Text(
                      'Supported by 箱根DMO',
                      style: WanWalkTypography.caption.copyWith(
                        color: isDark
                            ? WanWalkColors.textTertiaryDark
                            : WanWalkColors.textTertiaryLight,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }

              // フィードアイテム
              final feedIndex = index - insertedCount;
              if (feedIndex < 0 || feedIndex >= items.length) {
                return const SizedBox.shrink();
              }
              if (hasSummary && feedIndex == 0) {
                return const SizedBox.shrink();
              }
              final item = items[feedIndex];
              switch (item.type) {
                case FeedItemType.walkSummary:
                case FeedItemType.featuredRoute:
                  return const SizedBox.shrink();

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

  /// おすすめピックアップ
  Widget _buildFeaturedPickup(BuildContext context, AsyncValue<OfficialRoute?> featuredAsync, bool isDark) {
    return featuredAsync.when(
      data: (route) {
        if (route == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WanWalkSpacing.lg,
            vertical: WanWalkSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'おすすめピックアップ',
                style: WanWalkTypography.headlineSmall.copyWith(
                  color: isDark
                      ? WanWalkColors.textPrimaryDark
                      : WanWalkColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: WanWalkSpacing.sm),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RouteDetailScreen(routeId: route.id),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: WanWalkColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // サムネイル
                      if (route.thumbnailUrl != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            route.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: isDark ? WanWalkColors.cardDark : const Color(0xFFF0EDE8),
                              child: const Center(child: Icon(Icons.landscape, size: 48, color: Colors.grey)),
                            ),
                          ),
                        ),
                      // 情報
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        color: isDark ? WanWalkColors.cardDark : Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.name,
                              style: WanWalkTypography.bodyLarge.copyWith(
                                color: isDark
                                    ? WanWalkColors.textPrimaryDark
                                    : WanWalkColors.textPrimaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.straighten, size: 14, color: WanWalkColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  '${(route.distanceMeters / 1000).toStringAsFixed(1)}km',
                                  style: WanWalkTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? WanWalkColors.textSecondaryDark
                                        : WanWalkColors.textSecondaryLight,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.schedule, size: 14, color: WanWalkColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  '約${route.estimatedMinutes}分',
                                  style: WanWalkTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? WanWalkColors.textSecondaryDark
                                        : WanWalkColors.textSecondaryLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// エリアから探す（横スクロールカード）
  Widget _buildAreaCards(BuildContext context, WidgetRef ref, AsyncValue<List<Area>> areasAsync, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: WanWalkSpacing.lg,
            right: WanWalkSpacing.lg,
            top: WanWalkSpacing.md,
            bottom: WanWalkSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'エリアから探す',
                style: WanWalkTypography.headlineSmall.copyWith(
                  color: isDark
                      ? WanWalkColors.textPrimaryDark
                      : WanWalkColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AreaListScreen(),
                    ),
                  );
                },
                child: Text(
                  'すべて見る',
                  style: WanWalkTypography.bodySmall.copyWith(
                    color: WanWalkColors.accent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: areasAsync.when(
            data: (areas) {
              // 箱根エリアを先頭、それ以外はルート数順
              final hakoneAreas = areas.where((a) => a.name.startsWith('箱根')).toList();
              final otherAreas = areas.where((a) => !a.name.startsWith('箱根')).toList();
              final sorted = [...hakoneAreas, ...otherAreas];

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
                itemCount: sorted.length,
                itemBuilder: (context, i) {
                  final area = sorted[i];
                  final isHakone = area.name.startsWith('箱根');
                  return Padding(
                    padding: EdgeInsets.only(right: i < sorted.length - 1 ? 10 : 0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteListScreen(
                              areaId: area.id,
                              areaName: area.name,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: isHakone ? 130 : 110,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isHakone
                              ? WanWalkColors.accent.withValues(alpha: 0.08)
                              : (isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isHakone
                                ? WanWalkColors.accent.withValues(alpha: 0.2)
                                : (isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              area.name,
                              style: WanWalkTypography.bodySmall.copyWith(
                                color: isDark
                                    ? WanWalkColors.textPrimaryDark
                                    : WanWalkColors.textPrimaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              area.prefecture,
                              style: WanWalkTypography.caption.copyWith(
                                color: isDark
                                    ? WanWalkColors.textSecondaryDark
                                    : WanWalkColors.textSecondaryLight,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
