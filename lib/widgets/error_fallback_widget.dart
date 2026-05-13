import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../config/error_messages.dart';
import '../config/wanwalk_colors.dart';
import '../config/wanwalk_spacing.dart';
import '../config/wanwalk_typography.dart';
import '../screens/report_issue_screen.dart';
import '../utils/error_handler.dart';

/// A3: フルスクリーンのエラーフォールバック画面。
///
/// `ErrorWidget.builder` 経由のビルド失敗・`runZonedGuarded` で
/// 拾った致命的例外時に表示する。文言は `ErrorMessages` 準拠。
///
/// 二次災害防止：本 Widget は Supabase / FCM / 重い処理を呼ばない純粋 UI のみ。
class ErrorFallbackWidget extends StatelessWidget {
  const ErrorFallbackWidget({
    super.key,
    this.details,
    this.onRetry,
    this.onGoHome,
  });

  /// Flutter フレームワーク経由の詳細（オプショナル）。
  final FlutterErrorDetails? details;

  /// 「もう一度試す」押下時のコールバック。null の場合はホーム遷移にフォールバック。
  final VoidCallback? onRetry;

  /// 「ホームに戻る」押下時のコールバック。null の場合は `Navigator.popUntil`。
  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WanWalkColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WanWalkSpacing.xl,
            vertical: WanWalkSpacing.xxl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                PhosphorIcons.warning(),
                size: 64,
                color: WanWalkColors.accent,
              ),
              const SizedBox(height: WanWalkSpacing.lg),
              Text(
                ErrorMessages.errorBoundary,
                textAlign: TextAlign.center,
                style: WanWalkTypography.bodyLarge.copyWith(
                  color: WanWalkColors.textPrimaryLight,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: WanWalkSpacing.xxl),
              _PrimaryButton(
                label: ErrorButtonLabels.retry,
                onPressed: () => _handleRetry(context),
              ),
              const SizedBox(height: WanWalkSpacing.md),
              _SecondaryButton(
                label: ErrorButtonLabels.goHome,
                onPressed: () => _handleGoHome(context),
              ),
              const SizedBox(height: WanWalkSpacing.lg),
              TextButton(
                onPressed: () => _openReport(context),
                style: TextButton.styleFrom(
                  foregroundColor: WanWalkColors.textPrimaryLight,
                ),
                child: const Text('問題を報告する'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRetry(BuildContext context) {
    if (onRetry != null) {
      onRetry!();
      return;
    }
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  void _handleGoHome(BuildContext context) {
    if (onGoHome != null) {
      onGoHome!();
      return;
    }
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  void _openReport(BuildContext context) {
    final navigator = Navigator.maybeOf(context);
    if (navigator == null) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ReportIssueScreen(
          contextHint: details?.exceptionAsString(),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: WanWalkColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: WanWalkSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: WanWalkTypography.labelLarge,
      ),
      child: Text(label),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: WanWalkColors.accent,
        side: const BorderSide(color: WanWalkColors.accent),
        padding: const EdgeInsets.symmetric(vertical: WanWalkSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: WanWalkTypography.labelLarge,
      ),
      child: Text(label),
    );
  }
}

/// `ErrorWidget.builder` の置換実装。ビルド時の例外を本フォールバックで包む。
Widget wanwalkErrorWidgetBuilder(FlutterErrorDetails details) {
  // ビルド失敗時に重複報告にならないよう、Sentry へは ErrorHandler 経由で 1 度だけ送る。
  ErrorHandler.recordNonFatal(
    details.exception,
    stack: details.stack,
    extra: {
      'library': details.library ?? 'unknown',
      'context': details.context?.toString() ?? '',
    },
  );

  return Directionality(
    textDirection: TextDirection.ltr,
    child: ErrorFallbackWidget(details: details),
  );
}
