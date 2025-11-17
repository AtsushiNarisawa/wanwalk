// ==================================================
// Social Service for WanMap v2
// ==================================================
// Author: AI Assistant
// Created: 2024-11-17
// Purpose: Service layer for follow and like features
// ==================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social_model.dart';

class SocialService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================================================
  // フォロー機能
  // ==================================================

  /// 指定ユーザーをフォローする
  /// [targetUserId] フォローするユーザーのID
  Future<void> followUser(String targetUserId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      if (userId == targetUserId) {
        throw Exception('自分自身をフォローすることはできません');
      }

      await _supabase.from('user_follows').insert({
        'follower_id': userId,
        'following_id': targetUserId,
      });
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        throw Exception('すでにフォローしています');
      }
      throw Exception('フォローに失敗しました: $e');
    }
  }

  /// 指定ユーザーのフォローを解除する
  /// [targetUserId] フォロー解除するユーザーのID
  Future<void> unfollowUser(String targetUserId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      await _supabase
          .from('user_follows')
          .delete()
          .eq('follower_id', userId)
          .eq('following_id', targetUserId);
    } catch (e) {
      throw Exception('フォロー解除に失敗しました: $e');
    }
  }

  /// 指定ユーザーをフォローしているか確認
  /// [targetUserId] 確認するユーザーのID
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return false;
      }

      final response = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', userId)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('フォロー状態の確認に失敗しました: $e');
    }
  }

  /// フォロワー一覧を取得
  /// [userId] ユーザーID（指定しない場合は自分のフォロワー）
  /// [limit] 取得件数
  /// [offset] オフセット
  Future<List<UserProfileModel>> getFollowers({
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'get_followers',
        params: {
          'p_user_id': targetUserId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => UserProfileModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('フォロワー一覧の取得に失敗しました: $e');
    }
  }

  /// フォロー中のユーザー一覧を取得
  /// [userId] ユーザーID（指定しない場合は自分がフォロー中のユーザー）
  /// [limit] 取得件数
  /// [offset] オフセット
  Future<List<UserProfileModel>> getFollowing({
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'get_following',
        params: {
          'p_user_id': targetUserId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => UserProfileModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('フォロー中一覧の取得に失敗しました: $e');
    }
  }

  // ==================================================
  // いいね機能
  // ==================================================

  /// ルートにいいねする
  /// [routeId] いいねするルートのID
  Future<void> likeRoute(String routeId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      await _supabase.from('route_likes').insert({
        'user_id': userId,
        'route_id': routeId,
      });
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        throw Exception('すでにいいねしています');
      }
      throw Exception('いいねに失敗しました: $e');
    }
  }

  /// ルートのいいねを解除する
  /// [routeId] いいね解除するルートのID
  Future<void> unlikeRoute(String routeId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      await _supabase
          .from('route_likes')
          .delete()
          .eq('user_id', userId)
          .eq('route_id', routeId);
    } catch (e) {
      throw Exception('いいね解除に失敗しました: $e');
    }
  }

  /// ルートにいいねしているか確認
  /// [routeId] 確認するルートのID
  Future<bool> isLiked(String routeId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return false;
      }

      final response = await _supabase
          .from('route_likes')
          .select('id')
          .eq('user_id', userId)
          .eq('route_id', routeId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('いいね状態の確認に失敗しました: $e');
    }
  }

  /// ルートにいいねしたユーザー一覧を取得
  /// [routeId] ルートID
  /// [limit] 取得件数
  /// [offset] オフセット
  Future<List<LikerModel>> getRouteLikers({
    required String routeId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_route_likers',
        params: {
          'p_route_id': routeId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => LikerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('いいねしたユーザー一覧の取得に失敗しました: $e');
    }
  }

  // ==================================================
  // タイムライン機能
  // ==================================================

  /// フォロー中のユーザーの最新ルートを取得（タイムライン）
  /// [limit] 取得件数
  /// [offset] オフセット
  Future<List<TimelineItemModel>> getFollowingTimeline({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'get_following_timeline',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => TimelineItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('タイムラインの取得に失敗しました: $e');
    }
  }

  // ==================================================
  // 人気ルート機能
  // ==================================================

  /// 人気のルートを取得（いいね数順）
  /// [limit] 取得件数
  /// [offset] オフセット
  /// [area] エリアでフィルター（オプション）
  Future<List<PopularRouteModel>> getPopularRoutes({
    int limit = 20,
    int offset = 0,
    String? area,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_popular_routes',
        params: {
          'p_limit': limit,
          'p_offset': offset,
          'p_area': area,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => PopularRouteModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('人気ルート一覧の取得に失敗しました: $e');
    }
  }

  // ==================================================
  // ユーザー検索機能
  // ==================================================

  /// ユーザーを検索する
  /// [query] 検索クエリ（ユーザー名）
  /// [limit] 取得件数
  Future<List<UserProfileModel>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('users')
          .select('id, username, avatar_url, followers_count, following_count')
          .ilike('username', '%$query%')
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => UserProfileModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('ユーザー検索に失敗しました: $e');
    }
  }

  // ==================================================
  // ユーザープロフィール取得
  // ==================================================

  /// ユーザープロフィール情報を取得
  /// [userId] ユーザーID（指定しない場合は自分のプロフィール）
  Future<UserProfileModel?> getUserProfile({String? userId}) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase
          .from('users')
          .select('id, username, avatar_url, followers_count, following_count')
          .eq('id', targetUserId)
          .maybeSingle();

      if (response == null) return null;

      return UserProfileModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('プロフィールの取得に失敗しました: $e');
    }
  }

  // ==================================================
  // 複数状態の一括取得（効率化）
  // ==================================================

  /// 複数ルートのいいね状態を一括取得
  /// [routeIds] ルートIDのリスト
  Future<Map<String, bool>> getMultipleLikeStatus(List<String> routeIds) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || routeIds.isEmpty) {
        return {};
      }

      final response = await _supabase
          .from('route_likes')
          .select('route_id')
          .eq('user_id', userId)
          .inFilter('route_id', routeIds);

      final List<dynamic> data = response as List<dynamic>;
      final likedRouteIds = data
          .map((item) => (item as Map<String, dynamic>)['route_id'] as String)
          .toSet();

      return Map.fromEntries(
        routeIds.map((id) => MapEntry(id, likedRouteIds.contains(id))),
      );
    } catch (e) {
      throw Exception('いいね状態の一括取得に失敗しました: $e');
    }
  }

  /// 複数ユーザーのフォロー状態を一括取得
  /// [userIds] ユーザーIDのリスト
  Future<Map<String, bool>> getMultipleFollowStatus(List<String> userIds) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || userIds.isEmpty) {
        return {};
      }

      final response = await _supabase
          .from('user_follows')
          .select('following_id')
          .eq('follower_id', userId)
          .inFilter('following_id', userIds);

      final List<dynamic> data = response as List<dynamic>;
      final followingUserIds = data
          .map((item) => (item as Map<String, dynamic>)['following_id'] as String)
          .toSet();

      return Map.fromEntries(
        userIds.map((id) => MapEntry(id, followingUserIds.contains(id))),
      );
    } catch (e) {
      throw Exception('フォロー状態の一括取得に失敗しました: $e');
    }
  }
}
