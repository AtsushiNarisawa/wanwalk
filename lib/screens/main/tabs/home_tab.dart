import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../providers/area_provider.dart';
import '../../../providers/route_provider.dart';
import '../../../providers/official_route_provider.dart';
import '../../../providers/official_routes_screen_provider.dart';
import '../../../providers/recent_pins_provider.dart';
import '../../../providers/pin_like_provider.dart';
import '../../../providers/pin_bookmark_provider.dart';
import '../../../providers/pin_comment_provider.dart';
import '../../../providers/spot_review_provider.dart';
import '../../../providers/route_pin_provider.dart';
import '../../../models/recent_pin_post.dart';
import '../../outing/area_list_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../outing/pin_detail_screen.dart';
import '../../outing/pin_comment_screen.dart';
import '../../outing/hakone_sub_area_screen.dart';

import '../../routes/public_routes_screen.dart';
import '../../outing/route_list_screen.dart';
import '../../../models/area.dart';
import '../../../widgets/shimmer/wanmap_shimmer.dart';

/// HomeTab - 発見・閲覧のホーム画面
/// 
/// 構成:
/// 1. おすすめエリア（3枚 + 一覧を見るボタン）
/// 2. 今月の人気ルート
/// 3. 最新のピン投稿（横2枚）
/// 4. 高評価スポット（評価4以上）
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode) {
      print('🟡 HomeTab.build() called');
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kDebugMode) {
      print('🟡 About to watch areasProvider in HomeTab...');
    }
    final areasAsync = ref.watch(areasProvider);
    if (kDebugMode) {
      print('🟡 HomeTab areasAsync state: ${areasAsync.runtimeType}');
    }

    return Scaffold(
      backgroundColor: isDark 
          ? WanMapColors.backgroundDark 
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.pets, color: WanMapColors.accent, size: 28),
            const SizedBox(width: WanMapSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'WanMap',
                  style: WanMapTypography.headlineMedium.copyWith(
                    color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: WanMapSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Text(
                    'by DogHub 箱根',
                    style: WanMapTypography.caption.copyWith(
                      color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        // フォロー機能削除: 通知ボタンを非表示
        actions: [],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 最新のピン投稿（横2枚）
            _buildRecentPinPosts(context, isDark),
            
            const SizedBox(height: WanMapSpacing.xl),
            
            // 2. 今月の人気ルート
            _buildPopularRoutes(context, isDark),
            
            const SizedBox(height: WanMapSpacing.xl),
            
            // 3. おすすめエリア（3枚 + 一覧ボタン）
            _buildRecommendedAreas(context, isDark, areasAsync),
            
            const SizedBox(height: WanMapSpacing.xl),
            
            // 4. 高評価スポット
            _buildTopRatedSpots(context, isDark),
            
            const SizedBox(height: WanMapSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  /// MAP表示（今月の人気ルート1位を表示）
  Widget _buildMapPreview(BuildContext context, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final popularRoutesAsync = ref.watch(popularRoutesProvider);
        
        // デフォルト中心位置（横浜）
        LatLng center = const LatLng(35.4437, 139.638);
        String? topRouteId;
        
        return popularRoutesAsync.when(
          data: (routes) {
            // 今月の人気ルート1位のIDを取得
            if (routes.isNotEmpty) {
              topRouteId = routes.first['route_id'] as String?;
            }
            
            // ルートIDがある場合、詳細データを取得
            if (topRouteId != null) {
              final routeAsync = ref.watch(routeByIdProvider(topRouteId!));
              
              return routeAsync.when(
                data: (route) {
                  if (route != null) {
                    center = route.startLocation;
                  }
                  
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(WanMapSpacing.md),
                    child: Column(
                      children: [
                        // ヘッダー: 人気No.1ルート
                        GestureDetector(
                          onTap: route != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RouteDetailScreen(routeId: route.id),
                                    ),
                                  );
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: WanMapSpacing.md,
                              vertical: WanMapSpacing.sm,
                            ),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  WanMapColors.primary,
                                  WanMapColors.primaryDark,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🏆',
                                  style: TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: WanMapSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '人気No.1ルート',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      if (route != null)
                                        Text(
                                          route.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 地図
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: center,
                              initialZoom: 13.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                              // 人気ルート1位のマーカーを表示
                              if (route != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: route.startLocation,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => ClipRRect(
                  borderRadius: BorderRadius.circular(WanMapSpacing.md),
                  child: Container(
                    height: 260,
                    color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(WanMapSpacing.md),
                  child: Container(
                    height: 260,
                    color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                    child: const Center(child: Text('マップを読み込めませんでした')),
                  ),
                ),
              );
            }
            
            // ルートIDがない場合はデフォルト地図を表示
            return SizedBox(
              height: 280,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                ],
              ),
            );
          },
          loading: () => ClipRRect(
            borderRadius: BorderRadius.circular(WanMapSpacing.md),
            child: Container(
              height: 260,
              color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(WanMapSpacing.md),
            child: Container(
              height: 260,
              color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
              child: const Center(child: Text('マップを読み込めませんでした')),
            ),
          ),
        );
      },
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
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
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
                  const SizedBox(width: WanMapSpacing.sm),
                  Text(
                    '最新のピン投稿',
                    style: WanMapTypography.headlineMedium.copyWith(
                      color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WanMapSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
              child: Text(
                'みんなが見つけた素敵なスポット',
                style: WanMapTypography.bodyMedium.copyWith(
                  color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: WanMapSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
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
                        padding: const EdgeInsets.only(bottom: WanMapSpacing.md),
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
                      print('❌ 最新ピン投稿読み込みエラー: $error');
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
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WanMapColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.explore_rounded,
                  color: WanMapColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: WanMapSpacing.sm),
              Text(
                'おすすめエリア',
                style: WanMapTypography.headlineMedium.copyWith(
                  color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WanMapSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Text(
            '愛犬と行きたい人気のお出かけスポット',
            style: WanMapTypography.bodyMedium.copyWith(
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(height: WanMapSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
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
                    padding: const EdgeInsets.only(bottom: WanMapSpacing.md),
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
                            
                            final routeCount = routeCountResponse.count ?? 0;
                            
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
                            right: index == 0 ? WanMapSpacing.sm / 2 : 0,
                            left: index == 1 ? WanMapSpacing.sm / 2 : 0,
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
                  const SizedBox(height: WanMapSpacing.md),
                  // 一覧を見るボタン
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AreaListScreen()),
                    ),
                    icon: const Icon(Icons.list),
                    label: Text('一覧を見る（${areas.length}エリア）'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WanMapColors.accent,
                      side: const BorderSide(color: WanMapColors.accent),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: WanMapSpacing.lg),
                  // バナー
                  _buildPromotionalBanner(context, isDark),
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
        // 全ルート数を取得
        final allRoutesAsync = ref.watch(officialRoutesProvider);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // セクションヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WanMapColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.route_rounded,
                      color: WanMapColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: WanMapSpacing.sm),
                  Text(
                    '今月の人気ルート',
                    style: WanMapTypography.headlineMedium.copyWith(
                      color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WanMapSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
              child: Text(
                'みんなが歩いているルート',
                style: WanMapTypography.bodyMedium.copyWith(
                  color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: WanMapSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
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
                  final totalRoutes = allRoutesAsync.maybeWhen(
                    data: (allRoutes) => allRoutes.length,
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
                            bottom: index < displayRoutes.length - 1 ? WanMapSpacing.md : 0,
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
                        const SizedBox(height: WanMapSpacing.md),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (kDebugMode) {
                              print('📋 Navigate to public routes screen');
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
                            foregroundColor: WanMapColors.accent,
                            side: const BorderSide(color: WanMapColors.accent),
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
                      print('❌ 人気ルート読み込みエラー: $error');
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
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
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
                  const SizedBox(width: WanMapSpacing.sm),
                  Text(
                    '高評価スポット',
                    style: WanMapTypography.headlineMedium.copyWith(
                      color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WanMapSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
              child: Text(
                '評価4以上の人気スポット',
                style: WanMapTypography.bodyMedium.copyWith(
                  color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: WanMapSpacing.md),

            // スポット一覧
            topRatedSpotsAsync.when(
              data: (spotIds) {
                if (spotIds.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
                    child: _buildEmptyCard(isDark, 'まだ高評価スポットがありません'),
                  );
                }

                // 最大3件まで表示
                final displaySpots = spotIds.take(3).toList();

                return Column(
                  children: displaySpots.map((spotId) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WanMapSpacing.lg,
                        vertical: WanMapSpacing.xs,
                      ),
                      child: _buildSpotCard(context, isDark, spotId, ref),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(WanMapSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
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
              print('📍 Spot tapped: ${pin.title} (spotId: $spotId) → Navigate to PinDetailScreen');
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PinDetailScreen(pinId: spotId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(WanMapSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // アイコン
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.amber,
                    size: 28,
                  ),
                ),
                const SizedBox(width: WanMapSpacing.md),

                // スポット情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.title,
                        style: WanMapTypography.titleMedium.copyWith(
                          color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // 平均評価
                          averageRatingAsync.when(
                            data: (avg) {
                              if (avg == null) return const SizedBox.shrink();
                              return Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    avg.toStringAsFixed(1),
                                    style: WanMapTypography.bodySmall.copyWith(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const SizedBox(width: 50),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          const SizedBox(width: WanMapSpacing.sm),
                          // レビュー数
                          reviewCountAsync.when(
                            data: (count) {
                              return Text(
                                '($count件)',
                                style: WanMapTypography.bodySmall.copyWith(
                                  color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
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

                // 矢印アイコン
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(WanMapSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// プロモーションバナー
  Widget _buildPromotionalBanner(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse('https://map-hakone.staynavi.direct/');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/hakone_banner_new.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // フォールバック: グラデーション背景
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WanMapColors.primary,
                      WanMapColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '箱根観光デジタルマップ',
                        style: WanMapTypography.titleMedium.copyWith(
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
    );
  }

  Widget _buildEmptyCard(bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: WanMapTypography.bodyMedium.copyWith(
            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
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

  Color _getGradientColor(String name) {
    // エリア名に基づいて色を変える
    if (name.contains('横浜')) return Colors.blue;
    if (name.contains('鎌倉')) return Colors.teal;
    if (name.contains('江ノ島')) return Colors.cyan;
    if (name.contains('伊豆')) return Colors.orange;
    if (name.contains('熱海')) return Colors.red;
    return WanMapColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getGradientColor(name);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isHorizontal ? double.infinity : 160,
        height: isHorizontal ? null : 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // グラデーション背景
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      baseColor,
                      baseColor.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // 装飾アイコン
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  Icons.location_city,
                  size: 60,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              // コンテンツ
              Padding(
                padding: const EdgeInsets.all(WanMapSpacing.md),
                child: isHorizontal
                    ? Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: WanMapSpacing.md),
                          Expanded(
                            child: Text(
                              name,
                              style: WanMapTypography.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: WanMapSpacing.sm),
                          Text(
                            name,
                            style: WanMapTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
              ),
            ],
          ),
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
        // ピン投稿の詳細画面へ遷移
        if (kDebugMode) {
          print('📌 Pin tapped: ${widget.pin.title} (pinId: ${widget.pin.pinId}) → Navigate to PinDetailScreen');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PinDetailScreen(pinId: widget.pin.pinId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(WanMapSpacing.md),
        decoration: BoxDecoration(
          color: widget.isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // サムネイル画像（固定サイズ120x120）
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 120,
                height: 120,
                child: widget.pin.photoUrl.isNotEmpty
                    ? Image.network(
                        widget.pin.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultImage(),
                      )
                    : _buildDefaultImage(),
              ),
            ),
            const SizedBox(width: WanMapSpacing.md),
            // テキスト情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    widget.pin.title,
                    style: WanMapTypography.bodyMedium.copyWith(
                      color: widget.isDark
                          ? WanMapColors.textPrimaryDark
                          : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // エリア名
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.pin.areaName ?? '不明',
                          style: WanMapTypography.bodySmall.copyWith(
                            color: widget.isDark
                                ? WanMapColors.textSecondaryDark
                                : WanMapColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // ユーザー名
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.pin.userName ?? '匿名',
                          style: WanMapTypography.bodySmall.copyWith(
                            color: widget.isDark
                                ? WanMapColors.textSecondaryDark
                                : WanMapColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // いいね数・コメント数（読み取り専用）
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 16,
                        color: Colors.red.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likeCount',
                        style: WanMapTypography.bodySmall.copyWith(
                          color: widget.isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.chat_bubble,
                        size: 16,
                        color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$commentCount',
                        style: WanMapTypography.bodySmall.copyWith(
                          color: widget.isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
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
      color: widget.isDark ? Colors.grey[800] : Colors.grey[300],
      child: Icon(
        Icons.image_not_supported,
        size: 40,
        color: widget.isDark ? Colors.grey[600] : Colors.grey[400],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}ヶ月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
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
          print('🗺️ Route tapped: $title (routeId: $routeId) → Navigate to RouteDetailScreen');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailScreen(routeId: routeId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(WanMapSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // サムネイル画像
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WanMapColors.accent.withOpacity(0.8),
                      WanMapColors.primary.withOpacity(0.8),
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
                            size: 40,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.route,
                          size: 40,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: WanMapSpacing.md),
            
            // ルート情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    title,
                    style: WanMapTypography.titleMedium.copyWith(
                      color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // エリア・県
                  Text(
                    '$area・$prefecture',
                    style: WanMapTypography.bodySmall.copyWith(
                      color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 距離・所要時間・今月の散歩数
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.straighten, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${(distance / 1000).toStringAsFixed(1)}km',
                            style: WanMapTypography.bodySmall.copyWith(
                              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${duration}分',
                            style: WanMapTypography.bodySmall.copyWith(
                              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets, size: 14, color: WanMapColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            '$totalWalks回',
                            style: WanMapTypography.bodySmall.copyWith(
                              color: WanMapColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 矢印アイコン
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
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
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 背景グラデーション（画像の代わり）
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WanMapColors.accent,
                      WanMapColors.accent.withOpacity(0.7),
                      WanMapColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              // 装飾パターン
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.landscape,
                  size: 100,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              // コンテンツ
              Padding(
                padding: const EdgeInsets.all(WanMapSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.pets, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: WanMapSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                area.name,
                                style: WanMapTypography.headlineMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                area.prefecture,
                                style: WanMapTypography.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
