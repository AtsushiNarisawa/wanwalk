import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wanwalk/nav/route_nav_engine.dart';
import 'package:wanwalk/nav/nav_geometry.dart';

/// LAYER1_NAV_SPEC §11 walk_spot_visits の集計（最接近距離 / 滞在 / 重複排除）と
/// §10 NavParams.fromMap（リモート閾値のパース）の単体テスト。
void main() {
  // 東西の直線ルート（lat35.0・経度 +0.001 ≈ 91m/区間・11点 ≈ 910m）。
  List<LatLng> straightLine() => [
        for (var i = 0; i < 11; i++) LatLng(35.0, 139.0 + 0.001 * i),
      ];
  final total = lineLengthMeters(straightLine());
  final cum = cumulativeChainage(straightLine());

  // 線上の chainage 位置に置いたスポット（実座標 location 付き）。
  NavSpot spotOnLine(String id, double chainage, {String category = 'viewpoint'}) =>
      NavSpot(
        id: id,
        name: id,
        distanceFromStart: chainage.round(),
        category: category,
        location: pointAtChainage(straightLine(), chainage, cumChain: cum),
      );

  // 線に沿って一定間隔の good fix を流す（dtMs=3000 ≈ 1.67m/s=6km/h・サスペンド閾値12km/h未満）。
  void walkAlong(RouteNavEngine e, {double stepM = 5, int dtMs = 3000}) {
    final line = straightLine();
    var t = 0;
    for (var c = 0.0; c <= total; c += stepM) {
      e.processFix(NavFix(
        position: pointAtChainage(line, c, cumChain: cum),
        accuracyM: 6,
        tMillis: t,
        moving: true,
      ));
      t += dtMs;
    }
  }

  group('walk_spot_visits 集計', () {
    test('線上スポットを通過すると立寄りが成立し最接近距離は小さい（utilityも記録）', () {
      final spots = [
        spotOnLine('mid', total * 0.5),
        spotOnLine('goal', total, category: 'park'),
        spotOnLine('park0', 0, category: 'parking'),
      ];
      final e = RouteNavEngine(straightLine(), spots);
      walkAlong(e);
      final visits = e.collectVisits();
      final ids = visits.map((v) => v.routeSpotId).toSet();
      expect(ids.contains('mid'), isTrue);
      expect(ids.contains('goal'), isTrue);
      expect(ids.contains('park0'), isTrue,
          reason: 'utility(parking) も記録対象（§11・カード/通知は出さない）');
      for (final v in visits) {
        expect(v.minDistanceM, isNotNull);
        expect(v.minDistanceM!, lessThanOrEqualTo(40),
            reason: '線上スポットは通過時 visitRadius(40m) 内');
      }
    });

    test('ルートから離れた(>visitRadius)スポットは立寄りにならない', () {
      // 線から北へ ~200m（緯度 +0.0018）オフセットした cafe。
      final far = NavSpot(
        id: 'far',
        name: 'far',
        distanceFromStart: (total * 0.5).round(),
        category: 'cafe',
        location: LatLng(35.0018, 139.0 + 0.001 * 5),
      );
      final e = RouteNavEngine(straightLine(), [far]);
      walkAlong(e);
      expect(e.collectVisits().any((v) => v.routeSpotId == 'far'), isFalse);
    });

    test('location 未設定スポットは立寄り対象外', () {
      final e = RouteNavEngine(straightLine(), [
        NavSpot(
            id: 'noloc',
            name: 'noloc',
            distanceFromStart: (total * 0.5).round(),
            category: 'viewpoint'),
      ]);
      walkAlong(e);
      expect(e.collectVisits(), isEmpty);
    });

    test('スポット付近に滞在すると dwell_sec が積算される', () {
      final mid = pointAtChainage(straightLine(), total * 0.5, cumChain: cum);
      final e = RouteNavEngine(straightLine(), [spotOnLine('mid', total * 0.5)]);
      // mid 直上に約10秒とどまる（1秒間隔で11 fix・匂い嗅ぎ=静止も計上対象）。
      var t = 0;
      for (var i = 0; i <= 10; i++) {
        e.processFix(NavFix(position: mid, accuracyM: 6, tMillis: t, moving: false));
        t += 1000;
      }
      final v = e.collectVisits().firstWhere((x) => x.routeSpotId == 'mid');
      expect(v.minDistanceM, lessThanOrEqualTo(2));
      expect(v.dwellSec, greaterThanOrEqualTo(9), reason: '約10秒の滞在を積算');
    });

    test('visitDwellGapSec を超える空白を挟む再通過は滞在に数えない（周回の重複排除）', () {
      final mid = pointAtChainage(straightLine(), total * 0.5, cumChain: cum);
      final e = RouteNavEngine(straightLine(), [spotOnLine('mid', total * 0.5)]);
      // 1回目: mid 直上 2 fix（t=0,1000）。
      e.processFix(NavFix(position: mid, accuracyM: 6, tMillis: 0, moving: true));
      e.processFix(NavFix(position: mid, accuracyM: 6, tMillis: 1000, moving: true));
      // gap(120s)超の空白後に戻る（t=1,000,000ms = 1000s後）。
      e.processFix(NavFix(position: mid, accuracyM: 6, tMillis: 1000000, moving: true));
      final visits = e.collectVisits().where((x) => x.routeSpotId == 'mid').toList();
      expect(visits.length, 1, reason: '同一スポットは1件に集約（周回再通過の重複排除）');
      expect(visits.first.dwellSec, lessThanOrEqualTo(2),
          reason: 'gap超の離脱時間は滞在に加算しない');
    });

    test('低精度fix(>35m)はスポット直上でも立寄り計上しない（精度ゲート・false visit防止）', () {
      final mid = pointAtChainage(straightLine(), total * 0.5, cumChain: cum);
      final e = RouteNavEngine(straightLine(), [spotOnLine('mid', total * 0.5)]);
      // 初期化用に起点付近を good fix（mid からは遠い）。
      for (var i = 0; i < 6; i++) {
        e.processFix(NavFix(
            position: pointAtChainage(straightLine(), 5.0 + i * 3, cumChain: cum),
            accuracyM: 6,
            tMillis: i * 1000,
            moving: true));
      }
      // mid 直上だが精度60m(>35m)の fix を複数 → 精度ゲートで計上されないべき。
      var t = 100000;
      for (var i = 0; i < 5; i++) {
        e.processFix(NavFix(position: mid, accuracyM: 60, tMillis: t, moving: true));
        t += 1000;
      }
      expect(e.collectVisits().any((v) => v.routeSpotId == 'mid'), isFalse,
          reason: '精度ゲート(>35m)を通らない fix は立寄りに計上しない（渓谷/樹林の系統誤差対策）');
    });

    test('半径外を挟む再通過は離脱時間を滞在に数えない（連続区間のみ積算）', () {
      final mid = pointAtChainage(straightLine(), total * 0.5, cumChain: cum);
      final far = LatLng(35.002, 139.0 + 0.001 * 5); // mid から ~220m 北（半径外）
      final e = RouteNavEngine(straightLine(), [spotOnLine('mid', total * 0.5)]);
      // 半径内(0) → 半径内(1s・連続なので+1s) → 半径外(2s) → 半径内(3s・離脱を挟むので+しない)
      e.processFix(NavFix(position: mid, accuracyM: 6, tMillis: 0, moving: true));
      e.processFix(NavFix(position: mid, accuracyM: 6, tMillis: 1000, moving: true));
      e.processFix(NavFix(position: far, accuracyM: 6, tMillis: 2000, moving: false));
      e.processFix(NavFix(position: mid, accuracyM: 6, tMillis: 3000, moving: false));
      final v = e.collectVisits().firstWhere((x) => x.routeSpotId == 'mid');
      expect(v.dwellSec, lessThanOrEqualTo(1),
          reason: '連続区間(0→1s)の1秒のみ。半径外を挟んだ2→3sは加算しない（旧実装は3s計上のバグ）');
    });
  });

  group('NavParams.fromMap', () {
    test('文字列/数値の両方をパースし、欠損キーは内蔵既定値にフォールバック', () {
      final p = NavParams.fromMap({
        'version': 7,
        'off_route_m': '60', // PostgREST が numeric を文字列で返すケース
        'complete_coverage': 0.75, // 数値で返るケース
        'visit_radius_m': '45',
        'off_route_notify_max': 3,
        // goal_radius_m / merge_m などは欠損 → 既定値
      });
      expect(p.version, 7);
      expect(p.offRouteM, 60);
      expect(p.completeCoverage, 0.75);
      expect(p.visitRadiusM, 45);
      expect(p.offRouteNotifyMax, 3);
      expect(p.goalRadiusM, 50, reason: '欠損は既定値');
      expect(p.mergeM, 130, reason: '欠損は既定値');
    });

    test('既定の const NavParams は version=1', () {
      expect(const NavParams().version, 1);
    });
  });
}
