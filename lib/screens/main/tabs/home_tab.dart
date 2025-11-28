import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import '../../../providers/area_provider.dart';
import '../../../providers/route_provider.dart';
import '../../outing/area_list_screen.dart';
import '../../daily/daily_walking_screen.dart';
import '../../history/walk_history_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../favorites/favorite_routes_screen.dart';

/// HomeTab - おでかけ散歩を優先
/// 
/// 構成:
/// 1. おすすめエリア（カルーセル）
/// 2. 人気の公式ルート
/// 3. クイックアクション（4つ）
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
            Icon(Icons.pets, color: WanMapColors.accent, size: 28),
            const SizedBox(width: WanMapSpacing.sm),
            Text(
              'WanMap',
              style: WanMapTypography.headlineMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
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
            const SizedBox(height: WanMapSpacing.md),
            
            // クイックアクション（最優先で表示）
            _buildQuickActions(context, isDark),
            
            const SizedBox(height: WanMapSpacing.xxxl),
            
            // おすすめエリア
            _buildRecommendedAreas(context, isDark, areasAsync),
            
            const SizedBox(height: WanMapSpacing.xxxl),
            
            // 人気の公式ルート
            _buildPopularRoutes(context, isDark),
            
            const SizedBox(height: WanMapSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  /// おすすめエリア（カルーセル）
  Widget _buildRecommendedAreas(BuildContext context, bool isDark, AsyncValue<dynamic> areasAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Text(
            'おすすめエリア',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: WanMapSpacing.md),
        areasAsync.when(
          data: (areas) {
            if (areas.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
                child: _buildEmptyCard(isDark, 'エリアが登録されていません'),
              );
            }
            return SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
                itemCount: areas.length,
                itemBuilder: (context, index) {
                  final area = areas[index];
                  return Padding(
                    padding: EdgeInsets.only(right: index < areas.length - 1 ? WanMapSpacing.md : 0),
                    child: _AreaCard(
                      name: area.name,
                      isDark: isDark,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AreaListScreen())),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
            child: _buildEmptyCard(isDark, 'エリアの読み込みに失敗しました'),
          ),
        ),
      ],
    );
  }

  /// 人気の公式ルート
  Widget _buildPopularRoutes(BuildContext context, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final popularRoutesAsync = ref.watch(popularRoutesProvider);
        
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
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      final route = routes[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < routes.length - 1 ? WanMapSpacing.md : 0),
                        child: _PopularRouteCard(
                          routeId: route['route_id'],
                          title: route['title'] ?? '無題のルート',
                          description: route['description'] ?? '',
                          area: route['area'] ?? '',
                          prefecture: route['prefecture'] ?? '',
                          distance: (route['distance'] as num?)?.toDouble() ?? 0.0,
                          duration: route['duration'] as int? ?? 0,
                          likesCount: route['likes_count'] as int? ?? 0,
                          thumbnailUrl: route['thumbnail_url'],
                          isDark: isDark,
                        ),
                      );
                    },
                  );
                },
                loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
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

  /// クイックアクション（4つ）
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'クイックアクション',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: WanMapSpacing.md,
            mainAxisSpacing: WanMapSpacing.md,
            childAspectRatio: 1.5,
            children: [
              _QuickActionCard(
                icon: Icons.map_outlined,
                label: 'エリアを探す',
                color: Colors.orange,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AreaListScreen())),
              ),
              _QuickActionCard(
                icon: Icons.directions_walk,
                label: '日常の散歩',
                color: Colors.green,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyWalkingScreen())),
              ),
              _QuickActionCard(
                icon: Icons.favorite,
                label: 'お気に入り',
                color: Colors.red,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteRoutesScreen())),
              ),
              _QuickActionCard(
                icon: Icons.history,
                label: '散歩履歴',
                color: Colors.purple,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalkHistoryScreen())),
              ),
            ],
          ),
        ],
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
  final bool isDark;
  final VoidCallback onTap;

  const _AreaCard({required this.name, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(WanMapSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [WanMapColors.accent, WanMapColors.accent.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: WanMapColors.accent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_city, color: Colors.white, size: 40),
            const SizedBox(height: WanMapSpacing.sm),
            Text(
              name,
              style: WanMapTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(WanMapSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: WanMapSpacing.sm),
            Text(
              label,
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
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

class _PopularRouteCard extends StatelessWidget {
  final String routeId;
  final String title;
  final String description;
  final String area;
  final String prefecture;
  final double distance;
  final int duration;
  final int likesCount;
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
    required this.likesCount,
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
                      Icon(Icons.favorite, size: 14, color: Colors.red[300]),
                      const SizedBox(width: 4),
                      Text(
                        '$likesCount',
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
      child: Icon(
        Icons.route,
        size: 32,
        color: WanMapColors.accent,
      ),
    );
  }
}
