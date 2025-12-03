import 'package:supabase_flutter/supabase_flutter.dart';

class LikeService {
  final _supabase = Supabase.instance.client;

  /// ルートにいいねする
  Future<void> likeRoute(String routeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('未認証');

    await _supabase.from('likes').insert({
      'user_id': userId,
      'route_id': routeId,
    });
  }

  /// ルートのいいねを取り消す
  Future<void> unlikeRoute(String routeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('未認証');

    await _supabase
        .from('likes')
        .delete()
        .eq('user_id', userId)
        .eq('route_id', routeId);
  }

  /// いいねしているかチェック
  Future<bool> hasLiked(String routeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('likes')
        .select()
        .eq('user_id', userId)
        .eq('route_id', routeId)
        .maybeSingle();

    return response != null;
  }

  /// ルートのいいね数を取得
  Future<int> getLikeCount(String routeId) async {
    final response = await _supabase
        .from('likes')
        .select('id')
        .eq('route_id', routeId)
        .count(CountOption.exact);

    return response.count;
  }

  /// ユーザーがいいねしたルート一覧を取得
  Future<List<String>> getUserLikedRoutes(String userId) async {
    final response = await _supabase
        .from('likes')
        .select('route_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((item) => item['route_id'] as String).toList();
  }
}
