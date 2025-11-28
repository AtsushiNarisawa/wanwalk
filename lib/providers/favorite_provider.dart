import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite_route.dart';
import '../services/favorite_service.dart';
import 'auth_provider.dart';

/// FavoriteServiceのプロバイダー
final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  final supabase = Supabase.instance.client;
  return FavoriteService(supabase);
});

/// ユーザーのお気に入りルート一覧を取得
final userFavoritesProvider = FutureProvider.autoDispose<List<FavoriteRoute>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];

  final service = ref.watch(favoriteServiceProvider);
  return service.getUserFavorites(userId: userId);
});

/// 特定ルートのお気に入り状態を管理
final routeFavoriteProvider = StateNotifierProvider.family<RouteFavoriteNotifier, AsyncValue<bool>, String>(
  (ref, routeId) => RouteFavoriteNotifier(ref, routeId),
);

class RouteFavoriteNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;
  final String _routeId;

  RouteFavoriteNotifier(this._ref, this._routeId) : super(const AsyncValue.loading()) {
    _loadFavoriteStatus();
  }

  /// お気に入り状態をロード
  Future<void> _loadFavoriteStatus() async {
    final userId = _ref.read(userIdProvider);
    if (userId == null) {
      state = const AsyncValue.data(false);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final service = _ref.read(favoriteServiceProvider);
      final isFavorite = await service.isFavorite(userId: userId, routeId: _routeId);
      state = AsyncValue.data(isFavorite);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// お気に入りをトグル
  Future<void> toggle() async {
    final userId = _ref.read(userIdProvider);
    if (userId == null) return;

    // 楽観的更新
    final currentValue = state.value ?? false;
    state = AsyncValue.data(!currentValue);

    try {
      final service = _ref.read(favoriteServiceProvider);
      final newValue = await service.toggleFavorite(userId: userId, routeId: _routeId);
      state = AsyncValue.data(newValue);

      // お気に入り一覧を無効化して再読み込み
      _ref.invalidate(userFavoritesProvider);
    } catch (e, stack) {
      // エラー時は元に戻す
      state = AsyncValue.data(currentValue);
      state = AsyncValue.error(e, stack);
    }
  }
}

/// お気に入り数を取得
final favoriteCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return 0;

  final service = ref.watch(favoriteServiceProvider);
  return service.getFavoriteCount(userId: userId);
});

/// 特定ルートのお気に入り数を取得
final routeFavoriteCountProvider = FutureProvider.autoDispose.family<int, String>((ref, routeId) async {
  final service = ref.watch(favoriteServiceProvider);
  return service.getRouteFavoriteCount(routeId: routeId);
});
