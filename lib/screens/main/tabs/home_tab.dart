import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanwalk_colors.dart';
import '../../../config/wanwalk_icons.dart';
import '../../../config/wanwalk_typography.dart';
import '../../../config/wanwalk_spacing.dart';
import '../../../providers/home_feed_provider.dart';
import '../../../providers/area_provider.dart';
import '../../../models/area.dart';
import '../../../models/official_route.dart';
import '../../outing/area_list_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../outing/route_list_screen.dart';
import '../../outing/hakone_sub_area_screen.dart';
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
        // 挿入: エリアカード(1) + ピックアップ(1) + 最新ルートタイトル(1) = 3
        const insertedCount = 3;
        // フッター: バナー(1) + Supported(1) = 2
        const footerCount = 2;
        final totalCount = items.length + insertedCount + footerCount;

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
                                  '${(route.distanceMeters / 1000).toStringAsFixed(1)}km',
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
        SizedBox(
          height: 80,
          child: areasAsync.when(
            data: (areas) {
              // 箱根サブエリア(箱根・XX)を1つの"箱根"親チップに統合
              final hakoneSubs = areas.where((a) => a.name.startsWith('箱根・')).toList();
              final otherAreas = areas.where((a) => !a.name.startsWith('箱根')).toList();

              final chips = <_HomeAreaChipData>[];
              if (hakoneSubs.isNotEmpty) {
                chips.add(_HomeAreaChipData(
                  name: '箱根',
                  prefecture: '神奈川県',
                  isHakone: true,
                  hakoneSubs: hakoneSubs,
                ));
              }
              for (final a in otherAreas) {
                chips.add(_HomeAreaChipData(
                  name: a.name,
                  prefecture: a.prefecture,
                  area: a,
                ));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.s4),
                itemCount: chips.length,
                itemBuilder: (context, i) {
                  final chip = chips[i];
                  return Padding(
                    padding: EdgeInsets.only(right: i < chips.length - 1 ? 10 : 0),
                    child: GestureDetector(
                      onTap: () {
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
                              builder: (context) => HakoneSubAreaScreen(subAreas: subAreaMaps),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: chip.isHakone
                              ? WanWalkColors.accentPrimarySoft
                              : WanWalkColors.bgSecondary,
                          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
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
              );
            },
            loading: () => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: WanWalkColors.accentPrimary),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
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
  _HomeAreaChipData({
    required this.name,
    required this.prefecture,
    this.isHakone = false,
    this.area,
    this.hakoneSubs,
  });
}
