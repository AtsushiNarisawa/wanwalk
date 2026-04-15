import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger.dart';

class NotLoggedInException implements Exception {
  const NotLoggedInException();
  @override
  String toString() => 'ログインが必要です';
}

final _supabase = Supabase.instance.client;

/// ルートごとのブックマーク状態を取得。
final routeBookmarkStatusProvider =
    FutureProvider.family.autoDispose<bool, String>((ref, routeId) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return false;
  try {
    final rows = await _supabase
        .from('user_bookmarks')
        .select('id')
        .eq('user_id', userId)
        .eq('route_id', routeId)
        .limit(1);
    return (rows as List).isNotEmpty;
  } catch (e) {
    appLog('❌ bookmark status fetch error: $e');
    return false;
  }
});

/// ブックマークをトグル。未ログイン時は [NotLoggedInException]。
Future<bool> toggleBookmark(String routeId) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) {
    throw const NotLoggedInException();
  }
  final existing = await _supabase
      .from('user_bookmarks')
      .select('id')
      .eq('user_id', userId)
      .eq('route_id', routeId)
      .limit(1);

  if ((existing as List).isNotEmpty) {
    final id = existing.first['id'] as String;
    await _supabase.from('user_bookmarks').delete().eq('id', id);
    return false;
  } else {
    await _supabase
        .from('user_bookmarks')
        .insert({'user_id': userId, 'route_id': routeId});
    return true;
  }
}
