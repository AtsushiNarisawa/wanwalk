import 'package:flutter/material.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_spacing.dart';
import '../../../config/wanmap_typography.dart';

/// 散歩タイプ選択ボトムシート
/// 
/// MAP タブのFABから呼び出され、以下の3つの散歩タイプを選択できる:
/// 1. お出かけ散歩（公式ルートを歩く）
/// 2. 日常散歩（自由に歩く）
/// 3. ピン投稿のみ（散歩記録なし）
class WalkTypeBottomSheet extends StatelessWidget {
  const WalkTypeBottomSheet({super.key});

  /// ボトムシートを表示
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const WalkTypeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WanMapSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // ドラッグハンドル
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: WanMapSpacing.lg),

          // タイトル
          Text(
            '散歩を始める',
            style: WanMapTypography.headlineMedium.copyWith(
              color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.xs),
          Text(
            '散歩のタイプを選択してください',
            style: WanMapTypography.bodyMedium.copyWith(
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: WanMapSpacing.lg),

          // お出かけ散歩
          _WalkTypeCard(
            icon: Icons.route,
            title: 'お出かけ散歩',
            description: '公式ルートを歩く',
            color: WanMapColors.accent,
            onTap: () => Navigator.pop(context, 'outing'),
          ),
          const SizedBox(height: WanMapSpacing.md),

          // 日常散歩
          _WalkTypeCard(
            icon: Icons.pets,
            title: '日常散歩',
            description: '自由に歩く',
            color: WanMapColors.primary,
            onTap: () => Navigator.pop(context, 'daily'),
          ),
          const SizedBox(height: WanMapSpacing.md),

          // ピン投稿のみ
          _WalkTypeCard(
            icon: Icons.add_location_alt,
            title: 'ピン投稿のみ',
            description: '散歩記録なし',
            color: Colors.orange,
            onTap: () => Navigator.pop(context, 'pin_only'),
          ),
          const SizedBox(height: WanMapSpacing.md),

          // キャンセルボタン
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'キャンセル',
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(height: WanMapSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// 散歩タイプカード
class _WalkTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _WalkTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(WanMapSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // アイコン
            Container(
              padding: const EdgeInsets.all(WanMapSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: WanMapSpacing.md),

            // テキスト
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WanMapTypography.titleMedium.copyWith(
                      color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: WanMapTypography.bodySmall.copyWith(
                      color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // 矢印アイコン
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
