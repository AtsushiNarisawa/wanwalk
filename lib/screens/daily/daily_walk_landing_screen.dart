import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
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
          ? WanWalkColors.backgroundDark 
          : WanWalkColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'キャンセル',
        ),
        title: Row(
          children: [
            const Icon(Icons.directions_walk, color: WanWalkColors.accent, size: 28),
            const SizedBox(width: WanWalkSpacing.sm),
            Text(
              'クイック記録',
              style: WanWalkTypography.headlineMedium.copyWith(
                color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(WanWalkSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // イラスト（アイコン）
              Container(
                padding: const EdgeInsets.all(WanWalkSpacing.xxl),
                decoration: BoxDecoration(
                  color: WanWalkColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
  PhosphorIcons.dog(),
                  size: 80,
                  color: WanWalkColors.accent,
                ),
              ),
              
              const SizedBox(height: WanWalkSpacing.xxl),
              
              // タイトル
              Text(
                '日常の散歩',
                style: WanWalkTypography.headlineLarge.copyWith(
                  color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: WanWalkSpacing.md),
              
              // サブタイトル
              Text(
                'いつもの散歩を記録しましょう',
                style: WanWalkTypography.bodyLarge.copyWith(
                  color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: WanWalkSpacing.xxxl),
              
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
                  backgroundColor: WanWalkColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: WanWalkTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  elevation: 4,
                ),
              ),
              
              const SizedBox(height: WanWalkSpacing.md),
              
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
                  foregroundColor: WanWalkColors.accent,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: WanWalkColors.accent, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: WanWalkTypography.bodyLarge.copyWith(
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
