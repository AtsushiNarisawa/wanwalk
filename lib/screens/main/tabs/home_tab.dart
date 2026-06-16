import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanwalk_colors.dart';
import '../../../config/wanwalk_icons.dart';
import '../../../config/area_taxonomy.dart';
import '../../../config/wanwalk_typography.dart';
import '../../../config/wanwalk_spacing.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/home_feed_provider.dart';
import '../../../providers/recent_pins_provider.dart';
import '../../../providers/area_provider.dart';
import '../../../services/analytics_service.dart';
import '../../../models/area.dart';
import '../../../models/official_route.dart';
import '../../outing/area_list_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../outing/route_list_screen.dart';
import '../../outing/hakone_sub_area_screen.dart';
import '../../outing/pin_detail_screen.dart';
import '../../../widgets/feed/walk_summary_card.dart';
import '../../../widgets/feed/route_feed_card.dart';
import '../../../widgets/feed/pin_snap_card.dart';
import '../../../widgets/feed/area_feature_card.dart';
import '../../../widgets/banners/hakone_tourism_banner.dart';
import '../../../widgets/notification_recovery_banner.dart';
import '../../../widgets/home/today_recommend_section.dart';
import '../../../utils/distance_formatter.dart';
import '../../../utils/notification_deep_link.dart';

/// HomeTab - 統合フィード画面
///
/// 構成:
/// 1. 散歩サマリー（ログイン時のみ・先頭固定）
/// 2. エリアから探す（横スクロール・箱根メイン）
/// 3. 「最新のルート」セクションタイトル
/// 4. 公式ルートカード（NEW/季節バッジ付き・ルートのみ）
/// 5. 「愛犬家のスナップ」横スクロールカルーセル（コミュニティピン・ルートと分離）
/// 6. 箱根観光バナー
/// 7. フッター
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: WanWalkColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: WanWalkColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('WanWalk', style: WanWalkTypography.wwH2.copyWith(height: 1.1)),
            const SizedBox(height: 2),
            Text(
              '次の休日、どこ歩く？',
              style: WanWalkTypography.wwLabel.copyWith(
                fontSize: 10,
                height: 1.0,
                color: WanWalkColors.textSecondary,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: WanWalkColors.textPrimary),
      ),
      body: Column(
        children: [
          const NotificationRecoveryBanner(),
          Expanded(child: _buildFeed(context, ref, isDark)),
        ],
      ),
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
              padding: const EdgeInsets.all(WanWalkSpacing.s8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    WanWalkIcons.mapTrifold,
                    size: 48,
                    color: WanWalkColors.accentPrimary,
                  ),
                  const SizedBox(height: WanWalkSpacing.s4),
                  Text(
                    'ルートを探索しよう',
                    style: WanWalkTypography.wwBody.copyWith(color: WanWalkColors.textSecondary),
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
        // 挿入: 今日のおすすめ(1) + エリアカード(1) + ピックアップ(1) + 最新ルートタイトル(1) = 4
        const insertedCount = 4;
        // フッター: 愛犬家のスナップ(1) + バナー(1) + Supported(1) = 3
        const footerCount = 3;
        final totalCount = items.length + insertedCount + footerCount;

        // 通知タップ deep link 由来の scroll セクション要求を消費。
        // 現状は home_tab がアクティブな限り最上位の TodayRecommendSection が
        // 既に視界に入っているため、明示スクロールはせずフラグだけ消費する。
        if (NotificationDeepLink.pendingHomeScrollSection ==
            HomeScrollSection.todayRecommend) {
          NotificationDeepLink.pendingHomeScrollSection = null;
        }

        return RefreshIndicator(
          color: WanWalkColors.accentPrimary,
          onRefresh: () async {
            ref.invalidate(homeFeedProvider);
            ref.invalidate(areasProvider);
            ref.invalidate(featuredRouteProvider);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: WanWalkSpacing.s2, bottom: WanWalkSpacing.s9),
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

              // 今日のおすすめ（朝散歩リマインド deep link 着地点）
              if (index == summaryCount) {
                return const TodayRecommendSection();
              }

              // エリアから探す
              if (index == summaryCount + 1) {
                return _buildAreaCards(context, ref, areasAsync, isDark);
              }

              // おすすめピックアップ
              if (index == summaryCount + 2) {
                return _buildFeaturedPickup(context, featuredAsync, isDark);
              }

              // 「最新のルート」セクションタイトル
              if (index == summaryCount + 3) {
                return const Padding(
                  padding: EdgeInsets.only(
                    left: WanWalkSpacing.s4,
                    right: WanWalkSpacing.s4,
                    top: WanWalkSpacing.s4,
                    bottom: WanWalkSpacing.s2,
                  ),
                  child: Text('最新のルート', style: WanWalkTypography.wwH3),
                );
              }

              // フッター: 愛犬家のスナップ（コミュニティピン・横スクロール）
              if (index == totalCount - 3) {
                return _buildPinSnaps(context, ref, isDark);
              }
              // フッター: バナー
              if (index == totalCount - 2) {
                return HakoneTourismBanner(isDark: isDark);
              }
              // フッター: Supported
              if (index == totalCount - 1) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: WanWalkSpacing.s6,
                    bottom: WanWalkSpacing.s6,
                  ),
                  child: Center(
                    child: Text(
                      'Supported by 箱根DMO',
                      style: WanWalkTypography.wwLabel.copyWith(
                        color: WanWalkColors.textTertiary,
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
                      // GA4: route_card_click (Web 同名・ホームフィード経由)
                      unawaited(ref.read(analyticsServiceProvider).logRouteCardClick(
                            routeSlug: item.route!.id,
                            areaSlug: item.route!.areaId,
                            sourcePage: AppSourcePage.home,
                          ));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RouteDetailScreen(routeId: item.route!.id),
                        ),
                      );
                    },
                  );

                // コミュニティピンはメインフィードに混在させず、末尾の
                // 「愛犬家のスナップ」カルーセル（_buildPinSnaps）に分離した。
                // homeFeedProvider は communityPin を emit しないため到達不能。
                case FeedItemType.communityPin:
                  return const SizedBox.shrink();

                case FeedItemType.areaFeature:
                  final subAreaNames = (item.extra?['subAreas'] as List?)?.cast<String>() ?? [];
                  return AreaFeatureCard(
                    areaName: item.extra?['areaName'] ?? '',
                    routeCount: item.extra?['routeCount'] ?? 0,
                    subAreas: subAreaNames,
                    isDark: isDark,
                    onTap: () {
                      // GA4: area_card_click (areaFeature カード経由)
                      // areaSlug 不明（areaName のみ保持）→ areaName を slug 代替で渡す
                      unawaited(ref.read(analyticsServiceProvider).logAreaCardClick(
                            areaSlug: (item.extra?['areaName'] ?? '').toString(),
                            sourcePage: AppSourcePage.home,
                          ));
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
      loading: () => const Center(
        child: CircularProgressIndicator(color: WanWalkColors.accentPrimary),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(WanWalkIcons.warning, size: 48, color: WanWalkColors.semanticError),
            const SizedBox(height: WanWalkSpacing.s3),
            Text(
              '読み込みに失敗しました',
              style: WanWalkTypography.wwBody.copyWith(color: WanWalkColors.textSecondary),
            ),
            const SizedBox(height: WanWalkSpacing.s3),
            ElevatedButton(
              onPressed: () => ref.invalidate(homeFeedProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: WanWalkColors.accentPrimary,
                foregroundColor: WanWalkColors.textInverse,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
                ),
              ),
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
            horizontal: WanWalkSpacing.s4,
            vertical: WanWalkSpacing.s2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('おすすめピックアップ', style: WanWalkTypography.wwH3),
              const SizedBox(height: WanWalkSpacing.s2),
              Consumer(builder: (context, ref, _) {
                return GestureDetector(
                onTap: () {
                  // GA4: route_card_click (おすすめピックアップ経由)
                  unawaited(ref.read(analyticsServiceProvider).logRouteCardClick(
                        routeSlug: route.id,
                        areaSlug: route.areaId,
                        sourcePage: AppSourcePage.home,
                      ));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RouteDetailScreen(routeId: route.id),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: WanWalkColors.bgPrimary,
                    borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
                    border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (route.thumbnailUrl != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            route.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: WanWalkColors.accentPrimarySoft,
                              alignment: Alignment.center,
                              child: Icon(
                                WanWalkIcons.path,
                                size: 40,
                                color: WanWalkColors.accentPrimary,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(WanWalkSpacing.s4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(route.name, style: WanWalkTypography.wwH4),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(WanWalkIcons.ruler, size: WanWalkIcons.sizeXs, color: WanWalkColors.accentPrimary),
                                const SizedBox(width: 4),
                                Text(
                                  formatDistance(route.distanceMeters.toInt()),
                                  style: WanWalkTypography.wwNumeric.copyWith(
                                    fontSize: 12,
                                    color: WanWalkColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(WanWalkIcons.clock, size: WanWalkIcons.sizeXs, color: WanWalkColors.accentPrimary),
                                const SizedBox(width: 4),
                                Text(
                                  '約${route.estimatedMinutes}分',
                                  style: WanWalkTypography.wwNumeric.copyWith(
                                    fontSize: 12,
                                    color: WanWalkColors.textSecondary,
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
              );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// 愛犬家のスナップ（コミュニティピン横スクロールカルーセル）
  ///
  /// 公式ルートとはジャンルが異なる UGC なので、メインフィードに混在させず
  /// ここで写真ファーストのカルーセルとして分離表示する。ピンが無ければ非表示。
  Widget _buildPinSnaps(BuildContext context, WidgetRef ref, bool isDark) {
    final pinsAsync = ref.watch(recentPinsProvider);
    return pinsAsync.maybeWhen(
      data: (pins) {
        if (pins.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(
                left: WanWalkSpacing.s4,
                right: WanWalkSpacing.s4,
                top: WanWalkSpacing.s6,
                bottom: WanWalkSpacing.s1,
              ),
              child: Text('愛犬家のスナップ', style: WanWalkTypography.wwH3),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: WanWalkSpacing.s4,
                right: WanWalkSpacing.s4,
                bottom: WanWalkSpacing.s2,
              ),
              child: Text(
                '散歩中に見つけたおすすめスポット',
                style: WanWalkTypography.wwBodySm.copyWith(
                  color: WanWalkColors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              // サムネ(正方形=cardWidth) + キャプション2行ぶんの余白
              height: PinSnapCard.cardWidth + 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.s4),
                itemCount: pins.length,
                separatorBuilder: (_, __) => const SizedBox(width: WanWalkSpacing.s3),
                itemBuilder: (context, i) {
                  final pin = pins[i];
                  return PinSnapCard(
                    pin: pin,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PinDetailScreen(pinId: pin.pinId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  /// エリアから探す（横スクロールカード）
  Widget _buildAreaCards(BuildContext context, WidgetRef ref, AsyncValue<List<Area>> areasAsync, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: WanWalkSpacing.s4,
            right: WanWalkSpacing.s4,
            top: WanWalkSpacing.s4,
            bottom: WanWalkSpacing.s2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('エリアから探す', style: WanWalkTypography.wwH3),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AreaListScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'すべて見る',
                      style: WanWalkTypography.wwBodySm.copyWith(
                        color: WanWalkColors.accentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      WanWalkIcons.caretRight,
                      size: WanWalkIcons.sizeXs,
                      color: WanWalkColors.accentPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        areasAsync.when(
          data: (areas) {
            // tier='region' のみをホーム chip に出す（created_at 新着順は撤廃）。
            final regions =
                areas.where((a) => a.tier == AreaTier.region).toList();
            // 箱根サブ(tier='sub'/group_key='hakone')は1つの"箱根"親チップに合成。
            final hakoneSubs = areas
                .where((a) =>
                    a.tier == AreaTier.sub &&
                    a.groupKey == AreaGroupKey.hakone)
                .toList();

            final chips = <_HomeAreaChipData>[];
            if (hakoneSubs.isNotEmpty) {
              chips.add(_HomeAreaChipData(
                name: '箱根',
                prefecture: '神奈川県',
                isHakone: true,
                hakoneSubs: hakoneSubs,
                sortIndex: homeRegionOrderIndex('hakone'),
                routeCount:
                    hakoneSubs.fold<int>(0, (s, a) => s + a.routeCount),
              ));
            }
            for (final a in regions) {
              chips.add(_HomeAreaChipData(
                name: a.name,
                prefecture: a.prefecture,
                area: a,
                sortIndex: homeRegionOrderIndex(a.slug),
                routeCount: a.routeCount,
              ));
            }
            // 固定 sort_order（需要×地理順）→ 同順位はルート数降順。
            chips.sort((x, y) {
              final c = x.sortIndex.compareTo(y.sortIndex);
              if (c != 0) return c;
              return y.routeCount.compareTo(x.routeCount);
            });

            // 「東京の身近な公園」ミニ枠の対象 spot（高需要のみ温存）。
            final bySlug = {for (final a in areas) a.slug: a};
            final tokyoParks = kHomeTokyoParkSlugs
                .map((s) => bySlug[s])
                .whereType<Area>()
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: WanWalkSpacing.s4),
                    itemCount: chips.length,
                    itemBuilder: (context, i) {
                      final chip = chips[i];
                      return Padding(
                        padding: EdgeInsets.only(
                            right: i < chips.length - 1 ? 10 : 0),
                        child: GestureDetector(
                          onTap: () {
                            // GA4: area_card_click（ホーム「エリアから探す」chip 経由）
                            final areaSlugForGa = chip.isHakone
                                ? 'hakone'
                                : (chip.area?.slug ??
                                    chip.area?.id ??
                                    chip.name);
                            unawaited(ref
                                .read(analyticsServiceProvider)
                                .logAreaCardClick(
                                  areaSlug: areaSlugForGa,
                                  sourcePage: AppSourcePage.home,
                                  tier: chip.area?.tier ?? AreaTier.region,
                                  placement: 'home_region',
                                ));
                            if (chip.isHakone) {
                              final subAreaMaps = chip.hakoneSubs!
                                  .map((a) => <String, dynamic>{
                                        'id': a.id,
                                        'name': a.name,
                                        'prefecture': a.prefecture,
                                        'description': a.description,
                                      })
                                  .toList();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HakoneSubAreaScreen(
                                      subAreas: subAreaMaps),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RouteListScreen(
                                    areaId: chip.area!.id,
                                    areaName: chip.area!.name,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: chip.isHakone ? 130 : 110,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: chip.isHakone
                                  ? WanWalkColors.accentPrimarySoft
                                  : WanWalkColors.bgSecondary,
                              borderRadius: BorderRadius.circular(
                                  WanWalkSpacing.radiusMd),
                              border: Border.all(
                                color: chip.isHakone
                                    ? WanWalkColors.accentPrimary
                                    : WanWalkColors.borderSubtle,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  chip.name,
                                  style: WanWalkTypography.wwH4.copyWith(
                                    fontSize: 14,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  chip.prefecture,
                                  style: WanWalkTypography.wwLabel.copyWith(
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (tokyoParks.isNotEmpty)
                  _buildTokyoParksMini(context, ref, tokyoParks),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 80,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: WanWalkColors.accentPrimary),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// 「東京の身近な公園」ミニ枠（決定3＝高需要 spot を控えめに温存）。
  Widget _buildTokyoParksMini(
      BuildContext context, WidgetRef ref, List<Area> parks) {
    return Padding(
      padding: const EdgeInsets.only(
        left: WanWalkSpacing.s4,
        right: WanWalkSpacing.s4,
        top: WanWalkSpacing.s4,
        bottom: WanWalkSpacing.s2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '東京の身近な公園',
            style: WanWalkTypography.wwLabel.copyWith(
              color: WanWalkColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: WanWalkSpacing.s2),
          Wrap(
            spacing: WanWalkSpacing.s2,
            runSpacing: WanWalkSpacing.s2,
            children: parks
                .map((a) => GestureDetector(
                      onTap: () {
                        // GA4: area_card_click（東京の身近な公園ミニ枠）
                        unawaited(ref
                            .read(analyticsServiceProvider)
                            .logAreaCardClick(
                              areaSlug: a.slug ?? a.id,
                              sourcePage: AppSourcePage.home,
                              tier: a.tier,
                              placement: 'home_tokyo_parks',
                            ));
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteListScreen(
                              areaId: a.id,
                              areaName: a.name,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: WanWalkColors.bgSecondary,
                          borderRadius:
                              BorderRadius.circular(WanWalkSpacing.radiusMd),
                          border: Border.all(
                            color: WanWalkColors.borderSubtle,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              WanWalkIcons.mapPin,
                              size: WanWalkIcons.sizeXs,
                              color: WanWalkColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              a.name,
                              style: WanWalkTypography.wwBodySm.copyWith(
                                color: WanWalkColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// ホーム画面のエリアチップ用データ
class _HomeAreaChipData {
  final String name;
  final String prefecture;
  final bool isHakone;
  final Area? area; // 非箱根のとき
  final List<Area>? hakoneSubs; // 箱根の時のサブエリア
  final int sortIndex; // kHomeRegionOrder 上の位置（小さいほど先頭）
  final int routeCount; // 同順位のタイブレーク用
  _HomeAreaChipData({
    required this.name,
    required this.prefecture,
    this.isHakone = false,
    this.area,
    this.hakoneSubs,
    this.sortIndex = 9999,
    this.routeCount = 0,
  });
}
