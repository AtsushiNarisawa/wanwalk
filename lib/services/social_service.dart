import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

/// ソーシャル機能サービス
class SocialService {
  final SupabaseClient _supabase;

  SocialService(this._supabase);

  /// ユーザーをフォロー
  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {
    if (followerId == followingId) {
      throw Exception('自分自身をフォローすることはできません');
    }

    try {
      await _supabase.from('user_follows').insert({
        'follower_id': followerId,
        'following_id': followingId,
      });

      // 通知を作成
      await _createNotification(
        userId: followingId,
        type: 'new_follower',
        actorId: followerId,
        targetId: followerId,
        title: '新しいフォロワー',
        body: 'があなたをフォローしました',
      );
    } catch (e) {
      print('Error following user: $e');
      rethrow;
    }
  }

  /// フォロー解除
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await _supabase
          .from('user_follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);
    } catch (e) {
      print('Error unfollowing user: $e');
      rethrow;
    }
  }

  /// フォロー状態をトグル
  Future<void> toggleFollow({
    required String followerId,
    required String followingId,
    required bool isFollowing,
  }) async {
    if (isFollowing) {
      await unfollowUser(followerId: followerId, followingId: followingId);
    } else {
      await followUser(followerId: followerId, followingId: followingId);
    }
  }

  /// フォローしているか確認
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final response = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  /// フォロワー一覧取得
  Future<List<UserProfile>> getFollowers({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('user_follows')
          .select('follower_id, follower:follower_id(id, raw_user_meta_data)')
          .eq('following_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) {
        final followerData = item['follower'] as Map<String, dynamic>;
        return UserProfile.fromMap(followerData);
      }).toList();
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  /// フォロー中一覧取得
  Future<List<UserProfile>> getFollowing({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('user_follows')
          .select('following_id, following:following_id(id, raw_user_meta_data)')
          .eq('follower_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) {
        final followingData = item['following'] as Map<String, dynamic>;
        return UserProfile.fromMap(followingData);
      }).toList();
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  /// フォロワー数取得
  Future<int> getFollowersCount({required String userId}) async {
    try {
      final response = await _supabase
          .from('user_follows')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('following_id', userId);

      return (response as PostgrestList).count ?? 0;
    } catch (e) {
      print('Error getting followers count: $e');
      return 0;
    }
  }

  /// フォロー中の数取得
  Future<int> getFollowingCount({required String userId}) async {
    try {
      final response = await _supabase
          .from('user_follows')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('follower_id', userId);

      return (response as PostgrestList).count ?? 0;
    } catch (e) {
      print('Error getting following count: $e');
      return 0;
    }
  }

  /// タイムライン取得（フォロー中のユーザーの新着ピン）
  Future<List<Map<String, dynamic>>> getFollowingTimeline({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_following_timeline',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) return [];

      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting following timeline: $e');
      return [];
    }
  }

  /// 通知を作成（内部使用）
  Future<void> _createNotification({
    required String userId,
    required String type,
    String? actorId,
    String? targetId,
    required String title,
    String? body,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'actor_id': actorId,
        'target_id': targetId,
        'title': title,
        'body': body,
        'is_read': false,
      });
    } catch (e) {
      print('Error creating notification: $e');
      // 通知作成失敗は致命的ではないのでエラーを投げない
    }
  }
}
