import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry 初期化前に発生した例外を一時保持するバッファ。
///
/// `main()` の極初期（dotenv 読込・Supabase 初期化前）に発生した例外も拾い、
/// Sentry が立ち上がり次第 flush して送信する。
///
/// メモリのみで保持。再起動を跨いだ永続化は MVP では行わない
/// （オフライン flush は Sentry SDK 内部キューに委ねる）。
class ErrorBuffer {
  ErrorBuffer._();

  static const int _maxItems = 50;
  static final Queue<PendingError> _queue = Queue<PendingError>();

  static void add(PendingError event) {
    if (_queue.length >= _maxItems) {
      _queue.removeFirst();
    }
    _queue.addLast(event);
  }

  static int get length => _queue.length;

  /// バッファ内のイベントを順次送信する。送信に成功したかは問わない（fire-and-forget）。
  static Future<void> flushTo(
    Future<void> Function(
      Object error, {
      StackTrace? stack,
      String? hint,
      Map<String, dynamic>? extra,
      SentryLevel level,
    }) sender,
  ) async {
    if (_queue.isEmpty) return;
    if (kDebugMode) {
      // ignore: avoid_print
      print('[ErrorBuffer] flushing ${_queue.length} pending events');
    }
    while (_queue.isNotEmpty) {
      final pending = _queue.removeFirst();
      await sender(
        pending.error,
        stack: pending.stack,
        hint: pending.hint,
        extra: pending.extra,
        level: pending.level,
      );
    }
  }
}

class PendingError {
  PendingError({
    required this.error,
    this.stack,
    this.hint,
    this.extra,
    this.level = SentryLevel.error,
  });

  final Object error;
  final StackTrace? stack;
  final String? hint;
  final Map<String, dynamic>? extra;
  final SentryLevel level;
}
