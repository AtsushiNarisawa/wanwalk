import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../providers/area_provider.dart';
import '../../../providers/route_provider.dart';
import '../../../providers/official_routes_screen_provider.dart';
import '../../../providers/recent_pins_provider.dart';
import '../../../models/recent_pin_post.dart';
import '../../outing/area_list_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../routes/public_routes_screen.dart';
import '../../outing/route_list_screen.dart';
import '../../../models/area.dart';
import '../../../widgets/shimmer/wanmap_shimmer.dart';

/// HomeTab - ビジュアル重視のホーム画面
/// 
/// 構成:
/// 1. MAP表示（200px、最新ピン投稿中心）
/// 2. 最新の写真付きピン投稿（横2枚）
/// 3. 人気の公式ルート
/// 4. おすすめエリア（3枚 + 一覧を見るボタン）
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MAP表示（200px）
            _buildMapPreview(context, isDark),
            
            const SizedBox(height: WanMapSpacing.lg),
            
            // 2. 人気の公式ルート
            _buildPopularRoutes(context, isDark),
            
            const SizedBox(height: WanMapSpacing.xl),
            
            // 3. 最新の写真付きピン投稿（横2枚）
            _buildRecentPinPosts(context, isDark),
            
            const SizedBox(height: WanMapSpacing.xxxl),
            
            // 4. おすすめエリア（3枚 + 一覧ボタン）
            _buildRecommendedAreas(context, isDark, areasAsync),
            
            const SizedBox(height: WanMapSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  /// MAP表示（人気の公式ルート1位を表示）
  Widget _buildMapPreview(BuildContext context, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final popularRoutesAsync = ref.watch(popularRoutesProvider);
        
        // デフォルト中心位置（横浜）
        LatLng center = const LatLng(35.4437, 139.638);
        
        return popularRoutesAsync.when(
          data: (routes) {
            // 人気の公式ルート1位がある場合はその位置を中心に
            if (routes.isNotEmpty) {
              final topRoute = routes.first;
              // ルートの開始位置を使用
              if (topRoute['start_lat'] != null && topRoute['start_lon'] != null) {
                center = LatLng(
                  (topRoute['start_lat'] as num).toDouble(),
                  (topRoute['start_lon'] as num).toDouble(),
                );
              }
            }
            
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
                  // 人気ルート1位のマーカーを表示
                  if (routes.isNotEmpty && routes.first['start_lat'] != null && routes.first['start_lon'] != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            (routes.first['start_lat'] as num).toDouble(),
                            (routes.first['start_lon'] as num).toDouble(),
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.star,
                            color: WanMapColors.accent,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
          loading: () => Container(
            height: 280,
            color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Container(
            height: 280,
            color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
            child: const Center(child: Text('マップを読み込めませんでした')),
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
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '最新の写真付きピン投稿',
                style: WanMapTypography.headlineSmall.copyWith(
                  color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: WanMapSpacing.md),
              recentPinsAsync.when(
                data: (pins) {
                  if (pins.isEmpty) {
                    return _buildEmptyCard(isDark, 'まだピン投稿がありません');
                  }
                  return Row(
                    children: pins.take(2).map((pin) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: pins.indexOf(pin) == 0 ? WanMapSpacing.sm : 0,
                            left: pins.indexOf(pin) == 1 ? WanMapSpacing.sm : 0,
                          ),
                          child: _RecentPinCard(
                            pin: pin,
                            isDark: isDark,
                          ),
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
        );
      },
    );
  }

  /// おすすめエリア（3枚 + 一覧を見るボタン）
  /// おすすめエリア（箱根大きく + 2枚 + 一覧ボタン）
  Widget _buildRecommendedAreas(BuildContext context, bool isDark, AsyncValue<dynamic> areasAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'おすすめエリア',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),
          areasAsync.when(
            data: (areas) {
              if (areas.isEmpty) {
                return _buildEmptyCard(isDark, 'エリアが登録されていません');
              }
              
              // 箱根を最優先、その他はそのまま
              Area? hakoneArea;
              try {
                hakoneArea = areas.firstWhere((area) => area.name == '箱根');
              } catch (e) {
                hakoneArea = areas.isNotEmpty ? areas.first : null;
              }
              
              if (hakoneArea == null) {
                return _buildEmptyCard(isDark, 'エリアが登録されていません');
              }
              
              final otherAreas = areas.where((area) => area.name != '箱根').take(2).toList();
              
              return Column(
                children: [
                  // 箱根カード（大きく目立つ）
                  Padding(
                    padding: const EdgeInsets.only(bottom: WanMapSpacing.md),
                    child: _FeaturedAreaCard(
                      area: hakoneArea,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteListScreen(
                            areaId: hakoneArea!.id,
                            areaName: hakoneArea.name,
                          ),
                        ),
                      ),
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
    );
  }


  /// 人気の公式ルート（3枚 + 一覧ボタン）
  Widget _buildPopularRoutes(BuildContext context, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final popularRoutesAsync = ref.watch(popularRoutesProvider);
        // 全ルート数を取得
        final allRoutesAsync = ref.watch(officialRoutesProvider);
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '人気の公式ルート',
                style: WanMapTypography.headlineSmall.copyWith(
                  color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: WanMapSpacing.md),
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
                            totalWalks: route['total_walks'] as int? ?? 0,
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
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isHorizontal ? double.infinity : 160,
        padding: const EdgeInsets.all(WanMapSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [WanMapColors.accent, WanMapColors.accent.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: WanMapColors.accent.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isHorizontal
            ? Row(
                children: [
                  const Icon(Icons.location_city, color: Colors.white, size: 40),
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
                  const Icon(Icons.location_city, color: Colors.white, size: 40),
                  const SizedBox(height: WanMapSpacing.sm),
                  Text(
                    name,
                    style: WanMapTypography.bodyLarge.copyWith(
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
    );
  }
}

class _RecentPinCard extends StatelessWidget {
  final RecentPinPost pin;
  final bool isDark;

  const _RecentPinCard({
    required this.pin,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // ピンが投稿されたルートの詳細画面へ遷移
        if (kDebugMode) {
          print('📌 Pin tapped: ${pin.title} → Navigate to route: ${pin.routeName}');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailScreen(routeId: pin.routeId),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: pin.photoUrl.isNotEmpty
                  ? Image.network(
                      pin.photoUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultImage(),
                    )
                  : _buildDefaultImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    pin.title,
                    style: WanMapTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanMapColors.textPrimaryDark
                          : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // ユーザー名・エリア
                  Text(
                    '${pin.userName} · ${pin.areaName}',
                    style: WanMapTypography.bodySmall.copyWith(
                      color: isDark
                          ? WanMapColors.textSecondaryDark
                          : WanMapColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // いいね数・相対時間
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 14, color: Colors.red[300]),
                      const SizedBox(width: 4),
                      Text(
                        '${pin.likesCount}',
                        style: WanMapTypography.bodySmall.copyWith(
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      Text(
                        pin.relativeTime,
                        style: WanMapTypography.bodySmall.copyWith(
                          color: isDark
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
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: WanMapColors.accent.withOpacity(0.2),
      ),
      child: const Icon(
        Icons.photo,
        size: 48,
        color: WanMapColors.accent,
      ),
    );
  }
}

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
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailScreen(routeId: routeId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
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
            // サムネイル
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: thumbnailUrl != null
                  ? Image.network(
                      thumbnailUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultThumbnail(),
                    )
                  : _buildDefaultThumbnail(),
            ),
            const SizedBox(width: WanMapSpacing.md),
            // ルート情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WanMapTypography.bodyLarge.copyWith(
                      color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WanMapSpacing.xs),
                  Text(
                    '$area・$prefecture',
                    style: WanMapTypography.bodySmall.copyWith(
                      color: WanMapColors.accent,
                    ),
                  ),
                  const SizedBox(height: WanMapSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.directions_walk, size: 14, color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(
                        '${(distance / 1000).toStringAsFixed(1)}km',
                        style: WanMapTypography.bodySmall.copyWith(
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      const Icon(Icons.directions_walk, size: 14, color: WanMapColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        '$totalWalks回',
                        style: WanMapTypography.bodySmall.copyWith(
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
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

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: WanMapColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.route,
        size: 32,
        color: WanMapColors.accent,
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
        height: 160,
        padding: const EdgeInsets.all(WanMapSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B35),
              Color(0xFFFF8C42),
              WanMapColors.accent,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 48),
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
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        area.prefecture,
                        style: WanMapTypography.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
