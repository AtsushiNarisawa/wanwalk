import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/wanwalk_colors.dart';
import '../../../config/wanwalk_typography.dart';
import '../../../config/wanwalk_spacing.dart';
import '../../../providers/area_provider.dart';
import '../../../providers/route_provider.dart';
import '../../../providers/official_routes_screen_provider.dart';
import '../../../providers/recent_pins_provider.dart';
import '../../../providers/pin_like_provider.dart';
import '../../../providers/pin_comment_provider.dart';
import '../../../providers/spot_review_provider.dart';
import '../../../providers/route_pin_provider.dart';
import '../../../providers/home_feed_provider.dart';
import '../../../models/recent_pin_post.dart';
import '../../outing/area_list_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../outing/pin_detail_screen.dart';
import '../../outing/hakone_sub_area_screen.dart';

import '../../routes/public_routes_screen.dart';
import '../../outing/route_list_screen.dart';
import '../../../models/area.dart';
import '../../../widgets/shimmer/wanwalk_shimmer.dart';
import '../../../widgets/feed/walk_summary_card.dart';
import '../../../widgets/feed/route_feed_card.dart';
import '../../../widgets/feed/pin_feed_card.dart';
import '../../../widgets/feed/area_feature_card.dart';
import '../../../utils/logger.dart';

/// HomeTab - 発見・閲覧のホーム画面
/// 
/// 構成:
/// 1. 今月の人気ルート
/// 2. 最新のピン投稿（横2枚）
/// 3. おすすめエリア（3枚 + 一覧を見るボタン）
/// 4. 高評価スポット（評価4以上）
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode) {
      appLog('🟡 HomeTab.build() called');
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kDebugMode) {
      appLog('🟡 About to watch areasProvider in HomeTab...');
    }
    final areasAsync = ref.watch(areasProvider);
    if (kDebugMode) {
      appLog('🟡 HomeTab areasAsync state: ${areasAsync.runtimeType}');
    }

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
          ],
        ),
        // フォロー機能削除: 通知ボタンを非表示
        actions: [],
      ),
      body: _buildFeed(context, ref, isDark),
    );
  }

  /// 統合フィード
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
            itemCount: items.length + 1, // +1 for footer
            itemBuilder: (context, index) {
              if (index == items.length) {
                // フッター
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
                      // エリア一覧画面へ遷移
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

  /// 最新の写真付きピン投稿（横2枚）
  Widget _buildRecentPinPosts(BuildContext context, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final recentPinsAsync = ref.watch(recentPinsProvider);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // セクションヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.push_pin_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: WanWalkSpacing.sm),
                  Text(
                    '最新のピン投稿',
                    style: WanWalkTypography.headlineSmall.copyWith(
                      color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
              child: Text(
                'みんなが見つけた素敵なスポット',
                style: WanWalkTypography.bodyMedium.copyWith(
                  color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
              child: Column(
                children: [
              recentPinsAsync.when(
                data: (pins) {
                  if (pins.isEmpty) {
                    return _buildEmptyCard(isDark, 'まだピン投稿がありません');
                  }
                  return Column(
                    children: pins.take(3).map((pin) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: WanWalkSpacing.md),
                        child: _RecentPinCard(
                          pin: pin,
                          isDark: isDark,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const ImageCardShimmer(
                  count: 2,
                  height: 180,
                ),
                  error: (error, _) {
                    if (kDebugMode) {
                      appLog('❌ 最新ピン投稿読み込みエラー: $error');
                    }
                    return _buildEmptyCard(isDark, 'ピン投稿の読み込みに失敗しました');
                  },
                ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// おすすめエリア（3枚 + 一覧を見るボタン）
  /// おすすめエリア（箱根大きく + 2枚 + 一覧ボタン）
  Widget _buildRecommendedAreas(BuildContext context, bool isDark, AsyncValue<dynamic> areasAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションヘッダー
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WanWalkColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.explore_rounded,
                  color: WanWalkColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: WanWalkSpacing.sm),
              Text(
                'おすすめエリア',
                style: WanWalkTypography.headlineSmall.copyWith(
                  color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WanWalkSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
          child: Text(
            '愛犬と行きたい人気のお出かけスポット',
            style: WanWalkTypography.bodyMedium.copyWith(
              color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(height: WanWalkSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
          child: Column(
            children: [
          areasAsync.when(
            data: (areas) {
              if (areas.isEmpty) {
                return _buildEmptyCard(isDark, 'エリアが登録されていません');
              }
              
              // 箱根エリアを優先表示（箱根・で始まるエリアを除外）
              final areaList = areas as List<Area>;
              final hakoneSubAreas = areaList.where((area) => area.name.startsWith('箱根・')).toList();
              final nonHakoneAreas = areaList.where((area) => !area.name.startsWith('箱根・')).toList();
              
              // 箱根親エリアを作成（サブエリアが複数ある場合）
              Area? hakoneArea;
              if (hakoneSubAreas.length > 1) {
                // 箱根グループエリアを作成（表示用ダミー）
                hakoneArea = Area(
                  id: 'hakone_group',
                  name: '箱根',
                  prefecture: '神奈川県',
                  description: '神奈川県の人気観光地。温泉、美術館、芦ノ湖など多彩なスポットがあり、愛犬と楽しめる散歩ルートが豊富です。',
                  centerLocation: hakoneSubAreas.first.centerLocation,
                  createdAt: DateTime.now(),
                );
              } else if (hakoneSubAreas.isNotEmpty) {
                hakoneArea = hakoneSubAreas.first;
              } else {
                hakoneArea = nonHakoneAreas.isNotEmpty ? nonHakoneAreas.first : null;
              }
              
              if (hakoneArea == null) {
                return _buildEmptyCard(isDark, 'エリアが登録されていません');
              }
              
              // 箱根以外のエリアから2件取得
              final otherAreas = nonHakoneAreas.take(2).toList();
              
              return Column(
                children: [
                  // 箱根カード（大きく目立つ）
                  Padding(
                    padding: const EdgeInsets.only(bottom: WanWalkSpacing.md),
                    child: _FeaturedAreaCard(
                      area: hakoneArea,
                      isDark: isDark,
                      onTap: () async {
                        // 箱根グループの場合はサブエリア選択画面へ
                        if (hakoneArea!.id == 'hakone_group') {
                          final supabase = Supabase.instance.client;
                          
                          // 各サブエリアのルート数を取得
                          final subAreasData = <Map<String, dynamic>>[];
                          for (final area in hakoneSubAreas) {
                            final routeCountResponse = await supabase
                                .from('official_routes')
                                .select('id')
                                .eq('area_id', area.id)
                                .count(CountOption.exact);
                            
                            final routeCount = routeCountResponse.count;
                            
                            subAreasData.add({
                              'id': area.id,
                              'name': area.name,
                              'prefecture': area.prefecture,
                              'description': area.description,
                              'route_count': routeCount,
                            });
                          }
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HakoneSubAreaScreen(
                                subAreas: subAreasData,
                              ),
                            ),
                          );
                        } else {
                          // 通常のエリアはルート一覧へ
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteListScreen(
                                areaId: hakoneArea!.id,
                                areaName: hakoneArea.name,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  // その他2エリア（横2列）
                  Row(
                    children: otherAreas.asMap().entries.map<Widget>((entry) {
                      final index = entry.key;
                      final area = entry.value;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == 0 ? WanWalkSpacing.sm / 2 : 0,
                            left: index == 1 ? WanWalkSpacing.sm / 2 : 0,
                          ),
                          child: _AreaCard(
                            name: area.name,
                            prefecture: area.prefecture,
                            isDark: isDark,
                            isHorizontal: false,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RouteListScreen(
                                  areaId: area.id,
                                  areaName: area.name,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: WanWalkSpacing.md),
                  // 一覧を見るボタン
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AreaListScreen()),
                    ),
                    icon: const Icon(Icons.list),
                    label: Text('一覧を見る（${areas.length}エリア）'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WanWalkColors.accent,
                      side: const BorderSide(color: WanWalkColors.accent),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: WanWalkSpacing.sm),
                ],
              );
            },
              loading: () => Column(
                children: const [
                  AreaCardShimmer(count: 1, isFeatured: true),
                  AreaCardShimmer(count: 2),
                ],
              ),
              error: (error, _) => _buildEmptyCard(isDark, 'エリアの読み込みに失敗しました'),
            ),
            ],
          ),
        ),
      ],
    );
  }


  /// 今月の人気ルート（3枚 + 一覧ボタン）
  Widget _buildPopularRoutes(BuildContext context, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final popularRoutesAsync = ref.watch(popularRoutesProvider);
        // 全ルート数を取得（フィルタなし）
        final totalRoutesCountAsync = ref.watch(totalOfficialRoutesCountProvider);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // セクションヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WanWalkColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.route_rounded,
                      color: WanWalkColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: WanWalkSpacing.sm),
                  Text(
                    '今月の人気ルート',
                    style: WanWalkTypography.headlineSmall.copyWith(
                      color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
              child: Text(
                'みんなが歩いているルート',
                style: WanWalkTypography.bodyMedium.copyWith(
                  color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
              child: Column(
                children: [
              popularRoutesAsync.when(
                data: (routes) {
                  if (routes.isEmpty) {
                    return _buildEmptyCard(isDark, '公式ルートがまだありません');
                  }
                  
                  // 最大3件表示
                  final displayRoutes = routes.take(3).toList();
                  
                  // 全ルート数を取得（ボタン表示用）
                  final totalRoutes = totalRoutesCountAsync.maybeWhen(
                    data: (count) => count,
                    orElse: () => routes.length,
                  );
                  
                  return Column(
                    children: [
                      // ルートカード（最大3枚）
                      ...displayRoutes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final route = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < displayRoutes.length - 1 ? WanWalkSpacing.md : 0,
                          ),
                          child: _PopularRouteCard(
                            routeId: route['route_id'],
                            title: route['route_name'] ?? '無題のルート',
                            description: route['description'] ?? '',
                            area: route['area_name'] ?? '',
                            prefecture: route['prefecture'] ?? '',
                            distance: (route['distance_meters'] as num?)?.toDouble() ?? 0.0,
                            duration: route['estimated_minutes'] as int? ?? 0,
                            totalWalks: route['monthly_walks'] as int? ?? 0,
                            thumbnailUrl: route['thumbnail_url'],
                            isDark: isDark,
                          ),
                        );
                      }),
                      
                      // 一覧を見るボタン
                      if (routes.length > 3 || totalRoutes > 3) ...[
                        const SizedBox(height: WanWalkSpacing.md),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (kDebugMode) {
                              appLog('📋 Navigate to public routes screen');
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PublicRoutesScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list),
                          label: Text('一覧を見る（${totalRoutes}ルート）'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WanWalkColors.accent,
                            side: const BorderSide(color: WanWalkColors.accent),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ],
                  );
                },
                  loading: () => const RouteCardShimmer(count: 3),
                  error: (error, _) {
                    if (kDebugMode) {
                      appLog('❌ 人気ルート読み込みエラー: $error');
                    }
                    return _buildEmptyCard(isDark, '人気ルートの読み込みに失敗しました');
                  },
                ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 高評価スポット（評価4以上）
  Widget _buildTopRatedSpots(BuildContext context, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final topRatedSpotsAsync = ref.watch(topRatedSpotIdsProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // セクションヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: WanWalkSpacing.sm),
                  Text(
                    '高評価スポット',
                    style: WanWalkTypography.headlineSmall.copyWith(
                      color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
              child: Text(
                '評価4以上の人気スポット',
                style: WanWalkTypography.bodyMedium.copyWith(
                  color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.md),

            // スポット一覧
            topRatedSpotsAsync.when(
              data: (spotIds) {
                if (spotIds.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
                    child: _buildEmptyCard(isDark, 'まだ高評価スポットがありません'),
                  );
                }

                // 最大3件まで表示
                final displaySpots = spotIds.take(3).toList();

                return Column(
                  children: displaySpots.map((spotId) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WanWalkSpacing.lg,
                        vertical: WanWalkSpacing.xs,
                      ),
                      child: _buildSpotCard(context, isDark, spotId, ref),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(WanWalkSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
                child: _buildEmptyCard(isDark, 'スポットの読み込みに失敗しました'),
              ),
            ),
          ],
        );
      },
    );
  }

  /// スポットカードを構築
  Widget _buildSpotCard(BuildContext context, bool isDark, String spotId, WidgetRef ref) {
    final pinAsync = ref.watch(pinByIdProvider(spotId));
    final averageRatingAsync = ref.watch(spotAverageRatingProvider(spotId));
    final reviewCountAsync = ref.watch(spotReviewCountProvider(spotId));

    return pinAsync.when(
      data: (pin) {
        if (pin == null) return const SizedBox.shrink();
        
        return GestureDetector(
          onTap: () {
            if (kDebugMode) {
              appLog('📍 Spot tapped: ${pin.title} (spotId: $spotId) → Navigate to PinDetailScreen');
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PinDetailScreen(pinId: spotId),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // サムネイル写真
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: pin.hasPhotos
                        ? Image.network(
                            pin.photoUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.amber.withOpacity(0.15),
                              child: const Center(
                                child: Icon(Icons.location_on_rounded, color: Colors.amber, size: 32),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.amber.withOpacity(0.15),
                            child: const Center(
                              child: Icon(Icons.location_on_rounded, color: Colors.amber, size: 32),
                            ),
                          ),
                  ),
                ),

                // スポット情報
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.title,
                          style: WanWalkTypography.titleMedium.copyWith(
                            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // 平均評価
                            averageRatingAsync.when(
                              data: (avg) {
                                if (avg == null) return const SizedBox.shrink();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                                      const SizedBox(width: 3),
                                      Text(
                                        avg.toStringAsFixed(1),
                                        style: WanWalkTypography.labelMedium.copyWith(
                                          color: Colors.amber.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => const SizedBox(width: 50),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 8),
                            // レビュー数
                            reviewCountAsync.when(
                              data: (count) {
                                return Text(
                                  '($count件)',
                                  style: WanWalkTypography.bodySmall.copyWith(
                                    color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 矢印アイコン
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(WanWalkSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// 箱根観光バナーセクション（提携コンテンツ）
  Widget _buildHakoneBannerSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションラベル
          Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                size: 16,
                color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                '箱根をもっと楽しむ',
                style: WanWalkTypography.bodySmall.copyWith(
                  color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: WanWalkSpacing.sm),
          // バナー本体
          GestureDetector(
            onTap: () async {
              final url = Uri.parse('https://map-hakone.staynavi.direct/');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/hakone_banner_new.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            WanWalkColors.primary,
                            WanWalkColors.primary.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map, color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              '箱根観光デジタルマップ',
                              style: WanWalkTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: WanWalkTypography.bodyMedium.copyWith(
            color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final String name;
  final String prefecture;
  final bool isDark;
  final bool isHorizontal;
  final VoidCallback onTap;

  const _AreaCard({
    required this.name,
    required this.prefecture,
    required this.isDark,
    this.isHorizontal = false,
    required this.onTap,
  });

  Color _getAccentColor(String name) {
    if (name.contains('横浜')) return Colors.blue;
    if (name.contains('鎌倉')) return Colors.teal;
    if (name.contains('江ノ島')) return Colors.cyan;
    if (name.contains('伊豆')) return Colors.orange;
    if (name.contains('熱海')) return Colors.red;
    return WanWalkColors.primary;
  }

  IconData _getAreaIcon(String name) {
    if (name.contains('湘南')) return Icons.waves_rounded;
    if (name.contains('鎌倉')) return Icons.temple_buddhist_rounded;
    if (name.contains('横浜')) return Icons.location_city_rounded;
    if (name.contains('江ノ島')) return Icons.beach_access_rounded;
    if (name.contains('伊豆')) return Icons.hot_tub_rounded;
    if (name.contains('熱海')) return Icons.spa_rounded;
    if (name.contains('葉山')) return Icons.park_rounded;
    return Icons.place_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor(name);
    final areaIcon = _getAreaIcon(name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アイコンバッジ
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                areaIcon,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            // エリア名
            Text(
              name,
              style: WanWalkTypography.titleMedium.copyWith(
                color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 県名
            Text(
              prefecture,
              style: WanWalkTypography.labelSmall.copyWith(
                color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPinCard extends ConsumerStatefulWidget {
  final RecentPinPost pin;
  final bool isDark;

  const _RecentPinCard({
    required this.pin,
    required this.isDark,
  });

  @override
  ConsumerState<_RecentPinCard> createState() => _RecentPinCardState();
}

class _RecentPinCardState extends ConsumerState<_RecentPinCard> {
  @override
  void initState() {
    super.initState();
    // いいね数・コメント数を初期化
    Future.microtask(() {
      ref.read(pinLikeActionsProvider).initializePinLikeState(
        widget.pin.pinId,
        widget.pin.likesCount,
      );
      ref.read(pinCommentActionsProvider).initializeCommentCount(
        widget.pin.pinId,
        widget.pin.commentsCount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final likeCount = ref.watch(pinLikeCountProvider(widget.pin.pinId));
    final commentCount = ref.watch(pinCommentCountProvider(widget.pin.pinId));

    return GestureDetector(
      onTap: () {
        if (kDebugMode) {
          appLog('📌 Pin tapped: ${widget.pin.title} (pinId: ${widget.pin.pinId}) → Navigate to PinDetailScreen');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PinDetailScreen(pinId: widget.pin.pinId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真（大きく表示）
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: widget.pin.photoUrl.isNotEmpty
                    ? Image.network(
                        widget.pin.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultImage(),
                      )
                    : _buildDefaultImage(),
              ),
            ),
            // テキスト情報
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    widget.pin.title,
                    style: WanWalkTypography.titleMedium.copyWith(
                      color: widget.isDark
                          ? WanWalkColors.textPrimaryDark
                          : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // エリア名 + ユーザー名
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.pin.areaName ?? '不明',
                        style: WanWalkTypography.bodySmall.copyWith(
                          color: widget.isDark
                              ? WanWalkColors.textSecondaryDark
                              : WanWalkColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.person,
                        size: 14,
                        color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          widget.pin.userName,
                          style: WanWalkTypography.bodySmall.copyWith(
                            color: widget.isDark
                                ? WanWalkColors.textSecondaryDark
                                : WanWalkColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // いいね数・コメント数
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: Colors.red.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likeCount',
                        style: WanWalkTypography.bodySmall.copyWith(
                          color: widget.isDark
                              ? WanWalkColors.textSecondaryDark
                              : WanWalkColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$commentCount',
                        style: WanWalkTypography.bodySmall.copyWith(
                          color: widget.isDark
                              ? WanWalkColors.textSecondaryDark
                              : WanWalkColors.textSecondaryLight,
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
  }

  Widget _buildDefaultImage() {
    return Container(
      color: widget.isDark ? Colors.grey[800] : Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: widget.isDark ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
    );
  }

}

/// 人気ルートカード
class _PopularRouteCard extends StatelessWidget {
  final String routeId;
  final String title;
  final String description;
  final String area;
  final String prefecture;
  final double distance;
  final int duration;
  final int totalWalks;
  final String? thumbnailUrl;
  final bool isDark;

  const _PopularRouteCard({
    required this.routeId,
    required this.title,
    required this.description,
    required this.area,
    required this.prefecture,
    required this.distance,
    required this.duration,
    required this.totalWalks,
    this.thumbnailUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (kDebugMode) {
          appLog('🗺️ Route tapped: $title (routeId: $routeId) → Navigate to RouteDetailScreen');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailScreen(routeId: routeId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル画像（大きく表示）
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WanWalkColors.accent.withOpacity(0.8),
                      WanWalkColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                    ? Image.network(
                        thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.route,
                            size: 48,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.route,
                          size: 48,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
              ),
            ),
            // ルート情報
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    title,
                    style: WanWalkTypography.titleMedium.copyWith(
                      color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // エリア・県
                  Text(
                    '$area・$prefecture',
                    style: WanWalkTypography.bodySmall.copyWith(
                      color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // 距離・所要時間・今月の散歩数（チップ風）
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.straighten,
                        label: '${(distance / 1000).toStringAsFixed(1)}km',
                        color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.schedule,
                        label: '${duration}分',
                        color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.pets,
                        label: '$totalWalks回',
                        color: WanWalkColors.accent,
                        isBold: true,
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
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: WanWalkTypography.labelSmall.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 特集エリアカード（箱根専用・大きく表示）
class _FeaturedAreaCard extends StatelessWidget {
  final dynamic area;
  final bool isDark;
  final VoidCallback onTap;

  const _FeaturedAreaCard({
    required this.area,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: WanWalkColors.accent.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: WanWalkColors.accent.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 上部: アクセントバー
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: WanWalkColors.accent.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: WanWalkColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '注目エリア',
                      style: WanWalkTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    area.prefecture,
                    style: WanWalkTypography.bodySmall.copyWith(
                      color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // 下部: メインコンテンツ
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          area.name,
                          style: WanWalkTypography.headlineMedium.copyWith(
                            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '温泉・芦ノ湖・美術館など\n愛犬と楽しめるルートが豊富',
                          style: WanWalkTypography.bodySmall.copyWith(
                            color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: WanWalkColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: WanWalkColors.accent,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
