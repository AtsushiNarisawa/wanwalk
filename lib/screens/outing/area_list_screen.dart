import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/area_provider.dart';
import '../../models/area.dart';
import 'route_list_screen.dart';

/// エリア一覧画面
/// 箱根、横浜、鎌倉などのエリアを選択
class AreaListScreen extends ConsumerWidget {
  const AreaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode) {
      print('🟢 AreaListScreen.build() called');
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kDebugMode) {
      print('🟢 About to watch areasProvider...');
    }
    final areasAsync = ref.watch(areasProvider);
    if (kDebugMode) {
      print('🟢 areasAsync state: ${areasAsync.runtimeType}');
    }

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: const Text('エリアを選ぶ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: areasAsync.when(
        data: (areas) {
          if (areas.isEmpty) {
            return _buildEmptyState(isDark);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(WanMapSpacing.lg),
            itemCount: areas.length,
            itemBuilder: (context, index) {
              final area = areas[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < areas.length - 1 ? WanMapSpacing.md : 0,
                ),
                child: _AreaCard(
                  area: area,
                  isDark: isDark,
                  onTap: () {
                    // エリアを選択してルート一覧画面へ
                    ref.read(selectedAreaIdProvider.notifier).selectArea(area.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RouteListScreen(
                          areaId: area.id,
                          areaName: area.name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
              ),
              const SizedBox(height: WanMapSpacing.md),
              Text(
                'エリアの読み込みに失敗しました',
                style: WanMapTypography.bodyLarge.copyWith(
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: WanMapSpacing.sm),
              Text(
                error.toString(),
                style: WanMapTypography.caption.copyWith(
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WanMapSpacing.lg),
              ElevatedButton.icon(
                onPressed: () {
                  if (kDebugMode) {
                    print('🔄 Refresh button pressed - invalidating areasProvider');
                  }
                  ref.invalidate(areasProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: isDark
                ? WanMapColors.textSecondaryDark
                : WanMapColors.textSecondaryLight,
          ),
          const SizedBox(height: WanMapSpacing.md),
          Text(
            'エリアがありません',
            style: WanMapTypography.bodyLarge.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// エリアカード
class _AreaCard extends StatelessWidget {
  final Area area;
  final bool isDark;
  final VoidCallback onTap;

  const _AreaCard({
    required this.area,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Row(
          children: [
            // エリアアイコン
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    WanMapColors.accent,
                    WanMapColors.accent.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_city,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: WanMapSpacing.md),
            // エリア情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.name,
                    style: WanMapTypography.bodyLarge.copyWith(
                      color: isDark
                          ? WanMapColors.textPrimaryDark
                          : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: WanMapSpacing.xs),
                  Text(
                    area.description,
                    style: WanMapTypography.caption.copyWith(
                      color: isDark
                          ? WanMapColors.textSecondaryDark
                          : WanMapColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: WanMapSpacing.sm),
            // 矢印アイコン
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
