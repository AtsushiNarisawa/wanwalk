import 'package:flutter/material.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';

/// WanWalkエラー表示ウィジェット
/// 
/// エラー発生時のUI統一と再試行機能を提供
class WanWalkErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isNetworkError;
  final IconData? icon;

  const WanWalkErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.isNetworkError = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // アイコン
          Icon(
            icon ?? (isNetworkError ? Icons.wifi_off : Icons.error_outline),
            size: 64,
            color: isDark 
                ? WanWalkColors.textSecondaryDark 
                : WanWalkColors.textSecondaryLight,
          ),
          const SizedBox(height: WanWalkSpacing.lg),
          
          // エラーメッセージ
          Text(
            message,
            style: WanWalkTypography.bodyLarge.copyWith(
              color: isDark 
                  ? WanWalkColors.textPrimaryDark 
                  : WanWalkColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          
          // ネットワークエラー時の補足
          if (isNetworkError) ...[
            const SizedBox(height: WanWalkSpacing.sm),
            Text(
              'インターネット接続を確認してください',
              style: WanWalkTypography.bodySmall.copyWith(
                color: isDark 
                    ? WanWalkColors.textSecondaryDark 
                    : WanWalkColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          // 再試行ボタン
          if (onRetry != null) ...[
            const SizedBox(height: WanWalkSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WanWalkColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: WanWalkSpacing.xl,
                  vertical: WanWalkSpacing.md,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// カード型エラーウィジェット（小さな領域用）
class WanWalkErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const WanWalkErrorCard({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.lg),
      decoration: BoxDecoration(
        color: isDark 
            ? WanWalkColors.surfaceDark.withOpacity(0.5)
            : WanWalkColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? WanWalkColors.borderDark 
              : WanWalkColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: isDark 
                ? WanWalkColors.textSecondaryDark 
                : WanWalkColors.textSecondaryLight,
          ),
          const SizedBox(height: WanWalkSpacing.sm),
          Text(
            message,
            style: WanWalkTypography.bodyMedium.copyWith(
              color: isDark 
                  ? WanWalkColors.textPrimaryDark 
                  : WanWalkColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: WanWalkSpacing.md),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
              style: TextButton.styleFrom(
                foregroundColor: WanWalkColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 空状態ウィジェット
class WanWalkEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Widget? illustration;

  const WanWalkEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // イラストまたはアイコン
          if (illustration != null)
            illustration!
          else
            Icon(
              icon,
              size: 80,
              color: isDark 
                  ? WanWalkColors.textSecondaryDark.withOpacity(0.5)
                  : WanWalkColors.textSecondaryLight.withOpacity(0.5),
            ),
          const SizedBox(height: WanWalkSpacing.xl),
          
          // タイトル
          Text(
            title,
            style: WanWalkTypography.headlineSmall.copyWith(
              color: isDark 
                  ? WanWalkColors.textPrimaryDark 
                  : WanWalkColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WanWalkSpacing.sm),
          
          // メッセージ
          Text(
            message,
            style: WanWalkTypography.bodyMedium.copyWith(
              color: isDark 
                  ? WanWalkColors.textSecondaryDark 
                  : WanWalkColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          
          // アクションボタン
          if (onAction != null) ...[
            const SizedBox(height: WanWalkSpacing.xxl),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel ?? 'はじめる'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WanWalkColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: WanWalkSpacing.xxl,
                  vertical: WanWalkSpacing.md,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// カード型空状態ウィジェット
class WanWalkEmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const WanWalkEmptyCard({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.xl),
      decoration: BoxDecoration(
        color: isDark 
            ? WanWalkColors.surfaceDark.withOpacity(0.5)
            : WanWalkColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? WanWalkColors.borderDark 
              : WanWalkColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: isDark 
                ? WanWalkColors.textSecondaryDark.withOpacity(0.5)
                : WanWalkColors.textSecondaryLight.withOpacity(0.5),
          ),
          const SizedBox(height: WanWalkSpacing.md),
          Text(
            message,
            style: WanWalkTypography.bodyMedium.copyWith(
              color: isDark 
                  ? WanWalkColors.textSecondaryDark 
                  : WanWalkColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
