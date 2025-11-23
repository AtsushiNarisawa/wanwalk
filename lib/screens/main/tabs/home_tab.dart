import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import '../../../providers/area_provider.dart';
import '../../outing/area_list_screen.dart';
import '../../search/route_search_screen.dart';
import '../../daily/daily_walking_screen.dart';
import '../../history/walk_history_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../notifications/notifications_screen.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final areasAsync = ref.watch(areasProvider);

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
            
            // おすすめエリア
            _buildRecommendedAreas(context, isDark, areasAsync),
            
            const SizedBox(height: WanMapSpacing.xxxl),
            
            // 人気の公式ルート
            _buildPopularRoutes(context, isDark),
            
            const SizedBox(height: WanMapSpacing.xxxl),
            
            // クイックアクション
            _buildQuickActions(context, isDark),
            
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
          _buildEmptyCard(isDark, '公式ルートは準備中です'),
        ],
      ),
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
                icon: Icons.search,
                label: 'ルート検索',
                color: Colors.blue,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RouteSearchScreen())),
              ),
              _QuickActionCard(
                icon: Icons.directions_walk,
                label: '日常の散歩',
                color: Colors.green,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyWalkingScreen())),
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
