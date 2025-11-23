import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge.dart';
import '../services/badge_service.dart';

// Badge Service Provider
final badgeServiceProvider = Provider<BadgeService>((ref) {
  return BadgeService(Supabase.instance.client);
});

// User Badges Provider - FutureProvider.family for user-specific badges
final userBadgesProvider = FutureProvider.family<List<Badge>, String>(
  (ref, userId) async {
    final badgeService = ref.watch(badgeServiceProvider);
    return await badgeService.getUserBadges(userId: userId);
  },
);

// Badges by Category Provider - FutureProvider.family for organized view
final badgesByCategoryProvider = FutureProvider.family<
  Map<BadgeCategory, List<Badge>>,
  String
>(
  (ref, userId) async {
    final badgeService = ref.watch(badgeServiceProvider);
    return await badgeService.getBadgesByCategory(userId: userId);
  },
);

// Badge Statistics Provider - FutureProvider.family for progress tracking
final badgeStatisticsProvider = FutureProvider.family<BadgeStatistics, String>(
  (ref, userId) async {
    final badgeService = ref.watch(badgeServiceProvider);
    return await badgeService.getBadgeStatistics(userId: userId);
  },
);

// Next Badge to Unlock Provider - FutureProvider.family for motivation
// Requires user statistics to calculate which badge is closest
final nextBadgeProvider = FutureProvider.family<
  Badge?,
  ({String userId, Map<String, dynamic> statistics})
>(
  (ref, params) async {
    final badgeService = ref.watch(badgeServiceProvider);
    return await badgeService.getNextBadge(
      userId: params.userId,
      userStatistics: params.statistics,
    );
  },
);

// Badge Unlock Trigger - For refreshing badges after walk completion
// This is a helper provider to trigger badge checking and refresh the badge list
final badgeUnlockTriggerProvider = FutureProvider.family<List<String>, String>(
  (ref, userId) async {
    final badgeService = ref.watch(badgeServiceProvider);
    
    // Check and unlock eligible badges
    final newlyUnlockedIds = await badgeService.checkAndUnlockBadges(
      userId: userId,
    );
    
    // If any new badges were unlocked, invalidate the badge providers
    if (newlyUnlockedIds.isNotEmpty) {
      ref.invalidate(userBadgesProvider(userId));
      ref.invalidate(badgesByCategoryProvider(userId));
      ref.invalidate(badgeStatisticsProvider(userId));
    }
    
    return newlyUnlockedIds;
  },
);
