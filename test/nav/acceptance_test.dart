import 'package:flutter_test/flutter_test.dart';
import 'package:wanwalk/nav/nav_geometry.dart';
import 'package:wanwalk/nav/route_nav_engine.dart';

import 'gps_replay.dart';
import 'nav_fixtures.dart';

/// LAYER1_NAV_SPEC §14.2 受け入れハーネス。
/// 全公開ルートを合成GPSで機械回しし、本実装 RouteNavEngine のナビ品質を計測する。
///
/// ★ ハーネス（合成GPS生成 + 全85ルート機械回し + 基準計測）と本実装エンジンが
///   `lib/nav/route_nav_engine.dart` を共有。§14.2 厳格基準（誤逸脱0/接近100%/偽完走0/
///   正常完走100%）が最終目標。難所＝往復/周回/自己重複ジオメトリ＋GPSノイズ（§2本丸）。
void main() {
  final routes = NavFixtures.load();
  final gen = GpsReplayGenerator(stepM: 5);

  test('fixture が 85 ルート読めている', () {
    expect(routes.length, greaterThanOrEqualTo(80));
    expect(routes.every((r) => r.points.length >= 2), isTrue);
  });

  List<NavSpot> toNavSpots(NavFixtureRoute r) {
    final out = <NavSpot>[];
    for (var i = 0; i < r.spots.length; i++) {
      final s = r.spots[i];
      out.add(NavSpot(
        id: 's$i',
        name: s.name,
        distanceFromStart: s.distanceFromStart,
        category: s.category,
      ));
    }
    return out;
  }

  NavState runEngine(NavFixtureRoute r, List<ReplayFix> fixes) {
    final eng = RouteNavEngine(r.points, toNavSpots(r));
    for (final f in fixes) {
      eng.processFix(NavFix(
        position: f.position,
        accuracyM: f.accuracyM,
        tMillis: f.tMillis,
        moving: f.moving,
      ));
    }
    return eng.state;
  }

  int eligibleTargets(NavFixtureRoute r) {
    final total = lineLengthMeters(r.points);
    return r.spots
        .where((s) =>
            s.isApproachTarget &&
            s.distanceFromStart != null &&
            s.distanceFromStart! >= 0 &&
            s.distanceFromStart! <= total + 2)
        .length;
  }

  test('§14.2 計測レポート（全85ルート×8パターン・本実装 RouteNavEngine）', () {
    final n = routes.length;
    int normalComplete = 0, normalNoDeviation = 0, approachPerfect = 0;
    int noisyNoDeviation = 0;
    int degradedComplete = 0, degradedNoDeviation = 0;
    int stationaryComplete = 0, stationaryNoDeviation = 0;
    int reverseComplete = 0;
    int shortcutNoFalseComplete = 0;
    int midJoinNoFalseComplete = 0;
    int carSuspended = 0, carKeepsComplete = 0;
    int totalApproachFired = 0, totalApproachEligible = 0;
    final hardRoutes = <String>{};

    int gate(bool ok, String slug) {
      if (!ok) hardRoutes.add(slug);
      return ok ? 1 : 0;
    }

    for (var i = 0; i < n; i++) {
      final r = routes[i];
      final tgt = eligibleTargets(r);
      totalApproachEligible += tgt;

      final normal = runEngine(r, gen.generate(r.points, ReplayPattern.normal, seed: i));
      normalComplete += gate(normal.isCompleted, r.slug);
      normalNoDeviation += gate(normal.offRouteEvents == 0, r.slug);
      totalApproachFired += normal.firedApproachSpotIds.length;
      approachPerfect += gate(normal.firedApproachSpotIds.length == tgt, r.slug);

      final noisy = runEngine(r, gen.generate(r.points, ReplayPattern.noisy, seed: 100 + i));
      noisyNoDeviation += gate(noisy.offRouteEvents == 0, r.slug);

      final degraded = runEngine(r, gen.generate(r.points, ReplayPattern.accuracyDegraded, seed: 200 + i));
      degradedComplete += gate(degraded.isCompleted, r.slug);
      degradedNoDeviation += gate(degraded.offRouteEvents == 0, r.slug);

      final stationary = runEngine(r, gen.generate(r.points, ReplayPattern.stationary, seed: 300 + i));
      stationaryComplete += gate(stationary.isCompleted, r.slug);
      stationaryNoDeviation += gate(stationary.offRouteEvents == 0, r.slug);

      final reverse = runEngine(r, gen.generate(r.points, ReplayPattern.reverse, seed: 600 + i));
      reverseComplete += gate(reverse.isCompleted, r.slug);

      final shortcut = runEngine(r, gen.generate(r.points, ReplayPattern.shortcut, seed: 400 + i));
      shortcutNoFalseComplete += gate(!shortcut.isCompleted, r.slug);

      final midJoin = runEngine(r, gen.generate(r.points, ReplayPattern.midJoin, seed: 500 + i));
      midJoinNoFalseComplete += gate(!midJoin.isCompleted, r.slug);

      final car = runEngine(r, gen.generate(r.points, ReplayPattern.carDeparture, seed: 700 + i));
      carSuspended += gate(car.suspended, r.slug);
      if (car.isCompleted) carKeepsComplete++;
    }

    String pc(int v) => '$v/$n (${(v * 100 / n).round()}%)';
    // ignore: avoid_print
    print('''
================= §14.2 ナビ受け入れ 計測（本実装 RouteNavEngine） =================
対象: $n ルート × 8 パターン

[正常 normal]   完走:${pc(normalComplete)} / 誤逸脱0:${pc(normalNoDeviation)} / 接近100%:${pc(approachPerfect)} (総数$totalApproachFired/$totalApproachEligible)
[noisy]         誤逸脱0:${pc(noisyNoDeviation)}
[degraded渓谷]  完走:${pc(degradedComplete)} / 誤逸脱0:${pc(degradedNoDeviation)}
[stationary]    完走:${pc(stationaryComplete)} / 誤逸脱0:${pc(stationaryNoDeviation)}
[reverse]       完走:${pc(reverseComplete)}
[shortcut]      偽完走回避:${pc(shortcutNoFalseComplete)}  （厳格目標100%）
[midJoin]       偽完走回避:${pc(midJoinNoFalseComplete)}
[carDeparture]  サスペンド:${pc(carSuspended)} / 完走維持:${pc(carKeepsComplete)}
難所(いずれか外す):${hardRoutes.length}/$n  → 往復/周回/重複ジオメトリ中心（§2本丸）。厳格目標 §14.2。
================================================================================
''');

    // 回帰検知ゲート（厳格§14.2は最終目標。実測ベースライン直下に個別下限）。
    //
    // ★ 2026-06-20 再ベースライン（折り返しルート偽完走バグ修正に伴う）:
    //   従来 `_finalizeInit` が往復(非simple)ルートの起点二義性で chainage 0↔total に振動した
    //   init fix を markRange で繋ぎ、起点でカバレッジ全区画を true 化していた。これが「散歩開始
    //   直後に偽完走」の表バグであると同時に、ハードGPS（渓谷の再捕捉失敗・逆回り loop）の
    //   完走数を水増しする裏作用も持っていた。修正でカバレッジが正直になった結果:
    //     - shortcut/midJoin 偽完走回避: 56→85 / 80→85（=100%。バグの主指標。**上げてロック**）
    //     - normal 完走 80→81・誤逸脱0 66→79・接近100% 76→82（改善。基礎追従の回帰なし）
    //     - degraded 完走 54→38・reverse 完走 80→62（水増しの剥落。診断で「normal は全ルート完走」
    //       =基礎追従は健全、渓谷再捕捉/逆回り loop のカバレッジ補間が §14.2「難所」の既知 follow-up
    //       であることを確認。floor を実測直下へ正直に下げる）
    expect(normalComplete, greaterThanOrEqualTo((n * 0.88).floor()), reason: '正常完走 回帰');
    expect(normalNoDeviation, greaterThanOrEqualTo((n * 0.85).floor()), reason: 'normal誤逸脱 増');
    expect(approachPerfect, greaterThanOrEqualTo((n * 0.90).floor()), reason: '接近100% 回帰');
    expect(noisyNoDeviation, greaterThanOrEqualTo((n * 0.97).floor()), reason: 'noisy誤逸脱 増');
    expect(degradedComplete, greaterThanOrEqualTo((n * 0.40).floor()), reason: 'degraded完走 回帰');
    expect(degradedNoDeviation, greaterThanOrEqualTo((n * 0.72).floor()), reason: 'degraded誤逸脱 増');
    expect(stationaryNoDeviation, greaterThanOrEqualTo((n * 0.80).floor()), reason: 'stationary誤逸脱 増');
    expect(reverseComplete, greaterThanOrEqualTo((n * 0.68).floor()), reason: 'reverse完走 回帰');
    // ★ バグ修正をロック: 起点フラッディング再発で偽完走回避は 56/80 へ崩落するため 0.98 で締める。
    expect(shortcutNoFalseComplete, greaterThanOrEqualTo((n * 0.98).floor()), reason: 'shortcut偽完走 増（init フラッディング再発）');
    expect(midJoinNoFalseComplete, greaterThanOrEqualTo((n * 0.98).floor()), reason: 'midJoin偽完走 増（init フラッディング再発）');
    expect(carSuspended, greaterThanOrEqualTo((n * 0.95).floor()), reason: '車発進サスペンド 回帰');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
