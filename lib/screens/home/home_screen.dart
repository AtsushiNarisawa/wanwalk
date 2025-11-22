import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../widgets/walk_mode_switcher.dart';
import '../../providers/walk_mode_provider.dart';
import '../daily/daily_walk_view.dart';
import '../outing/outing_walk_view.dart';

/// ホーム画面 (WanMap リニューアル版)
/// 
/// リニューアルの特徴:
/// - 2モード制：Daily（日常の散歩）とOuting（おでかけ散歩）
/// - モード切り替えスイッチャー
/// - モードに応じた異なるコンテンツ表示
/// - 公式ルート・エリア・ピン機能
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMode = ref.watch(walkModeProvider);

    return Scaffold(
      backgroundColor: isDark 
          ? WanMapColors.backgroundDark 
          : WanMapColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ヘッダー
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Icon(
                  Icons.pets,
                  color: WanMapColors.accent,
                  size: 28,
                ),
                const SizedBox(width: WanMapSpacing.sm),
                Text(
                  'WanMap',
                  style: WanMapTypography.headlineMedium.copyWith(
                    color: isDark 
                        ? WanMapColors.textPrimaryDark 
                        : WanMapColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'プロフィール',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('プロフィール機能は準備中です'),
                    ),
                  );
                },
              ),
            ],
          ),

          // モード切り替えスイッチャー
          const SliverToBoxAdapter(
            child: WalkModeSwitcher(),
          ),

          // モードに応じたコンテンツ
          SliverToBoxAdapter(
            child: currentMode.isDaily
                ? const DailyWalkView()
                : const OutingWalkView(),
          ),
        ],
      ),
    );
  }
}
