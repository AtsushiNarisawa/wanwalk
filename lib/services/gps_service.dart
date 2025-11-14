import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';

/// GPS位置情報サービス
class GpsService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<RoutePoint> _currentRoutePoints = [];
  DateTime? _startTime;
  bool _isRecording = false;

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
        print('位置情報の権限がありません');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('位置情報の取得に失敗しました: $e');
      return null;
    }
  }

  /// ルート記録を開始
  Future<bool> startRecording() async {
    if (_isRecording) {
      print('既に記録中です');
      return false;
    }

    final hasPermission = await checkPermission();
    if (!hasPermission) {
      print('位置情報の権限がありません');
      return false;
    }

    _currentRoutePoints.clear();
    _startTime = DateTime.now();
    _isRecording = true;

    // 位置情報の更新を監視
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10メートル移動ごとに更新
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _addRoutePoint(position);
    });

    print('ルート記録を開始しました');
    return true;
  }

  /// ルート記録を停止
  RouteModel? stopRecording({
    required String userId,
    required String title,
    String? description,
    String? dogId,
  }) {
    if (!_isRecording) {
      print('記録していません');
      return null;
    }

    _isRecording = false;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    if (_currentRoutePoints.isEmpty) {
      print('記録されたポイントがありません');
      return null;
    }

    // 所要時間を計算
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    // ルートモデルを作成
    final route = RouteModel(
      userId: userId,
      dogId: dogId,
      title: title,
      description: description,
      points: List.from(_currentRoutePoints),
      duration: duration,
    );

    // 距離を計算
    final distance = route.calculateDistance();

    final completedRoute = route.copyWith(distance: distance);

    // リセット
    _currentRoutePoints.clear();
    _startTime = null;

    print('ルート記録を停止しました: ${completedRoute.formatDistance()}, ${completedRoute.formatDuration()}');
    return completedRoute;
  }

  /// ポイントを追加
  void _addRoutePoint(Position position) {
    if (!_isRecording) return;

    final point = RoutePoint(
      latLng: LatLng(position.latitude, position.longitude),
      altitude: position.altitude,
      timestamp: DateTime.now(),
      sequenceNumber: _currentRoutePoints.length,
    );

    _currentRoutePoints.add(point);
    print('ポイント追加: ${point.latLng.latitude}, ${point.latLng.longitude}');
  }

  /// 記録中かどうか
  bool get isRecording => _isRecording;

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
  }
}
