import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/app_exception.dart';

/// グローバルなエラーハンドリングサービス
class ErrorHandlerService {
  /// Supabase エラーをアプリケーション例外に変換
  static AppException handleSupabaseError(dynamic error, StackTrace stackTrace) {
    if (error is supabase.AuthException) {
      return AuthException(
        message: 'Authentication failed: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is supabase.PostgrestException) {
      if (error.code == '23505') {
        return DatabaseException(
          message: 'Duplicate entry',
          code: 'DUPLICATE_ENTRY',
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      return DatabaseException(
        message: 'Database error: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is supabase.StorageException) {
      return DatabaseException(
        message: 'Storage error: ${error.message}',
        code: 'STORAGE_ERROR',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // その他の Supabase エラー
    return AppException(
      message: 'Supabase error: ${error.toString()}',
      code: 'SUPABASE_ERROR',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// ネットワークエラーをハンドリング
  static AppException handleNetworkError(dynamic error, StackTrace stackTrace) {
    return NetworkException(
      message: 'Network error: ${error.toString()}',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// 一般的なエラーをハンドリング
  static AppException handleGenericError(dynamic error, StackTrace stackTrace) {
    if (error is AppException) {
      return error;
    }

    return AppException(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// エラーをログに記録（開発時のみ）
  static void logError(AppException exception) {
    if (kDebugMode) {
      print('❌ Error [${exception.code}]: ${exception.message}');
      if (exception.originalError != null) {
        if (kDebugMode) {
          print('   Original: ${exception.originalError}');
        }
      }
      if (exception.stackTrace != null) {
        if (kDebugMode) {
          print('   StackTrace: ${exception.stackTrace}');
        }
      }
    }
  }

  /// エラーをユーザーフレンドリーなメッセージに変換
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppException) {
      return error.getUserMessage();
    }

    // デフォルトメッセージ
    return '予期しないエラーが発生しました。もう一度お試しください';
  }
}