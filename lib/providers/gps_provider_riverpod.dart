import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/walk_mode.dart';
import '../services/gps_service.dart';
import 'walk_mode_provider.dart';

/// GPS記録の状態
class GpsState {
  final bool isRecording;
  final bool isPaused;
  final LatLng? currentLocation;
  final List<RoutePoint> currentRoutePoints;
  final String? errorMessage;
  final WalkMode walkMode; // 記録開始時のモード

  GpsState({
    this.isRecording = false,
    this.isPaused = false,
    this.currentLocation,
    this.currentRoutePoints = const [],
    this.errorMessage,
    required this.walkMode,
  });

  GpsState copyWith({
    bool? isRecording,
    bool? isPaused,
    LatLng? currentLocation,
    List<RoutePoint>? currentRoutePoints,
    String? errorMessage,
    WalkMode? walkMode,
  }) {
    return GpsState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      currentLocation: currentLocation ?? this.currentLocation,
      currentRoutePoints: currentRoutePoints ?? this.currentRoutePoints,
      errorMessage: errorMessage,
      walkMode: walkMode ?? this.walkMode,
    );
  }

  int get currentPointCount => currentRoutePoints.length;
  bool get hasPermission => currentLocation != null;
}

/// GPS記録を管理するNotifier（Riverpod版）
class GpsNotifier extends StateNotifier<GpsState> {
  final GpsService _gpsService = GpsService();
  final Ref ref;

  GpsNotifier(this.ref) : super(GpsState(walkMode: WalkMode.daily));

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

  /// 記録を開始（現在のWalkModeを記録）
  Future<bool> startRecording() async {
    try {
      // 現在のWalkModeを取得
      final currentMode = ref.read(walkModeProvider);

      final success = await _gpsService.startRecording();
      if (success) {
        state = state.copyWith(
          isRecording: true,
          isPaused: false,
          currentRoutePoints: [],
          errorMessage: null,
          walkMode: currentMode, // 記録開始時のモードを保存
        );

        // 定期的にポイント数を更新
        _startPointCountUpdater();
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
    state = state.copyWith(isPaused: true);
  }

  /// 記録を再開
  void resumeRecording() {
    if (!state.isRecording || !state.isPaused) return;

    _gpsService.resumeRecording();
    state = state.copyWith(isPaused: false);
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
      state = state.copyWith(
        isRecording: false,
        isPaused: false,
        currentRoutePoints: [],
        errorMessage: null,
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
    state = state.copyWith(
      isRecording: false,
      isPaused: false,
      currentRoutePoints: [],
      errorMessage: null,
    );
  }

  /// 定期的にポイント数を更新
  void _startPointCountUpdater() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (state.isRecording) {
        state = state.copyWith(
          currentRoutePoints: _gpsService.currentRoutePoints,
        );
        return true;
      }
      return false;
    });
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
