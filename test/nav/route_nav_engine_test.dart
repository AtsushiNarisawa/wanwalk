import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wanwalk/nav/route_nav_engine.dart';
import 'package:wanwalk/nav/nav_geometry.dart';

import 'gps_replay.dart';

/// Build 42 本実装 RouteNavEngine のライブ API（NavState / NavCompletion）の単体テスト。
/// §14 ハーネス（acceptance）は全85ルートの精度を見る。ここは UI が読む値の正しさを見る。
void main() {
  // 東西に伸びる直線ルート（緯度35.0・経度 +0.001 ステップ ≈ 91m/区間・11点 ≈ 910m）。
  List<LatLng> straightLine() => [
        for (var i = 0; i < 11; i++) LatLng(35.0, 139.0 + 0.001 * i),
      ];

  // 直線の総延長（実測）。
  final total = lineLengthMeters(straightLine());

  // スポット: 起点(parking) / 中間(viewpoint) / 終点。dfs は沿線距離。
  List<NavSpot> spotsWithParkingAndViewpoint() => [
        NavSpot(id: 's0', name: '駐車場', distanceFromStart: 0, category: 'parking'),
        NavSpot(
            id: 's1',
            name: '見晴らし台',
            distanceFromStart: (total * 0.5).round(),
            category: 'viewpoint'),
        NavSpot(
            id: 's2',
            name: 'ゴール広場',
            distanceFromStart: total.round(),
            category: 'park'),
      ];

  test('正常歩行で完走判定・進捗100%・誤逸脱0', () {
    final line = straightLine();
    final gen = GpsReplayGenerator(stepM: 5);
    final fixes = gen.generate(line, ReplayPattern.normal, seed: 1);
    final engine = RouteNavEngine(line, spotsWithParkingAndViewpoint());
    for (final f in fixes) {
      engine.processFix(NavFix(
        position: f.position,
        accuracyM: f.accuracyM,
        tMillis: f.tMillis,
        moving: f.moving,
      ));
    }
    final s = engine.state;
    expect(s.ready, isTrue);
    expect(s.coveragePct, greaterThanOrEqualTo(0.8));
    expect(s.progressPct, greaterThan(0.9));
    expect(s.isCompleted, isTrue, reason: 'カバレッジ80%超かつゴール50m圏');
    expect(s.offRouteEvents, 0, reason: '直線・正常歩行で逸脱は出ない');
    expect(s.remainingMeters, lessThan(60));
  });

  test('起点で初期化後、次スポットは viewpoint・駐車場戻り距離が出る', () {
    final line = straightLine();
    final gen = GpsReplayGenerator(stepM: 5);
    final fixes = gen.generate(line, ReplayPattern.normal, seed: 2);
    final engine = RouteNavEngine(line, spotsWithParkingAndViewpoint());
    // 起点付近の最初の十数 fix だけ流す（中間スポットへ到達する前）。
    for (final f in fixes.take(12)) {
      engine.processFix(NavFix(
        position: f.position,
        accuracyM: f.accuracyM,
        tMillis: f.tMillis,
        moving: f.moving,
      ));
    }
    final s = engine.state;
    expect(s.ready, isTrue);
    expect(s.nextSpot?.name, '見晴らし台');
    // 次スポットまでの残りは ~総延長の半分（誤差許容）。
    expect(s.nextSpotRemainingMeters, isNotNull);
    expect(s.nextSpotRemainingMeters!, closeTo(total * 0.5, total * 0.25));
    // §7 駐車場（dfs=0）への戻り距離 ≈ 現在進捗（起点付近なので小さい）。
    expect(s.returnToParkingMeters, isNotNull);
    expect(s.returnToParkingMeters!, lessThan(total * 0.4));
  });

  test('駐車場スポットが無いルートでは returnToParkingMeters は null', () {
    final line = straightLine();
    final engine = RouteNavEngine(line, [
      NavSpot(
          id: 'v',
          name: '展望',
          distanceFromStart: (total * 0.5).round(),
          category: 'viewpoint'),
    ]);
    final gen = GpsReplayGenerator(stepM: 5);
    for (final f in gen.generate(line, ReplayPattern.normal, seed: 3).take(8)) {
      engine.processFix(NavFix(
        position: f.position,
        accuracyM: f.accuracyM,
        tMillis: f.tMillis,
        moving: f.moving,
      ));
    }
    expect(engine.state.returnToParkingMeters, isNull);
  });

  test('散歩後の車発進でサスペンドする', () {
    final line = straightLine();
    final gen = GpsReplayGenerator(stepM: 5);
    final fixes = gen.generate(line, ReplayPattern.carDeparture, seed: 4);
    final engine = RouteNavEngine(line, spotsWithParkingAndViewpoint());
    for (final f in fixes) {
      engine.processFix(NavFix(
        position: f.position,
        accuracyM: f.accuracyM,
        tMillis: f.tMillis,
        moving: f.moving,
      ));
    }
    expect(engine.state.suspended, isTrue);
  });

  test('接近対象スポットが全て発火する（直線・正常歩行）', () {
    final line = straightLine();
    final gen = GpsReplayGenerator(stepM: 5);
    final fixes = gen.generate(line, ReplayPattern.normal, seed: 5);
    final fired = <String>{};
    final engine = RouteNavEngine(
      line,
      spotsWithParkingAndViewpoint(),
      onApproach: (e) => fired.add(e.spot.id),
    );
    for (final f in fixes) {
      engine.processFix(NavFix(
        position: f.position,
        accuracyM: f.accuracyM,
        tMillis: f.tMillis,
        moving: f.moving,
      ));
    }
    // viewpoint(s1) と park(s2) は接近対象。parking(s0) は対象外。
    expect(fired.contains('s1'), isTrue);
    expect(fired.contains('s2'), isTrue);
    expect(fired.contains('s0'), isFalse, reason: 'parking は接近ガイド対象外');
  });

  test('NavCompletion.fromState が生値を丸めて構築する', () {
    final line = straightLine();
    final gen = GpsReplayGenerator(stepM: 5);
    final fixes = gen.generate(line, ReplayPattern.normal, seed: 6);
    final engine = RouteNavEngine(line, spotsWithParkingAndViewpoint());
    for (final f in fixes) {
      engine.processFix(NavFix(
        position: f.position,
        accuracyM: f.accuracyM,
        tMillis: f.tMillis,
        moving: f.moving,
      ));
    }
    final c = NavCompletion.fromState(engine.state);
    expect(c.isRouteCompleted, isTrue);
    expect(c.coveragePct, inInclusiveRange(0.0, 1.0));
    expect(c.maxProgressPct, inInclusiveRange(0.0, 1.0));
    expect(c.minGoalDistanceM, isNotNull);
    expect(c.minGoalDistanceM!, lessThanOrEqualTo(50));
  });

  test('低精度fix(>35m)は committed を動かさずカバレッジのみ塗る', () {
    final line = straightLine();
    final cum = cumulativeChainage(line);
    final engine = RouteNavEngine(line, const []);
    // 起点付近の good fix を initConfirm 回流して初期化。
    for (var i = 0; i < 6; i++) {
      engine.processFix(NavFix(
        position: pointAtChainage(line, 10.0 + i * 5, cumChain: cum),
        accuracyM: 8,
        tMillis: i * 1000,
        moving: true,
      ));
    }
    final before = engine.state.chainageMeters;
    // 精度劣化 fix（accuracy 60m）を1つ。committed は据え置かれるべき。
    engine.processFix(NavFix(
      position: pointAtChainage(line, total * 0.7, cumChain: cum),
      accuracyM: 60,
      tMillis: 10000,
      moving: true,
    ));
    expect(engine.state.chainageMeters, before,
        reason: '低精度fixは進捗(committed)を更新しない（§2 精度ゲート）');
  });
}
