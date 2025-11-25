import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/area_provider.dart';
import 'area_list_screen.dart';

/// Outing Walk View（おでかけ散歩モード）
/// - 公式ルートを探す
/// - エリアから選ぶ
/// - 近くのルートを探す
/// - コミュニティのピンを見る
class OutingWalkView extends ConsumerWidget {
  const OutingWalkView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode) {
      print('🔴 OutingWalkView.build() called');
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kDebugMode) {
      print('🔴 About to watch areasProvider in OutingWalkView...');
    }
    final areasAsync = ref.watch(areasProvider);
    if (kDebugMode) {
      print('🔴 OutingWalkView areasAsync state: ${areasAsync.runtimeType}');
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヒーローセクション
          _buildHeroSection(context, isDark),

          const SizedBox(height: WanMapSpacing.xl),

          // クイックアクション
          _buildQuickActions(context, isDark),

          const SizedBox(height: WanMapSpacing.xxxl),

          // エリア一覧
          _buildAreasSection(context, isDark, areasAsync),

          const SizedBox(height: WanMapSpacing.xxxl),

          // 人気ルート
          _buildPopularRoutes(context, isDark),

          const SizedBox(height: WanMapSpacing.xxxl),
        ],
      ),
    );
  }

  /// ヒーローセクション
  Widget _buildHeroSection(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      padding: const EdgeInsets.all(WanMapSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WanMapColors.accent,
            WanMapColors.accent.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: WanMapColors.accent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.explore,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: WanMapSpacing.sm),
              Text(
                'おでかけ散歩',
                style: WanMapTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.md),
          Text(
            '公式ルートを歩いて体験を共有しよう',
            style: WanMapTypography.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// クイックアクション
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'クイックアクション',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),
          // Row 1: バッジ・統計
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.emoji_events,
                  label: 'バッジ',
                  color: Colors.amber,
                  isDark: isDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('バッジ機能は準備中です')),
                    );
                  },
                ),
              ),
              const SizedBox(width: WanMapSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.bar_chart,
                  label: '統計',
                  color: Colors.blue,
                  isDark: isDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('統計機能は準備中です')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.md),
          // Row 2: 近くのルート・エリア
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.location_on,
                  label: '近くのルート',
                  color: Colors.green,
                  isDark: isDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('近くのルート検索機能は準備中です'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: WanMapSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.map,
                  label: 'エリア',
                  color: Colors.teal,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// エリア一覧セクション
  Widget _buildAreasSection(
    BuildContext context,
    bool isDark,
    AsyncValue<dynamic> areasAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'エリアから探す',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),
          areasAsync.when(
            data: (areas) {
              if (areas.isEmpty) {
                return _buildEmptyState(isDark, 'エリアがありません');
              }
              return SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: areas.length,
                  itemBuilder: (context, index) {
                    final area = areas[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < areas.length - 1 ? WanMapSpacing.md : 0,
                      ),
                      child: _AreaChip(
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
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildEmptyState(
              isDark,
              'エリアの読み込みに失敗しました',
            ),
          ),
        ],
      ),
    );
  }

  /// 人気ルートセクション
  Widget _buildPopularRoutes(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '人気のルート',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),
          _buildEmptyState(isDark, 'まだ人気ルートがありません'),
        ],
      ),
    );
  }

  /// 空状態
  Widget _buildEmptyState(bool isDark, String message) {
    return Container(
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
              message,
              style: WanMapTypography.bodyLarge.copyWith(
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

/// クイックアクションカード（DailyWalkViewと統一）
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
        padding: const EdgeInsets.all(WanMapSpacing.lg),
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
          children: [
            Icon(
              icon,
              color: color,
              size: 48,
            ),
            const SizedBox(height: WanMapSpacing.sm),
            Text(
              label,
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
        width: 120,
        padding: const EdgeInsets.all(WanMapSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: WanMapColors.accent.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_city,
              color: WanMapColors.accent,
              size: 32,
            ),
            const SizedBox(height: WanMapSpacing.sm),
            Text(
              name,
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark
                    ? WanMapColors.textPrimaryDark
                    : WanMapColors.textPrimaryLight,
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
