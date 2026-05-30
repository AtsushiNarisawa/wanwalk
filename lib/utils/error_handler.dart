import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'error_buffer.dart';
import 'logger.dart';

/// A3 クラッシュゼロ化のためのグローバル例外ハンドラ。
///
/// - `FlutterError.onError`：Flutter フレームワーク内例外（build/layout）。
/// - `PlatformDispatcher.instance.onError`：プラットフォーム（async/zone 外）例外。
/// - `runZonedGuarded` の onError は `main.dart` 側で本クラスを呼ぶ。
///
/// Sentry 未初期化時は `ErrorBuffer` に積み、初期化完了後に flush する。
class ErrorHandler {
  ErrorHandler._();

  static bool _registered = false;

  /// Sentry の初期化が完了したか。`SentryFlutter.init` の `appRunner` 内で `true` をセット。
  static bool sentryReady = false;

  /// A18: 致命例外時にユーザーをフォールバック画面へ誘導するコールバック。
  /// material/widget 依存を `main.dart` 側に閉じ込めるため、navigatorKey 経由の
  /// 画面 push は `main.dart` が提供する。未設定（起動超初期）なら Sentry 記録のみ。
  static void Function()? onFatalError;

  /// フォールバック画面を表示中か（多重 push 防止）。閉じたら `main.dart` が false に戻す。
  static bool fatalFallbackActive = false;

  /// `main.dart` の最初期で1度だけ呼ぶ。Sentry 初期化前でも安全に登録できる。
  static void register() {
    if (_registered) return;
    _registered = true;

    final previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // 開発中のオーバーフローは Sentry 送信から除外（既存方針を踏襲）。
      final errorString = details.exceptionAsString();
      if (errorString.contains('overflowed') ||
          errorString.contains('RenderFlex')) {
        if (kDebugMode) {
          appLog('[ErrorHandler] overflow suppressed');
        }
        return;
      }

      FlutterError.presentError(details);
      _capture(
        details.exception,
        stack: details.stack,
        hint: 'FlutterError.onError',
      );
      previousFlutterOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _capture(error, stack: stack, hint: 'PlatformDispatcher.onError');
      // A18: async/platform 例外（build 外）の致命例外はここを通る。
      // 白画面放置を避けてフォールバック画面へ誘導する。
      _maybeShowFallback();
      return true;
    };

    if (kDebugMode) {
      appLog('[ErrorHandler] global handlers registered');
    }
  }

  /// `runZonedGuarded` の onError から呼ぶ。
  static void captureZoneError(Object error, StackTrace stack) {
    _capture(error, stack: stack, hint: 'runZonedGuarded');
    // A18: zone 由来の未捕捉例外は fire-and-forget(unawaited)の取りこぼしを含み
    // 多くが非致命。これをフルスクリーン昇格すると散歩中等に UI を乗っ取るため、
    // フォールバック誘導は PlatformDispatcher.onError(フレーム/プラットフォーム級の
    // より致命的なシグナル)に限定する。zone 由来は Sentry 記録のみで観測を担保。
  }

  /// A18: 致命例外時にフォールバック画面誘導を 1 回だけ起動する。
  /// build 時例外（FlutterError.onError）は `ErrorWidget.builder` 側が
  /// フォールバックを出すため、ここからは呼ばない（二重表示回避）。
  static void _maybeShowFallback() {
    final cb = onFatalError;
    // navigator 未マウント（起動超初期）や多重発火時は誘導しない。
    if (cb == null || fatalFallbackActive) return;
    fatalFallbackActive = true;
    try {
      cb();
    } catch (_) {
      // 誘導自体の失敗で二次例外ループに陥らないよう握り、フラグを戻す。
      fatalFallbackActive = false;
    }
  }

  /// 任意の場所からの非致命報告。例：Supabase クエリ失敗時の `try-catch` ブロック。
  static Future<void> recordNonFatal(
    Object error, {
    StackTrace? stack,
    Map<String, dynamic>? extra,
  }) async {
    await _capture(
      error,
      stack: stack,
      hint: 'nonFatal',
      extra: extra,
      level: SentryLevel.warning,
    );
  }

  /// Sentry 初期化完了を通知。バッファされたイベントを flush する。
  static Future<void> markSentryReady() async {
    sentryReady = true;
    await ErrorBuffer.flushTo(_sendToSentry);
  }

  static Future<void> _capture(
    Object error, {
    StackTrace? stack,
    String? hint,
    Map<String, dynamic>? extra,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (!sentryReady) {
      ErrorBuffer.add(
        PendingError(
          error: error,
          stack: stack,
          hint: hint,
          extra: extra,
          level: level,
        ),
      );
      if (kDebugMode) {
        appLog('[ErrorHandler] buffered (sentry not ready): $error');
      }
      return;
    }

    await _sendToSentry(
      error,
      stack: stack,
      hint: hint,
      extra: extra,
      level: level,
    );
  }

  static Future<void> _sendToSentry(
    Object error, {
    StackTrace? stack,
    String? hint,
    Map<String, dynamic>? extra,
    SentryLevel level = SentryLevel.error,
  }) async {
    try {
      await Sentry.captureException(
        error,
        stackTrace: stack,
        withScope: (scope) {
          scope.level = level;
          if (hint != null) {
            scope.setTag('handler', hint);
          }
          extra?.forEach((key, value) {
            scope.setExtra(key, value);
          });
        },
      );
    } catch (e) {
      if (kDebugMode) {
        appLog('[ErrorHandler] Sentry send failed: $e');
      }
    }
  }
}
