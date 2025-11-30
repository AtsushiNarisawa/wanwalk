import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_model.dart';
import '../models/route_pin.dart';
import 'package:latlong2/latlong.dart';

/// お出かけ散歩詳細を取得するサービス
class WalkDetailService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// お出かけ散歩の詳細を取得
  /// 
  /// Parameters:
  /// - [walkId]: 散歩ID
  /// 
  /// Returns: 散歩詳細データ
  Future<WalkDetail?> getWalkDetail({
    required String walkId,
  }) async {
    try {
      // 1. 散歩の基本情報を取得
      final walkResponse = await _supabase
          .from('walks')
          .select('''
            id,
            start_time,
            duration_minutes,
            routes!inner(
              id,
              name,
              distance_km,
              estimated_time_minutes,
              difficulty,
              area
            )
          ''')
          .eq('id', walkId)
          .eq('walk_type', 'outing')
          .single();

      final route = walkResponse['routes'];
      final areaName = route['area'] as String;

      // 2. GPSポイントを path_geojson から取得
      List<RoutePoint> routePoints = [];
      if (walkResponse['path_geojson'] != null) {
        final geoJson = walkResponse['path_geojson'] as Map<String, dynamic>;
        if (geoJson['type'] == 'LineString' && geoJson['coordinates'] != null) {
          final coordinates = geoJson['coordinates'] as List<dynamic>;
          routePoints = coordinates.asMap().entries.map((entry) {
            final index = entry.key;
            final coord = entry.value as List<dynamic>;
            final lon = coord[0] as double;
            final lat = coord[1] as double;
            final alt = coord.length > 2 ? coord[2] as double? : null;
            
            return RoutePoint(
              latLng: LatLng(lat, lon),
              altitude: alt,
              timestamp: DateTime.now(), // GeoJSONにはtimestampがない
              sequenceNumber: index,
            );
          }).toList();
        }
      }

      // 3. ピン情報を取得（このルートで、この日に投稿されたピン）
      final walkedDate = DateTime.parse(walkResponse['start_time']);
      final startOfDay = DateTime(walkedDate.year, walkedDate.month, walkedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final pinsResponse = await _supabase
          .from('route_pins')
          .select('''
            id,
            location,
            pin_type,
            title,
            comment,
            likes_count,
            created_at,
            route_pin_photos(
              id,
              photo_url,
              display_order
            )
          ''')
          .eq('route_id', route['id'])
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: true);

      List<RoutePin> pins = [];
      pins = (pinsResponse as List<dynamic>).map((pin) {
        final location = _parsePostGISPoint(pin['location']);
        final photos = (pin['route_pin_photos'] as List<dynamic>?)
            ?.map((photo) => photo['photo_url'] as String)
            .toList() ?? [];

        return RoutePin(
          id: pin['id'],
          routeId: route['id'],
          userId: '', // ユーザーIDは不要
          location: location,
          pinType: PinType.fromString(pin['pin_type']),
          title: pin['title'],
          comment: pin['comment'],
          likesCount: pin['likes_count'] ?? 0,
          photoUrls: photos,
          createdAt: DateTime.parse(pin['created_at']),
        );
      }).toList();
    
      // 4. 写真一覧を取得（ピンの写真を統合）
      final allPhotos = <String>[];
      for (var pin in pins) {
        allPhotos.addAll(pin.photoUrls);
      }

      return WalkDetail(
        id: walkResponse['id'],
        routeId: route['id'],
        routeName: route['name'],
        areaName: areaName,
        walkedAt: walkedDate,
        distanceMeters: (route['distance_km']?.toDouble() ?? 0.0) * 1000.0,
        durationSeconds: (walkResponse['duration_minutes'] ?? 0) * 60,
        difficulty: route['difficulty'] ?? 'easy',
        routePoints: routePoints,
        pins: pins,
        photoUrls: allPhotos,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching walk detail: $e');
      }
      return null;
    }
  }

  /// PostGIS POINT形式を解析
  /// "POINT(longitude latitude)" -> LatLng
  LatLng _parsePostGISPoint(String pointStr) {
    // "POINT(139.7380 35.6762)" のような形式
    final regex = RegExp(r'POINT\(([-\d.]+)\s+([-\d.]+)\)');
    final match = regex.firstMatch(pointStr);
    
    if (match != null) {
      final lon = double.parse(match.group(1)!);
      final lat = double.parse(match.group(2)!);
      return LatLng(lat, lon);
    }
    
    // パースできない場合はデフォルト値
    return const LatLng(35.6762, 139.6503); // 東京
  }
}

/// お出かけ散歩詳細モデル
class WalkDetail {
  final String id;
  final String routeId;
  final String routeName;
  final String areaName;
  final DateTime walkedAt;
  final double distanceMeters;
  final int durationSeconds;
  final String difficulty;
  final List<RoutePoint> routePoints;
  final List<RoutePin> pins;
  final List<String> photoUrls;

  WalkDetail({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.areaName,
    required this.walkedAt,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.difficulty,
    required this.routePoints,
    required this.pins,
    required this.photoUrls,
  });

  /// 距離のフォーマット
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(2)}km';
    }
  }

  /// 時間のフォーマット
  String get formattedDuration {
    if (durationSeconds < 60) {
      return '$durationSeconds秒';
    } else if (durationSeconds < 3600) {
      return '${(durationSeconds / 60).toStringAsFixed(0)}分';
    } else {
      final hours = durationSeconds ~/ 3600;
      final minutes = (durationSeconds % 3600) ~/ 60;
      return '$hours時間$minutes分';
    }
  }

  /// 平均ペース（分/km）
  String get averagePace {
    if (distanceMeters == 0) return '-';
    final distanceKm = distanceMeters / 1000;
    final durationMin = durationSeconds / 60;
    final pace = durationMin / distanceKm;
    return '${pace.toStringAsFixed(1)}分/km';
  }

  /// 難易度のラベル
  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':
        return '簡単';
      case 'moderate':
        return '普通';
      case 'hard':
        return '難しい';
      default:
        return '普通';
    }
  }
}

// Import必要なクラス
