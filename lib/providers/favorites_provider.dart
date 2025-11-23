import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_statistics.dart';
import '../services/favorites_service.dart';
import 'auth_provider.dart';

/// FavoritesService プロバイダー
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService(Supabase.instance.client);
});

/// お気に入りルート一覧プロバイダー
class FavoriteRoutesParams {
  final String userId;
  final int limit;
  final int offset;

  const FavoriteRoutesParams({
    required this.userId,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteRoutesParams &&
        other.userId == userId &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(userId, limit, offset);
}

final favoriteRoutesProvider = FutureProvider.family<
    List<FavoriteRoute>,
    FavoriteRoutesParams>((ref, params) async {
  final service = ref.read(favoritesServiceProvider);
  return await service.getFavoriteRoutes(
    userId: params.userId,
    limit: params.limit,
    offset: params.offset,
  );
});

/// 保存したピン一覧プロバイダー
class BookmarkedPinsParams {
  final String userId;
  final int limit;
  final int offset;

  const BookmarkedPinsParams({
    required this.userId,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkedPinsParams &&
        other.userId == userId &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(userId, limit, offset);
}

final bookmarkedPinsProvider = FutureProvider.family<
    List<BookmarkedPin>,
    BookmarkedPinsParams>((ref, params) async {
  final service = ref.read(favoritesServiceProvider);
  return await service.getBookmarkedPins(
    userId: params.userId,
    limit: params.limit,
    offset: params.offset,
  );
});
