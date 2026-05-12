// A1 致命1 SSoT 化（distance_formatter）の unit test。
//
// docs/mvp_specs/A1_build30_integration.md §7 Unit テスト + DoD 5 サンプル。

import 'package:flutter_test/flutter_test.dart';
import 'package:wanwalk/utils/distance_formatter.dart';

void main() {
  group('formatDistance', () {
    test('境界値: 1000m 未満は XXXm', () {
      expect(formatDistance(0), '0m');
      expect(formatDistance(1), '1m');
      expect(formatDistance(667), '667m');
      expect(formatDistance(999), '999m');
    });

    test('境界値: 1000m 以上は X.Xkm', () {
      expect(formatDistance(1000), '1.0km');
      expect(formatDistance(1500), '1.5km');
      expect(formatDistance(10100), '10.1km');
    });

    test('CEO 確定 DoD 5 サンプル (2026-05-19)', () {
      // 雲場池 4,340m → "4.3km"
      expect(formatDistance(4340), '4.3km');
      // 浄蓮の滝 432m → "432m"
      expect(formatDistance(432), '432m');
      // 南ヶ丘牧場 632m → "632m"
      expect(formatDistance(632), '632m');
      // 桃源台ロープウェイ 10,112m → "10.1km"
      expect(formatDistance(10112), '10.1km');
      // 湘南平 3,657m → "3.7km"（標準四捨五入）
      expect(formatDistance(3657), '3.7km');
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

    test('正の値は formatDistance に委譲', () {
      expect(formatDistanceOrDash(432), '432m');
      expect(formatDistanceOrDash(4340), '4.3km');
    });
  });
}
