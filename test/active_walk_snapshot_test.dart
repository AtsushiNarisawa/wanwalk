import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wanwalk/models/route_model.dart';
import 'package:wanwalk/models/walk_mode.dart';
import 'package:wanwalk/services/active_walk_snapshot.dart';

/// A11: 散歩記録スナップショットの直列化往復テスト。
/// kill/クラッシュ復元の信頼性は「保存した状態が欠損なく復元できる」ことが前提。
void main() {
  group('ActiveWalkSnapshot', () {
    RoutePoint pt(double lat, double lng, int seq) => RoutePoint(
          latLng: LatLng(lat, lng),
          altitude: 12.5,
          timestamp: DateTime.parse('2026-05-30T10:0$seq:00.000'),
          sequenceNumber: seq,
        );

    test('toJson/fromJson が全フィールドを往復で保つ（outing・一時停止中）', () {
      final original = ActiveWalkSnapshot(
        isPaused: true,
        walkMode: WalkMode.outing,
        startTime: DateTime.parse('2026-05-30T10:00:00.000'),
        pausedTotalMs: 42000,
        pausedAt: DateTime.parse('2026-05-30T10:05:00.000'),
        points: [pt(35.4361, 139.6380, 0), pt(35.4365, 139.6390, 1)],
        routeId: 'route-abc',
        routeName: '鎌倉海岸ルート',
      );

      // jsonEncode → jsonDecode を挟んで実ストア相当の経路を再現
      final decoded = ActiveWalkSnapshot.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);

      expect(decoded.isPaused, true);
      expect(decoded.walkMode, WalkMode.outing);
      expect(decoded.startTime, original.startTime);
      expect(decoded.pausedTotalMs, 42000);
      expect(decoded.pausedAt, original.pausedAt);
      expect(decoded.routeId, 'route-abc');
      expect(decoded.routeName, '鎌倉海岸ルート');
      expect(decoded.points.length, 2);
      expect(decoded.points[1].latLng.latitude, closeTo(35.4365, 1e-9));
      expect(decoded.points[1].latLng.longitude, closeTo(139.6390, 1e-9));
      expect(decoded.points[1].sequenceNumber, 1);
      expect(decoded.points[0].altitude, closeTo(12.5, 1e-9));
    });

    test('daily・pausedAt=null・routeId=null も往復で保つ', () {
      final original = ActiveWalkSnapshot(
        isPaused: false,
        walkMode: WalkMode.daily,
        startTime: DateTime.parse('2026-05-30T08:00:00.000'),
        pausedTotalMs: 0,
        pausedAt: null,
        points: [pt(35.0, 139.0, 0)],
        routeId: null,
        routeName: null,
      );

      final decoded = ActiveWalkSnapshot.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);

      expect(decoded.walkMode, WalkMode.daily);
      expect(decoded.isPaused, false);
      expect(decoded.pausedAt, isNull);
      expect(decoded.routeId, isNull);
      expect(decoded.routeName, isNull);
      expect(decoded.points.length, 1);
    });

    test('未知/欠損フィールドはフォールバックで安全に読める', () {
      final decoded = ActiveWalkSnapshot.fromJson({
        'startTime': '2026-05-30T09:00:00.000',
        // walkMode / isPaused / pausedTotalMs / points を意図的に欠落
      });
      expect(decoded.walkMode, WalkMode.daily); // 既定
      expect(decoded.isPaused, false);
      expect(decoded.pausedTotalMs, 0);
      expect(decoded.points, isEmpty);
    });

    test('§2 v2: navSnapshot / navStartEpochMs が往復で保たれる', () {
      final original = ActiveWalkSnapshot(
        isPaused: false,
        walkMode: WalkMode.outing,
        startTime: DateTime.parse('2026-06-17T10:00:00.000'),
        pausedTotalMs: 0,
        pausedAt: null,
        points: [pt(35.4361, 139.6380, 0)],
        routeId: 'route-xyz',
        routeName: 'テストルート',
        navSnapshot: {
          'v': 1,
          'coverageBits': '111000',
          'committedMeters': 123.4,
          'direction': 1,
          'firedApproachIds': ['s1', 's2'],
          'minGoalDistanceM': 42.0,
          'maxChainageM': 130.0,
          'completed': false,
          'offRouteEvents': 1,
          'recentRateMps': 0.83,
          'totalMeters': 150.0,
          'visits': const [],
        },
        navStartEpochMs: 1700000000000,
      );

      final decoded = ActiveWalkSnapshot.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);

      expect(decoded.navStartEpochMs, 1700000000000);
      expect(decoded.navSnapshot, isNotNull);
      expect(decoded.navSnapshot!['coverageBits'], '111000');
      expect(decoded.navSnapshot!['committedMeters'], 123.4);
      expect(decoded.navSnapshot!['firedApproachIds'], ['s1', 's2']);
      // toJson は version 2 を書く（形式の世代）。
      expect(original.toJson()['version'], 2);
    });

    test('旧 v1 スナップショット（nav なし）は navSnapshot=null で後方互換', () {
      final v1 = {
        'version': 1,
        'isPaused': false,
        'walkMode': 'outing',
        'startTime': '2026-05-01T10:00:00.000',
        'pausedTotalMs': 0,
        'pausedAt': null,
        'points': [pt(35.0, 139.0, 0).toJson()],
        'routeId': 'route-old',
        'routeName': '旧ルート',
        // navSnapshot / navStartEpochMs は存在しない
      };
      final decoded = ActiveWalkSnapshot.fromJson(v1);
      expect(decoded.navSnapshot, isNull);
      expect(decoded.navStartEpochMs, isNull);
      expect(decoded.routeId, 'route-old');
    });
  });
}
