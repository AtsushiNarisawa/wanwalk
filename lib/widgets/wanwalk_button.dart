import 'package:flutter/material.dart';
import '../config/wanwalk_colors.dart';
import '../config/wanwalk_typography.dart';
import '../config/wanwalk_spacing.dart';

/// WanWalk 共通ボタンウィジェット
/// Nike Run Club風の大きく目立つボタン

enum WanWalkButtonSize {
  small,
  medium,
  large,
}

enum WanWalkButtonVariant {
  primary,    // 塗りつぶし（アクセントカラー）
  secondary,  // 塗りつぶし（セカンダリカラー）
  outlined,   // アウトライン
  text,       // テキストのみ
}

class WanWalkButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final WanWalkButtonSize size;
  final WanWalkButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;

  const WanWalkButton({
    super.key,
    required this.text,
    this.onPressed,
    this.size = WanWalkButtonSize.medium,
    this.variant = WanWalkButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || loading;

    // サイズに応じたパディングとテキストスタイル
    EdgeInsets padding;
    TextStyle textStyle;
    double iconSize;

    switch (size) {
      case WanWalkButtonSize.small:
        padding = const EdgeInsets.symmetric(
          horizontal: 6.0,
          vertical: WanWalkSpacing.sm,
        );
        textStyle = WanWalkTypography.titleSmall;
        iconSize = 20;
        break;
      case WanWalkButtonSize.medium:
        padding = WanWalkSpacing.buttonPadding;
        textStyle = WanWalkTypography.buttonMedium;
        iconSize = 24;
        break;
      case WanWalkButtonSize.large:
        padding = WanWalkSpacing.buttonPaddingLarge;
        textStyle = WanWalkTypography.buttonLarge;
        iconSize = 28;
        break;
    }

    // バリアントに応じたスタイル
    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;
    double elevation;

    switch (variant) {
      case WanWalkButtonVariant.primary:
        backgroundColor = isDisabled 
            ? WanWalkColors.textTertiaryLight 
            : WanWalkColors.accent;
        foregroundColor = Colors.white;
        borderColor = null;
        elevation = isDisabled ? 0 : 2;
        break;
      case WanWalkButtonVariant.secondary:
        backgroundColor = isDisabled 
            ? WanWalkColors.textTertiaryLight 
            : WanWalkColors.secondary;
        foregroundColor = Colors.white;
        borderColor = null;
        elevation = isDisabled ? 0 : 2;
        break;
      case WanWalkButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = isDisabled 
            ? WanWalkColors.textTertiaryLight 
            : WanWalkColors.accent;
        borderColor = foregroundColor;
        elevation = 0;
        break;
      case WanWalkButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = isDisabled 
            ? WanWalkColors.textTertiaryLight 
            : WanWalkColors.accent;
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
        borderRadius: WanWalkSpacing.borderRadiusXL,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: WanWalkSpacing.borderRadiusXL,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: WanWalkSpacing.borderRadiusXL,
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 2)
                  : null,
            ),
            child: buttonChild,
          ),
        ),
      ),
    );
  }
}

/// フローティングアクションボタン（カメラボタンなど）
class WanWalkFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const WanWalkFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? WanWalkColors.accent,
      foregroundColor: foregroundColor ?? Colors.white,
      tooltip: tooltip,
      elevation: 4,
      child: Icon(icon, size: 28),
    );
  }
}
