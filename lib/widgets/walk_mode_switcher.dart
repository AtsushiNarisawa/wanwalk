import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/walk_mode.dart';
import '../providers/walk_mode_provider.dart';
import '../config/wanmap_colors.dart';
import '../config/wanmap_typography.dart';
import '../config/wanmap_spacing.dart';

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
        horizontal: WanMapSpacing.lg,
        vertical: WanMapSpacing.lg,  // md → lg に変更（目立たせる）
      ),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(  // 枠線を追加（目立たせる）
          color: WanMapColors.accent.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: WanMapColors.accent.withOpacity(0.15),  // accentカラーの影に変更
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
          vertical: WanMapSpacing.lg,  // md → lg に変更（余白を増やす）
          horizontal: WanMapSpacing.md,  // sm → md に変更
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? WanMapColors.accent
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
                  : (isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight),
              size: 32,  // 28 → 32 に変更（アイコンを大きく）
            ),
            const SizedBox(height: WanMapSpacing.xs),
            Text(
              mode.label,
              style: WanMapTypography.bodyMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WanMapSpacing.xs),
            Text(
              mode.description,
              style: WanMapTypography.caption.copyWith(
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : (isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight),
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
