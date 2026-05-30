import 'package:sentry_flutter/sentry_flutter.dart';

/// A15: Sentry へ送信する前に PII を伏字へ置換するスクラバ。
///
/// アプリ自身が積む payload（不具合報告 ReportIssue の自由記述が乗る extra['description']・
/// 例外メッセージ・breadcrumb・その他 extra 値）を一律 redact し、
/// ReportIssue UI の「メールアドレスや位置情報は含まれません」表記と実装を整合させる。
/// （例外オブジェクト _UserReport.toString() 自体は len のみで PII レス。本文は extra に乗る）
///
/// `SentryFlutter.init` の `beforeSend` から [scrubSentryEvent] を呼ぶ。
/// SDK の `sendDefaultPii=false` で native 自動付与（IP/user）は無いが、
/// 自由記述に手入力された email/電話/氏名/座標は素通りするため beforeSend で防御する。
///
/// 設計方針: スタックトレースのフレームは PII でなくデバッグ価値が高いため触らない。
/// redact 対象は「人が入力しうるテキスト」= message / extra 値 / breadcrumb / exception.value のみ。

/// 文字列向けの伏字パターン群（[REDACTED] へ置換）。
final List<RegExp> _redactPatterns = [
  // email
  RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'),
  // JWT（Supabase access_token 等。eyJ... の3セグメント）
  RegExp(r'eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+'),
  // Bearer トークン
  RegExp(r'[Bb]earer\s+[A-Za-z0-9._\-]+'),
  // access_token / refresh_token = ... or : ...
  RegExp(r'(access|refresh)_?token["' "'" r']?\s*[:=]\s*["' "'" r']?[\w.\-]+',
      caseSensitive: false),
  // 日本の電話番号（+81 もしくは 0 始まり・区切り任意・計 9〜11 桁相当）
  RegExp(r'(?:\+81|0)\d{1,4}[-\s]?\d{1,4}[-\s]?\d{3,4}'),
];

/// 緯度経度らしき高精度小数（小数第4位以上）。[GEO] へ置換。
final RegExp _geoPattern = RegExp(r'-?\d{1,3}\.\d{4,}');

/// 文字列中の PII を伏字へ置換する。
String redactPii(String input) {
  if (input.isEmpty) return input;
  var out = input;
  for (final p in _redactPatterns) {
    out = out.replaceAll(p, '[REDACTED]');
  }
  out = out.replaceAll(_geoPattern, '[GEO]');
  return out;
}

/// 任意の値（String / Map / List / その他）を再帰的に redact する。
/// [depth] 循環参照・過深ネストによる StackOverflow を防ぐ深度ガード。
dynamic _scrubValue(dynamic value, [int depth = 0]) {
  if (depth > 8) return '[REDACTED:deep]';
  if (value is String) return redactPii(value);
  if (value is Map) {
    return value.map((k, v) => MapEntry(k, _scrubValue(v, depth + 1)));
  }
  if (value is List) {
    return value.map((e) => _scrubValue(e, depth + 1)).toList();
  }
  return value;
}

Map<String, dynamic>? _scrubMap(Map<String, dynamic>? input) {
  if (input == null) return null;
  return input.map((k, v) => MapEntry(k, _scrubValue(v)));
}

SentryMessage? _scrubMessage(SentryMessage? message) {
  if (message == null) return null;
  return SentryMessage(
    redactPii(message.formatted),
    template: message.template,
    params: message.params?.map(_scrubValue).toList(),
  );
}

/// `beforeSend` 用。SentryEvent の人手入力経路を redact して返す。
///
/// `copyWith` は全フィールド `?? this.x` のため、scrub 済みの非 null 値を渡した
/// フィールドだけが置換される（user は常に null = setUser 未使用なので対象外）。
///
/// 重要: sentry 8.x は beforeSend が throw しても event を drop せず「未 redact の
/// 原本」を送信してしまう。よって scrub が万一失敗しても PII 漏洩しないよう
/// try/catch でラップし、失敗時はリスクフィールドを一律伏字化した安全イベントを返す。
SentryEvent scrubSentryEvent(SentryEvent event) {
  try {
    return event.copyWith(
      message: _scrubMessage(event.message),
      // ignore: deprecated_member_use
      extra: _scrubMap(event.extra),
      breadcrumbs: event.breadcrumbs
          ?.map((b) => b.copyWith(
                message: b.message == null ? null : redactPii(b.message!),
                data: _scrubMap(b.data),
              ))
          .toList(),
      exceptions: event.exceptions
          ?.map((e) =>
              e.value == null ? e : e.copyWith(value: redactPii(e.value!)))
          .toList(),
    );
  } catch (_) {
    return _redactedFallback(event);
  }
}

/// scrub が例外を投げた場合のフォールバック。
/// 人手入力が乗りうるフィールドを一律伏字化（再帰しない＝再 throw しない）。
SentryEvent _redactedFallback(SentryEvent event) {
  return event.copyWith(
    message: const SentryMessage('[REDACTED]'),
    // ignore: deprecated_member_use
    extra: <String, dynamic>{'scrub': 'failed_redacted'},
    breadcrumbs: <Breadcrumb>[],
    exceptions: event.exceptions
        ?.map((e) => e.value == null ? e : e.copyWith(value: '[REDACTED]'))
        .toList(),
  );
}
