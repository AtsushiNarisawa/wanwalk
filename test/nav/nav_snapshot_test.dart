import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wanwalk/nav/nav_geometry.dart';
import 'package:wanwalk/nav/route_nav_engine.dart';

import 'gps_replay.dart';

/// LAYER1_NAV_SPEC §2: kill→復元スナップショット v2 のエンジン部分（exportSnapshot /
/// importSnapshot）の単体検証。
///
/// 核心の主張は「中途参加でクラッシュ前カバレッジが消失し完走判定が控えめに出る」問題が
/// 解消されること。連続性テスト（feed前半→export→新エンジンimport→feed後半 が、全fixを
/// 連続投入したエンジンと一致する）でそれを機械実証する。
void main() {
  // 東西に伸びる直線ルート（≈91m/区間・11点 ≈ 910m）。route_nav_engine_test と同型。
  List<LatLng> straightLine() => [
        for (var i = 0; i < 11; i++) LatLng(35.0, 139.0 + 0.001 * i),
      ];
  final total = lineLengthMeters(straightLine());

  List<NavSpot> spots() => [
        NavSpot(id: 's0', name: '駐車場', distanceFromStart: 0, category: 'parking'),
        NavSpot(
            id: 's1',
            name: '見晴らし台',
            distanceFromStart: (total * 0.5).round(),
            category: 'viewpoint',
            location: pointAtChainage(straightLine(), total * 0.5)),
        NavSpot(
            id: 's2',
            name: 'ゴール広場',
            distanceFromStart: total.round(),
            category: 'park'),
      ];

  List<NavFix> fixesFor(ReplayPattern pattern, {int seed = 1}) {
    final gen = GpsReplayGenerator(stepM: 5);
    return [
      for (final f in gen.generate(straightLine(), pattern, seed: seed))
        NavFix(
          position: f.position,
          accuracyM: f.accuracyM,
          tMillis: f.tMillis,
          moving: f.moving,
        )
    ];
  }

  RouteNavEngine fed(List<NavFix> fixes) {
    final e = RouteNavEngine(straightLine(), spots());
    for (final f in fixes) {
      e.processFix(f);
    }
    return e;
  }

  test('未初期化（ready 前）の exportSnapshot は null', () {
    final e = RouteNavEngine(straightLine(), spots());
    // good fix が initConfirm 個に満たない段階では committed 未確定 = 復元対象外。
    e.processFix(NavFix(position: straightLine().first, accuracyM: 8, tMillis: 0));
    expect(e.state.ready, isFalse);
    expect(e.exportSnapshot(), isNull);
  });

  test('export→import 往復で持続状態（カバレッジ/進捗/方向/接近発火/立寄り）が一致', () {
    final fixes = fixesFor(ReplayPattern.normal);
    final a = fed(fixes);
    final snap = a.exportSnapshot();
    expect(snap, isNotNull);

    // 実ストア相当の JSON 経路（SharedPreferences の保存→読込）を挟む。
    final restored = NavEngineSnapshot.fromJson(
        jsonDecode(jsonEncode(snap!.toJson())) as Map<String, dynamic>);

    final b = RouteNavEngine(straightLine(), spots());
    expect(b.importSnapshot(restored), isTrue);

    final sa = a.state;
    final sb = b.state;
    expect(sb.ready, isTrue);
    expect(sb.coveragePct, closeTo(sa.coveragePct, 1e-9));
    expect(sb.chainageMeters, closeTo(sa.chainageMeters, 1e-6));
    expect(sb.progressPct, closeTo(sa.progressPct, 1e-9));
    expect(sb.maxProgressPct, closeTo(sa.maxProgressPct, 1e-9));
    expect(sb.minGoalDistanceM, closeTo(sa.minGoalDistanceM, 1e-6));
    expect(sb.isCompleted, sa.isCompleted);
    expect(sb.direction, sa.direction);
    expect(sb.firedApproachSpotIds, equals(sa.firedApproachSpotIds));
    expect(sb.offRouteEvents, sa.offRouteEvents);
    // 立寄り（§11）も引き継がれる（接近半径に入ったスポット分）。
    expect(b.collectVisits().map((v) => v.routeSpotId).toSet(),
        equals(a.collectVisits().map((v) => v.routeSpotId).toSet()));
  });

  test('中途 kill→復元: 前半 export→新エンジン import→後半 が全fix連続投入と一致', () {
    final fixes = fixesFor(ReplayPattern.normal, seed: 7);
    final k = fixes.length ~/ 2;

    // C: 全fixを1つのエンジンに連続投入（kill が起きなかった真値）。
    final c = fed(fixes);

    // A→B: 前半でクラッシュ→スナップショット→新エンジンで取り込み→後半を継続。
    final a = fed(fixes.sublist(0, k));
    final b = RouteNavEngine(straightLine(), spots());
    expect(b.importSnapshot(a.exportSnapshot()!), isTrue);
    for (final f in fixes.sublist(k)) {
      b.processFix(f);
    }

    // D: スナップショットを使わず後半だけ（＝従来の復元＝カバレッジ消失する挙動）。
    final d = fed(fixes.sublist(k));

    final sb = b.state;
    final sc = c.state;
    final sd = d.state;

    // 復元ありは「連続投入の真値」とほぼ一致（継ぎ目で補間1区画分のみ差が出うる）。
    expect(sb.coveragePct, closeTo(sc.coveragePct, 0.03),
        reason: 'クラッシュ前カバレッジを引き継ぐので連続投入と一致する');
    expect(sb.isCompleted, sc.isCompleted, reason: '完走判定が連続投入と一致');
    expect(sb.maxProgressPct, closeTo(sc.maxProgressPct, 1e-6));

    // 復元ありは「後半だけ（従来挙動）」より明確にカバレッジが高い＝本修正の効果。
    expect(sb.coveragePct, greaterThan(sd.coveragePct + 0.2),
        reason: 'スナップショット復元が前半カバレッジを取り戻している');
    expect(sd.isCompleted, isFalse,
        reason: '後半だけでは前半が抜け 80% に届かない（従来の控えめ判定）');
  });

  test('ジオメトリ不一致（セル数違い）は取り込まず false・新規開始へフォールバック', () {
    final a = fed(fixesFor(ReplayPattern.normal));
    final snap = a.exportSnapshot()!;
    // セル数が違う（= 別ルート／再densify）スナップショットを捏造。
    final bogus = NavEngineSnapshot(
      coverageBits: '${snap.coverageBits}1111', // 長さを変える
      committedMeters: snap.committedMeters,
      direction: snap.direction,
      firedApproachIds: snap.firedApproachIds,
      minGoalDistanceM: snap.minGoalDistanceM,
      maxChainageM: snap.maxChainageM,
      completed: snap.completed,
      offRouteEvents: snap.offRouteEvents,
      offRouteActive: snap.offRouteActive,
      offRouteRun: snap.offRouteRun,
      recentRateMps: snap.recentRateMps,
      totalMeters: snap.totalMeters,
      visits: snap.visits,
    );
    final b = RouteNavEngine(straightLine(), spots());
    expect(b.importSnapshot(bogus), isFalse);
    expect(b.state.ready, isFalse, reason: '取り込み失敗時はまっさらなまま');
  });

  test('総延長不一致（別ルート）も取り込まない', () {
    final a = fed(fixesFor(ReplayPattern.normal));
    final snap = a.exportSnapshot()!;
    final wrongTotal = NavEngineSnapshot(
      coverageBits: snap.coverageBits, // セル数は同じだが
      committedMeters: snap.committedMeters,
      direction: snap.direction,
      firedApproachIds: snap.firedApproachIds,
      minGoalDistanceM: snap.minGoalDistanceM,
      maxChainageM: snap.maxChainageM,
      completed: snap.completed,
      offRouteEvents: snap.offRouteEvents,
      offRouteActive: snap.offRouteActive,
      offRouteRun: snap.offRouteRun,
      recentRateMps: snap.recentRateMps,
      totalMeters: snap.totalMeters + 500, // 総延長が違う
      visits: snap.visits,
    );
    final b = RouteNavEngine(straightLine(), spots());
    expect(b.importSnapshot(wrongTotal), isFalse);
  });

  test('§14: 逸脱中の kill→復元で off_route_event を二重発火しない（ラッチ引き継ぎ）', () {
    // ルートから約70m 北へ外れた fix（accuracy 8m で精度ゲート通過＝逸脱判定に乗る）。
    NavFix offRoute(double chainage, int tMillis) => NavFix(
          position: offsetMeters(pointAtChainage(straightLine(), chainage), 70, 0),
          accuracyM: 8,
          tMillis: tMillis,
          moving: true,
        );

    // A: 正常に歩き出して（初期化）→ 逸脱エピソードに入り onOffRoute が1回発火する。
    var aFires = 0;
    final a = RouteNavEngine(straightLine(), spots(), onOffRoute: (_) => aFires++);
    final initFixes = fixesFor(ReplayPattern.normal, seed: 11).take(12).toList();
    for (final f in initFixes) {
      a.processFix(f);
    }
    expect(a.state.ready, isTrue);
    expect(a.state.offRouteEvents, 0);

    var t = initFixes.last.tMillis;
    final c = a.state.chainageMeters;
    for (var i = 0; i < 6; i++) {
      t += 6000;
      a.processFix(offRoute(c, t));
    }
    expect(aFires, 1, reason: '1エピソードにつき発火は1回');
    expect(a.state.offRouteActive, isTrue);
    expect(a.state.offRouteEvents, 1);

    // kill→復元（JSON 経路）。ラッチ（offRouteActive/offRouteRun）も引き継ぐ。
    final restored = NavEngineSnapshot.fromJson(
        jsonDecode(jsonEncode(a.exportSnapshot()!.toJson())) as Map<String, dynamic>);
    var bFires = 0;
    final b = RouteNavEngine(straightLine(), spots(), onOffRoute: (_) => bFires++);
    expect(b.importSnapshot(restored), isTrue);
    expect(b.state.offRouteEvents, 1, reason: '逸脱カウントを引き継ぐ');
    expect(b.state.offRouteActive, isTrue, reason: 'エピソードラッチを引き継ぐ');

    // 復元後もまだ逸脱中（同一エピソード継続）。再発火してはならない。
    for (var i = 0; i < 6; i++) {
      t += 6000;
      b.processFix(offRoute(c, t));
    }
    expect(bFires, 0, reason: '同一エピソードの off_route_event 再発火なし（§14 二重通知0件）');
    expect(b.state.offRouteEvents, 1, reason: 'カウントは1のまま');
  });
}
