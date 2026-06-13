import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wanwalk/nav/nav_geometry.dart';

/// LAYER1_NAV_SPEC §2/§14 沿線距離エンジン幾何プリミティブの単体テスト。
void main() {
  // 東西に伸びる直線（緯度一定）。1点目を基準にメートル換算が素直になるよう低緯度を避け実緯度を使う。
  final base = LatLng(35.3000, 139.4000);
  // 約100mごとに東へ進む5点の直線（経度方向）。
  List<LatLng> eastLine(int n, double stepM) {
    final pts = <LatLng>[base];
    for (var i = 1; i < n; i++) {
      pts.add(offsetMeters(base, 0, stepM * i));
    }
    return pts;
  }

  group('haversineMeters', () {
    test('緯度1度 ≈ 111319m（半径定数 6378137 をピン留め）', () {
      // 許容を締めて半径定数の誤変更を検知する（赤道半径ベースの球面近似で約111319m）。
      final d = haversineMeters(LatLng(35.0, 139.0), LatLng(36.0, 139.0));
      expect(d, closeTo(111319, 40));
    });

    test('offsetMeters で作った100m差がhaversineで≈100m', () {
      final p2 = offsetMeters(base, 100, 0);
      expect(haversineMeters(base, p2), closeTo(100, 1.0));
      final p3 = offsetMeters(base, 0, 100);
      expect(haversineMeters(base, p3), closeTo(100, 1.0));
    });
  });

  group('projectPointOnSegment', () {
    test('線分上の点は perp≈0・t整合', () {
      final a = base;
      final b = offsetMeters(base, 0, 200);
      final mid = offsetMeters(base, 0, 100);
      final r = projectPointOnSegment(mid, a, b);
      expect(r.perpM, closeTo(0, 1.0));
      expect(r.t, closeTo(0.5, 0.02));
    });

    test('線分から30m北の点は perp≈30', () {
      final a = base;
      final b = offsetMeters(base, 0, 200);
      final off = offsetMeters(offsetMeters(base, 0, 100), 30, 0);
      final r = projectPointOnSegment(off, a, b);
      expect(r.perpM, closeTo(30, 1.5));
      expect(r.t, closeTo(0.5, 0.02));
    });

    test('端点の外側は t=0/1 にクランプ', () {
      final a = base;
      final b = offsetMeters(base, 0, 100);
      final before = offsetMeters(base, 0, -50);
      final after = offsetMeters(base, 0, 150);
      expect(projectPointOnSegment(before, a, b).t, 0.0);
      expect(projectPointOnSegment(after, a, b).t, 1.0);
    });
  });

  group('chainage', () {
    test('cumulativeChainage と lineLengthMeters が整合', () {
      final line = eastLine(5, 100);
      final cum = cumulativeChainage(line);
      expect(cum.length, 5);
      expect(cum.first, 0.0);
      expect(cum.last, closeTo(lineLengthMeters(line), 0.01));
      expect(cum.last, closeTo(400, 4)); // 100m×4
      // 単調増加
      for (var i = 1; i < cum.length; i++) {
        expect(cum[i], greaterThan(cum[i - 1]));
      }
    });

    test('projectToLine: 線上の点で chainage が一致', () {
      final line = eastLine(5, 100);
      final p = offsetMeters(base, 0, 250); // 起点から250m
      final proj = projectToLine(p, line);
      expect(proj.perpMeters, closeTo(0, 1.5));
      expect(proj.chainageMeters, closeTo(250, 3));
    });

    test('pointAtChainage ↔ projectToLine の往復', () {
      final line = eastLine(9, 50);
      final cum = cumulativeChainage(line);
      for (final c in [0.0, 75.0, 200.0, 399.0]) {
        final pt = pointAtChainage(line, c, cumChain: cum);
        final back = projectToLine(pt, line, cumChain: cum);
        expect(back.chainageMeters, closeTo(c, 2),
            reason: 'chainage $c roundtrip');
        expect(back.perpMeters, closeTo(0, 1.0));
      }
    });

    test('pointAtChainage は端でクランプ', () {
      final line = eastLine(5, 100);
      expect(pointAtChainage(line, -10), line.first);
      expect(pointAtChainage(line, 99999), line.last);
    });
  });

  group('projectToLineWindowed（往復近接の誤吸着防止）', () {
    test('out-and-back: 窓で復路レーンを選べる', () {
      // 東へ200m進んで同じ道を戻る out-and-back（往路と復路が空間的に重なる）。
      final outbound = [
        base,
        offsetMeters(base, 0, 100),
        offsetMeters(base, 0, 200),
      ];
      final back = [
        offsetMeters(base, 0, 100),
        base,
      ];
      final line = [...outbound, ...back]; // 0..200 往路, 200..400 復路
      final cum = cumulativeChainage(line);
      // 起点付近の点。全線投影では往路(≈0)が最近だが、窓を復路(300-400)に張ると復路を選ぶ。
      final p = offsetMeters(base, 2, 5);
      final full = projectToLine(p, line, cumChain: cum);
      expect(full.chainageMeters, lessThan(50)); // 往路に吸着
      final windowed =
          projectToLineWindowed(p, line, cum, 300, cum.last + 10);
      expect(windowed, isNotNull);
      expect(windowed!.chainageMeters, greaterThan(300)); // 復路を選択
    });

    test('線の範囲外の窓なら null（重なるセグメント無し）', () {
      final line = eastLine(5, 100); // 総延長 ≈ 400m
      final cum = cumulativeChainage(line);
      final p = offsetMeters(base, 0, 50);
      final windowed = projectToLineWindowed(p, line, cum, 500, 600); // 線の外
      expect(windowed, isNull);
    });
  });

  group('CoverageGrid', () {
    test('mark/markRange/coverage', () {
      final g = CoverageGrid(1000, cellMeters: 25); // 40 cells
      expect(g.cellCount, 40);
      expect(g.coverage(), 0.0);
      g.mark(10); // cell 0
      g.mark(30); // cell 1
      expect(g.visitedCount, 2);
      g.markRange(0, 500); // cells 0..20 → 21 cells
      expect(g.visitedCount, 21);
      expect(g.coverage(), closeTo(21 / 40, 0.001));
    });

    test('export/import bits 往復', () {
      final g = CoverageGrid(500, cellMeters: 25); // 20 cells
      g.markRange(0, 250);
      final bits = g.exportBits();
      final g2 = CoverageGrid(500, cellMeters: 25);
      g2.importBits(bits);
      expect(g2.coverage(), closeTo(g.coverage(), 0.0001));
    });

    test('markRange は from>to を入替（対称）', () {
      final a = CoverageGrid(500, cellMeters: 25);
      final b = CoverageGrid(500, cellMeters: 25);
      a.markRange(100, 300);
      b.markRange(300, 100);
      expect(b.visitedCount, a.visitedCount);
      expect(b.coverage(), closeTo(a.coverage(), 0.0001));
    });

    test('mark の負値はクランプ（cell 0）', () {
      final g = CoverageGrid(500, cellMeters: 25);
      g.mark(-100);
      expect(g.visitedCount, 1);
    });
  });

  group('退化入力ガード', () {
    test('連続重複頂点でも projectToLine が NaN/ゼロ除算しない', () {
      final dup = [base, base, offsetMeters(base, 0, 100), offsetMeters(base, 0, 100)];
      final proj = projectToLine(offsetMeters(base, 0, 50), dup);
      expect(proj.chainageMeters.isFinite, isTrue);
      expect(proj.perpMeters.isFinite, isTrue);
    });

    test('極近傍 offsetMeters は有限値（cosLatガード）', () {
      final nearPole = LatLng(89.9999, 139.0);
      final p = offsetMeters(nearPole, 0, 100);
      expect(p.latitude.isFinite, isTrue);
      expect(p.longitude.isFinite, isTrue);
    });

    test('ライン末端を越える点は chainage が total にクランプ', () {
      final line = eastLine(5, 100); // total ≈ 400
      final beyond = offsetMeters(base, 0, 600);
      final proj = projectToLine(beyond, line);
      expect(proj.chainageMeters, closeTo(400, 5));
    });
  });
}
