import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge.dart';

/// バッジサービス
class BadgeService {
  final SupabaseClient _supabase;

  BadgeService(this._supabase);

  /// ユーザーのバッジ一覧取得（解除済み・未解除含む）
  Future<List<Badge>> getUserBadges({required String userId}) async {
    try {
      final response = await _supabase.rpc(
        'get_user_badges',
        params: {'p_user_id': userId},
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => Badge.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user badges: $e');
      }
      return [];
    }
  }

  /// バッジ解除チェック（新規バッジがあれば解除）
  Future<List<String>> checkAndUnlockBadges({required String userId}) async {
    try {
      final response = await _supabase.rpc(
        'check_and_unlock_badges',
        params: {'p_user_id': userId},
      );

      if (response == null) return [];

      // 新規解除されたバッジIDのリスト
      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) return [];

      final newlyUnlockedIds = (data.first['newly_unlocked_badges'] as List<dynamic>?)
          ?.cast<String>() ?? [];

      return newlyUnlockedIds;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking and unlocking badges: $e');
      }
      return [];
    }
  }

  /// 新規バッジを既読にする
  Future<void> markBadgesAsSeen({required String userId}) async {
    try {
      await _supabase.rpc(
        'mark_badges_as_seen',
        params: {'p_user_id': userId},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error marking badges as seen: $e');
      }
      rethrow;
    }
  }

  /// バッジ統計取得
  Future<BadgeStatistics> getBadgeStatistics({required String userId}) async {
    final badges = await getUserBadges(userId: userId);
    return BadgeStatistics.fromBadgeList(badges);
  }

  /// カテゴリ別バッジ取得
  Future<Map<BadgeCategory, List<Badge>>> getBadgesByCategory({
    required String userId,
  }) async {
    final badges = await getUserBadges(userId: userId);
    final result = <BadgeCategory, List<Badge>>{};

    for (final category in BadgeCategory.values) {
      result[category] = badges.where((b) => b.category == category).toList();
    }

    return result;
  }

  /// 未解除バッジ取得
  Future<List<Badge>> getLockedBadges({required String userId}) async {
    final badges = await getUserBadges(userId: userId);
    return badges.where((b) => !b.isUnlocked).toList();
  }

  /// 解除済みバッジ取得
  Future<List<Badge>> getUnlockedBadges({required String userId}) async {
    final badges = await getUserBadges(userId: userId);
    return badges.where((b) => b.isUnlocked).toList();
  }

  /// 新規バッジ取得
  Future<List<Badge>> getNewBadges({required String userId}) async {
    final badges = await getUserBadges(userId: userId);
    return badges.where((b) => b.isNew && b.isUnlocked).toList();
  }

  /// 次に解除可能なバッジを取得（統計情報と比較）
  Future<Badge?> getNextBadge({
    required String userId,
    required Map<String, dynamic> userStatistics,
  }) async {
    final lockedBadges = await getLockedBadges(userId: userId);
    if (lockedBadges.isEmpty) return null;

    // 統計から次に近いバッジを探す
    Badge? nextBadge;
    double minDistance = double.infinity;

    for (final badge in lockedBadges) {
      double distance = _calculateBadgeDistance(badge, userStatistics);
      if (distance >= 0 && distance < minDistance) {
        minDistance = distance;
        nextBadge = badge;
      }
    }

    return nextBadge;
  }

  /// バッジまでの距離を計算
  double _calculateBadgeDistance(
    Badge badge,
    Map<String, dynamic> userStatistics,
  ) {
    // バッジコードから要件タイプを判定
    if (badge.badgeCode.startsWith('distance_')) {
      final targetKm = _extractNumberFromCode(badge.badgeCode);
      final currentKm = (userStatistics['total_distance_km'] as num?)?.toDouble() ?? 0.0;
      return targetKm - currentKm;
    } else if (badge.badgeCode.startsWith('area_')) {
      final targetAreas = _extractNumberFromCode(badge.badgeCode);
      final currentAreas = (userStatistics['areas_visited'] as int?) ?? 0;
      return (targetAreas - currentAreas).toDouble();
    } else if (badge.badgeCode.startsWith('pins_')) {
      final targetPins = _extractNumberFromCode(badge.badgeCode);
      final currentPins = (userStatistics['pins_created'] as int?) ?? 0;
      return (targetPins - currentPins).toDouble();
    } else if (badge.badgeCode.startsWith('followers_')) {
      final targetFollowers = _extractNumberFromCode(badge.badgeCode);
      final currentFollowers = (userStatistics['followers_count'] as int?) ?? 0;
      return (targetFollowers - currentFollowers).toDouble();
    }

    return -1; // 計算不可
  }

  /// バッジコードから数値を抽出
  int _extractNumberFromCode(String badgeCode) {
    final match = RegExp(r'\d+').firstMatch(badgeCode);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 0;
  }
}
