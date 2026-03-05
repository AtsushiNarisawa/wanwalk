import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/walk_mode.dart';
import '../providers/walk_mode_provider.dart';
import '../config/wanwalk_colors.dart';
import '../config/wanwalk_typography.dart';
import '../config/wanwalk_spacing.dart';

/// 散歩モード切り替えWidget
/// Daily（日常の散歩）とOuting（おでかけ散歩）を切り替える
class WalkModeSwitcher extends ConsumerWidget {
  const WalkModeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(walkModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.lg,
        vertical: WanWalkSpacing.lg,  // md → lg に変更（目立たせる）
      ),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(  // 枠線を追加（目立たせる）
          color: WanWalkColors.accent.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: WanWalkColors.accent.withOpacity(0.15),  // accentカラーの影に変更
            blurRadius: 15,  // 10 → 15 に変更（より強調）
            offset: const Offset(0, 6),  // 4 → 6 に変更
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),  // 4 → 6 に変更（余白を増やす）
        child: Row(
          children: [
            // Daily モードボタン
            Expanded(
              child: _ModeButton(
                mode: WalkMode.daily,
                isSelected: currentMode == WalkMode.daily,
                onTap: () async {
                  await ref.read(walkModeProvider.notifier).switchToDaily();
                },
              ),
            ),
            const SizedBox(width: 4),
            // Outing モードボタン
            Expanded(
              child: _ModeButton(
                mode: WalkMode.outing,
                isSelected: currentMode == WalkMode.outing,
                onTap: () async {
                  await ref.read(walkModeProvider.notifier).switchToOuting();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// モードボタン
class _ModeButton extends StatelessWidget {
  final WalkMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: WanWalkSpacing.lg,  // md → lg に変更（余白を増やす）
          horizontal: WanWalkSpacing.md,  // sm → md に変更
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? WanWalkColors.accent
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          // 選択されていない時も薄い枠線を追加
          border: isSelected
              ? null
              : Border.all(
                  color: (isDark ? Colors.grey[700] : Colors.grey[300])!,
                  width: 1,
                ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mode.isDaily ? Icons.home : Icons.explore,
              color: isSelected
                  ? Colors.white
                  : (isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight),
              size: 32,  // 28 → 32 に変更（アイコンを大きく）
            ),
            const SizedBox(height: WanWalkSpacing.xs),
            Text(
              mode.label,
              style: WanWalkTypography.bodyMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WanWalkSpacing.xs),
            Text(
              mode.description,
              style: WanWalkTypography.caption.copyWith(
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : (isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight),
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
