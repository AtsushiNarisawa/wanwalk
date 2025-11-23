import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_statistics.dart';

/// お気に入り・ブックマークサービス
class FavoritesService {
  final SupabaseClient _supabase;

  FavoritesService(this._supabase);

  /// お気に入りルート一覧取得
  Future<List<FavoriteRoute>> getFavoriteRoutes({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_favorite_routes',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => FavoriteRoute.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting favorite routes: $e');
      rethrow;
    }
  }

  /// 保存したピン一覧取得
  Future<List<BookmarkedPin>> getBookmarkedPins({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_bookmarked_pins',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => BookmarkedPin.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting bookmarked pins: $e');
      rethrow;
    }
  }

  /// ピンをブックマークに追加
  Future<void> addPinBookmark({
    required String userId,
    required String pinId,
  }) async {
    try {
      await _supabase.from('pin_bookmarks').insert({
        'user_id': userId,
        'pin_id': pinId,
      });
    } catch (e) {
      print('Error adding pin bookmark: $e');
      rethrow;
    }
  }

  /// ピンをブックマークから削除
  Future<void> removePinBookmark({
    required String userId,
    required String pinId,
  }) async {
    try {
      await _supabase
          .from('pin_bookmarks')
          .delete()
          .eq('user_id', userId)
          .eq('pin_id', pinId);
    } catch (e) {
      print('Error removing pin bookmark: $e');
      rethrow;
    }
  }

  /// ピンのブックマーク状態をトグル
  Future<void> togglePinBookmark({
    required String userId,
    required String pinId,
    required bool isBookmarked,
  }) async {
    if (isBookmarked) {
      await removePinBookmark(userId: userId, pinId: pinId);
    } else {
      await addPinBookmark(userId: userId, pinId: pinId);
    }
  }

  /// ピンがブックマークされているか確認
  Future<bool> isPinBookmarked({
    required String userId,
    required String pinId,
  }) async {
    try {
      final response = await _supabase
          .from('pin_bookmarks')
          .select('id')
          .eq('user_id', userId)
          .eq('pin_id', pinId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking pin bookmark status: $e');
      return false;
    }
  }
}
