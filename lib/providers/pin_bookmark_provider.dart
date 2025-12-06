import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pinブックマークサービス
class PinBookmarkService {
  final _supabase = Supabase.instance.client;

  /// ブックマークを追加
  Future<bool> bookmarkPin(String pinId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase.rpc('bookmark_pin', params: {
        'p_pin_id': pinId,
        'p_user_id': userId,
      });

      return response['success'] == true;
    } catch (e) {
      print('Error bookmarking pin: $e');
      return false;
    }
  }

  /// ブックマークを削除
  Future<bool> unbookmarkPin(String pinId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase.rpc('unbookmark_pin', params: {
        'p_pin_id': pinId,
        'p_user_id': userId,
      });

      return response['success'] == true;
    } catch (e) {
      print('Error unbookmarking pin: $e');
      return false;
    }
  }

  /// ユーザーがブックマーク済みか確認
  Future<bool> hasBookmarked(String pinId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase.rpc('check_user_bookmarked_pin', params: {
        'p_pin_id': pinId,
        'p_user_id': userId,
      });

      return response == true;
    } catch (e) {
      print('Error checking if pin is bookmarked: $e');
      return false;
    }
  }

  /// ユーザーがブックマークしたピン一覧を取得
  Future<List<Map<String, dynamic>>> getUserBookmarkedPins({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase.rpc('get_user_bookmarked_pins', params: {
        'p_user_id': userId,
        'p_limit': limit,
        'p_offset': offset,
      }) as List;

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching user bookmarked pins: $e');
      return [];
    }
  }
}

/// PinBookmarkServiceのプロバイダー
final pinBookmarkServiceProvider = Provider((ref) => PinBookmarkService());

/// ピンのブックマーク状態プロバイダー（キャッシュ付き）
final pinBookmarkedStateProvider = StateProvider.family<bool, String>((ref, pinId) => false);

/// ピンブックマークアクション
class PinBookmarkActions {
  final PinBookmarkService _service;
  final Ref _ref;

  PinBookmarkActions(this._service, this._ref);

  /// ブックマーク/取り消しをトグル
  Future<bool> toggleBookmark(String pinId) async {
    // 現在の状態を取得
    final currentState = _ref.read(pinBookmarkedStateProvider(pinId));

    // 楽観的UI更新（即座にUIを更新）
    _ref.read(pinBookmarkedStateProvider(pinId).notifier).state = !currentState;

    // サーバーに送信
    final success = currentState 
        ? await _service.unbookmarkPin(pinId)
        : await _service.bookmarkPin(pinId);

    // 失敗した場合は元に戻す
    if (!success) {
      _ref.read(pinBookmarkedStateProvider(pinId).notifier).state = currentState;
      return false;
    }

    return true;
  }

  /// ブックマーク状態を初期化（ピンカード表示時に呼び出す）
  Future<void> initializePinBookmarkState(String pinId) async {
    // ブックマーク済みか確認
    final hasBookmarked = await _service.hasBookmarked(pinId);
    _ref.read(pinBookmarkedStateProvider(pinId).notifier).state = hasBookmarked;
  }
}

/// PinBookmarkActionsのプロバイダー
final pinBookmarkActionsProvider = Provider((ref) {
  final service = ref.watch(pinBookmarkServiceProvider);
  return PinBookmarkActions(service, ref);
});

/// ユーザーがブックマークしたピン一覧プロバイダー
final userBookmarkedPinsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(pinBookmarkServiceProvider);
  return await service.getUserBookmarkedPins();
});
