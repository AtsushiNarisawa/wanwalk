import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/official_route.dart';

/// Supabaseクライアントのインスタンス取得
final _supabase = Supabase.instance.client;

/// エリアIDで公式ルート一覧を取得するProvider
final routesByAreaProvider = FutureProvider.family<List<OfficialRoute>, String>(
  (ref, areaId) async {
    if (kDebugMode) {
      print('🔵 routesByAreaProvider: Starting fetch for areaId=$areaId');
    }
    try {
      // PostGISデータをGeoJSON形式で取得するためにRPCを使用
      if (kDebugMode) {
        print('🔵 Calling RPC: get_routes_by_area_geojson with areaId=$areaId');
      }
      final response = await _supabase.rpc(
        'get_routes_by_area_geojson',
        params: {'p_area_id': areaId},
      );

      if (kDebugMode) {
        print('🔵 RPC Response type: ${response.runtimeType}');
      }

      final routes = (response as List)
          .map((json) => OfficialRoute.fromJson(json))
          .toList();
      
      if (kDebugMode) {
        print('✅ Successfully parsed ${routes.length} routes');
      }
      
      return routes;
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Error in routesByAreaProvider: $e');
        if (kDebugMode) {
          print('Stack trace: $stack');
        }
      }
      throw Exception('Failed to fetch routes by area: $e');
    }
  },
);

/// 特定のルートIDでルート詳細を取得するProvider
final routeByIdProvider = FutureProvider.family<OfficialRoute?, String>(
  (ref, routeId) async {
    try {
      // PostGISデータをGeoJSON形式で取得
      final response = await _supabase.rpc(
        'get_route_by_id_geojson',
        params: {'p_route_id': routeId},
      );

      if (response == null || (response is List && response.isEmpty)) {
        return null;
      }
      
      final data = response is List ? response.first : response;
      return OfficialRoute.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in routeByIdProvider: $e');
      }
      throw Exception('Failed to fetch route: $e');
    }
  },
);

/// 近くの公式ルートを検索するProvider
class NearbyRoutesParams {
  final double latitude;
  final double longitude;
  final int radiusMeters;

  NearbyRoutesParams({
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 5000,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NearbyRoutesParams &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.radiusMeters == radiusMeters;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, radiusMeters);
}

final nearbyRoutesProvider = FutureProvider.family<List<OfficialRoute>, NearbyRoutesParams>(
  (ref, params) async {
    try {
      final response = await _supabase.rpc(
        'find_nearby_routes',
        params: {
          'p_latitude': params.latitude,
          'p_longitude': params.longitude,
          'p_radius_meters': params.radiusMeters,
          'p_limit': 20,
        },
      );

      return (response as List).map((json) {
        return OfficialRoute.fromJson({
          'id': json['route_id'],
          'name': json['route_name'],
          'area_id': '',
          'description': '',
          'start_location': null,
          'end_location': null,
          'route_line': null,
          'distance_meters': json['distance_meters'],
          'estimated_minutes': json['estimated_minutes'],
          'difficulty_level': json['difficulty_level'],
          'total_pins': json['total_pins'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in nearbyRoutesProvider: $e');
      }
      throw Exception('Failed to fetch nearby routes: $e');
    }
  },
);

/// 選択中のルートIDを管理するProvider
class SelectedRouteNotifier extends StateNotifier<String?> {
  SelectedRouteNotifier() : super(null);

  void selectRoute(String? routeId) {
    state = routeId;
  }

  void clearSelection() {
    state = null;
  }
}

final selectedRouteIdProvider = StateNotifierProvider<SelectedRouteNotifier, String?>(
  (ref) => SelectedRouteNotifier(),
);

/// 選択中のルート情報を取得するProvider
final selectedRouteProvider = Provider<AsyncValue<OfficialRoute?>>((ref) {
  final routeId = ref.watch(selectedRouteIdProvider);
  if (routeId == null) {
    return const AsyncValue.data(null);
  }
  return ref.watch(routeByIdProvider(routeId));
});

/// 全ての公式ルートを取得するProvider（MAP画面用）
final allRoutesProvider = FutureProvider<List<OfficialRoute>>((ref) async {
  if (kDebugMode) {
    print('🔵 allRoutesProvider: Fetching all routes');
  }
  try {
    final response = await _supabase.rpc('get_all_routes_geojson');
    
    final routes = (response as List)
        .map((json) => OfficialRoute.fromJson(json))
        .toList();
    
    if (kDebugMode) {
      print('✅ Successfully fetched ${routes.length} routes');
    }
    
    return routes;
  } catch (e, stack) {
    if (kDebugMode) {
      print('❌ Error in allRoutesProvider: $e');
      if (kDebugMode) {
        print('Stack trace: $stack');
      }
    }
    throw Exception('Failed to fetch all routes: $e');
  }
});
