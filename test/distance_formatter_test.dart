// 距離表記 SSoT（distance_formatter）の unit test。
//
// Cross 統一 B案（DESIGN_TOKENS.md §9 / 2026-06-02 CEO 確定）:
// ルート総距離は km 統一・小数第1位（1km 未満も "0.4km"）。

import 'package:flutter_test/flutter_test.dart';
import 'package:wanwalk/utils/distance_formatter.dart';

void main() {
  group('formatDistance（km 統一・B案）', () {
    test('1km 未満も km・小数第1位', () {
      expect(formatDistance(432), '0.4km'); // 浄蓮の滝
      expect(formatDistance(632), '0.6km'); // 南ヶ丘牧場
      expect(formatDistance(920), '0.9km'); // 宮城野桜
      expect(formatDistance(1), '0.0km');
    });

    test('境界値: 1km 付近', () {
      expect(formatDistance(950), '0.9km'); // 0.95 → 0.9（標準四捨五入）
      expect(formatDistance(999), '1.0km'); // 0.999 → 1.0
      expect(formatDistance(1000), '1.0km');
    });

    test('1km 以上は従来どおり小数第1位 km（B案でも不変）', () {
      expect(formatDistance(1500), '1.5km');
      expect(formatDistance(4340), '4.3km'); // 雲場池
      expect(formatDistance(3657), '3.7km'); // 湘南平（標準四捨五入）
      expect(formatDistance(10100), '10.1km');
      expect(formatDistance(10112), '10.1km'); // 桃源台ロープウェイ
    });

    test('四捨五入の振る舞い (Dart toStringAsFixed)', () {
      expect(formatDistance(1049), '1.0km'); // 1.049 → 1.0
      expect(formatDistance(1050), '1.1km'); // 1.050 → 1.1（半数 round up）
      expect(formatDistance(1099), '1.1km');
    });
  });

  group('formatDistanceOrDash', () {
    test('null は dash', () {
      expect(formatDistanceOrDash(null), '—');
    });

    test('0 以下は dash', () {
      expect(formatDistanceOrDash(0), '—');
      expect(formatDistanceOrDash(-1), '—');
    });

    test('正の値は formatDistance に委譲（km 統一）', () {
      expect(formatDistanceOrDash(432), '0.4km');
      expect(formatDistanceOrDash(4340), '4.3km');
    });
  });
}
