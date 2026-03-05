import 'package:flutter/material.dart';
import '../config/wanwalk_colors.dart';
import '../config/wanwalk_spacing.dart';

/// WanWalk 共通カードウィジェット
/// ルート表示用の大きなカード

enum WanWalkCardSize {
  small,
  medium,
  large,
}

class WanWalkCard extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final WanWalkCardSize size;
  final bool withShadow;
  final EdgeInsets? padding;

  const WanWalkCard({
    super.key,
    this.child,
    this.onTap,
    this.backgroundColor,
    this.size = WanWalkCardSize.medium,
    this.withShadow = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBackgroundColor = isDark 
        ? WanWalkColors.surfaceDark 
        : WanWalkColors.surfaceLight;

    // サイズに応じた角丸とパディング
    BorderRadius borderRadius;
    EdgeInsets defaultPadding;

    switch (size) {
      case WanWalkCardSize.small:
        borderRadius = WanWalkSpacing.borderRadiusMD;
        defaultPadding = const EdgeInsets.all(WanWalkSpacing.md);
        break;
      case WanWalkCardSize.medium:
        borderRadius = WanWalkSpacing.borderRadiusLG;
        defaultPadding = const EdgeInsets.all(WanWalkSpacing.lg);
        break;
      case WanWalkCardSize.large:
        borderRadius = WanWalkSpacing.borderRadiusXL;
        defaultPadding = const EdgeInsets.all(WanWalkSpacing.xl);
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
class WanWalkHeroCard extends StatelessWidget {
  final String? imageUrl;
  final Widget child;
  final VoidCallback? onTap;
  final double imageHeight;
  final Widget? imageOverlay;

  const WanWalkHeroCard({
    super.key,
    this.imageUrl,
    required this.child,
    this.onTap,
    this.imageHeight = 200,
    this.imageOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return WanWalkCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      size: WanWalkCardSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヒーロー画像
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(WanWalkSpacing.radiusXL),
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
                        color: WanWalkColors.textTertiaryLight,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: WanWalkColors.textSecondaryLight,
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
            padding: const EdgeInsets.all(WanWalkSpacing.lg),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// 統計カード（数字を大きく表示）
class WanWalkStatCard extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const WanWalkStatCard({
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
        ? WanWalkColors.textPrimaryDark 
        : WanWalkColors.textPrimaryLight;
    final secondaryTextColor = isDark 
        ? WanWalkColors.textSecondaryDark 
        : WanWalkColors.textSecondaryLight;

    return WanWalkCard(
      onTap: onTap,
      size: WanWalkCardSize.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // アイコン
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(WanWalkSpacing.sm),
              decoration: BoxDecoration(
                color: (color ?? WanWalkColors.accent).withOpacity(0.1),
                borderRadius: WanWalkSpacing.borderRadiusMD,
              ),
              child: Icon(
                icon,
                size: 24,
                color: color ?? WanWalkColors.accent,
              ),
            ),
          if (icon != null) const SizedBox(height: WanWalkSpacing.md),
          
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
              const SizedBox(width: WanWalkSpacing.xs),
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
          const SizedBox(height: WanWalkSpacing.xxs),
          
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
