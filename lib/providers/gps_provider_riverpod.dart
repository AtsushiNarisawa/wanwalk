import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/walk_mode.dart';
import '../services/gps_service.dart';
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
        final now = DateTime.now();
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
    state = state.copyWith(
      isRecording: false,
      isPaused: false,
      currentRoutePoints: [],
      errorMessage: null,
      startTime: null,
      distance: 0.0,
      elapsedSeconds: 0,
    );
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
        
        // 経過時間を計算
        final elapsed = state.startTime != null
            ? DateTime.now().difference(state.startTime!).inSeconds
            : 0;
        
        // 最新の位置情報をcurrentLocationに設定
        final currentLoc = points.isNotEmpty ? points.last.latLng : null;
        
        state = state.copyWith(
          currentRoutePoints: points,
          currentLocation: currentLoc,
          distance: totalDistance,
          elapsedSeconds: elapsed,
        );
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
