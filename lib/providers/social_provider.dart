import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/social_service.dart';
import 'auth_provider.dart';

/// SocialService プロバイダー
final socialServiceProvider = Provider<SocialService>((ref) {
  return SocialService(Supabase.instance.client);
});

/// フォロー状態プロバイダー
final isFollowingProvider = FutureProvider.family<bool, String>(
  (ref, targetUserId) async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return false;

    final service = ref.read(socialServiceProvider);
    return await service.isFollowing(
      followerId: currentUser.id,
      followingId: targetUserId,
    );
  },
);

/// フォロワー一覧プロバイダー
class FollowersParams {
  final String userId;
  final int limit;
  final int offset;

  const FollowersParams({
    required this.userId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FollowersParams &&
        other.userId == userId &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(userId, limit, offset);
}

final followersProvider = FutureProvider.family<
    List<UserProfile>,
    FollowersParams>((ref, params) async {
  final service = ref.read(socialServiceProvider);
  return await service.getFollowers(
    userId: params.userId,
    limit: params.limit,
    offset: params.offset,
  );
});

/// フォロー中一覧プロバイダー
class FollowingParams {
  final String userId;
  final int limit;
  final int offset;

  const FollowingParams({
    required this.userId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FollowingParams &&
        other.userId == userId &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(userId, limit, offset);
}

final followingProvider = FutureProvider.family<
    List<UserProfile>,
    FollowingParams>((ref, params) async {
  final service = ref.read(socialServiceProvider);
  return await service.getFollowing(
    userId: params.userId,
    limit: params.limit,
    offset: params.offset,
  );
});

/// フォロワー数プロバイダー
final followersCountProvider = FutureProvider.family<int, String>(
  (ref, userId) async {
    final service = ref.read(socialServiceProvider);
    return await service.getFollowersCount(userId: userId);
  },
);

/// フォロー中の数プロバイダー
final followingCountProvider = FutureProvider.family<int, String>(
  (ref, userId) async {
    final service = ref.read(socialServiceProvider);
    return await service.getFollowingCount(userId: userId);
  },
);

/// タイムラインプロバイダー
class TimelineParams {
  final String userId;
  final int limit;
  final int offset;

  const TimelineParams({
    required this.userId,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineParams &&
        other.userId == userId &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(userId, limit, offset);
}

final timelineProvider = FutureProvider.family<
    List<TimelinePin>,
    TimelineParams>((ref, params) async {
  final service = ref.read(socialServiceProvider);
  final response = await service.getFollowingTimeline(
    userId: params.userId,
    limit: params.limit,
    offset: params.offset,
  );
  
  return response.map((item) => TimelinePin.fromMap(item)).toList();
});
