import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanmap_v2/services/like_service.dart';

final likeServiceProvider = Provider((ref) => LikeService());

/// いいね状態プロバイダー
final hasLikedProvider = FutureProvider.family<bool, String>((ref, routeId) async {
  final service = ref.watch(likeServiceProvider);
  return await service.hasLiked(routeId);
});

/// いいね数プロバイダー
final likeCountProvider = FutureProvider.family<int, String>((ref, routeId) async {
  final service = ref.watch(likeServiceProvider);
  return await service.getLikeCount(routeId);
});

/// ユーザーのいいねしたルート一覧プロバイダー
final userLikedRoutesProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final service = ref.watch(likeServiceProvider);
  return await service.getUserLikedRoutes(userId);
});

/// いいね/取り消しアクション
class LikeActions {
  final LikeService _service;
  final Ref _ref;

  LikeActions(this._service, this._ref);

  Future<void> toggleLike(String routeId) async {
    final hasLiked = await _service.hasLiked(routeId);
    
    if (hasLiked) {
      await _service.unlikeRoute(routeId);
    } else {
      await _service.likeRoute(routeId);
    }

    // プロバイダーを無効化して再読み込み
    _ref.invalidate(hasLikedProvider(routeId));
    _ref.invalidate(likeCountProvider(routeId));
  }
}

final likeActionsProvider = Provider((ref) {
  final service = ref.watch(likeServiceProvider);
  return LikeActions(service, ref);
});
