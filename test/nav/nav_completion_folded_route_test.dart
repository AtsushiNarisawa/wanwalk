import 'package:flutter_test/flutter_test.dart';
import 'package:wanwalk/nav/nav_geometry.dart';
import 'package:wanwalk/nav/route_nav_engine.dart';

import 'gps_replay.dart';
import 'nav_fixtures.dart';

/// 回帰: 折り返し（往復・非simple）ルートで散歩開始直後に偽完走しないこと。
///
/// 2026-06-19 発見バグ（浄蓮の滝〜わさび田 `izu-jorennotaki-wasabida`・432m・
/// ST_IsSimple=false・起点≈終点）。往復ルートは全ての物理地点が「往路 c / 復路 total-c」の
/// 2つの chainage に投影されるため、起点付近の init fix の global 投影が 0↔total に振動する。
/// `_finalizeInit` が raw global chain を `markRange` で繋いでいたためカバレッジ全区画が一気に
/// true 化し、散歩開始直後に coverage≥80% かつゴール（=起点）50m圏成立で `isCompleted=true`
/// （「ルートを歩ききりました」誤表示・北極星 is_route_completed 過大計上）になっていた。
///
/// このハーネスは「序盤では完走しない」を機械で縛る。既存テストは直線/単調ルートのみで、
/// 往復ルートの完走判定を縛るものが無かった（＝この型がすり抜けた構造的盲点）。
void main() {
  final routes = NavFixtures.load();

  List<NavSpot> navSpots(NavFixtureRoute r) => [
        for (var i = 0; i < r.spots.length; i++)
          NavSpot(
            id: 's$i',
            name: r.spots[i].name,
            distanceFromStart: r.spots[i].distanceFromStart,
            category: r.spots[i].category,
            location: r.spots[i].pos,
          )
      ];

  List<NavFix> toFixes(List<ReplayFix> rf) => [
        for (final f in rf)
          NavFix(
            position: f.position,
            accuracyM: f.accuracyM,
            tMillis: f.tMillis,
            moving: f.moving,
          )
      ];

  test('折り返しルート(浄蓮の滝)で序盤15%は偽完走しない', () {
    final r = routes.firstWhere((x) => x.slug == 'izu-jorennotaki-wasabida');
    final line = r.points;
    final total = lineLengthMeters(line);
    expect(total, greaterThan(400), reason: 'fixture 前提（432m 往復ルート）');

    for (final seed in [1, 2, 3, 7, 42]) {
      for (final pattern in [ReplayPattern.normal, ReplayPattern.noisy]) {
        final fixes =
            toFixes(GpsReplayGenerator(stepM: 3).generate(line, pattern, seed: seed));
        final engine = RouteNavEngine(line, navSpots(r));
        // 序盤15%だけ歩く（往路の途中・まだ折り返していない）。
        final partial = fixes.take((fixes.length * 0.15).ceil()).toList();
        for (final f in partial) {
          engine.processFix(f);
        }
        final s = engine.state;
        final tag = 'seed=$seed pattern=$pattern';
        expect(s.isCompleted, isFalse,
            reason: '$tag: 序盤15%で完走判定が出てはならない');
        expect(s.coveragePct, lessThan(0.8),
            reason: '$tag: 序盤でカバレッジは80%未満のはず');
        expect(s.maxProgressPct, lessThan(0.6),
            reason: '$tag: 往路序盤で最大到達(maxProgress)が過大計上されない');
      }
    }
  });

  test('全fixture掃引: 初期化直後(最初の8fix)で偽完走0・カバレッジ/最大到達の過大計上0', () {
    // 「最初の数fixでカバレッジが全区画に塗られる」init フラッディングを全ルートで縛る。
    // 非simpleルートだけが赤になる（simpleルートは振動しないので元から低い）。
    final checked = <String>[];
    for (final r in routes) {
      final line = r.points;
      if (line.length < 2) continue;
      final total = lineLengthMeters(line);
      // 極短ルートは init 数fixで正当に高進捗になり得るため対象外。
      if (total < 200) continue;
      final fixes = toFixes(
          GpsReplayGenerator(stepM: 3).generate(line, ReplayPattern.normal, seed: 5));
      if (fixes.isEmpty) continue;
      final engine = RouteNavEngine(line, navSpots(r));
      for (final f in fixes.take(8)) {
        engine.processFix(f);
      }
      final s = engine.state;
      checked.add(r.slug);
      expect(s.isCompleted, isFalse,
          reason: '${r.slug}: 初期化直後に完走してはならない');
      expect(s.coveragePct, lessThan(0.5),
          reason: '${r.slug}: 初期化直後のカバレッジが過大（init フラッディング）');
      expect(s.maxProgressPct, lessThan(0.5),
          reason: '${r.slug}: 初期化直後の最大到達が過大');
    }
    expect(checked, isNotEmpty, reason: '掃引対象ルートが1本以上あること');
  });

  test('折り返しルートでも最後まで歩けば正しく完走する（過剰修正で正常系を壊さない）', () {
    final r = routes.firstWhere((x) => x.slug == 'izu-jorennotaki-wasabida');
    final line = r.points;
    final fixes = toFixes(
        GpsReplayGenerator(stepM: 3).generate(line, ReplayPattern.normal, seed: 1));
    final engine = RouteNavEngine(line, navSpots(r));
    for (final f in fixes) {
      engine.processFix(f);
    }
    final s = engine.state;
    expect(s.coveragePct, greaterThanOrEqualTo(0.8),
        reason: '全行程歩破でカバレッジ80%以上');
    expect(s.isCompleted, isTrue,
        reason: '往復を最後まで歩けば完走（修正は正常系を壊さない）');
  });
}
