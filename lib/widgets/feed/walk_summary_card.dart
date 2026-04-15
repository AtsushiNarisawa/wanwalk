import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';

/// 自分の散歩サマリーカード（フィード先頭に固定表示）
class WalkSummaryCard extends StatelessWidget {
  final int walkCount;
  final String totalDistanceKm;
  final int totalMinutes;
  final bool isDark;

  const WalkSummaryCard({
    super.key,
    required this.walkCount,
    required this.totalDistanceKm,
    required this.totalMinutes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.lg,
        vertical: WanWalkSpacing.sm,
      ),
      padding: const EdgeInsets.all(WanWalkSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WanWalkColors.accent,
            WanWalkColors.accent.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: WanWalkColors.accent.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.dog(), color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '今週のお散歩',
                style: WanWalkTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: WanWalkSpacing.md),
          Row(
            children: [
              _StatBubble(value: '$walkCount', label: '回', icon: Icons.directions_walk),
              const SizedBox(width: WanWalkSpacing.md),
              _StatBubble(value: totalDistanceKm, label: 'km', icon: Icons.straighten),
              const SizedBox(width: WanWalkSpacing.md),
              _StatBubble(value: '$totalMinutes', label: '分', icon: Icons.timer),
            ],
          ),
          const SizedBox(height: WanWalkSpacing.md),
          Text(
            walkCount > 3
                ? 'たくさん歩いてますね！愛犬も喜んでます'
                : '週末は新しいルートを歩いてみませんか？',
            style: WanWalkTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatBubble({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '$value$label',
            style: WanWalkTypography.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
