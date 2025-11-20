import 'package:flutter/material.dart';
import '../config/wanmap_colors.dart';
import '../config/wanmap_typography.dart';
import '../config/wanmap_spacing.dart';

/// WanMap 共通ボタンウィジェット
/// Nike Run Club風の大きく目立つボタン

enum WanMapButtonSize {
  small,
  medium,
  large,
}

enum WanMapButtonVariant {
  primary,    // 塗りつぶし（アクセントカラー）
  secondary,  // 塗りつぶし（セカンダリカラー）
  outlined,   // アウトライン
  text,       // テキストのみ
}

class WanMapButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final WanMapButtonSize size;
  final WanMapButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;

  const WanMapButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.size = WanMapButtonSize.medium,
    this.variant = WanMapButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || loading;

    // サイズに応じたパディングとテキストスタイル
    EdgeInsets padding;
    TextStyle textStyle;
    double iconSize;

    switch (size) {
      case WanMapButtonSize.small:
        padding = const EdgeInsets.symmetric(
          horizontal: 6.0,
          vertical: WanMapSpacing.sm,
        );
        textStyle = WanMapTypography.titleSmall;
        iconSize = 20;
        break;
      case WanMapButtonSize.medium:
        padding = WanMapSpacing.buttonPadding;
        textStyle = WanMapTypography.buttonMedium;
        iconSize = 24;
        break;
      case WanMapButtonSize.large:
        padding = WanMapSpacing.buttonPaddingLarge;
        textStyle = WanMapTypography.buttonLarge;
        iconSize = 28;
        break;
    }

    // バリアントに応じたスタイル
    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;
    double elevation;

    switch (variant) {
      case WanMapButtonVariant.primary:
        backgroundColor = isDisabled 
            ? WanMapColors.textTertiaryLight 
            : WanMapColors.accent;
        foregroundColor = Colors.white;
        borderColor = null;
        elevation = isDisabled ? 0 : 2;
        break;
      case WanMapButtonVariant.secondary:
        backgroundColor = isDisabled 
            ? WanMapColors.textTertiaryLight 
            : WanMapColors.secondary;
        foregroundColor = Colors.white;
        borderColor = null;
        elevation = isDisabled ? 0 : 2;
        break;
      case WanMapButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = isDisabled 
            ? WanMapColors.textTertiaryLight 
            : WanMapColors.accent;
        borderColor = foregroundColor;
        elevation = 0;
        break;
      case WanMapButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = isDisabled 
            ? WanMapColors.textTertiaryLight 
            : WanMapColors.accent;
        borderColor = null;
        elevation = 0;
        break;
    }

    
    Widget buttonChild = loading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize),
                if (text.isNotEmpty) const SizedBox(width: 4.0),
              ],
              if (text.isNotEmpty)
                Flexible(
                  child: Text(
                    text,
                    style: textStyle.copyWith(color: foregroundColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: backgroundColor,
        elevation: elevation,
        borderRadius: WanMapSpacing.borderRadiusXL,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: WanMapSpacing.borderRadiusXL,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: WanMapSpacing.borderRadiusXL,
                border: borderColor != null
                    ? Border.all(color: borderColor, width: 2)
                    : null,
              ),
              child: buttonChild,
            ),
          ),
        );
    );
  }
}

/// フローティングアクションボタン（カメラボタンなど）
class WanMapFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const WanMapFAB({
    Key? key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? WanMapColors.accent,
      foregroundColor: foregroundColor ?? Colors.white,
      tooltip: tooltip,
      elevation: 4,
      child: Icon(icon, size: 28),
    );
  }
}
