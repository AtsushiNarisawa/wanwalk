import 'package:flutter/material.dart';
import '../config/wanmap_colors.dart';
import '../config/wanmap_typography.dart';
import '../config/wanmap_spacing.dart';

/// WanMap 共通テキストフィールドウィジェット
/// スタイリッシュで使いやすい入力フィールド

class WanMapTextField extends StatelessWidget {
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

  const WanMapTextField({
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
        ? WanMapColors.surfaceDark 
        : WanMapColors.surfaceLight;
    final textColor = isDark 
        ? WanMapColors.textPrimaryDark 
        : WanMapColors.textPrimaryLight;
    final hintColor = isDark 
        ? WanMapColors.textSecondaryDark 
        : WanMapColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ラベル
        if (labelText != null) ...[
          Text(
            labelText!,
            style: WanMapTypography.labelMedium.copyWith(
              color: textColor,
            ),
          ),
          const SizedBox(height: WanMapSpacing.xs),
        ],
        
        // テキストフィールド
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: WanMapSpacing.borderRadiusLG,
            border: Border.all(
              color: errorText != null 
                  ? WanMapColors.error 
                  : WanMapColors.textTertiaryLight,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: WanMapTypography.bodyLarge.copyWith(
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
              hintStyle: WanMapTypography.bodyLarge.copyWith(
                color: hintColor,
              ),
              prefixIcon: prefixIcon != null 
                  ? Icon(prefixIcon, color: hintColor) 
                  : null,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: WanMapSpacing.lg,
                vertical: WanMapSpacing.md,
              ),
              counterText: '', // 文字数カウンターを非表示
            ),
          ),
        ),
        
        // エラーメッセージ
        if (errorText != null) ...[
          const SizedBox(height: WanMapSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 16,
                color: WanMapColors.error,
              ),
              const SizedBox(width: WanMapSpacing.xxs),
              Text(
                errorText!,
                style: WanMapTypography.labelSmall.copyWith(
                  color: WanMapColors.error,
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
class WanMapSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const WanMapSearchField({
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
        ? WanMapColors.surfaceDark 
        : WanMapColors.surfaceLight;
    final textColor = isDark 
        ? WanMapColors.textPrimaryDark 
        : WanMapColors.textPrimaryLight;
    final hintColor = isDark 
        ? WanMapColors.textSecondaryDark 
        : WanMapColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: WanMapSpacing.borderRadiusXL,
      ),
      child: TextField(
        controller: controller,
        style: WanMapTypography.bodyLarge.copyWith(
          color: textColor,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText ?? '検索',
          hintStyle: WanMapTypography.bodyLarge.copyWith(
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
            horizontal: WanMapSpacing.lg,
            vertical: WanMapSpacing.md,
          ),
        ),
      ),
    );
  }
}

/// タグ入力フィールド
class WanMapTagInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final String? hintText;

  const WanMapTagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.hintText,
  });

  @override
  State<WanMapTagInput> createState() => _WanMapTagInputState();
}

class _WanMapTagInputState extends State<WanMapTagInput> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タグリスト
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: WanMapSpacing.xs,
            runSpacing: WanMapSpacing.xs,
            children: widget.tags.map((tag) {
              return Chip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                labelPadding: EdgeInsets.zero,
                label: Text(
                  tag,
                  style: WanMapTypography.labelSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: WanMapColors.accent,
                deleteIcon: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
                onDeleted: () => _removeTag(tag),
              );
            }).toList(),
          ),
        if (widget.tags.isNotEmpty) const SizedBox(height: WanMapSpacing.sm),
        
        // 入力フィールド
        WanMapTextField(
          controller: _controller,
          hintText: widget.hintText ?? 'タグを追加',
          prefixIcon: Icons.label_outline,
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: WanMapColors.accent,
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
