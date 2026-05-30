import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:latlong2/latlong.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wanwalk/services/gps_service.dart';

/// A5/A11: 散歩保存の信頼性。
/// - buildCurrentRoute は状態を破壊しない（保存失敗時にデータを保持しリトライ可能）
/// - finalizeRecording で初めて記録を確定終了（クリア）
/// 位置情報ストリームは GeolocatorPlatform を空ストリームの fake に差し替えて遮断する。
class _FakeGeolocator extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      const Stream<Position>.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GeolocatorPlatform.instance = _FakeGeolocator();
  });

  RoutePoint pt(double lat, double lng, int seq) => RoutePoint(
        latLng: LatLng(lat, lng),
        altitude: 0,
        timestamp: DateTime(2026, 5, 30, 10, seq),
        sequenceNumber: seq,
      );

  group('GpsService 散歩保存（A5/A11）', () {
    test('未記録時の buildCurrentRoute は null', () {
      final svc = GpsService();
      expect(svc.buildCurrentRoute(userId: 'u', title: 't'), isNull);
    });

    test('restoreState で注入 → buildCurrentRoute はルートを返し状態を破壊しない', () {
      final svc = GpsService();
      svc.restoreState(
        points: [pt(35.4360, 139.6380, 0), pt(35.4400, 139.6420, 1)],
        startTime: DateTime(2026, 5, 30, 10, 0),
        isPaused: false,
        onStreamError: (_) {},
      );
      expect(svc.isRecording, true);
      expect(svc.currentPointCount, 2);

      final route = svc.buildCurrentRoute(
        userId: 'u',
        title: '散歩',
        durationSeconds: 600,
      );
      expect(route, isNotNull);
      expect(route!.points.length, 2);
      expect(route.duration, 600); // A9: 控除済み経過秒を尊重
      expect(route.distance, greaterThan(0)); // 2 点間に距離あり

      // A5: buildCurrentRoute はリセットしない（保存失敗時リトライ可能）
      expect(svc.currentPointCount, 2);
      expect(svc.isRecording, true);
    });

    test('finalizeRecording で記録を確定終了（クリア）', () {
      final svc = GpsService();
      svc.restoreState(
        points: [pt(35.0, 139.0, 0)],
        startTime: DateTime(2026, 5, 30, 10, 0),
        isPaused: false,
        onStreamError: (_) {},
      );
      expect(svc.currentPointCount, 1);

      svc.finalizeRecording();
      expect(svc.currentPointCount, 0);
      expect(svc.isRecording, false);
      expect(svc.buildCurrentRoute(userId: 'u', title: 't'), isNull);
    });
  });
}
