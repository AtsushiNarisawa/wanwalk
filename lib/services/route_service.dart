import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/route_spot.dart';

class RouteService {
  final _supabase = Supabase.instance.client;

  Future<String?> saveRoute(RouteModel route) async {
    try {
      final response = await _supabase.from('routes').insert({
        'user_id': route.userId,
        'title': route.title,
        'description': route.description,
        'distance': route.distance,
        'duration': route.duration,
        'started_at': route.startedAt.toIso8601String(),
        'ended_at': route.endedAt?.toIso8601String(),
      }).select().single();

      final routeId = response['id'] as String;

      if (route.points.isNotEmpty) {
        final points = route.points.asMap().entries.map((entry) {
          return {
            'route_id': routeId,
            'latitude': entry.value.latLng.latitude,
            'longitude': entry.value.latLng.longitude,
            'sequence_number': entry.key,
            'timestamp': entry.value.timestamp.toIso8601String(),
          };
        }).toList();

        await _supabase.from('route_points').insert(points);
      }

      return routeId;
    } catch (e) {
      if (kDebugMode) {
        print('ルート保存エラー: $e');
      }
      rethrow;
    }
  }

  Future<List<RouteModel>> getUserRoutes(String userId) async {
    try {
      final response = await _supabase
          .from('routes')
          .select()
          .eq('user_id', userId)
          .order('started_at', ascending: false);

      return (response as List).map((json) {
        return RouteModel(
          id: json['id'] as String,
          userId: json['user_id'] as String,
          title: json['title'] as String,
          description: json['description'] as String?,
          distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
          duration: json['duration'] as int? ?? 0,
          startedAt: DateTime.parse(json['started_at'] as String),
          endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
          points: [],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ルート一覧取得エラー: $e');
      }
      rethrow;
    }
  }

  Future<RouteModel?> getRouteDetail(String routeId) async {
    try {
      final routeResponse = await _supabase.from('routes').select().eq('id', routeId).single();
      final pointsResponse = await _supabase.from('route_points').select().eq('route_id', routeId).order('sequence_number', ascending: true);

      final points = (pointsResponse as List).asMap().entries.map((entry) {
        final json = entry.value;
        return RoutePoint(
          latLng: LatLng(json['latitude'] as double, json['longitude'] as double),
          timestamp: DateTime.parse(json['timestamp'] as String),
          sequenceNumber: entry.key,
        );
      }).toList();

      return RouteModel(
        id: routeResponse['id'] as String,
        userId: routeResponse['user_id'] as String,
        title: routeResponse['title'] as String,
        description: routeResponse['description'] as String?,
        distance: (routeResponse['distance'] as num?)?.toDouble() ?? 0.0,
        duration: routeResponse['duration'] as int? ?? 0,
        startedAt: DateTime.parse(routeResponse['started_at'] as String),
        endedAt: routeResponse['ended_at'] != null ? DateTime.parse(routeResponse['ended_at'] as String) : null,
        points: points,
      );
    } catch (e) {
      if (kDebugMode) {
        print('ルート詳細取得エラー: $e');
      }
      return null;
    }
  }

  Future<bool> deleteRoute(String routeId, String userId) async {
    try {
      await _supabase.from('routes').delete().eq('id', routeId).eq('user_id', userId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('ルート削除エラー: $e');
      }
      return false;
    }
  }

  Future<void> createTestData(String userId) async {
    final now = DateTime.now();
    
    final route1 = RouteModel(
      userId: userId,
      title: '箱根の朝の散歩',
      description: '芦ノ湖周辺の美しいルート。景色が最高でした！',
      startedAt: now.subtract(const Duration(days: 2, hours: 3)),
      endedAt: now.subtract(const Duration(days: 2, hours: 2)),
      distance: 3200,
      duration: 3600,
      points: [
        RoutePoint(latLng: const LatLng(35.2042, 139.0244), timestamp: now.subtract(const Duration(days: 2, hours: 3)), sequenceNumber: 0),
        RoutePoint(latLng: const LatLng(35.2048, 139.0250), timestamp: now.subtract(const Duration(days: 2, hours: 3, minutes: 12)), sequenceNumber: 1),
        RoutePoint(latLng: const LatLng(35.2055, 139.0258), timestamp: now.subtract(const Duration(days: 2, hours: 3, minutes: 24)), sequenceNumber: 2),
        RoutePoint(latLng: const LatLng(35.2062, 139.0265), timestamp: now.subtract(const Duration(days: 2, hours: 3, minutes: 36)), sequenceNumber: 3),
        RoutePoint(latLng: const LatLng(35.2070, 139.0272), timestamp: now.subtract(const Duration(days: 2, hours: 2)), sequenceNumber: 4),
      ],
    );
    
    final route2 = RouteModel(
      userId: userId,
      title: '近所の公園',
      description: '短めの散歩。ワンちゃんも満足そうでした。',
      startedAt: now.subtract(const Duration(days: 1, hours: 5)),
      endedAt: now.subtract(const Duration(days: 1, hours: 4, minutes: 30)),
      distance: 1500,
      duration: 1800,
      points: [
        RoutePoint(latLng: const LatLng(35.6762, 139.6503), timestamp: now.subtract(const Duration(days: 1, hours: 5)), sequenceNumber: 0),
        RoutePoint(latLng: const LatLng(35.6765, 139.6510), timestamp: now.subtract(const Duration(days: 1, hours: 4, minutes: 45)), sequenceNumber: 1),
        RoutePoint(latLng: const LatLng(35.6770, 139.6515), timestamp: now.subtract(const Duration(days: 1, hours: 4, minutes: 37)), sequenceNumber: 2),
        RoutePoint(latLng: const LatLng(35.6775, 139.6520), timestamp: now.subtract(const Duration(days: 1, hours: 4, minutes: 30)), sequenceNumber: 3),
      ],
    );
    
    final route3 = RouteModel(
      userId: userId,
      title: '山道ハイキング',
      description: '愛犬と一緒に山を登りました。疲れたけど楽しかった！',
      startedAt: now.subtract(const Duration(hours: 2)),
      endedAt: now.subtract(const Duration(hours: 1)),
      distance: 5800,
      duration: 3600,
      points: [
        RoutePoint(latLng: const LatLng(35.3000, 139.1000), timestamp: now.subtract(const Duration(hours: 2)), sequenceNumber: 0),
        RoutePoint(latLng: const LatLng(35.3010, 139.1010), timestamp: now.subtract(const Duration(hours: 1, minutes: 50)), sequenceNumber: 1),
        RoutePoint(latLng: const LatLng(35.3020, 139.1020), timestamp: now.subtract(const Duration(hours: 1, minutes: 40)), sequenceNumber: 2),
        RoutePoint(latLng: const LatLng(35.3030, 139.1030), timestamp: now.subtract(const Duration(hours: 1, minutes: 30)), sequenceNumber: 3),
        RoutePoint(latLng: const LatLng(35.3040, 139.1040), timestamp: now.subtract(const Duration(hours: 1, minutes: 20)), sequenceNumber: 4),
        RoutePoint(latLng: const LatLng(35.3050, 139.1050), timestamp: now.subtract(const Duration(hours: 1)), sequenceNumber: 5),
      ],
    );
    
    await saveRoute(route1);
    await saveRoute(route2);
    await saveRoute(route3);
  }

  Future<List<RouteModel>> getPublicRoutes({
    int limit = 20,
    String? area,
    bool includePoints = true, // マップ表示用にpointsを含めるかどうか
  }) async {
    try {
      var query = _supabase
          .from('routes')
          .select()
          .eq('is_public', true);
      
      // エリアフィルタリング
      if (area != null && area.isNotEmpty) {
        query = query.eq('area', area);
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final routes = <RouteModel>[];
      
      for (final json in response as List) {
        final routeId = json['id'] as String;
        
        // ポイントデータを取得（マップ表示用）
        List<RoutePoint> points = [];
        if (includePoints) {
          try {
            final pointsResponse = await _supabase
                .from('route_points')
                .select()
                .eq('route_id', routeId)
                .order('sequence_number', ascending: true)
                .limit(100); // パフォーマンスのため最大100ポイントに制限
            
            points = (pointsResponse as List).map<RoutePoint>((p) {
              return RoutePoint(
                latLng: LatLng(
                  (p['latitude'] as num).toDouble(),
                  (p['longitude'] as num).toDouble(),
                ),
                altitude: p['altitude']?.toDouble(),
                timestamp: DateTime.parse(p['timestamp'] as String),
                sequenceNumber: p['sequence_number'] as int,
              );
            }).toList();
          } catch (e) {
            if (kDebugMode) {
              print('ポイント取得エラー (route_id: $routeId): $e');
            }
            // ポイント取得失敗してもルート自体は返す
          }
        }
        
        routes.add(RouteModel(
          id: routeId,
          userId: json['user_id'] as String,
          title: json['title'] as String,
          description: json['description'] as String?,
          distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
          duration: json['duration'] as int? ?? 0,
          startedAt: DateTime.parse(json['started_at'] as String),
          endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
          points: points,
          isPublic: json['is_public'] as bool? ?? false,
          area: json['area'] as String?,
          prefecture: json['prefecture'] as String?,
          thumbnailUrl: json['thumbnail_url'] as String?,
        ));
      }
      
      return routes;
    } catch (e) {
      if (kDebugMode) {
        print('公開ルート一覧取得エラー: $e');
      }
      rethrow;
    }
  }

  Future<bool> updateRoute({
    required String routeId,
    required String userId,
    required String title,
    String? description,
    required bool isPublic,
  }) async {
    try {
      await _supabase
          .from('routes')
          .update({
            'title': title,
            'description': description,
            'is_public': isPublic,
          })
          .eq('id', routeId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('ルート更新エラー: $e');
      }
      return false;
    }
  }
  /// 特定ユーザーの公開ルートを取得
  Future<List<RouteModel>> getPublicRoutesByUser(String userId) async {
    final response = await _supabase
        .from('routes')
        .select()
        .eq('user_id', userId)
        .eq('is_public', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => RouteModel.fromJson(json))
        .toList();
  }

  /// 公式ルートを検索・ソート・フィルタして取得（official_routes用）
  Future<List<dynamic>> searchOfficialRoutes({
    String? searchQuery,
    String? areaId,
    String sortBy = 'popularity', // popularity, distance_asc, distance_desc, newest, duration_asc, duration_desc
    int limit = 100,
  }) async {
    try {
      // データベースの実際のカラム名を使用
      dynamic query = _supabase
          .from('official_routes')
          .select();

      // エリアフィルタ
      if (areaId != null && areaId.isNotEmpty) {
        query = query.eq('area_id', areaId);
      }

      // 検索クエリ（ルート名・説明文）
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      // ソート処理
      switch (sortBy) {
        case 'distance_asc':
          query = query.order('distance_meters', ascending: true);
          break;
        case 'distance_desc':
          query = query.order('distance_meters', ascending: false);
          break;
        case 'newest':
          query = query.order('created_at', ascending: false);
          break;
        case 'duration_asc':
          query = query.order('estimated_minutes', ascending: true);
          break;
        case 'duration_desc':
          query = query.order('estimated_minutes', ascending: false);
          break;
        case 'popularity':
        default:
          query = query.order('total_walks', ascending: false);
          break;
      }

      query = query.limit(limit);

      final response = await query;
      
      return response as List;
    } catch (e) {
      if (kDebugMode) {
        print('公式ルート検索エラー: $e');
        print('エラー詳細: ${e.runtimeType}');
      }
      rethrow;
    }
  }

  /// 特定ルートのスポット情報を取得
  Future<List<RouteSpot>> fetchRouteSpots(String routeId) async {
    try {
      final response = await _supabase
          .from('route_spots')
          .select()
          .eq('route_id', routeId)
          .order('spot_order', ascending: true);

      if (kDebugMode) {
        print('✅ ルートスポット取得成功 (route_id: $routeId): ${response.length}件');
        if (response.isNotEmpty) {
          print('   📍 最初のスポット location形式: ${response[0]['location'].runtimeType}');
          print('   📍 location値: ${response[0]['location']}');
        }
      }

      return (response as List)
          .map((json) => RouteSpot.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ルートスポット取得エラー (route_id: $routeId): $e');
      }
      return [];
    }
  }

}
