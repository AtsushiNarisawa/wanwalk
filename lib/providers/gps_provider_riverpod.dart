import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/official_route.dart';
import '../models/route_model.dart';
import '../models/walk_mode.dart';
import '../services/active_walk_snapshot.dart';
import '../services/gps_service.dart';
import 'active_walk_provider.dart';
import 'official_route_provider.dart';
import 'walk_mode_provider.dart';

/// GPS記録の状態
class GpsState {
  final bool isInitialized; // 記録を開始したかどうか（スタートボタンを押したか）
  final bool isRecording;
  final bool isPaused;
  final LatLng? currentLocation;
  final List<RoutePoint> currentRoutePoints;
  final String? errorMessage;
  final WalkMode walkMode; // 記録開始時のモード
  final DateTime? startTime; // 記録開始時刻
  final double distance; // 累積距離（メートル）
  final int elapsedSeconds; // 経過時間（秒）

  GpsState({
    this.isInitialized = false,
    this.isRecording = false,
    this.isPaused = false,
    this.currentLocation,
    this.currentRoutePoints = const [],
    this.errorMessage,
    required this.walkMode,
    this.startTime,
    this.distance = 0.0,
    this.elapsedSeconds = 0,
  });

  GpsState copyWith({
    bool? isInitialized,
    bool? isRecording,
    bool? isPaused,
    LatLng? currentLocation,
    List<RoutePoint>? currentRoutePoints,
    String? errorMessage,
    WalkMode? walkMode,
    DateTime? startTime,
    double? distance,
    int? elapsedSeconds,
  }) {
    return GpsState(
      isInitialized: isInitialized ?? this.isInitialized,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      currentLocation: currentLocation ?? this.currentLocation,
      currentRoutePoints: currentRoutePoints ?? this.currentRoutePoints,
      errorMessage: errorMessage,
      walkMode: walkMode ?? this.walkMode,
      startTime: startTime ?? this.startTime,
      distance: distance ?? this.distance,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  int get currentPointCount => currentRoutePoints.length;
  bool get hasPermission => currentLocation != null;
  
  /// 距離を km 単位でフォーマット
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)}km';
    }
  }
  
  /// 経過時間をフォーマット（分または時間:分）
  String get formattedDuration {
    if (elapsedSeconds < 60) {
      return '$elapsedSeconds秒';
    } else if (elapsedSeconds < 3600) {
      return '${(elapsedSeconds / 60).toStringAsFixed(0)}分';
    } else {
      final hours = elapsedSeconds ~/ 3600;
      final minutes = (elapsedSeconds % 3600) ~/ 60;
      return '$hours時間$minutes分';
    }
  }
}

/// GPS記録を管理するNotifier（Riverpod版）
class GpsNotifier extends StateNotifier<GpsState> {
  final GpsService _gpsService = GpsService();
  final Ref ref;

  /// A9: 一時停止の累積時間（経過時間から控除する）
  Duration _pausedTotal = Duration.zero;

  /// A9: 現在の一時停止が始まった時刻（停止中のみ非 null）
  DateTime? _pausedAt;

  /// A11: 直近で永続化したポイント数（差分閾値で書込みをスロットルするため）
  int _lastPersistedPointCount = 0;

  GpsNotifier(this.ref) : super(GpsState(walkMode: WalkMode.daily));

  /// A9: 一時停止時間を控除した実経過秒を計算する。
  int _activeElapsedSeconds() {
    if (state.startTime == null) return 0;
    final now = DateTime.now();
    var paused = _pausedTotal;
    if (_pausedAt != null) {
      paused += now.difference(_pausedAt!);
    }
    final secs = now.difference(state.startTime!).inSeconds - paused.inSeconds;
    return secs < 0 ? 0 : secs;
  }

  /// 現在位置を取得
  Future<void> getCurrentLocation() async {
    try {
      final location = await _gpsService.getCurrentPosition();
      state = state.copyWith(
        currentLocation: location,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: '位置情報の取得に失敗しました: ${e.toString()}',
      );
    }
  }

  /// GPS権限をチェック
  Future<bool> checkPermission() async {
    try {
      final hasPermission = await _gpsService.checkPermission();
      if (!hasPermission) {
        state = state.copyWith(
          errorMessage: '位置情報の権限が必要です',
        );
      }
      return hasPermission;
    } catch (e) {
      state = state.copyWith(
        errorMessage: '権限チェックに失敗しました: ${e.toString()}',
      );
      return false;
    }
  }

  /// 記録を開始（記録モードを state に保存）。
  ///
  /// [mode] を渡すと、そのモードで記録する（おでかけ/日常を呼び出し画面が明示）。
  /// 省略時は後方互換で walkModeProvider を読む。
  /// ※ おでかけ散歩を route_detail→「このルートを歩く」から開始する経路は
  ///   walk_mode_switcher を通らず walkModeProvider が daily のままになるため、
  ///   walking_screen から WalkMode.outing を明示する（kill→復元時のルート再取得に必要）。
  Future<bool> startRecording({WalkMode? mode}) async {
    try {
      // 記録モードを確定（明示指定 > walkModeProvider）
      final currentMode = mode ?? ref.read(walkModeProvider);

      // A10: ストリームエラーを errorMessage で可視化する
      final success = await _gpsService.startRecording(
        onStreamError: (e) {
          state = state.copyWith(
            errorMessage: '位置情報の取得が中断されました。権限やGPSの状態を確認してください',
          );
        },
      );
      if (success) {
        final now = DateTime.now();
        // A9: 一時停止の累積をリセット
        _pausedTotal = Duration.zero;
        _pausedAt = null;
        state = state.copyWith(
          isInitialized: true, // スタートボタンを押した
          isRecording: true,
          isPaused: false,
          currentRoutePoints: [],
          errorMessage: null,
          walkMode: currentMode, // 記録開始時のモードを保存
          startTime: now,
          distance: 0.0,
          elapsedSeconds: 0,
        );

        // 定期的に統計情報を更新
        _startStatsUpdater();
        unawaited(_persistSnapshot()); // A11: 開始直後に1度退避
        return true;
      } else {
        state = state.copyWith(
          errorMessage: '記録の開始に失敗しました',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: '記録開始エラー: ${e.toString()}',
      );
      return false;
    }
  }

  /// 記録を一時停止
  void pauseRecording() {
    if (!state.isRecording || state.isPaused) return;

    _gpsService.pauseRecording();
    _pausedAt = DateTime.now(); // A9: 停止開始時刻を記録
    state = state.copyWith(isPaused: true);
    unawaited(_persistSnapshot()); // A11
  }

  /// 記録を再開
  void resumeRecording() {
    if (!state.isRecording || !state.isPaused) return;

    _gpsService.resumeRecording();
    // A9: 停止していた時間を累積に加算
    if (_pausedAt != null) {
      _pausedTotal += DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
    }
    state = state.copyWith(isPaused: false);
    unawaited(_persistSnapshot()); // A11
  }

  /// 現在の記録からルートを生成する（A5: 記録状態は変更しない）。
  ///
  /// 保存に失敗してもデータが残りリトライ可能。保存成功後に [finalizeWalk] を
  /// 呼んで記録を確定終了する。
  RouteModel? buildCurrentRoute({
    required String userId,
    required String title,
    String? description,
    String? dogId,
    bool isPublic = false,
  }) {
    if (!state.isRecording) {
      state = state.copyWith(errorMessage: '記録していません');
      return null;
    }
    return _gpsService.buildCurrentRoute(
      userId: userId,
      title: title,
      description: description,
      dogId: dogId,
      isPublic: isPublic,
      durationSeconds: _activeElapsedSeconds(), // A9: 一時停止控除済み
    );
  }

  /// 記録を確定終了してリセットする（A5: 保存成功後に呼ぶ）。
  void finalizeWalk() {
    _gpsService.finalizeRecording();
    _pausedTotal = Duration.zero;
    _pausedAt = null;
    unawaited(_clearSnapshot()); // A11: 保存成功＝退避破棄
    state = GpsState(walkMode: state.walkMode);
  }

  /// 記録を停止
  RouteModel? stopRecording({
    required String userId,
    required String title,
    String? description,
    String? dogId,
    bool isPublic = false,
  }) {
    if (!state.isRecording) {
      state = state.copyWith(
        errorMessage: '記録していません',
      );
      return null;
    }

    final route = _gpsService.stopRecording(
      userId: userId,
      title: title,
      description: description,
      dogId: dogId,
      isPublic: isPublic,
    );

    if (route != null) {
      unawaited(_clearSnapshot()); // A11: 保存成功＝退避破棄
      state = state.copyWith(
        isInitialized: false, // リセット
        isRecording: false,
        isPaused: false,
        currentRoutePoints: [],
        errorMessage: null,
        startTime: null,
        distance: 0.0,
        elapsedSeconds: 0,
      );
    } else {
      state = state.copyWith(
        errorMessage: 'ルート記録に失敗しました（ポイント不足）',
      );
    }

    return route;
  }

  /// 記録をキャンセル
  void cancelRecording() {
    _gpsService.dispose();
    _pausedTotal = Duration.zero;
    _pausedAt = null;
    unawaited(_clearSnapshot()); // A11
    // copyWith は null 上書きできないため新規 state でクリーンにリセット
    state = GpsState(walkMode: state.walkMode);
  }

  // ─────────────────────────────────────────────────────────────
  // A11: 記録状態のローカル永続化（アプリ kill/クラッシュからの復元）
  // ─────────────────────────────────────────────────────────────

  /// 現在の記録状態を SharedPreferences へ退避する（best-effort）。
  Future<void> _persistSnapshot() async {
    if (!state.isRecording || state.startTime == null) return;
    final active = ref.read(activeWalkProvider);
    final points = _gpsService.currentRoutePoints;
    _lastPersistedPointCount = points.length;
    await ActiveWalkSnapshotStore.save(
      ActiveWalkSnapshot(
        isPaused: state.isPaused,
        walkMode: state.walkMode,
        startTime: state.startTime!,
        pausedTotalMs: _pausedTotal.inMilliseconds,
        pausedAt: _pausedAt,
        points: points,
        routeId: active.routeId,
        routeName: active.routeName,
      ),
    );
  }

  /// 退避したスナップショットを破棄する（記録の確定終了・キャンセル時）。
  Future<void> _clearSnapshot() async {
    _lastPersistedPointCount = 0;
    await ActiveWalkSnapshotStore.clear();
  }

  /// 起動時に1度だけ呼ぶ。退避された記録があれば復元してストリームを再開する。
  ///
  /// 冪等：既に記録中なら何もしない。破損・点なしのスナップショットは破棄して通常起動。
  /// おでかけ散歩は公式ルート実体を再取得し、ActiveWalkBanner から復帰可能にする。
  Future<bool> restoreIfAny() async {
    if (state.isRecording) return false; // 二重復元防止
    final snapshot = await ActiveWalkSnapshotStore.load();
    if (snapshot == null) return false;
    if (snapshot.points.isEmpty) {
      await ActiveWalkSnapshotStore.clear();
      return false;
    }

    try {
      _gpsService.restoreState(
        points: snapshot.points,
        startTime: snapshot.startTime,
        isPaused: snapshot.isPaused,
        onStreamError: (e) {
          state = state.copyWith(
            errorMessage:
                '位置情報の取得が中断されました。権限やGPSの状態を確認してください',
          );
        },
      );

      _pausedTotal = Duration(milliseconds: snapshot.pausedTotalMs);
      _pausedAt = snapshot.pausedAt;
      _lastPersistedPointCount = snapshot.points.length;

      // 距離を再計算
      double totalDistance = 0.0;
      for (int i = 1; i < snapshot.points.length; i++) {
        totalDistance += _calculateDistance(
            snapshot.points[i - 1].latLng, snapshot.points[i].latLng);
      }

      // 経過秒を再計算（A9: 一時停止控除込み・state 確定前なので手計算）
      final now = DateTime.now();
      var paused = Duration(milliseconds: snapshot.pausedTotalMs);
      if (snapshot.pausedAt != null) {
        paused += now.difference(snapshot.pausedAt!);
      }
      final elapsedRaw = now.difference(snapshot.startTime).inSeconds -
          paused.inSeconds;

      state = GpsState(
        isInitialized: true,
        isRecording: true,
        isPaused: snapshot.isPaused,
        currentLocation: snapshot.points.last.latLng,
        currentRoutePoints: snapshot.points,
        walkMode: snapshot.walkMode,
        startTime: snapshot.startTime,
        distance: totalDistance,
        elapsedSeconds: elapsedRaw < 0 ? 0 : elapsedRaw,
      );

      // ActiveWalkBanner 復帰用に散歩状態も復元
      if (snapshot.walkMode == WalkMode.outing && snapshot.routeId != null) {
        OfficialRoute? route;
        try {
          route =
              await ref.read(routeByIdProvider(snapshot.routeId!).future);
        } catch (_) {
          route = null; // オフライン等で再取得失敗でも点データは保持済み
        }
        ref.read(activeWalkProvider.notifier).startWalk(
              mode: WalkMode.outing,
              routeId: snapshot.routeId,
              routeName: snapshot.routeName,
              outingRoute: route,
            );
      } else {
        ref.read(activeWalkProvider.notifier).startWalk(mode: WalkMode.daily);
      }

      _startStatsUpdater();
      return true;
    } catch (e) {
      // 復元失敗は通常起動へフォールバック（壊れたスナップショットを残さない）
      await ActiveWalkSnapshotStore.clear();
      _resetAfterFailedRestore();
      return false;
    }
  }

  void _resetAfterFailedRestore() {
    _gpsService.dispose();
    _pausedTotal = Duration.zero;
    _pausedAt = null;
    _lastPersistedPointCount = 0;
    state = GpsState(walkMode: WalkMode.daily);
  }

  /// 定期的に統計情報を更新（距離・時間・ポイント数）
  void _startStatsUpdater() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (state.isRecording && !state.isPaused) {
        final points = _gpsService.currentRoutePoints;
        
        // 距離を計算（Haversine公式）
        double totalDistance = 0.0;
        for (int i = 1; i < points.length; i++) {
          final prev = points[i - 1].latLng;
          final curr = points[i].latLng;
          totalDistance += _calculateDistance(prev, curr);
        }
        
        // 経過時間を計算（A9: 一時停止時間を控除した実経過秒）
        final elapsed = _activeElapsedSeconds();

        // 最新の位置情報をcurrentLocationに設定
        final currentLoc = points.isNotEmpty ? points.last.latLng : null;
        
        state = state.copyWith(
          currentRoutePoints: points,
          currentLocation: currentLoc,
          distance: totalDistance,
          elapsedSeconds: elapsed,
        );
        // A11: 一定間隔（直近退避から +5 点）で記録をローカル退避
        if (points.length - _lastPersistedPointCount >= 5) {
          unawaited(_persistSnapshot());
        }
        return true;
      } else if (state.isRecording && state.isPaused) {
        // 一時停止中は時間だけ停止、ポイントは更新
        state = state.copyWith(
          currentRoutePoints: _gpsService.currentRoutePoints,
        );
        return true;
      }
      return false;
    });
  }
  
  /// Haversine公式で2点間の距離を計算（メートル）
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 地球の半径（メートル）
    
    final lat1Rad = point1.latitude * (3.141592653589793 / 180);
    final lat2Rad = point2.latitude * (3.141592653589793 / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (3.141592653589793 / 180);
    final deltaLon = (point2.longitude - point1.longitude) * (3.141592653589793 / 180);
    
    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.pow(math.sin(deltaLon / 2), 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  /// エラーメッセージをクリア
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }
}

/// GPS Provider（Riverpod版）
final gpsProviderRiverpod = StateNotifierProvider<GpsNotifier, GpsState>(
  (ref) => GpsNotifier(ref),
);

/// 現在記録中かどうか
final isRecordingProvider = Provider<bool>((ref) {
  return ref.watch(gpsProviderRiverpod).isRecording;
});

/// 現在一時停止中かどうか
final isPausedProvider = Provider<bool>((ref) {
  return ref.watch(gpsProviderRiverpod).isPaused;
});

/// 現在の位置
final currentLocationProvider = Provider<LatLng?>((ref) {
  return ref.watch(gpsProviderRiverpod).currentLocation;
});

/// 現在のルートポイント数
final currentPointCountProvider = Provider<int>((ref) {
  return ref.watch(gpsProviderRiverpod).currentPointCount;
});

/// 記録中のWalkMode
final recordingWalkModeProvider = Provider<WalkMode>((ref) {
  return ref.watch(gpsProviderRiverpod).walkMode;
});
