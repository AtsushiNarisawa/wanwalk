import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/official_route.dart';

/// Supabaseクライアントのインスタンス取得
final _supabase = Supabase.instance.client;

/// エリアIDで公式ルート一覧を取得するProvider
final routesByAreaProvider = FutureProvider.family<List<OfficialRoute>, String>(
  (ref, areaId) async {
    try {
      final response = await _supabase
          .from('official_routes')
          .select()
          .eq('area_id', areaId)
          .order('total_pins', ascending: false); // 人気順

      return (response as List)
          .map((json) => OfficialRoute.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch routes by area: $e');
    }
  },
);

/// 特定のルートIDでルート詳細を取得するProvider
final routeByIdProvider = FutureProvider.family<OfficialRoute?, String>(
  (ref, routeId) async {
    try {
      final response = await _supabase
          .from('official_routes')
          .select()
          .eq('id', routeId)
          .maybeSingle();

      if (response == null) return null;
      return OfficialRoute.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch route: $e');
    }
  },
);

/// 近くの公式ルートを検索するProvider
/// 引数: [latitude, longitude, radiusMeters]
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
      // RPC関数を呼び出して近くのルートを取得
      final response = await _supabase.rpc(
        'find_nearby_routes',
        params: {
          'p_latitude': params.latitude,
          'p_longitude': params.longitude,
          'p_radius_meters': params.radiusMeters,
          'p_limit': 20,
        },
      );

      // RPC関数の戻り値をパース
      return (response as List).map((json) {
        // RPC関数は一部のフィールドしか返さないため、
        // 完全なルート情報を取得するために個別にクエリ
        return OfficialRoute.fromJson({
          'id': json['route_id'],
          'name': json['route_name'],
          'area_id': '', // RPC関数からは取得できないため空
          'description': '',
          'start_location': null, // 後で取得
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
