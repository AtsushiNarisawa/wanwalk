import 'package:flutter/material.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';

/// エリア特集カード（箱根など）
class AreaFeatureCard extends StatelessWidget {
  final String areaName;
  final int routeCount;
  final List<String> subAreas;
  final bool isDark;
  final VoidCallback onTap;

  const AreaFeatureCard({
    super.key,
    required this.areaName,
    required this.routeCount,
    required this.subAreas,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: WanWalkSpacing.lg,
          vertical: WanWalkSpacing.sm,
        ),
        padding: const EdgeInsets.all(WanWalkSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2E7D32), // 深い緑
              const Color(0xFF43A047),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.explore, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  '$areaNameエリア特集',
                  style: WanWalkTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            Text(
              '${subAreas.length}サブエリア・犬連れ散歩コースが充実',
              style: WanWalkTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.md),
            // サブエリアチップ
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: subAreas.take(5).map((area) {
                final displayName = area.toString().replaceFirst('箱根・', '');
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    displayName,
                    style: WanWalkTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: WanWalkSpacing.md),
            Row(
              children: [
                Text(
                  'エリアを探索する',
                  style: WanWalkTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
