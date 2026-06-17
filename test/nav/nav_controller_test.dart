import 'package:flutter_test/flutter_test.dart';
import 'package:wanwalk/nav/route_nav_engine.dart';
import 'package:wanwalk/providers/nav_controller_provider.dart';

import 'gps_replay.dart';
import 'nav_fixtures.dart';

/// NavController（Provider 配線）の単体検証。エンジン品質は acceptance_test が担保するので、
/// ここでは「feed→エンジン→NavState 反映」「configure 前は無反応」「reset で空」を確認。
void main() {
  final routes = NavFixtures.load();
  // 単調な線形ルートを1本選ぶ（往復/周回でない＝配線検証に素直）。
  final r = routes.firstWhere((x) => x.slug == 'tokyo-tamagawa-riverside-walk',
      orElse: () => routes.first);
  final gen = GpsReplayGenerator(stepM: 5);

  List<NavSpot> navSpots(NavFixtureRoute route) => [
        for (var i = 0; i < route.spots.length; i++)
          NavSpot(
            id: 's$i',
            name: route.spots[i].name,
            distanceFromStart: route.spots[i].distanceFromStart,
            category: route.spots[i].category,
          )
      ];

  test('configure 前の feed は無反応（state は empty）', () {
    final c = NavController();
    addTearDown(c.dispose);
    c.feed(NavFix(position: r.points.first, accuracyM: 5, tMillis: 0));
    expect(c.state.ready, isFalse);
    expect(c.isReady, isFalse);
  });

  test('configure→feed で NavState が前進する', () {
    final c = NavController();
    addTearDown(c.dispose);
    c.configure(line: r.points, spots: navSpots(r));
    final fixes = gen.generate(r.points, ReplayPattern.normal, seed: 1);
    for (final f in fixes) {
      c.feed(NavFix(
        position: f.position,
        accuracyM: f.accuracyM,
        tMillis: f.tMillis,
        moving: f.moving,
      ));
    }
    expect(c.state.ready, isTrue);
    expect(c.state.chainageMeters, greaterThan(0));
    expect(c.state.progressPct, greaterThan(0.5));
    expect(c.state.coveragePct, greaterThan(0.5));
    // tamagawa には接近対象スポットがあるので発火しているはず
    expect(c.state.firedApproachSpotIds, isNotEmpty);
    // 終端到達でゴール近接 → 完走の生値が取れる
    final completion = NavCompletion.fromState(c.state);
    expect(completion.maxProgressPct, greaterThan(0.5));
  });

  test('reset で空に戻る', () {
    final c = NavController();
    addTearDown(c.dispose);
    c.configure(line: r.points, spots: navSpots(r));
    c.feed(NavFix(position: r.points.first, accuracyM: 5, tMillis: 0));
    c.reset();
    expect(c.state.ready, isFalse);
    expect(c.isReady, isFalse);
  });

  test('§2: configure(restoreFrom) で kill 前の進捗を引き継いで再開する', () {
    // 1つ目のコントローラで途中まで歩いてスナップショットを取る。
    final a = NavController();
    addTearDown(a.dispose);
    a.configure(line: r.points, spots: navSpots(r));
    final fixes = gen.generate(r.points, ReplayPattern.normal, seed: 3);
    for (final f in fixes.take(fixes.length ~/ 2)) {
      a.feed(NavFix(
        position: f.position,
        accuracyM: f.accuracyM,
        tMillis: f.tMillis,
        moving: f.moving,
      ));
    }
    final snap = a.exportSnapshot();
    expect(snap, isNotNull);
    final beforeCoverage = a.state.coveragePct;
    expect(beforeCoverage, greaterThan(0));

    // 2つ目（= kill→復元相当）。restoreFrom で進捗を引き継いで ready で立ち上がる。
    final b = NavController();
    addTearDown(b.dispose);
    b.configure(
      line: r.points,
      spots: navSpots(r),
      restoreFrom: snap,
      restoreStartEpochMs: 1700000000000,
    );
    expect(b.state.ready, isTrue, reason: '取り込み成功で即 ready');
    expect(b.state.coveragePct, closeTo(beforeCoverage, 1e-9));
    expect(b.navStartEpochMs, 1700000000000, reason: 'nav 基準時刻も引き継ぐ');
  });
}
