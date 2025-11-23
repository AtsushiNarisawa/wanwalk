import 'package:supabase_flutter/supabase_flutter.dart';

/// お気に入り管理サービス
class FavoriteService {
  final _supabase = Supabase.instance.client;

  /// お気に入りに追加
  Future<bool> addFavorite(String routeId, String userId) async {
    try {
      await _supabase.from('route_favorites').insert({
        'user_id': userId,
        'route_id': routeId,
      });
      return true;
    } catch (e) {
      print('お気に入り追加エラー: $e');
      return false;
    }
  }

  /// お気に入りから削除
  Future<bool> removeFavorite(String routeId, String userId) async {
    try {
      await _supabase
          .from('route_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('route_id', routeId);
      return true;
    } catch (e) {
      print('お気に入り削除エラー: $e');
      return false;
    }
  }

  /// お気に入りかどうか確認
  Future<bool> isFavorite(String routeId, String userId) async {
    try {
      final response = await _supabase
          .from('route_favorites')
          .select()
          .eq('user_id', userId)
          .eq('route_id', routeId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('お気に入り確認エラー: $e');
      return false;
    }
  }

  /// ユーザーのお気に入りルートIDリストを取得
  Future<List<String>> getUserFavoriteRouteIds(String userId) async {
    try {
      final response = await _supabase
          .from('route_favorites')
          .select('route_id')
          .eq('user_id', userId);

      return (response as List).map((item) => item['route_id'] as String).toList();
    } catch (e) {
      print('お気に入りリスト取得エラー: $e');
      return [];
    }
  }
}
