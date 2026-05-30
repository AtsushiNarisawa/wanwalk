import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wanwalk/utils/pii_scrubber.dart';

/// A15: PII スクラバの回帰テスト。
/// 正規表現は将来の調整で「過少マッチ＝PII 漏洩」方向に壊れるリスクがあるため固定する。
void main() {
  group('redactPii', () {
    test('email を伏字化', () {
      expect(redactPii('連絡先 narisawa@dog-hub.shop です'),
          isNot(contains('narisawa@dog-hub.shop')));
      expect(redactPii('a.b+c@example.co.jp'), contains('[REDACTED]'));
    });

    test('JWT / Bearer / access_token を伏字化', () {
      expect(
          redactPii(
              'token eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.abcDEF_-123'),
          isNot(contains('eyJhbGci')));
      expect(redactPii('Authorization: Bearer sk_live_abc.def-123'),
          isNot(contains('sk_live_abc')));
      expect(redactPii('access_token=ya29.aBcD.eFgH'),
          isNot(contains('ya29')));
    });

    test('電話番号を伏字化', () {
      expect(redactPii('TEL 090-1234-5678'), isNot(contains('090-1234-5678')));
      expect(redactPii('09012345678'), contains('[REDACTED]'));
    });

    test('緯度経度を伏字化', () {
      final out = redactPii('現在地 35.4361, 139.6380');
      expect(out, isNot(contains('35.4361')));
      expect(out, isNot(contains('139.6380')));
    });

    test('バージョン番号・エラーコードは誤って redact しない', () {
      expect(redactPii('アプリ 1.1.2 ビルド36 エラー 404'),
          equals('アプリ 1.1.2 ビルド36 エラー 404'));
      expect(redactPii('index 5 not in 0..120'),
          equals('index 5 not in 0..120'));
    });

    test('空文字は素通し', () {
      expect(redactPii(''), equals(''));
    });
  });

  group('scrubSentryEvent', () {
    test('extra の自由記述（不具合報告本文）を伏字化', () {
      final event = SentryEvent(
        message: SentryMessage('連絡 a@b.co'),
        // ignore: deprecated_member_use
        extra: {'description': 'メール a@b.co と電話 090-1234-5678'},
      );
      final scrubbed = scrubSentryEvent(event);
      // ignore: deprecated_member_use
      final desc = scrubbed.extra?['description'] as String;
      expect(desc, isNot(contains('a@b.co')));
      expect(desc, isNot(contains('090-1234-5678')));
      expect(scrubbed.message?.formatted, isNot(contains('a@b.co')));
    });

    test('null フィールドのイベントでも例外を投げない', () {
      final event = SentryEvent();
      expect(() => scrubSentryEvent(event), returnsNormally);
    });

    test('循環参照を含む extra でも StackOverflow せず安全に返す（再帰ガード）', () {
      final cyclic = <String, dynamic>{};
      cyclic['self'] = cyclic; // 自己参照
      final event = SentryEvent(
        // ignore: deprecated_member_use
        extra: {'loop': cyclic, 'mail': 'a@b.co'},
      );
      // 深度ガード or try/catch フォールバックで必ず非例外で返ること
      expect(() => scrubSentryEvent(event), returnsNormally);
    });
  });
}
