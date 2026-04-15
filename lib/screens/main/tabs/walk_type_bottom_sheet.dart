import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../config/wanwalk_colors.dart';
import '../../../config/wanwalk_spacing.dart';
import '../../../config/wanwalk_typography.dart';

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
          color: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            WanWalkSpacing.lg,
            WanWalkSpacing.md,
            WanWalkSpacing.lg,
            WanWalkSpacing.lg,
          ),
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
              const SizedBox(height: WanWalkSpacing.lg),

              // タイトル
              Row(
                children: [
                  Icon(
                    PhosphorIcons.personSimpleWalk(),
                    color: WanWalkColors.accentPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: WanWalkSpacing.xs),
                  Text(
                    'お散歩を始めよう',
                    style: WanWalkTypography.headlineSmall.copyWith(
                      color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WanWalkSpacing.lg + WanWalkSpacing.xs),

              // お出かけ散歩（メイン）
              _WalkTypeCard(
                icon: PhosphorIcons.mapTrifold(),
                title: 'お出かけ散歩',
                description: '公式ルートに沿って散歩',
                detail: 'おすすめコースをナビで案内',
                gradientColors: const [
                  WanWalkColors.accentPrimary,
                  WanWalkColors.accentPrimaryHover,
                ],
                onTap: () => Navigator.pop(context, 'outing'),
              ),
              const SizedBox(height: WanWalkSpacing.sm),

              // 日常散歩
              _WalkTypeCard(
                icon: PhosphorIcons.houseSimple(),
                title: '日常散歩',
                description: 'いつものお散歩を記録',
                detail: '自由なルートで散歩を楽しむ',
                gradientColors: const [
                  WanWalkColors.accentPrimary,
                  WanWalkColors.accentPrimaryHover,
                ],
                onTap: () => Navigator.pop(context, 'daily'),
              ),
              const SizedBox(height: WanWalkSpacing.sm),

              // ピン投稿のみ
              _WalkTypeCard(
                icon: PhosphorIcons.mapPin(),
                title: 'ピン投稿のみ',
                description: 'お気に入りスポットを共有',
                detail: '散歩せずにピンだけ投稿',
                gradientColors: const [
                  WanWalkColors.accentPrimary,
                  WanWalkColors.accentPrimaryHover,
                ],
                isCompact: true,
                onTap: () => Navigator.pop(context, 'pin_only'),
              ),
              const SizedBox(height: WanWalkSpacing.lg),

              // キャンセルボタン
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: WanWalkSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'キャンセル',
                    style: WanWalkTypography.bodyMedium.copyWith(
                      color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
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
  final String detail;
  final List<Color> gradientColors;
  final bool isCompact;
  final VoidCallback onTap;

  const _WalkTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.detail,
    required this.gradientColors,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isCompact ? WanWalkSpacing.md : WanWalkSpacing.md + 2),
          decoration: BoxDecoration(
            color: isDark ? WanWalkColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: WanWalkColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // グラデーションアイコン
              Container(
                width: isCompact ? 48 : 56,
                height: isCompact ? 48 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isCompact ? 24 : 28,
                ),
              ),
              const SizedBox(width: WanWalkSpacing.md),

              // テキスト
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: WanWalkTypography.titleMedium.copyWith(
                        color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        style: WanWalkTypography.bodySmall.copyWith(
                          color: isDark ? WanWalkColors.textTertiaryDark : WanWalkColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 矢印
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.grey[800] : Colors.grey[100])!,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
