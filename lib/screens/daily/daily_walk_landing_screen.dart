import 'package:flutter/material.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../daily/daily_walking_screen.dart';
import '../history/walk_history_screen.dart';

/// 日常の散歩ランディング画面
/// 
/// ユーザーが「クイック記録」タブをタップした際に表示
/// 散歩を始めるか、履歴を見るかを選択できる
class DailyWalkLandingScreen extends StatelessWidget {
  const DailyWalkLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? WanMapColors.backgroundDark 
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'キャンセル',
        ),
        title: Row(
          children: [
            const Icon(Icons.directions_walk, color: WanMapColors.accent, size: 28),
            const SizedBox(width: WanMapSpacing.sm),
            Text(
              'クイック記録',
              style: WanMapTypography.headlineMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(WanMapSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // イラスト（アイコン）
              Container(
                padding: const EdgeInsets.all(WanMapSpacing.xxl),
                decoration: BoxDecoration(
                  color: WanMapColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  size: 80,
                  color: WanMapColors.accent,
                ),
              ),
              
              const SizedBox(height: WanMapSpacing.xxl),
              
              // タイトル
              Text(
                '日常の散歩',
                style: WanMapTypography.headlineLarge.copyWith(
                  color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: WanMapSpacing.md),
              
              // サブタイトル
              Text(
                'いつもの散歩を記録しましょう',
                style: WanMapTypography.bodyLarge.copyWith(
                  color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: WanMapSpacing.xxxl),
              
              // 散歩を始めるボタン
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyWalkingScreen()),
                  );
                },
                icon: const Icon(Icons.play_arrow, size: 32),
                label: const Text('散歩を始める'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WanMapColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: WanMapTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  elevation: 4,
                ),
              ),
              
              const SizedBox(height: WanMapSpacing.md),
              
              // 履歴を見るボタン
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalkHistoryScreen()),
                  );
                },
                icon: const Icon(Icons.history, size: 24),
                label: const Text('散歩履歴を見る'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WanMapColors.accent,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: WanMapColors.accent, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: WanMapTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
