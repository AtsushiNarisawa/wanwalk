import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import '../../outing/walking_screen.dart';
import '../../map/map_screen.dart';

/// MapTab - おでかけ散歩の中心（公式ルート、エリア、ピン）
/// 
/// 構成:
/// - マップ表示（プレースホルダー）
/// - FAB: おでかけ散歩開始
class MapTab extends ConsumerWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'マップ',
          style: WanMapTypography.headlineMedium.copyWith(
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: '現在地',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('現在地機能は準備中です'), duration: Duration(seconds: 2)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '検索',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('検索機能は準備中です'), duration: Duration(seconds: 2)),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // マップエリア（プレースホルダー）
          Center(
            child: Padding(
              padding: const EdgeInsets.all(WanMapSpacing.xxxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: WanMapColors.accent.withOpacity(0.3), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 80, color: WanMapColors.accent.withOpacity(0.5)),
                        const SizedBox(height: WanMapSpacing.lg),
                        Text(
                          'マップ機能',
                          style: WanMapTypography.headlineSmall.copyWith(
                            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: WanMapSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.xxxl),
                          child: Text(
                            '公式ルート、エリア、ピンを表示\n（Phase 2で実装予定）',
                            style: WanMapTypography.bodyMedium.copyWith(
                              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: WanMapSpacing.xl),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                    icon: const Icon(Icons.map),
                    label: const Text('既存のマップを開く'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WanMapColors.accent,
                      side: BorderSide(color: WanMapColors.accent),
                      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.xl, vertical: WanMapSpacing.md),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // FAB: おでかけ散歩開始
          Positioned(
            right: WanMapSpacing.lg,
            bottom: WanMapSpacing.lg,
            child: FloatingActionButton.extended(
              onPressed: () {
                // おでかけ散歩開始（公式ルート選択→WalkingScreen）
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('おでかけ散歩機能は準備中です'), duration: Duration(seconds: 2)),
                );
              },
              backgroundColor: WanMapColors.accent,
              elevation: 8,
              icon: const Icon(Icons.explore, size: 28, color: Colors.white),
              label: Text(
                'おでかけ散歩',
                style: WanMapTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
