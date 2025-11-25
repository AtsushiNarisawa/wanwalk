import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_search_params.dart';

/// ルート検索サービス
class RouteSearchService {
  final SupabaseClient _supabase;

  RouteSearchService(this._supabase);

  /// 高度なルート検索
  Future<List<SearchRouteResult>> searchRoutes({
    required String userId,
    required RouteSearchParams params,
  }) async {
    try {
      final response = await _supabase.rpc(
        'search_routes',
        params: params.toRpcParams(userId),
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => SearchRouteResult.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error searching routes: $e');
      }
      rethrow;
    }
  }

  /// お気に入りに追加
  Future<void> addFavorite({
    required String userId,
    required String routeId,
  }) async {
    try {
      await _supabase.from('route_favorites').insert({
        'user_id': userId,
        'route_id': routeId,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding favorite: $e');
      }
      rethrow;
    }
  }

  /// お気に入りから削除
  Future<void> removeFavorite({
    required String userId,
    required String routeId,
  }) async {
    try {
      await _supabase
          .from('route_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('route_id', routeId);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing favorite: $e');
      }
      rethrow;
    }
  }

  /// お気に入り状態をトグル
  Future<void> toggleFavorite({
    required String userId,
    required String routeId,
    required bool isFavorited,
  }) async {
    if (isFavorited) {
      await removeFavorite(userId: userId, routeId: routeId);
    } else {
      await addFavorite(userId: userId, routeId: routeId);
    }
  }
}
