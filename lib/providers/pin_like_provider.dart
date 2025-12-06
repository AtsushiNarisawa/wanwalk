import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pinいいねサービス
class PinLikeService {
  final _supabase = Supabase.instance.client;

  /// いいねを追加
  Future<bool> likePin(String pinId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase.rpc('like_pin', params: {
        'p_pin_id': pinId,
        'p_user_id': userId,
      });

      return response['success'] == true;
    } catch (e) {
      print('Error liking pin: $e');
      return false;
    }
  }

  /// いいねを削除
  Future<bool> unlikePin(String pinId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase.rpc('unlike_pin', params: {
        'p_pin_id': pinId,
        'p_user_id': userId,
      });

      return response['success'] == true;
    } catch (e) {
      print('Error unliking pin: $e');
      return false;
    }
  }

  /// ユーザーがいいね済みか確認
  Future<bool> hasLiked(String pinId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase.rpc('check_user_liked_pin', params: {
        'p_pin_id': pinId,
        'p_user_id': userId,
      });

      return response == true;
    } catch (e) {
      print('Error checking if pin is liked: $e');
      return false;
    }
  }

  /// ユーザーがいいねしたピン一覧を取得
  Future<List<Map<String, dynamic>>> getUserLikedPins({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase.rpc('get_user_liked_pins', params: {
        'p_user_id': userId,
        'p_limit': limit,
        'p_offset': offset,
      }) as List;

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching user liked pins: $e');
      return [];
    }
  }
}

/// PinLikeServiceのプロバイダー
final pinLikeServiceProvider = Provider((ref) => PinLikeService());

/// ピンのいいね状態プロバイダー（キャッシュ付き）
final pinLikedStateProvider = StateProvider.family<bool, String>((ref, pinId) => false);

/// ピンのいいね数プロバイダー（キャッシュ付き）
final pinLikeCountProvider = StateProvider.family<int, String>((ref, pinId) => 0);

/// ピンいいねアクション
class PinLikeActions {
  final PinLikeService _service;
  final Ref _ref;

  PinLikeActions(this._service, this._ref);

  /// いいね/取り消しをトグル
  Future<bool> toggleLike(String pinId) async {
    // 現在の状態を取得
    final currentState = _ref.read(pinLikedStateProvider(pinId));
    final currentCount = _ref.read(pinLikeCountProvider(pinId));

    // 楽観的UI更新（即座にUIを更新）
    _ref.read(pinLikedStateProvider(pinId).notifier).state = !currentState;
    _ref.read(pinLikeCountProvider(pinId).notifier).state = 
        currentState ? currentCount - 1 : currentCount + 1;

    // サーバーに送信
    final success = currentState 
        ? await _service.unlikePin(pinId)
        : await _service.likePin(pinId);

    // 失敗した場合は元に戻す
    if (!success) {
      _ref.read(pinLikedStateProvider(pinId).notifier).state = currentState;
      _ref.read(pinLikeCountProvider(pinId).notifier).state = currentCount;
      return false;
    }

    return true;
  }

  /// いいね状態を初期化（ピンカード表示時に呼び出す）
  Future<void> initializePinLikeState(String pinId, int initialLikeCount) async {
    // いいね数を設定
    _ref.read(pinLikeCountProvider(pinId).notifier).state = initialLikeCount;

    // いいね済みか確認
    final hasLiked = await _service.hasLiked(pinId);
    _ref.read(pinLikedStateProvider(pinId).notifier).state = hasLiked;
  }
}

/// PinLikeActionsのプロバイダー
final pinLikeActionsProvider = Provider((ref) {
  final service = ref.watch(pinLikeServiceProvider);
  return PinLikeActions(service, ref);
});

/// ユーザーがいいねしたピン一覧プロバイダー
final userLikedPinsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(pinLikeServiceProvider);
  return await service.getUserLikedPins();
});
