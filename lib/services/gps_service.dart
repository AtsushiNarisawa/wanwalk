import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../utils/logger.dart';

/// GPS位置情報サービス
class GpsService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<RoutePoint> _currentRoutePoints = [];
  DateTime? _startTime;
  bool _isRecording = false;
  bool _isPaused = false;

  /// 位置情報の権限をチェック
  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 位置情報サービスが有効かチェック
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 位置情報サービスが無効
      return false;
    }

    // 権限をチェック
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 権限をリクエスト
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // 権限が拒否された
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 権限が永久に拒否された
      return false;
    }

    // 権限OK
    return true;
  }

  /// 現在位置を取得
  Future<LatLng?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          appLog('位置情報の権限がありません');
        }
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      if (kDebugMode) {
        appLog('位置情報の取得に失敗しました: $e');
      }
      return null;
    }
  }

  /// プラットフォーム別の位置情報設定を構築。
  ///
  /// A4: iOS はバックグラウンドでも記録を継続させるため
  /// `allowBackgroundLocationUpdates` 等を明示的に有効化する
  /// （Info.plist の UIBackgroundModes:location 宣言だけでは実装が無効だった）。
  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
        activityType: ActivityType.fitness,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'WanWalk',
          notificationText: '散歩を記録中です',
          enableWakeLock: true,
        ),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );
  }

  /// ルート記録を開始
  ///
  /// [onStreamError] 位置情報ストリームがエラー（権限剥奪・GPS障害等）で
  /// 中断された場合に呼ばれる。A10: 無言停止を防ぐため呼び出し側へ通知する。
  Future<bool> startRecording({void Function(Object error)? onStreamError}) async {
    if (_isRecording) {
      if (kDebugMode) {
        appLog('既に記録中です');
      }
      return false;
    }

    final hasPermission = await checkPermission();
    if (!hasPermission) {
      if (kDebugMode) {
        appLog('位置情報の権限がありません');
      }
      return false;
    }

    _currentRoutePoints.clear();
    _startTime = DateTime.now();
    _isRecording = true;
    _isPaused = false;  // 一時停止状態をリセット

    // 位置情報の更新を監視（A4: プラットフォーム別設定で BG 記録を有効化）
    final locationSettings = _buildLocationSettings();

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _addRoutePoint(position);
      },
      // A10: ストリームエラーを握り潰さず可視化＋通知。
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          appLog('❌ 位置情報ストリームエラー: $e');
        }
        onStreamError?.call(e);
      },
      cancelOnError: false,
    );

    if (kDebugMode) {
      appLog('ルート記録を開始しました');
    }
    return true;
  }

  /// ルート記録を停止
  RouteModel? stopRecording({
    required String userId,
    required String title,
    String? description,
    String? dogId,
    bool isPublic = false,
  }) {
    if (kDebugMode) {
      appLog('🔵 stopRecording 呼び出し: isRecording=$_isRecording, points=${_currentRoutePoints.length}');
    }
    
    if (!_isRecording) {
      if (kDebugMode) {
        appLog('❌ 記録していません');
      }
      return null;
    }

    _isRecording = false;
    _isPaused = false;  // 一時停止状態もリセット
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    if (kDebugMode) {
      appLog('🔵 記録されたポイント数: ${_currentRoutePoints.length}');
    }
    
    if (_currentRoutePoints.isEmpty) {
      if (kDebugMode) {
        appLog('❌ 記録されたポイントがありません');
      }
      return null;
    }
    
    // テスト用：最低1ポイントあればOK（本番では2ポイント以上推奨）
    if (_currentRoutePoints.isEmpty) {
      if (kDebugMode) {
        appLog('❌ ポイントが不足しています（最低1ポイント必要）');
      }
      return null;
    }

    // 所要時間を計算
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    if (kDebugMode) {
      appLog('🔵 ルートモデル作成中: userId=$userId, title=$title, points=${_currentRoutePoints.length}');
    }

    // 終了時刻
    final endTime = DateTime.now();
    
    // ルートモデルを作成
    final route = RouteModel(
      userId: userId,
      dogId: dogId,
      title: title,
      description: description,
      points: List.from(_currentRoutePoints),
      duration: duration,
      startedAt: _startTime,  // 開始時刻を明示的に設定
      endedAt: endTime,       // 終了時刻を明示的に設定
      isPublic: isPublic,
    );

    // 距離を計算
    final distance = route.calculateDistance();
    if (kDebugMode) {
      appLog('🔵 計算された距離: $distance meters');
    }

    final completedRoute = route.copyWith(distance: distance);

    // リセット
    _currentRoutePoints.clear();
    _startTime = null;

    if (kDebugMode) {
      appLog('✅ ルート記録を停止しました: ${completedRoute.formatDistance()}, ${completedRoute.formatDuration()}');
    }
    return completedRoute;
  }

  /// 現在の記録からルートモデルを生成する（A5: 記録状態は変更しない）。
  ///
  /// `stopRecording` と異なり、ストリーム停止・ポイント破棄・フラグリセットを
  /// 行わない。保存に失敗してもデータがメモリに残り、リトライ可能になる。
  /// 保存成功後に [finalizeRecording] を呼んで初めて記録を確定終了する。
  ///
  /// [durationSeconds] 一時停止時間を控除した実経過秒（A9）。未指定時は
  /// 開始からの単純経過秒。
  RouteModel? buildCurrentRoute({
    required String userId,
    required String title,
    String? description,
    String? dogId,
    bool isPublic = false,
    int? durationSeconds,
  }) {
    if (!_isRecording) {
      if (kDebugMode) {
        appLog('❌ 記録していません（buildCurrentRoute）');
      }
      return null;
    }
    if (_currentRoutePoints.isEmpty) {
      if (kDebugMode) {
        appLog('❌ 記録されたポイントがありません（buildCurrentRoute）');
      }
      return null;
    }

    final duration = durationSeconds ??
        (_startTime != null
            ? DateTime.now().difference(_startTime!).inSeconds
            : 0);

    final route = RouteModel(
      userId: userId,
      dogId: dogId,
      title: title,
      description: description,
      points: List.from(_currentRoutePoints),
      duration: duration,
      startedAt: _startTime,
      endedAt: DateTime.now(),
      isPublic: isPublic,
    );

    final distance = route.calculateDistance();
    return route.copyWith(distance: distance);
  }

  /// 記録を確定終了してリセット（A5: 保存成功後に呼ぶ）。
  ///
  /// ストリームを停止し、ポイント・開始時刻・フラグをクリアする。
  void finalizeRecording() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _currentRoutePoints.clear();
    _startTime = null;
    _isRecording = false;
    _isPaused = false;
    if (kDebugMode) {
      appLog('✅ 記録を確定終了しました（finalizeRecording）');
    }
  }

  /// 記録を一時停止
  void pauseRecording() {
    if (!_isRecording || _isPaused) {
      if (kDebugMode) {
        appLog('一時停止できません: isRecording=$_isRecording, isPaused=$_isPaused');
      }
      return;
    }

    _isPaused = true;
    if (kDebugMode) {
      appLog('✅ GPS記録を一時停止しました');
    }
  }

  /// 記録を再開
  void resumeRecording() {
    if (!_isRecording || !_isPaused) {
      if (kDebugMode) {
        appLog('再開できません: isRecording=$_isRecording, isPaused=$_isPaused');
      }
      return;
    }

    _isPaused = false;
    if (kDebugMode) {
      appLog('✅ GPS記録を再開しました');
    }
  }

  /// ポイントを追加
  void _addRoutePoint(Position position) {
    if (!_isRecording || _isPaused) return;

    final point = RoutePoint(
      latLng: LatLng(position.latitude, position.longitude),
      altitude: position.altitude,
      timestamp: DateTime.now(),
      sequenceNumber: _currentRoutePoints.length,
    );

    _currentRoutePoints.add(point);
    if (kDebugMode) {
      appLog('ポイント追加: ${point.latLng.latitude}, ${point.latLng.longitude}');
    }
  }

  /// 記録中かどうか
  bool get isRecording => _isRecording;

  /// 一時停止中かどうか
  bool get isPaused => _isPaused;

  /// 現在のルートポイント数
  int get currentPointCount => _currentRoutePoints.length;

  /// 現在のルートポイントを取得
  List<RoutePoint> get currentRoutePoints => List.from(_currentRoutePoints);

  /// リソースを解放
  void dispose() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _currentRoutePoints.clear();
    _isRecording = false;
    _isPaused = false;
  }
}
