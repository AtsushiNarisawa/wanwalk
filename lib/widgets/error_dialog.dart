import 'package:flutter/material.dart';
import '../config/wanwalk_colors.dart';
import '../models/app_exception.dart';
import '../services/error_handler_service.dart';

/// エラー表示用のダイアログ
class ErrorDialog extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = ErrorHandlerService.getUserFriendlyMessage(error);
    final isRetryable = _isRetryableError(error);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: Colors.red[700]),
          const SizedBox(width: 8),
          const Text('エラー'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(errorMessage),
          if (error is AppException && error.code != null) ...[
            const SizedBox(height: 8),
            Text(
              'エラーコード: ${error.code}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (isRetryable && onRetry != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  bool _isRetryableError(dynamic error) {
    if (error is NetworkException) return true;
    if (error is DatabaseException) return true;
    return false;
  }

  /// エラーを表示する静的メソッド
  static void show(
    BuildContext context, {
    required dynamic error,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
      ),
    );
  }
}

/// エラー表示用のスナックバー
class ErrorSnackBar {
  static void show(
    BuildContext context, {
    required dynamic error,
    VoidCallback? onRetry,
  }) {
    final errorMessage = ErrorHandlerService.getUserFriendlyMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(errorMessage)),
          ],
        ),
        backgroundColor: WanWalkColors.semanticError,
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: '再試行',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}