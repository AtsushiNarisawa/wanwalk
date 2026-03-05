import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/wanwalk_colors.dart';
import '../config/wanwalk_spacing.dart';
import '../config/wanwalk_typography.dart';
import '../providers/gps_provider_riverpod.dart';
import '../models/walk_mode.dart';
import '../screens/daily/daily_walking_screen.dart';

/// 散歩中バナーウィジェット
/// 
/// 散歩記録中の場合、画面下部に固定表示され、
/// タップすると散歩中画面へ遷移する
/// 
/// 注意: Outing Walkの場合、ルート情報が必要なため、
/// バナーからの遷移は実装していません。
/// Daily Walk専用の機能です。
class ActiveWalkBanner extends ConsumerWidget {
  const ActiveWalkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gpsState = ref.watch(gpsProviderRiverpod);

    // 散歩中でない場合は非表示
    if (!gpsState.isRecording) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 8,
      color: WanWalkColors.primary,
      child: InkWell(
        onTap: () => _navigateToWalkingScreen(context, gpsState),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WanWalkSpacing.md,
            vertical: WanWalkSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                WanWalkColors.primary,
                WanWalkColors.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // アニメーション付きアイコン
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 1.0 + (value * 0.2),
                      child: Icon(
                        gpsState.isPaused 
                            ? Icons.pause_circle_filled
                            : Icons.directions_walk,
                        color: Colors.white,
                        size: 32,
                      ),
                    );
                  },
                ),
                const SizedBox(width: WanWalkSpacing.sm),
                // 散歩情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gpsState.isPaused 
                            ? '散歩を一時停止中'
                            : '散歩を記録中',
                        style: WanWalkTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            gpsState.formattedDistance,
                            style: WanWalkTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: WanWalkSpacing.sm),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: WanWalkSpacing.sm),
                          Text(
                            gpsState.formattedDuration,
                            style: WanWalkTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: WanWalkSpacing.sm),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: WanWalkSpacing.sm),
                          Text(
                            gpsState.walkMode == WalkMode.daily
                                ? '日常散歩'
                                : 'おでかけ散歩',
                            style: WanWalkTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 矢印アイコン
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 散歩中画面へ遷移
  void _navigateToWalkingScreen(BuildContext context, GpsState gpsState) {
    if (gpsState.walkMode == WalkMode.daily) {
      // Daily Walk画面へ遷移
      // 注意: push（戻るボタンで戻れる）を使用
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DailyWalkingScreen(),
        ),
      );
    } else {
      // Outing Walk画面は、ルート情報が必要なため、
      // バナーからの遷移は未対応
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('おでかけ散歩中です。マップタブから確認してください。'),
          backgroundColor: WanWalkColors.accent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
