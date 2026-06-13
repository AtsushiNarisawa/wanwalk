import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../nav/route_nav_engine.dart';

/// LAYER1_NAV_SPEC §2: 沿線距離ナビエンジンを GPS に接続する Riverpod コントローラ。
///
/// nav 状態は **画面 State でなく Provider** に持つ（walking_screen は最小化→復帰で
/// 再生成され State が消えるため・申し送り）。walking_screen は:
///   1) ルート線とスポットが揃ったら [configure]
///   2) gpsNotifier.navFixStream を [attach]（一時停止判定を渡す）
///   3) ref.watch(navControllerProvider) で NavState を購読しUI描画
///   4) 散歩終了時に最新 NavState から NavCompletion を作って保存
/// テストは [feed] に NavFix を直接流して検証できる（Position 不要）。
class NavController extends StateNotifier<NavState> {
  RouteNavEngine? _engine;
  StreamSubscription<Position>? _sub;
  bool Function()? _isPaused;
  int? _startMs;

  NavController() : super(NavState.empty);

  bool get isReady => _engine != null;
  NavState? get current => _engine?.state;

  /// ルート線＋スポットでエンジンを構成（再構成時は購読も切る）。
  void configure({
    required List<LatLng> line,
    required List<NavSpot> spots,
    NavParams params = const NavParams(),
    void Function(NavApproachEvent event)? onApproach,
    void Function(NavOffRouteEvent event)? onOffRoute,
  }) {
    _detach();
    _startMs = null;
    if (line.length < 2) {
      _engine = null;
      state = NavState.empty;
      return;
    }
    _engine = RouteNavEngine(line, spots,
        p: params, onApproach: onApproach, onOffRoute: onOffRoute);
    state = _engine!.state;
  }

  /// 1フィックスを流す（テスト/任意注入用）。
  void feed(NavFix fix) {
    final e = _engine;
    if (e == null) return;
    e.processFix(fix);
    state = e.state;
  }

  /// GpsService の生 Position ストリームを接続。isPaused は moving 判定に使う。
  void attach(Stream<Position> positions, {bool Function()? isPaused}) {
    _sub?.cancel();
    _isPaused = isPaused;
    _sub = positions.listen((p) {
      // §2: 一時停止中は全 nav 判定を停止する。GpsService は現在地追従のため一時停止中も
      // navFix を流す設計なので、ここで止める（fix を流さない＝進捗/接近/逸脱/完走が凍結）。
      if (_isPaused?.call() ?? false) return;
      final ts = p.timestamp.millisecondsSinceEpoch;
      _startMs ??= ts;
      feed(NavFix(
        position: LatLng(p.latitude, p.longitude),
        accuracyM: p.accuracy,
        tMillis: ts - _startMs!,
        moving: true,
      ));
    });
  }

  void _detach() {
    _sub?.cancel();
    _sub = null;
  }

  /// 散歩終了/破棄時にリセット。
  void reset() {
    _detach();
    _engine = null;
    _startMs = null;
    state = NavState.empty;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }
}

/// nav 状態 Provider（画面外で生存させ、最小化→復帰でリセットされないようにする）。
final navControllerProvider =
    StateNotifierProvider<NavController, NavState>((ref) => NavController());
