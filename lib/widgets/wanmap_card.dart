import 'package:flutter/material.dart';
import '../config/wanmap_colors.dart';
import '../config/wanmap_spacing.dart';

/// WanMap 共通カードウィジェット
/// ルート表示用の大きなカード

enum WanMapCardSize {
  small,
  medium,
  large,
}

class WanMapCard extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final WanMapCardSize size;
  final bool withShadow;
  final EdgeInsets? padding;

  const WanMapCard({
    super.key,
    this.child,
    this.onTap,
    this.backgroundColor,
    this.size = WanMapCardSize.medium,
    this.withShadow = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBackgroundColor = isDark 
        ? WanMapColors.surfaceDark 
        : WanMapColors.surfaceLight;

    // サイズに応じた角丸とパディング
    BorderRadius borderRadius;
    EdgeInsets defaultPadding;

    switch (size) {
      case WanMapCardSize.small:
        borderRadius = WanMapSpacing.borderRadiusMD;
        defaultPadding = const EdgeInsets.all(WanMapSpacing.md);
        break;
      case WanMapCardSize.medium:
        borderRadius = WanMapSpacing.borderRadiusLG;
        defaultPadding = const EdgeInsets.all(WanMapSpacing.lg);
        break;
      case WanMapCardSize.large:
        borderRadius = WanMapSpacing.borderRadiusXL;
        defaultPadding = const EdgeInsets.all(WanMapSpacing.xl);
        break;
    }

    return Material(
      color: backgroundColor ?? defaultBackgroundColor,
      borderRadius: borderRadius,
      elevation: withShadow ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: padding ?? defaultPadding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ヒーロー画像付きカード（ルート詳細用）
class WanMapHeroCard extends StatelessWidget {
  final String? imageUrl;
  final Widget child;
  final VoidCallback? onTap;
  final double imageHeight;
  final Widget? imageOverlay;

  const WanMapHeroCard({
    super.key,
    this.imageUrl,
    required this.child,
    this.onTap,
    this.imageHeight = 200,
    this.imageOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return WanMapCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      size: WanMapCardSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヒーロー画像
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(WanMapSpacing.radiusXL),
              ),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl!,
                    width: double.infinity,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: imageHeight,
                        color: WanMapColors.textTertiaryLight,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: WanMapColors.textSecondaryLight,
                        ),
                      );
                    },
                  ),
                  if (imageOverlay != null)
                    Positioned.fill(child: imageOverlay!),
                ],
              ),
            ),
          // コンテンツ
          Padding(
            padding: const EdgeInsets.all(WanMapSpacing.lg),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// 統計カード（数字を大きく表示）
class WanMapStatCard extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const WanMapStatCard({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
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

    return WanMapCard(
      onTap: onTap,
      size: WanMapCardSize.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // アイコン
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(WanMapSpacing.sm),
              decoration: BoxDecoration(
                color: (color ?? WanMapColors.accent).withOpacity(0.1),
                borderRadius: WanMapSpacing.borderRadiusMD,
              ),
              child: Icon(
                icon,
                size: 24,
                color: color ?? WanMapColors.accent,
              ),
            ),
          if (icon != null) const SizedBox(height: WanMapSpacing.md),
          
          // 数値と単位
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.0,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: WanMapSpacing.xs),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.xxs),
          
          // ラベル
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
