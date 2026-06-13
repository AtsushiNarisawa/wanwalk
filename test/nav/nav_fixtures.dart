import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';

/// §14 fixture（scripts/dump_nav_fixtures.py が生成）のローダ。
/// Flutter テストは VM 上で dart:io が使えるのでファイル直読みでよい。

class NavFixtureSpot {
  final String name;
  final String? category;
  final String spotType; // start / waypoint / end
  final int? distanceFromStart;
  final bool isOptional;
  final LatLng pos;

  NavFixtureSpot({
    required this.name,
    required this.category,
    required this.spotType,
    required this.distanceFromStart,
    required this.isOptional,
    required this.pos,
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

class NavFixtureRoute {
  final String slug;
  final String name;
  final String routeType;
  final num? distanceMeters;
  final int? estimatedMinutes;
  final List<LatLng> points;
  final List<NavFixtureSpot> spots;

  NavFixtureRoute({
    required this.slug,
    required this.name,
    required this.routeType,
    required this.distanceMeters,
    required this.estimatedMinutes,
    required this.points,
    required this.spots,
  });
}

class NavFixtures {
  static const String defaultPath = 'test/nav/fixtures/routes_nav_fixture.json';

  static List<NavFixtureRoute> load([String path = defaultPath]) {
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError(
          'fixture が見つかりません: $path（scripts/dump_nav_fixtures.py を実行）');
    }
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final routes = (data['routes'] as List).cast<Map<String, dynamic>>();
    return routes.map(_parseRoute).toList();
  }

  static NavFixtureRoute _parseRoute(Map<String, dynamic> r) {
    final points = (r['points'] as List)
        .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    final spots = (r['spots'] as List).cast<Map<String, dynamic>>().map((s) {
      return NavFixtureSpot(
        name: s['name'] as String? ?? '?',
        category: s['category'] as String?,
        spotType: s['spot_type'] as String? ?? 'waypoint',
        distanceFromStart: (s['distance_from_start'] as num?)?.round(),
        isOptional: s['is_optional'] as bool? ?? false,
        pos: LatLng((s['lat'] as num).toDouble(), (s['lng'] as num).toDouble()),
      );
    }).toList();
    return NavFixtureRoute(
      slug: r['slug'] as String,
      name: r['name'] as String? ?? '',
      routeType: r['route_type'] as String? ?? 'line',
      distanceMeters: r['distance_meters'] as num?,
      estimatedMinutes: (r['estimated_minutes'] as num?)?.round(),
      points: points,
      spots: spots,
    );
  }
}
