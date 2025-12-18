import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import 'daily_walking_screen.dart';

/// Daily Walk View（日常の散歩モード）
/// - プライベート記録
/// - マップ表示
/// - 統計情報
/// - 過去の散歩履歴
class DailyWalkView extends ConsumerWidget {
  const DailyWalkView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヒーローセクション
          _buildHeroSection(context, isDark),

          const SizedBox(height: WanMapSpacing.xl),

          // 散歩開始ボタン
          _buildStartWalkButton(context, isDark),

          const SizedBox(height: WanMapSpacing.xxxl),

          // クイックアクション
          _buildQuickActions(context, isDark),

          const SizedBox(height: WanMapSpacing.xxxl),

          // 今日の統計
          _buildTodayStats(context, isDark),

          const SizedBox(height: WanMapSpacing.xxxl),

          // 最近の散歩
          _buildRecentWalks(context, isDark),

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
                Icons.home,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: WanMapSpacing.sm),
              Text(
                '日常の散歩',
                style: WanMapTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.md),
          Text(
            'いつものルートを記録しよう',
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
        ],
      ),
    );
  }

  /// 散歩開始ボタン
  Widget _buildStartWalkButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DailyWalkingScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: WanMapColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: WanMapColors.accent.withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_filled, size: 32),
              const SizedBox(width: WanMapSpacing.sm),
              Text(
                'お散歩を開始',
                style: WanMapTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 今日の統計
  Widget _buildTodayStats(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日の統計',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.directions_walk,
                  label: '今日の散歩',
                  value: '0回',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: WanMapSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.route,
                  label: '今日の距離',
                  value: '0.0km',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.timer,
                  label: '今日の時間',
                  value: '0分',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: WanMapSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  label: '連続日数',
                  value: '0日',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 最近の散歩
  Widget _buildRecentWalks(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最近の散歩',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),
          Container(
            padding: const EdgeInsets.all(WanMapSpacing.xl),
            decoration: BoxDecoration(
              color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.pets,
                    size: 48,
                    color: isDark
                        ? WanMapColors.textSecondaryDark
                        : WanMapColors.textSecondaryLight,
                  ),
                  const SizedBox(height: WanMapSpacing.md),
                  Text(
                    'まだ散歩の記録がありません',
                    style: WanMapTypography.bodyLarge.copyWith(
                      color: isDark
                          ? WanMapColors.textSecondaryDark
                          : WanMapColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// クイックアクションカード
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

/// 統計カード
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: WanMapColors.accent,
            size: 28,
          ),
          const SizedBox(height: WanMapSpacing.sm),
          Text(
            label,
            style: WanMapTypography.caption.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: WanMapSpacing.xs),
          Text(
            value,
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
