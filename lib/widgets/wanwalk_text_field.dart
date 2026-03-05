import 'package:flutter/material.dart';
import '../config/wanwalk_colors.dart';
import '../config/wanwalk_typography.dart';
import '../config/wanwalk_spacing.dart';

/// WanWalk 共通テキストフィールドウィジェット
/// スタイリッシュで使いやすい入力フィールド

class WanWalkTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const WanWalkTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark 
        ? WanWalkColors.surfaceDark 
        : WanWalkColors.surfaceLight;
    final textColor = isDark 
        ? WanWalkColors.textPrimaryDark 
        : WanWalkColors.textPrimaryLight;
    final hintColor = isDark 
        ? WanWalkColors.textSecondaryDark 
        : WanWalkColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ラベル
        if (labelText != null) ...[
          Text(
            labelText!,
            style: WanWalkTypography.labelMedium.copyWith(
              color: textColor,
            ),
          ),
          const SizedBox(height: WanWalkSpacing.xs),
        ],
        
        // テキストフィールド
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: WanWalkSpacing.borderRadiusLG,
            border: Border.all(
              color: errorText != null 
                  ? WanWalkColors.error 
                  : WanWalkColors.textTertiaryLight,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: WanWalkTypography.bodyLarge.copyWith(
              color: textColor,
            ),
            keyboardType: keyboardType,
            obscureText: obscureText,
            readOnly: readOnly,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: WanWalkTypography.bodyLarge.copyWith(
                color: hintColor,
              ),
              prefixIcon: prefixIcon != null 
                  ? Icon(prefixIcon, color: hintColor) 
                  : null,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: WanWalkSpacing.lg,
                vertical: WanWalkSpacing.md,
              ),
              counterText: '', // 文字数カウンターを非表示
            ),
          ),
        ),
        
        // エラーメッセージ
        if (errorText != null) ...[
          const SizedBox(height: WanWalkSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 16,
                color: WanWalkColors.error,
              ),
              const SizedBox(width: WanWalkSpacing.xxs),
              Text(
                errorText!,
                style: WanWalkTypography.labelSmall.copyWith(
                  color: WanWalkColors.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 検索フィールド
class WanWalkSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const WanWalkSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark 
        ? WanWalkColors.surfaceDark 
        : WanWalkColors.surfaceLight;
    final textColor = isDark 
        ? WanWalkColors.textPrimaryDark 
        : WanWalkColors.textPrimaryLight;
    final hintColor = isDark 
        ? WanWalkColors.textSecondaryDark 
        : WanWalkColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: WanWalkSpacing.borderRadiusXL,
      ),
      child: TextField(
        controller: controller,
        style: WanWalkTypography.bodyLarge.copyWith(
          color: textColor,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText ?? '検索',
          hintStyle: WanWalkTypography.bodyLarge.copyWith(
            color: hintColor,
          ),
          prefixIcon: Icon(Icons.search, color: hintColor),
          suffixIcon: controller?.text.isNotEmpty ?? false
              ? IconButton(
                  icon: Icon(Icons.clear, color: hintColor),
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WanWalkSpacing.lg,
            vertical: WanWalkSpacing.md,
          ),
        ),
      ),
    );
  }
}

/// タグ入力フィールド
class WanWalkTagInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final String? hintText;

  const WanWalkTagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.hintText,
  });

  @override
  State<WanWalkTagInput> createState() => _WanWalkTagInputState();
}

class _WanWalkTagInputState extends State<WanWalkTagInput> {
  final TextEditingController _controller = TextEditingController();

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !widget.tags.contains(tag.trim())) {
      widget.onTagsChanged([...widget.tags, tag.trim()]);
      _controller.clear();
    }
  }

  void _removeTag(String tag) {
    widget.onTagsChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タグリスト
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: WanWalkSpacing.xs,
            runSpacing: WanWalkSpacing.xs,
            children: widget.tags.map((tag) {
              return Chip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                labelPadding: EdgeInsets.zero,
                label: Text(
                  tag,
                  style: WanWalkTypography.labelSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: WanWalkColors.accent,
                deleteIcon: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
                onDeleted: () => _removeTag(tag),
              );
            }).toList(),
          ),
        if (widget.tags.isNotEmpty) const SizedBox(height: WanWalkSpacing.sm),
        
        // 入力フィールド
        WanWalkTextField(
          controller: _controller,
          hintText: widget.hintText ?? 'タグを追加',
          prefixIcon: Icons.label_outline,
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: WanWalkColors.accent,
            ),
            onPressed: () => _addTag(_controller.text),
          ),
          onChanged: (value) {
            if (value.endsWith(' ') || value.endsWith(',')) {
              _addTag(value.trim().replaceAll(',', ''));
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
