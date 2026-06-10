import 'package:flutter_test/flutter_test.dart';
import 'package:wanwalk/services/deep_link_service.dart';

/// A2 Universal Links の URL 解析・重複判定・ログパス正規化（純粋関数）の単体テスト。
/// 設計書: docs/mvp_specs/A2_universal_links.md §7.5
void main() {
  group('parseDeepLink', () {
    test('ルートパス（/）はホーム', () {
      expect(
        parseDeepLink(Uri.parse('https://wanwalk.jp/')).type,
        DeepLinkType.home,
      );
    });

    test('ホスト名のみ（パス無し）もホーム', () {
      expect(
        parseDeepLink(Uri.parse('https://wanwalk.jp')).type,
        DeepLinkType.home,
      );
    });

    test('/routes/{slug} は routeSlug を抽出', () {
      final t =
          parseDeepLink(Uri.parse('https://wanwalk.jp/routes/hakone-sengokuhara-susuki'));
      expect(t.type, DeepLinkType.routeSlug);
      expect(t.slug, 'hakone-sengokuhara-susuki');
    });

    test('クエリ付きでも slug を抽出', () {
      final t = parseDeepLink(
          Uri.parse('https://wanwalk.jp/routes/foo?utm_source=line&utm_medium=share'));
      expect(t.type, DeepLinkType.routeSlug);
      expect(t.slug, 'foo');
    });

    test('末尾スラッシュ付き slug も抽出', () {
      final t = parseDeepLink(Uri.parse('https://wanwalk.jp/routes/foo/'));
      expect(t.type, DeepLinkType.routeSlug);
      expect(t.slug, 'foo');
    });

    test('/routes（slug 無し）は unsupported', () {
      expect(
        parseDeepLink(Uri.parse('https://wanwalk.jp/routes')).type,
        DeepLinkType.unsupported,
      );
    });

    test('/areas・/spots・/about は unsupported（Web フォールバック）', () {
      expect(parseDeepLink(Uri.parse('https://wanwalk.jp/areas/hakone')).type,
          DeepLinkType.unsupported);
      expect(parseDeepLink(Uri.parse('https://wanwalk.jp/spots/foo')).type,
          DeepLinkType.unsupported);
      expect(parseDeepLink(Uri.parse('https://wanwalk.jp/about')).type,
          DeepLinkType.unsupported);
    });

    test('www. サブドメインも許可', () {
      expect(
        parseDeepLink(Uri.parse('https://www.wanwalk.jp/routes/foo')).type,
        DeepLinkType.routeSlug,
      );
    });

    test('想定外ホストは unsupported', () {
      expect(
        parseDeepLink(Uri.parse('https://example.com/routes/foo')).type,
        DeepLinkType.unsupported,
      );
    });
  });

  group('isDuplicateDeepLink', () {
    final uri = Uri.parse('https://wanwalk.jp/routes/foo');
    final base = DateTime(2026, 6, 10, 12, 0, 0);

    test('lastUri 無し（初回）は重複でない', () {
      expect(
        isDuplicateDeepLink(
            incoming: uri, lastUri: null, lastAt: null, now: base),
        isFalse,
      );
    });

    test('同一 URL・2 秒以内は重複', () {
      expect(
        isDuplicateDeepLink(
          incoming: uri,
          lastUri: uri,
          lastAt: base,
          now: base.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    test('同一 URL・2 秒以降は重複でない', () {
      expect(
        isDuplicateDeepLink(
          incoming: uri,
          lastUri: uri,
          lastAt: base,
          now: base.add(const Duration(seconds: 3)),
        ),
        isFalse,
      );
    });

    test('別 URL は重複でない', () {
      final other = Uri.parse('https://wanwalk.jp/routes/bar');
      expect(
        isDuplicateDeepLink(
          incoming: other,
          lastUri: uri,
          lastAt: base,
          now: base.add(const Duration(milliseconds: 100)),
        ),
        isFalse,
      );
    });
  });

  group('deepLinkLogPath', () {
    test('ルートはスラッグを伏せて :slug に正規化', () {
      expect(deepLinkLogPath(Uri.parse('https://wanwalk.jp/routes/abc-def')),
          '/routes/:slug');
    });
    test('ホームは /', () {
      expect(deepLinkLogPath(Uri.parse('https://wanwalk.jp/')), '/');
    });
    test('その他は先頭セグメント', () {
      expect(deepLinkLogPath(Uri.parse('https://wanwalk.jp/areas/hakone')),
          '/areas');
    });
  });
}
