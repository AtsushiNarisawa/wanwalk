import 'package:flutter_test/flutter_test.dart';
import 'package:wanwalk/providers/home_feed_provider.dart';

/// A26: ホームフィードの並び替え + バランス調整（composeHomeFeed）の回帰テスト。
/// 「walkSummary 先頭」「ルート最大10件」「ルート2件ごとに非ルート1件」のルールを固定する。
void main() {
  FeedItem item(FeedItemType type, int day) =>
      FeedItem(type: type, sortDate: DateTime(2026, 5, day));

  group('composeHomeFeed', () {
    test('空入力は空を返す', () {
      expect(composeHomeFeed([]), isEmpty);
    });

    test('sortDate 降順（新しいものが先）', () {
      final out = composeHomeFeed([
        item(FeedItemType.officialRoute, 5),
        item(FeedItemType.officialRoute, 20),
        item(FeedItemType.officialRoute, 12),
      ]);
      expect(out.map((i) => i.sortDate.day).toList(), [20, 12, 5]);
    });

    test('walkSummary は（最古でも）先頭に固定', () {
      final out = composeHomeFeed([
        item(FeedItemType.officialRoute, 20),
        item(FeedItemType.walkSummary, 1),
      ]);
      expect(out.first.type, FeedItemType.walkSummary);
    });

    test('ルートは最大10件に制限', () {
      final many =
          List.generate(15, (i) => item(FeedItemType.officialRoute, i + 1));
      final out = composeHomeFeed(many);
      final routeCount =
          out.where((i) => i.type == FeedItemType.officialRoute).length;
      expect(routeCount, 10);
    });

    test('ルート2件ごとに非ルートを1件インターリーブ（R R P R R P）', () {
      final out = composeHomeFeed([
        item(FeedItemType.officialRoute, 10),
        item(FeedItemType.officialRoute, 9),
        item(FeedItemType.officialRoute, 8),
        item(FeedItemType.officialRoute, 7),
        item(FeedItemType.communityPin, 6),
        item(FeedItemType.communityPin, 5),
      ]);
      expect(out.map((i) => i.type).toList(), [
        FeedItemType.officialRoute,
        FeedItemType.officialRoute,
        FeedItemType.communityPin,
        FeedItemType.officialRoute,
        FeedItemType.officialRoute,
        FeedItemType.communityPin,
      ]);
    });

    test('seasonalRoute もルート枠として扱う', () {
      final out = composeHomeFeed([
        item(FeedItemType.seasonalRoute, 10),
        item(FeedItemType.seasonalRoute, 9),
        item(FeedItemType.areaFeature, 8),
      ]);
      // R R A の順
      expect(out.map((i) => i.type).toList(), [
        FeedItemType.seasonalRoute,
        FeedItemType.seasonalRoute,
        FeedItemType.areaFeature,
      ]);
    });

    test('入力リストを破壊しない（純粋関数）', () {
      final input = [
        item(FeedItemType.officialRoute, 5),
        item(FeedItemType.officialRoute, 20),
      ];
      final before = input.map((i) => i.sortDate.day).toList();
      composeHomeFeed(input);
      expect(input.map((i) => i.sortDate.day).toList(), before);
    });
  });
}
