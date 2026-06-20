import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'nav_geometry.dart';

/// LAYER1_NAV_SPEC §2-§7 沿線距離ナビエンジン（本実装・Flutter非依存の純Dart）。
///
/// 設計（仕様の核）:
/// - 全判定を「沿線距離(chainage)」基準に統一。
/// - GPS精度ゲート(>35m除外)・窓付き投影(即時スナップ禁止)・方向推定・速度予測で
///   往復/周回の誤吸着を抑える。
/// - 接近は1スポット1散歩1回ラッチ・完走は25mカバレッジ80%かつゴール50m圏。
/// - 終了忘れサスペンド（速度継続）・テレポート検出（ショートカット）。
///
/// このエンジンは `lib/nav/nav_geometry.dart` のプリミティブだけに依存し、
/// `test/nav/` の GPSリプレイ・ハーネス（§14）と、アプリの nav_controller_provider が
/// 同一コードを共有する。状態は [processFix] で更新、[state] で読む。

/// エンジンへ注入する1フィックス（GPS or 合成）。
class NavFix {
  final LatLng position;
  final double accuracyM; // 水平精度
  final int tMillis; // 基準時刻からの経過(ms)
  final bool moving; // 静止中(一時停止/匂い嗅ぎ)は false

  const NavFix({
    required this.position,
    required this.accuracyM,
    required this.tMillis,
    this.moving = true,
  });
}

/// ナビが扱うスポット（RouteSpot or fixture から構築）。
class NavSpot {
  final String id;
  final String name;
  final int? distanceFromStart;
  final String? category;

  /// スポットの実座標（§11 立寄り判定の最接近距離算出に使用）。
  /// fixture 等で未指定なら立寄り追跡の対象外（min_distance を出せないため）。
  final LatLng? location;

  const NavSpot({
    required this.id,
    required this.name,
    this.distanceFromStart,
    this.category,
    this.location,
  });

  /// §4 接近ガイド対象（景観系 + 商業系）。utility(parking/restroom/water_station) と
  /// null は対象外（地図アイコンのみ）。
  static const Set<String> approachCategories = {
    'viewpoint', 'park', 'shrine_temple', 'landmark', 'historical_landmark', 'beach',
    'cafe', 'restaurant', 'shop', 'dog_run',
  };

  bool get isApproachTarget =>
      category != null && approachCategories.contains(category);
}

/// 閾値（§10 既定値。Build 43 で nav_params テーブルからリモート上書き）。
class NavParams {
  final double offRouteM; // 逸脱閾値（perp - accuracy）
  final double accuracyGateM; // これ超の精度fixは接近/逸脱/進捗から除外
  final double completeCoverage; // 完走カバレッジ閾値
  final double goalRadiusM; // ゴール到達半径
  final double suspendSpeedKmh; // 終了忘れサスペンド速度
  final double startSnapM; // 起点圏（進捗0固定）
  final double interpMaxSpeedMps; // カバレッジ補間を許す最大速度
  final double reacquireJumpM; // これ超のchainage跳びは即時スナップせず再捕捉
  final int reacquireConfirm; // 再捕捉に必要な連続一致fix数
  final double offRouteSuspendM; // これ超の逸脱継続でサスペンド
  final int suspendSpeedConfirm; // 高速がこの回数連続でサスペンド（§2「継続」）
  final int initConfirm; // 初期化に使う最初のgood fix数（周回起点の0/total二義性を方向で解消）
  final int offRouteConfirm; // 逸脱は連続この回数でエピソード計上（§6「複数fix連続」）
  final double discontinuitySpeedMps; // 連続fix間の空間速度がこれ超=テレポートとして再捕捉
  final double mergeM; // 接近密集マージ（§4・将来UI用）

  // §4 B 接近ガイド / §6 D 復帰サポート（Build 43 有効化時に使用・先行収容）
  final double approachPreM; // 接近予告
  final double approachCardM; // 接近カード表示
  final int offRouteNotifyMax; // 逸脱通知上限

  // §11 walk_spot_visits 立寄り判定
  final double visitRadiusM; // この距離内に入ったら立寄りと記録
  final int visitDwellGapSec; // 連続滞在とみなす最大fix間隔（超で滞在加算をスキップ）

  final int version; // nav_params_version（全イベントへ付与・§10）

  const NavParams({
    this.offRouteM = 50,
    this.accuracyGateM = 35,
    this.completeCoverage = 0.80,
    this.goalRadiusM = 50,
    this.suspendSpeedKmh = 12,
    this.startSnapM = 50,
    this.interpMaxSpeedMps = 3.0,
    this.reacquireJumpM = 120,
    this.reacquireConfirm = 3,
    this.offRouteSuspendM = 500,
    this.suspendSpeedConfirm = 4,
    this.initConfirm = 5,
    this.offRouteConfirm = 3,
    this.discontinuitySpeedMps = 8.0,
    this.mergeM = 130,
    this.approachPreM = 100,
    this.approachCardM = 30,
    this.offRouteNotifyMax = 2,
    this.visitRadiusM = 40,
    this.visitDwellGapSec = 120,
    this.version = 1,
  });

  /// nav_params テーブルの1行から構築（§10 リモート閾値）。
  /// PostgREST は numeric を数値/文字列どちらでも返しうるため両対応でパースし、
  /// 欠損キーはアプリ内蔵の既定値にフォールバックする。
  factory NavParams.fromMap(Map<String, dynamic> m) {
    const d = NavParams();
    return NavParams(
      offRouteM: _numD(m['off_route_m'], d.offRouteM),
      accuracyGateM: _numD(m['accuracy_gate_m'], d.accuracyGateM),
      completeCoverage: _numD(m['complete_coverage'], d.completeCoverage),
      goalRadiusM: _numD(m['goal_radius_m'], d.goalRadiusM),
      suspendSpeedKmh: _numD(m['suspend_speed_kmh'], d.suspendSpeedKmh),
      startSnapM: _numD(m['start_snap_m'], d.startSnapM),
      interpMaxSpeedMps: _numD(m['interp_max_speed_mps'], d.interpMaxSpeedMps),
      reacquireJumpM: _numD(m['reacquire_jump_m'], d.reacquireJumpM),
      reacquireConfirm: _numI(m['reacquire_confirm'], d.reacquireConfirm),
      offRouteSuspendM: _numD(m['off_route_suspend_m'], d.offRouteSuspendM),
      suspendSpeedConfirm: _numI(m['suspend_speed_confirm'], d.suspendSpeedConfirm),
      initConfirm: _numI(m['init_confirm'], d.initConfirm),
      offRouteConfirm: _numI(m['off_route_confirm'], d.offRouteConfirm),
      discontinuitySpeedMps: _numD(m['discontinuity_speed_mps'], d.discontinuitySpeedMps),
      mergeM: _numD(m['merge_m'], d.mergeM),
      approachPreM: _numD(m['approach_pre_m'], d.approachPreM),
      approachCardM: _numD(m['approach_card_m'], d.approachCardM),
      offRouteNotifyMax: _numI(m['off_route_notify_max'], d.offRouteNotifyMax),
      visitRadiusM: _numD(m['visit_radius_m'], d.visitRadiusM),
      visitDwellGapSec: _numI(m['visit_dwell_gap_sec'], d.visitDwellGapSec),
      version: _numI(m['version'], d.version),
    );
  }
}

double _numD(dynamic v, double def) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? def;
  return def;
}

int _numI(dynamic v, int def) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? def;
  return def;
}

/// エンジンの観測可能状態（UI / 計測 / 保存が読む）。
class NavState {
  final bool ready; // 初期化完了（committed 確定）
  final double chainageMeters; // 現在の沿線距離
  final double totalMeters;
  final double progressPct; // chainage/total（0-1）
  final double remainingMeters; // total-chainage（線形）/ ループは戻り距離
  final double maxProgressPct;
  final double coveragePct;
  final bool isCompleted;
  final double minGoalDistanceM;
  final double offRouteDistanceM; // 直近good fixの垂線距離
  final bool offRouteActive;
  final int offRouteEvents;
  final bool suspended;
  final int direction; // +1 / -1
  final Set<String> firedApproachSpotIds;
  final NavSpot? nextSpot; // 次の接近対象スポット
  final double? nextSpotRemainingMeters; // 次スポットまでの沿線距離
  final double? returnToParkingMeters; // §7 駐車場へルート沿いに戻る距離（parkingなければnull）

  const NavState({
    required this.ready,
    required this.chainageMeters,
    required this.totalMeters,
    required this.progressPct,
    required this.remainingMeters,
    required this.maxProgressPct,
    required this.coveragePct,
    required this.isCompleted,
    required this.minGoalDistanceM,
    required this.offRouteDistanceM,
    required this.offRouteActive,
    required this.offRouteEvents,
    required this.suspended,
    required this.direction,
    required this.firedApproachSpotIds,
    required this.nextSpot,
    required this.nextSpotRemainingMeters,
    this.returnToParkingMeters,
  });

  static const empty = NavState(
    ready: false,
    chainageMeters: 0,
    totalMeters: 0,
    progressPct: 0,
    remainingMeters: 0,
    maxProgressPct: 0,
    coveragePct: 0,
    isCompleted: false,
    minGoalDistanceM: double.infinity,
    offRouteDistanceM: 0,
    offRouteActive: false,
    offRouteEvents: 0,
    suspended: false,
    direction: 1,
    firedApproachSpotIds: <String>{},
    nextSpot: null,
    nextSpotRemainingMeters: null,
  );
}

/// walks へ保存する完走の生値（§5）。NavState から構築し walk_save_service へ渡す。
class NavCompletion {
  final double coveragePct;
  final double maxProgressPct;
  final int? minGoalDistanceM;
  final bool isRouteCompleted;

  const NavCompletion({
    required this.coveragePct,
    required this.maxProgressPct,
    required this.minGoalDistanceM,
    required this.isRouteCompleted,
  });

  factory NavCompletion.fromState(NavState s) => NavCompletion(
        coveragePct: double.parse(s.coveragePct.toStringAsFixed(4)),
        maxProgressPct: double.parse(s.maxProgressPct.toStringAsFixed(4)),
        minGoalDistanceM: s.minGoalDistanceM.isFinite ? s.minGoalDistanceM.round() : null,
        isRouteCompleted: s.isCompleted,
      );
}

/// 1スポットの接近発火イベント（B 接近ガイド／F 計測が消費）。
class NavApproachEvent {
  final NavSpot spot;
  final double chainageMeters;
  NavApproachEvent(this.spot, this.chainageMeters);
}

/// 逸脱エピソード開始イベント（D 復帰サポート／F 計測 off_route_event が消費）。
///
/// §14.4: Build 42 は D の UI を出さないが、accuracy_m / threshold_m / was_stationary を
/// テレメトリとして送り、リモート閾値チューニングの「目」にする。
class NavOffRouteEvent {
  final double chainageMeters;
  final double perpMeters; // 逸脱の垂線距離
  final double accuracyM; // 発火 fix の水平精度
  final double thresholdM; // 逸脱閾値（offRouteM）
  final bool wasStationary; // 発火時に静止していたか（移動中のみ計上のため通常 false）
  NavOffRouteEvent({
    required this.chainageMeters,
    required this.perpMeters,
    required this.accuracyM,
    required this.thresholdM,
    required this.wasStationary,
  });
}

/// §11 立寄り記録の1件（walk保存成功時に walk_spot_visits へ一括INSERT）。
/// [firstSeenMillis] は **nav 基準時刻（最初の GPS fix の時刻）からの相対ms**。
/// 保存側は nav 基準時刻の絶対 epoch（NavController.navStartEpochMs）に足して絶対
/// visited_at に変換する（エンジンは絶対時刻を知らない＝純Dartで時計に非依存）。
class SpotVisit {
  final String routeSpotId;
  final int firstSeenMillis; // 最初に接近半径内へ入った相対時刻(ms)
  final int dwellSec; // 接近半径内の連続滞在合計（秒）
  final int? minDistanceM; // 最接近距離（m）。算出不能なら null

  const SpotVisit({
    required this.routeSpotId,
    required this.firstSeenMillis,
    required this.dwellSec,
    required this.minDistanceM,
  });
}

/// §2 kill→復元: 進行中ナビの永続化スナップショット（v2）のうちエンジン部分（純データ）。
///
/// 従来の復元（GPS点のみ）はエンジンを新規生成して復元後の fix からしか積算しないため、
/// クラッシュ前に歩いた区間のカバレッジが消失し完走判定が控えめに出ていた。これを解消するため
/// 「セグメント訪問ビットマップ・沿線進捗・方向・接近発火済みID・立寄り」を保存し復元時に取り込む。
///
/// 一過性状態（直近 fix・補間アンカー・サスペンド・再捕捉バッファ）は**保存しない**。復元時に
/// クリーン再開することで kill 跨ぎを「補間」「テレポート」「終了忘れ」と誤検出しないため（§2）。
/// [totalMeters] と [coverageBits] の長さは復元先エンジンとのジオメトリ整合検証キーになる
/// （ルート再densify 等で線が変わっていたら取り込まずに新規開始へフォールバック）。
class NavEngineSnapshot {
  static const int schemaVersion = 1;

  final String coverageBits; // '0'/'1' 列。長さ = CoverageGrid セル数（整合検証キー）
  final double committedMeters; // 沿線進捗（chainage）
  final int? direction; // 進行方向 +1/-1（未確定なら null）
  final List<String> firedApproachIds; // 接近発火済みスポットID（再通知防止）
  final double? minGoalDistanceM; // ゴール最接近（infinity は null で表現）
  final double maxChainageM; // 最大到達 chainage（maxProgressPct 復元）
  final bool completed; // 完走確定済みか
  final int offRouteEvents; // 逸脱エピソード累計（NavState 表示・テレメトリ継続用）
  // 逸脱エピソードの重複防止ラッチ＋連続カウント。kill 跨ぎの一過性状態ではなく
  // 「1エピソード=1通知」を保証する状態なので保存・復元する（保存しないと逸脱中の kill→
  // 復元で同一エピソードの off_route_event が再発火＝二重通知になる・§14 受け入れ基準）。
  final bool offRouteActive;
  final int offRouteRun;
  final double recentRateMps; // 直近の沿線速度（方向付き予測の継続用）
  final double totalMeters; // ジオメトリ整合検証
  final List<NavVisitSnapshot> visits; // §11 立寄り（接近半径に入った分のみ）

  const NavEngineSnapshot({
    required this.coverageBits,
    required this.committedMeters,
    required this.direction,
    required this.firedApproachIds,
    required this.minGoalDistanceM,
    required this.maxChainageM,
    required this.completed,
    required this.offRouteEvents,
    required this.offRouteActive,
    required this.offRouteRun,
    required this.recentRateMps,
    required this.totalMeters,
    required this.visits,
  });

  Map<String, dynamic> toJson() => {
        'v': schemaVersion,
        'coverageBits': coverageBits,
        'committedMeters': committedMeters,
        'direction': direction,
        'firedApproachIds': firedApproachIds,
        'minGoalDistanceM': minGoalDistanceM,
        'maxChainageM': maxChainageM,
        'completed': completed,
        'offRouteEvents': offRouteEvents,
        'offRouteActive': offRouteActive,
        'offRouteRun': offRouteRun,
        'recentRateMps': recentRateMps,
        'totalMeters': totalMeters,
        'visits': visits.map((v) => v.toJson()).toList(),
      };

  factory NavEngineSnapshot.fromJson(Map<String, dynamic> j) => NavEngineSnapshot(
        coverageBits: j['coverageBits'] as String? ?? '',
        committedMeters: _numD(j['committedMeters'], 0),
        direction: (j['direction'] as num?)?.toInt(),
        firedApproachIds: (j['firedApproachIds'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        minGoalDistanceM:
            j['minGoalDistanceM'] == null ? null : _numD(j['minGoalDistanceM'], 0),
        maxChainageM: _numD(j['maxChainageM'], 0),
        completed: j['completed'] as bool? ?? false,
        offRouteEvents: _numI(j['offRouteEvents'], 0),
        // 旧スナップショットには無いキー（false/0 既定で後方互換）。
        offRouteActive: j['offRouteActive'] as bool? ?? false,
        offRouteRun: _numI(j['offRouteRun'], 0),
        recentRateMps: _numD(j['recentRateMps'], 0),
        totalMeters: _numD(j['totalMeters'], 0),
        visits: (j['visits'] as List<dynamic>? ?? const [])
            .map((e) => NavVisitSnapshot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// §11 立寄り1件の永続化（接近半径に入ったスポットのみ保存）。
class NavVisitSnapshot {
  final String spotId;
  final double? minDistanceM; // 最接近（infinity は null）
  final int firstSeenMillis; // 最初に半径内へ入った相対ms（nav 基準時刻基準）
  final int dwellMs; // 半径内の連続滞在合計（ms）

  const NavVisitSnapshot({
    required this.spotId,
    required this.minDistanceM,
    required this.firstSeenMillis,
    required this.dwellMs,
  });

  Map<String, dynamic> toJson() => {
        'spotId': spotId,
        'minDistanceM': minDistanceM,
        'firstSeenMillis': firstSeenMillis,
        'dwellMs': dwellMs,
      };

  factory NavVisitSnapshot.fromJson(Map<String, dynamic> j) => NavVisitSnapshot(
        spotId: j['spotId'] as String,
        minDistanceM:
            j['minDistanceM'] == null ? null : _numD(j['minDistanceM'], 0),
        firstSeenMillis: _numI(j['firstSeenMillis'], 0),
        dwellMs: _numI(j['dwellMs'], 0),
      );
}

/// スポットごとの立寄り集計バッファ（エンジン内部状態）。
class _VisitAccum {
  double minDistM = double.infinity;
  int? firstWithinMs; // 最初に半径内へ入った相対時刻(ms)
  int dwellMs = 0; // 半径内に「居続けた」連続時間の合計
  int? prevFixMs; // 直近 good fix の時刻（半径内外を問わず）
  bool prevWithin = false; // 直近 good fix が半径内だったか
}

class RouteNavEngine {
  final List<LatLng> line;
  final List<double> _cum;
  final double totalMeters;
  final List<NavSpot> spots;
  final NavParams p;

  /// 接近発火コールバック（B のカード/通知・F の計測が購読）。Build 43 でフラグ制御。
  final void Function(NavApproachEvent event)? onApproach;

  /// 逸脱エピソード開始コールバック（D の復帰バナー・F の off_route_event が購読）。
  final void Function(NavOffRouteEvent event)? onOffRoute;

  late final CoverageGrid _coverage;
  final Set<String> _firedApproach = {};
  final Map<String, _VisitAccum> _visits = {}; // §11 立寄り集計（spot.id 別）
  int _offRouteEvents = 0;
  bool _offRouteActive = false;
  bool _completed = false;
  bool _suspended = false;
  double _minGoalDist = double.infinity;
  double _maxChainage = 0;
  double _lastPerp = 0;

  double? _committed;
  double? _lastGoodChainage;
  int? _lastGoodTms;
  int? _direction;
  NavFix? _lastFix;
  int _highSpeedRun = 0;
  int _offRouteRun = 0;
  double _recentRateMps = 0;
  int? _lastCommitTms;
  bool _forceReacquire = false;

  final List<_InitSample> _initBuf = [];
  final List<double> _reacqBuf = [];

  RouteNavEngine(this.line, this.spots,
      {this.p = const NavParams(), this.onApproach, this.onOffRoute})
      : _cum = cumulativeChainage(line),
        totalMeters = lineLengthMeters(line) {
    _coverage = CoverageGrid(totalMeters, cellMeters: 25);
  }

  LatLng get _goal => line.last;

  void processFix(NavFix fix) {
    final prevFix = _lastFix;
    // サスペンド: 速度継続（車発進）。あわせて単発テレポート（ショートカット）検出。
    if (prevFix != null && !_suspended) {
      final dtS = (fix.tMillis - prevFix.tMillis) / 1000.0;
      if (dtS > 0.1) {
        final sp = haversineMeters(prevFix.position, fix.position) / dtS;
        if (sp * 3.6 > p.suspendSpeedKmh) {
          _highSpeedRun++;
        } else {
          _highSpeedRun = 0;
        }
        if (_highSpeedRun >= p.suspendSpeedConfirm) _suspended = true;
        if (sp > p.discontinuitySpeedMps) _forceReacquire = true;
      }
    }
    _lastFix = fix;
    if (_suspended) return;

    final goodAccuracy = fix.accuracyM <= p.accuracyGateM;

    // §11: 立寄り追跡は精度ゲートを通った fix のみで行う（>35m のマルチパス系統誤差で
    // false visit / 過小 min_distance を作らないため＝進捗/接近/逸脱と対称）。初期化前後に
    // 依らず全 good fix で実施。サスペンド後は計上しない（上で return 済み）。
    if (goodAccuracy) _trackVisits(fix);

    // 初期化: 最初の good fix を貯め、方向と開始chainageを決める（周回二義性回避・§2）。
    if (_committed == null) {
      if (goodAccuracy) {
        final g = projectToLine(fix.position, line, cumChain: _cum);
        _initBuf.add(_InitSample(g.chainageMeters, fix.tMillis, fix.position));
        final gd = haversineMeters(fix.position, _goal);
        if (gd < _minGoalDist) _minGoalDist = gd;
      }
      if (_initBuf.length >= p.initConfirm) _finalizeInit();
      return;
    }

    // §2: accuracy>35m は進捗/接近/逸脱に使わない。カバレッジのみ chainage で塗る。
    if (!goodAccuracy) {
      final g = projectToLine(fix.position, line, cumChain: _cum);
      _coverage.mark(g.chainageMeters);
      return;
    }

    final gd = haversineMeters(fix.position, _goal);
    if (gd < _minGoalDist) _minGoalDist = gd;

    final proj = _project(fix);
    if (proj == null) return; // 再捕捉確定までホールド
    final newChainage = proj.chainageMeters;
    _lastPerp = proj.perpMeters;

    final prevChainage = _committed;
    _committed = newChainage;
    if (newChainage > _maxChainage) _maxChainage = newChainage;

    if (prevChainage != null && _lastCommitTms != null) {
      final dt = (fix.tMillis - _lastCommitTms!) / 1000.0;
      if (dt > 0.1) {
        var r = (newChainage - prevChainage) / dt;
        if (r > 2.5) r = 2.5;
        if (r < -2.5) r = -2.5;
        _recentRateMps = _recentRateMps == 0 ? r : 0.5 * _recentRateMps + 0.5 * r;
      }
    }
    _lastCommitTms = fix.tMillis;

    // カバレッジ（補間は歩行速度で妥当な区間のみ＝テレポートを埋めない）。
    _coverage.mark(newChainage);
    if (_lastGoodChainage != null && _lastGoodTms != null) {
      final dtS = (fix.tMillis - _lastGoodTms!) / 1000.0;
      final dC = (newChainage - _lastGoodChainage!).abs();
      if (dtS > 0 && (dC / dtS) <= p.interpMaxSpeedMps) {
        _coverage.markRange(_lastGoodChainage!, newChainage);
      }
    }
    _lastGoodChainage = newChainage;
    _lastGoodTms = fix.tMillis;

    if (prevChainage != null) _checkApproach(prevChainage, newChainage);

    // 逸脱（連続・静止除外・低精度fixはこの分岐に来ない）。
    if (!fix.moving) {
      _offRouteRun = 0;
    } else {
      final off = proj.perpMeters - fix.accuracyM;
      if (off > p.offRouteM) {
        _offRouteRun++;
        if (_offRouteRun >= p.offRouteConfirm && !_offRouteActive) {
          _offRouteActive = true;
          _offRouteEvents++;
          onOffRoute?.call(NavOffRouteEvent(
            chainageMeters: newChainage,
            perpMeters: proj.perpMeters,
            accuracyM: fix.accuracyM,
            thresholdM: p.offRouteM,
            wasStationary: !fix.moving,
          ));
        }
        if (proj.perpMeters > p.offRouteSuspendM && _offRouteRun >= p.offRouteConfirm) {
          _suspended = true;
        }
      } else {
        _offRouteRun = 0;
        if (proj.perpMeters < p.offRouteM * 0.6) _offRouteActive = false;
      }
    }

    if (!_completed &&
        _coverage.coverage() >= p.completeCoverage &&
        _minGoalDist <= p.goalRadiusM) {
      _completed = true;
    }
  }

  void _finalizeInit() {
    if (_initBuf.isEmpty) {
      _committed = 0;
      return;
    }

    // §2 初期化の二義性対策（折り返し/周回ルートの偽完走バグ修正・2026-06-19）。
    // 往復(非simple)ルートは全ての物理地点が「往路 c / 復路 total-c」の2つの chainage に
    // 投影されるため、起点付近の init fix の global 投影が 0↔total に振動する。これを raw の
    // まま markRange で繋ぐとカバレッジ全区画が一気に true 化し、散歩開始直後に coverage≥80%
    // かつゴール(=起点)50m圏成立で偽完走（「歩ききりました」誤表示・北極星 is_route_completed
    // 過大計上）になっていた。
    //
    // 対策: ①最初のサンプルを「起点50m圏なら 0／それ以外は global投影」にアンカー（§2 起点固定）。
    // ②以降は直前アンカー周りの窓付き投影で1レーンへ畳む（main loop の連続性スナップと同型）。
    // 窓外＝物理的に離れた別レーンは採らず prev を据え置く（init は数m移動・据え置きは直後の
    // main loop fix が即補正するため無害／偽完走を生む過大計上より控えめ側へ倒す）。
    // simple ルートでは二義性が無く clean は raw と一致するため挙動は不変。
    //
    // ※ 周回を逆回りで歩く場合の起点アンカーは 0 のまま（dir は +1 と推定される）。これは
    //   逆回り loop の完走感度をやや下げるが、後続サンプルの global 投影で復路を判定する案は
    //   往路の往復ルートで誤爆し正常完走を壊したため不採用（normal 81→73 回帰を実測）。逆回り
    //   loop の完走は §14.2「難所」の既知 follow-up（カバレッジ補間・再捕捉の堅牢化）に委ねる。
    final startDist = haversineMeters(_initBuf.first.pos, line.first);
    final firstAnchor = startDist <= p.startSnapM ? 0.0 : _initBuf.first.chain;

    final clean = <double>[firstAnchor];
    for (var i = 1; i < _initBuf.length; i++) {
      final prev = clean[i - 1];
      final win = _windowedBiased(_initBuf[i].pos, prev - 120, prev + 120, prev);
      clean.add((win != null && win.perpMeters < 60) ? win.chainageMeters : prev);
    }

    if (clean.length < 2) {
      _committed = clean.first;
      _coverage.mark(clean.first);
      _lastGoodChainage = clean.first;
      _lastGoodTms = _initBuf.first.tMillis;
      return;
    }

    final dir = (clean.last - clean.first) >= 0 ? 1 : -1;
    _direction = dir;
    _committed = clean.last;
    _maxChainage = clean.reduce(math.max);
    for (var i = 0; i < clean.length; i++) {
      _coverage.mark(clean[i]);
      if (i > 0) _coverage.markRange(clean[i - 1], clean[i]);
    }
    _lastGoodChainage = clean.last;
    _lastGoodTms = _initBuf.last.tMillis;
    _lastCommitTms = _initBuf.last.tMillis;
    _recentRateMps = dir * 0.83;
    _checkApproach(dir > 0 ? 0.0 : totalMeters, _committed!);
  }

  LineProjection? _project(NavFix fix) {
    if (_committed == null) {
      final global = projectToLine(fix.position, line, cumChain: _cum);
      final startDist = haversineMeters(fix.position, line.first);
      if (startDist <= p.startSnapM) {
        return LineProjection(
            chainageMeters: 0, perpMeters: global.perpMeters, segmentIndex: 0, t: 0);
      }
      return global;
    }

    final dir = _direction ?? 1;
    final dtS = _lastCommitTms != null ? (fix.tMillis - _lastCommitTms!) / 1000.0 : 0.0;
    final rate = _recentRateMps != 0 ? _recentRateMps : dir * 0.83;
    final predicted = _committed! + rate * (dtS > 0 && dtS < 30 ? dtS : 6.0);
    if (!_forceReacquire) {
      final back = dir > 0 ? 60.0 : 300.0;
      final fwd = dir > 0 ? 300.0 : 60.0;
      final win = _windowedBiased(
          fix.position, _committed! - back, _committed! + fwd, predicted);
      if (win != null && win.perpMeters < 100) {
        _reacqBuf.clear();
        return win;
      }
    }

    final g = projectToLine(fix.position, line, cumChain: _cum);
    if (!_forceReacquire && (g.chainageMeters - _committed!).abs() <= p.reacquireJumpM) {
      _reacqBuf.clear();
      return g;
    }
    _reacqBuf.add(g.chainageMeters);
    if (_reacqBuf.length >= p.reacquireConfirm) {
      final spread = _reacqBuf.reduce(math.max) - _reacqBuf.reduce(math.min);
      if (spread < 80) {
        final avg = _reacqBuf.reduce((a, b) => a + b) / _reacqBuf.length;
        _reacqBuf.clear();
        _forceReacquire = false;
        _lastGoodChainage = null;
        _lastGoodTms = null;
        return LineProjection(
            chainageMeters: avg, perpMeters: g.perpMeters, segmentIndex: g.segmentIndex, t: g.t);
      }
      _reacqBuf.removeAt(0);
    }
    return null;
  }

  LineProjection? _windowedBiased(LatLng pos, double lo, double hi, double predicted) {
    const continuityWeight = 0.5;
    double bestScore = double.infinity;
    double bestPerp = 0, bestChain = 0, bestT = 0;
    int bestSeg = -1;
    for (var i = 0; i < line.length - 1; i++) {
      final segStart = _cum[i];
      final segEnd = _cum[i + 1];
      if (segEnd < lo || segStart > hi) continue;
      final r = projectPointOnSegment(pos, line[i], line[i + 1]);
      final segChain = segStart + r.t * (segEnd - segStart);
      final score = r.perpM + continuityWeight * (segChain - predicted).abs();
      if (score < bestScore) {
        bestScore = score;
        bestPerp = r.perpM;
        bestChain = segChain;
        bestSeg = i;
        bestT = r.t;
      }
    }
    if (bestSeg < 0) return null;
    return LineProjection(
        chainageMeters: bestChain, perpMeters: bestPerp, segmentIndex: bestSeg, t: bestT);
  }

  void _checkApproach(double prevC, double newC) {
    var lo = prevC < newC ? prevC : newC;
    var hi = prevC < newC ? newC : prevC;
    if (hi >= totalMeters - 3) hi = totalMeters + 5;
    for (final s in spots) {
      if (!s.isApproachTarget) continue;
      final dfs = s.distanceFromStart;
      if (dfs == null) continue;
      if (_firedApproach.contains(s.id)) continue;
      if (dfs >= lo && dfs <= hi) {
        _firedApproach.add(s.id);
        onApproach?.call(NavApproachEvent(s, newC));
      }
    }
  }

  /// §11: 各スポットへの最接近距離と接近半径内の滞在時間を更新する。
  /// utility(parking/restroom/water_station) も含め location を持つ全スポットが対象。
  /// 滞在は「半径内に居続けた連続時間」の合計＝直前 fix も半径内だった区間だけを積算する
  /// （半径外を挟んだ離脱時間は数えない・周回の再通過は別区間扱い）。さらに fix 間隔が
  /// visitDwellGapSec を超える場合は不規則サンプリングとみなし加算しない（安全弁）。
  void _trackVisits(NavFix fix) {
    for (final s in spots) {
      final loc = s.location;
      if (loc == null) continue;
      final d = haversineMeters(fix.position, loc);
      final acc = _visits.putIfAbsent(s.id, () => _VisitAccum());
      if (d < acc.minDistM) acc.minDistM = d;
      final within = d <= p.visitRadiusM;
      if (within) {
        if (acc.firstWithinMs == null) {
          acc.firstWithinMs = fix.tMillis;
        } else if (acc.prevWithin && acc.prevFixMs != null) {
          // 直前 fix も半径内だった「連続区間」のみ滞在に加算。
          final gap = fix.tMillis - acc.prevFixMs!;
          if (gap >= 0 && gap <= p.visitDwellGapSec * 1000) acc.dwellMs += gap;
        }
      }
      acc.prevWithin = within;
      acc.prevFixMs = fix.tMillis;
    }
  }

  /// §11: 立寄りが成立した（接近半径内に1回以上入った）スポットの記録を返す。
  /// walk保存成功後に walk_spot_visits へ一括INSERTする（散歩中は書き込まない）。
  List<SpotVisit> collectVisits() {
    final out = <SpotVisit>[];
    for (final s in spots) {
      final acc = _visits[s.id];
      if (acc == null || acc.firstWithinMs == null) continue;
      out.add(SpotVisit(
        routeSpotId: s.id,
        firstSeenMillis: acc.firstWithinMs!,
        dwellSec: (acc.dwellMs / 1000).round(),
        minDistanceM: acc.minDistM.isFinite ? acc.minDistM.round() : null,
      ));
    }
    return out;
  }

  /// §2 kill→復元: 現在のエンジン状態をスナップショット化する。
  /// 初期化前（[state].ready=false）は復元対象外として null を返す。
  NavEngineSnapshot? exportSnapshot() {
    if (_committed == null) return null;
    final visits = <NavVisitSnapshot>[];
    for (final e in _visits.entries) {
      final a = e.value;
      if (a.firstWithinMs == null) continue; // 接近半径に入った分のみ（collectVisits と対称）
      visits.add(NavVisitSnapshot(
        spotId: e.key,
        minDistanceM: a.minDistM.isFinite ? a.minDistM : null,
        firstSeenMillis: a.firstWithinMs!,
        dwellMs: a.dwellMs,
      ));
    }
    return NavEngineSnapshot(
      coverageBits: _coverage.exportBits().map((b) => b ? '1' : '0').join(),
      committedMeters: _committed!,
      direction: _direction,
      firedApproachIds: _firedApproach.toList(),
      minGoalDistanceM: _minGoalDist.isFinite ? _minGoalDist : null,
      maxChainageM: _maxChainage,
      completed: _completed,
      offRouteEvents: _offRouteEvents,
      offRouteActive: _offRouteActive,
      offRouteRun: _offRouteRun,
      recentRateMps: _recentRateMps,
      totalMeters: totalMeters,
      visits: visits,
    );
  }

  /// §2 kill→復元: スナップショットをこのエンジンへ取り込む。
  ///
  /// ジオメトリが一致しない（セル数 or 総延長が違う＝ルートが変わった）場合は **取り込まず
  /// false** を返し、呼び出し側は新規開始へフォールバックする。取り込み成功時は持続状態
  /// （カバレッジ・進捗・方向・接近発火済み・立寄り）を復元し、一過性状態（直近 fix・補間
  /// アンカー・サスペンド・再捕捉/初期化バッファ）はクリーン再開のためリセットする（§2）。
  bool importSnapshot(NavEngineSnapshot s) {
    if (s.coverageBits.length != _coverage.cellCount) return false;
    if ((s.totalMeters - totalMeters).abs() > 1.0) return false;

    final bits = [for (var i = 0; i < s.coverageBits.length; i++) s.coverageBits[i] == '1'];
    _coverage.importBits(bits);
    _committed = s.committedMeters;
    _direction = s.direction;
    _firedApproach
      ..clear()
      ..addAll(s.firedApproachIds);
    _minGoalDist = s.minGoalDistanceM ?? double.infinity;
    _maxChainage = s.maxChainageM;
    _completed = s.completed;
    _offRouteEvents = s.offRouteEvents;
    // 逸脱エピソードのラッチ＋連続カウントは復元する（リセットしない）。逸脱中に kill→
    // 復元しても同一エピソードの off_route_event を再発火させないため（§14 二重通知0件）。
    _offRouteActive = s.offRouteActive;
    _offRouteRun = s.offRouteRun;
    _recentRateMps = s.recentRateMps;
    _visits.clear();
    for (final v in s.visits) {
      _visits[v.spotId] = _VisitAccum()
        ..minDistM = v.minDistanceM ?? double.infinity
        ..firstWithinMs = v.firstSeenMillis
        ..dwellMs = v.dwellMs;
      // prevWithin=false / prevFixMs=null：復元後の連続滞在は次 fix から計り直す。
    }

    // 一過性状態のリセット（kill 跨ぎを補間/テレポート/終了忘れと誤検出しない・§2）。
    // ※ _offRouteActive / _offRouteRun はエピソード重複防止ラッチなので上で復元済み（リセット
    //   しない）。_suspended は復元後に通知が再発火しないよう false に戻す（クリーン再開）。
    _lastFix = null;
    _lastGoodChainage = null;
    _lastGoodTms = null;
    _lastCommitTms = null;
    _forceReacquire = false;
    _highSpeedRun = 0;
    _suspended = false;
    _lastPerp = 0;
    _initBuf.clear();
    _reacqBuf.clear();
    return true;
  }

  /// 次の接近対象スポット（進行方向で chainage が先のもの・最も近い）。
  ({NavSpot spot, double remainingM})? _nextSpot() {
    if (_committed == null) return null;
    final dir = _direction ?? 1;
    NavSpot? best;
    double bestRem = double.infinity;
    for (final s in spots) {
      if (!s.isApproachTarget) continue;
      final dfs = s.distanceFromStart;
      if (dfs == null) continue;
      final rem = dir > 0 ? (dfs - _committed!) : (_committed! - dfs);
      if (rem > 0 && rem < bestRem) {
        bestRem = rem;
        best = s;
      }
    }
    if (best == null) return null;
    return (spot: best, remainingM: bestRem);
  }

  /// §7 E: 駐車場へ「ルート沿いに戻って約Xkm」。
  /// parking スポットの distance_from_start と現在進捗の差分（追加データ取得ゼロ）。
  /// 周回（起点≈終点）は短い側を採る。直線距離+方角はやらない（誤誘導の実害・§7）。
  double? _returnToParkingMeters() {
    if (_committed == null) return null;
    final isLoop = haversineMeters(line.first, line.last) <= 30;
    double? best;
    for (final s in spots) {
      if (s.category != 'parking') continue;
      final dfs = s.distanceFromStart;
      if (dfs == null) continue;
      var d = (dfs - _committed!).abs();
      if (isLoop) d = math.min(d, totalMeters - d);
      if (best == null || d < best) best = d;
    }
    return best;
  }

  NavState get state {
    // 重要: この getter は**副作用を持たない**（読み取り専用）。初期化の確定は processFix が
    // initConfirm 個の good fix を集めた時点でのみ行う。NavController.feed は毎 fix 後に
    // この getter を読むため、ここで _finalizeInit を呼ぶと初期化バッファ（方向推定・周回の
    // 0/total 二義性解消）が最初の1 fix で誤って確定してしまう（ライブ経路のみ顕在化し、
    // 全 fix 投入後に1回だけ読む §14 ハーネスでは検出されない）。
    final committed = _committed ?? 0;
    final dir = _direction ?? 1;
    final remaining = dir > 0
        ? math.max(0.0, totalMeters - committed)
        : math.max(0.0, committed);
    final next = _nextSpot();
    return NavState(
      ready: _committed != null,
      chainageMeters: committed,
      totalMeters: totalMeters,
      progressPct: totalMeters > 0 ? (committed / totalMeters).clamp(0.0, 1.0) : 0,
      remainingMeters: remaining,
      maxProgressPct: totalMeters > 0 ? (_maxChainage / totalMeters).clamp(0.0, 1.0) : 0,
      coveragePct: _coverage.coverage(),
      isCompleted: _completed,
      minGoalDistanceM: _minGoalDist,
      offRouteDistanceM: _lastPerp,
      offRouteActive: _offRouteActive,
      offRouteEvents: _offRouteEvents,
      suspended: _suspended,
      direction: dir,
      firedApproachSpotIds: Set.unmodifiable(_firedApproach),
      nextSpot: next?.spot,
      nextSpotRemainingMeters: next?.remainingM,
      returnToParkingMeters: _returnToParkingMeters(),
    );
  }
}

class _InitSample {
  final double chain; // global投影の chainage（フォールバック用）
  final int tMillis;
  final LatLng pos; // 起点アンカー判定・窓付き再投影で1レーンへ畳むのに使う
  _InitSample(this.chain, this.tMillis, this.pos);
}
