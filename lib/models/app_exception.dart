/// アプリケーション全体で使用する例外クラス
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (code != null) {
      return 'AppException [$code]: $message';
    }
    return 'AppException: $message';
  }

  /// ユーザー向けのエラーメッセージを取得
  String getUserMessage() {
    return message;
  }
}

/// ネットワークエラー
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: code ?? 'NETWORK_ERROR',
        );

  @override
  String getUserMessage() {
    return 'ネットワーク接続を確認してください';
  }
}

/// 認証エラー
class AuthException extends AppException {
  AuthException({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: code ?? 'AUTH_ERROR',
        );

  @override
  String getUserMessage() {
    return 'ログインが必要です。再度ログインしてください';
  }
}

/// データベースエラー
class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: code ?? 'DATABASE_ERROR',
        );

  @override
  String getUserMessage() {
    return 'データの保存に失敗しました。もう一度お試しください';
  }
}

/// バリデーションエラー
class ValidationException extends AppException {
  ValidationException({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: code ?? 'VALIDATION_ERROR',
        );

  @override
  String getUserMessage() {
    return message; // バリデーションメッセージはそのまま表示
  }
}

/// 権限エラー
class PermissionException extends AppException {
  PermissionException({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: code ?? 'PERMISSION_ERROR',
        );

  @override
  String getUserMessage() {
    return '必要な権限がありません。設定から権限を許可してください';
  }
}