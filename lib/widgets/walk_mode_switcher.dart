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
        vertical: WanMapSpacing.md,
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(4),
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
          vertical: WanMapSpacing.md,
          horizontal: WanMapSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? WanMapColors.accent
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mode.isDaily ? Icons.home : Icons.explore,
              color: isSelected
                  ? Colors.white
                  : (isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight),
              size: 28,
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
