import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite_route.dart';

/// お気に入りルートサービス
class FavoriteService {
  final SupabaseClient _supabase;

  FavoriteService(this._supabase);

  /// ユーザーのお気に入りルート一覧を取得
  Future<List<FavoriteRoute>> getUserFavorites({required String userId}) async {
    try {
      if (kDebugMode) {
        print('🔵 FavoriteService: Fetching favorites for user $userId');
      }

      final response = await _supabase.rpc(
        'get_user_favorite_routes',
        params: {'p_user_id': userId},
      );

      if (response == null) {
        if (kDebugMode) {
          print('⚠️ FavoriteService: No favorites found');
        }
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;
      
      if (kDebugMode) {
        print('✅ FavoriteService: Found ${data.length} favorites');
      }

      return data.map((item) => FavoriteRoute.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ FavoriteService: Error fetching favorites: $e');
      }
      rethrow;
    }
  }

  /// お気に入りのトグル（追加/削除）
  Future<bool> toggleFavorite({
    required String userId,
    required String routeId,
  }) async {
    try {
      if (kDebugMode) {
        print('🔵 FavoriteService: Toggling favorite - userId: $userId, routeId: $routeId');
      }

      final response = await _supabase.rpc(
        'toggle_favorite_route',
        params: {
          'p_user_id': userId,
          'p_route_id': routeId,
        },
      );

      final result = response as Map<String, dynamic>;
      final isFavorite = result['is_favorite'] as bool;

      if (kDebugMode) {
        print('✅ FavoriteService: Toggle result - isFavorite: $isFavorite');
      }

      return isFavorite;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FavoriteService: Error toggling favorite: $e');
      }
      rethrow;
    }
  }

  /// 特定のルートがお気に入りかどうか確認
  Future<bool> isFavorite({
    required String userId,
    required String routeId,
  }) async {
    try {
      final response = await _supabase
          .from('favorite_routes')
          .select('id')
          .eq('user_id', userId)
          .eq('route_id', routeId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FavoriteService: Error checking favorite status: $e');
      }
      return false;
    }
  }

  /// お気に入り数を取得
  Future<int> getFavoriteCount({required String userId}) async {
    try {
      final response = await _supabase
          .from('favorite_routes')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userId);

      return (response as PostgrestList).count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FavoriteService: Error getting favorite count: $e');
      }
      return 0;
    }
  }

  /// 特定ルートのお気に入り数を取得
  Future<int> getRouteFavoriteCount({required String routeId}) async {
    try {
      final response = await _supabase
          .from('favorite_routes')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('route_id', routeId);

      return (response as PostgrestList).count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FavoriteService: Error getting route favorite count: $e');
      }
      return 0;
    }
  }
}
