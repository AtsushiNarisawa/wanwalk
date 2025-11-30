import 'package:flutter/material.dart';
import '../config/wanmap_colors.dart';
import '../config/wanmap_typography.dart';
import '../config/wanmap_spacing.dart';

/// WanMap 統計表示ウィジェット
/// GPS記録画面などで使用する超大サイズの数値表示

/// 超大サイズ統計表示（GPS記録画面用）
class WanMapHeroStat extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color? valueColor;
  final Color? unitColor;
  final Color? labelColor;

  const WanMapHeroStat({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    this.valueColor,
    this.unitColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultValueColor = valueColor ?? 
        (isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight);
    final defaultUnitColor = unitColor ?? 
        (isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight);
    final defaultLabelColor = labelColor ?? 
        (isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 数値 + 単位
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: WanMapTypography.displayLarge.copyWith(
                color: defaultValueColor,
              ),
            ),
            const SizedBox(width: WanMapSpacing.sm),
            Text(
              unit,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: defaultUnitColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: WanMapSpacing.xs),
        
        // ラベル
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: defaultLabelColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// 横並び統計表示（複数の統計を並べる）
class WanMapStatsRow extends StatelessWidget {
  final List<WanMapStatItem> stats;

  const WanMapStatsRow({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: stats.map((stat) {
        return Expanded(
          child: _buildStatItem(context, stat),
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(BuildContext context, WanMapStatItem stat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark 
        ? WanMapColors.textPrimaryDark 
        : WanMapColors.textPrimaryLight;
    final secondaryTextColor = isDark 
        ? WanMapColors.textSecondaryDark 
        : WanMapColors.textSecondaryLight;

    return Column(
      children: [
        // アイコン（オプション）
        if (stat.icon != null) ...[
          Container(
            padding: const EdgeInsets.all(WanMapSpacing.sm),
            decoration: BoxDecoration(
              color: (stat.color ?? WanMapColors.accent).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              stat.icon,
              size: 24,
              color: stat.color ?? WanMapColors.accent,
            ),
          ),
          const SizedBox(height: WanMapSpacing.sm),
        ],
        
        // 数値 + 単位
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              stat.value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: textColor,
                height: 1.0,
              ),
            ),
            const SizedBox(width: WanMapSpacing.xxs),
            Text(
              stat.unit,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: WanMapSpacing.xxs),
        
        // ラベル
        Text(
          stat.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// 統計アイテムのデータクラス
class WanMapStatItem {
  final String value;
  final String unit;
  final String label;
  final IconData? icon;
  final Color? color;

  const WanMapStatItem({
    required this.value,
    required this.unit,
    required this.label,
    this.icon,
    this.color,
  });
}

/// プログレスサークル統計表示
class WanMapProgressStat extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0
  final String value;
  final String unit;
  final String label;
  final Color? progressColor;
  final double size;

  const WanMapProgressStat({
    super.key,
    required this.progress,
    required this.value,
    required this.unit,
    required this.label,
    this.progressColor,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark 
        ? WanMapColors.textPrimaryDark 
        : WanMapColors.textPrimaryLight;
    final secondaryTextColor = isDark 
        ? WanMapColors.textSecondaryDark 
        : WanMapColors.textSecondaryLight;
    final defaultProgressColor = progressColor ?? WanMapColors.accent;

    return Column(
      children: [
        // プログレスサークル
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 背景サークル
              SizedBox(
                width: size,
                height: size,
                child: const CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    WanMapColors.textTertiaryLight,
                  ),
                ),
              ),
              // プログレスサークル
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    defaultProgressColor,
                  ),
                ),
              ),
              // 中央の数値
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: size * 0.25,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: size * 0.12,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: WanMapSpacing.sm),
        
        // ラベル
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// リニアプログレス統計表示
class WanMapLinearProgressStat extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0
  final String value;
  final String unit;
  final String label;
  final Color? progressColor;

  const WanMapLinearProgressStat({
    super.key,
    required this.progress,
    required this.value,
    required this.unit,
    required this.label,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark 
        ? WanMapColors.textPrimaryDark 
        : WanMapColors.textPrimaryLight;
    final secondaryTextColor = isDark 
        ? WanMapColors.textSecondaryDark 
        : WanMapColors.textSecondaryLight;
    final defaultProgressColor = progressColor ?? WanMapColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ラベルと数値
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: WanMapSpacing.xxs),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: WanMapSpacing.sm),
        
        // プログレスバー
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: WanMapColors.textTertiaryLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              defaultProgressColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// 比較統計表示（先週比など）
class WanMapComparisonStat extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final double? comparisonValue; // 前回の値
  final String? comparisonLabel; // "vs 先週" など

  const WanMapComparisonStat({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    this.comparisonValue,
    this.comparisonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark 
        ? WanMapColors.textPrimaryDark 
        : WanMapColors.textPrimaryLight;
    final secondaryTextColor = isDark 
        ? WanMapColors.textSecondaryDark 
        : WanMapColors.textSecondaryLight;

    // 差分計算
    double? diff;
    bool? isIncrease;
    if (comparisonValue != null) {
      final currentVal = double.tryParse(value);
      if (currentVal != null) {
        diff = currentVal - comparisonValue!;
        isIncrease = diff > 0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ラベル
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: WanMapSpacing.xs),
        
        // メインの数値
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: textColor,
                height: 1.0,
              ),
            ),
            const SizedBox(width: WanMapSpacing.xs),
            Text(
              unit,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
        
        // 比較情報
        if (diff != null && isIncrease != null) ...[
          const SizedBox(height: WanMapSpacing.xs),
          Row(
            children: [
              Icon(
                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: isIncrease ? WanMapColors.success : WanMapColors.error,
              ),
              const SizedBox(width: WanMapSpacing.xxs),
              Text(
                '${diff.abs().toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isIncrease ? WanMapColors.success : WanMapColors.error,
                ),
              ),
              if (comparisonLabel != null) ...[
                const SizedBox(width: WanMapSpacing.xs),
                Text(
                  comparisonLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
