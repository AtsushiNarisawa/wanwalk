import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/walk_history_service.dart';
import '../models/walk_history.dart';

/// WalkHistoryServiceのプロバイダー
final walkHistoryServiceProvider = Provider<WalkHistoryService>((ref) {
  return WalkHistoryService();
});

/// お出かけ散歩履歴プロバイダー
final outingWalkHistoryProvider = FutureProvider.autoDispose.family<List<OutingWalkHistory>, OutingHistoryParams>(
  (ref, params) async {
    final service = ref.read(walkHistoryServiceProvider);
    return await service.getOutingWalkHistory(
      userId: params.userId,
      limit: params.limit,
      offset: params.offset,
    );
  },
);

/// 日常散歩履歴プロバイダー
final dailyWalkHistoryProvider = FutureProvider.autoDispose.family<List<DailyWalkHistory>, DailyHistoryParams>(
  (ref, params) async {
    final service = ref.read(walkHistoryServiceProvider);
    return await service.getDailyWalkHistory(
      userId: params.userId,
      limit: params.limit,
      offset: params.offset,
    );
  },
);

/// 全散歩履歴プロバイダー（統合）
final allWalkHistoryProvider = FutureProvider.autoDispose.family<List<WalkHistoryItem>, AllHistoryParams>(
  (ref, params) async {
    final service = ref.read(walkHistoryServiceProvider);
    return await service.getAllWalkHistory(
      userId: params.userId,
      limit: params.limit,
    );
  },
);

/// 月別散歩回数プロバイダー
final monthlyWalkCountProvider = FutureProvider.family<int, MonthlyCountParams>(
  (ref, params) async {
    final service = ref.read(walkHistoryServiceProvider);
    return await service.getMonthlyWalkCount(
      userId: params.userId,
      year: params.year,
      month: params.month,
    );
  },
);

/// 期間別統計モデル
class PeriodStatistics {
  final int totalWalks;
  final double totalDistanceKm;
  final int totalDurationMinutes;

  PeriodStatistics({
    required this.totalWalks,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
  });

  String get formattedDistance {
    if (totalDistanceKm >= 100) {
      return '${totalDistanceKm.toStringAsFixed(0)} km';
    } else {
      return '${totalDistanceKm.toStringAsFixed(1)} km';
    }
  }

  String get formattedDuration {
    final hours = totalDurationMinutes ~/ 60;
    final minutes = totalDurationMinutes % 60;
    if (hours > 0) {
      return '$hours時間$minutes分';
    }
    return '$minutes分';
  }
}

/// 1週間の統計プロバイダー
final weeklyStatisticsProvider = FutureProvider.family<PeriodStatistics, String>(
  (ref, userId) async {
    final service = ref.read(walkHistoryServiceProvider);
    final walks = await service.getAllWalkHistory(userId: userId, limit: 1000);
    
    // 過去7日間の散歩をフィルタリング
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final weeklyWalks = walks.where((walk) {
      return walk.walkedAt.isAfter(weekAgo);
    }).toList();
    
    // 統計計算
    final totalWalks = weeklyWalks.length;
    final totalDistanceKm = weeklyWalks.fold<double>(
      0.0,
      (sum, walk) => sum + (walk.distanceMeters / 1000),
    );
    final totalDurationMinutes = weeklyWalks.fold<int>(
      0,
      (sum, walk) => sum + (walk.durationSeconds ~/ 60),
    );
    
    return PeriodStatistics(
      totalWalks: totalWalks,
      totalDistanceKm: totalDistanceKm,
      totalDurationMinutes: totalDurationMinutes,
    );
  },
);

/// 1ヶ月の統計プロバイダー
final monthlyStatisticsProvider = FutureProvider.family<PeriodStatistics, String>(
  (ref, userId) async {
    final service = ref.read(walkHistoryServiceProvider);
    final walks = await service.getAllWalkHistory(userId: userId, limit: 1000);
    
    // 過去30日間の散歩をフィルタリング
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    
    final monthlyWalks = walks.where((walk) {
      return walk.walkedAt.isAfter(monthAgo);
    }).toList();
    
    // 統計計算
    final totalWalks = monthlyWalks.length;
    final totalDistanceKm = monthlyWalks.fold<double>(
      0.0,
      (sum, walk) => sum + (walk.distanceMeters / 1000),
    );
    final totalDurationMinutes = monthlyWalks.fold<int>(
      0,
      (sum, walk) => sum + (walk.durationSeconds ~/ 60),
    );
    
    return PeriodStatistics(
      totalWalks: totalWalks,
      totalDistanceKm: totalDistanceKm,
      totalDurationMinutes: totalDurationMinutes,
    );
  },
);

/// 訪問済みエリアプロバイダー
final visitedAreasProvider = FutureProvider.family<List<String>, String>(
  (ref, userId) async {
    final service = ref.read(walkHistoryServiceProvider);
    return await service.getVisitedAreas(userId: userId);
  },
);

/// 現在のユーザーIDプロバイダー
final currentUserProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

// ============================================================
// パラメータクラス
// ============================================================

/// お出かけ散歩履歴取得パラメータ
class OutingHistoryParams {
  final String userId;
  final int limit;
  final int offset;

  OutingHistoryParams({
    required this.userId,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutingHistoryParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => userId.hashCode ^ limit.hashCode ^ offset.hashCode;
}

/// 日常散歩履歴取得パラメータ
class DailyHistoryParams {
  final String userId;
  final int limit;
  final int offset;

  DailyHistoryParams({
    required this.userId,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyHistoryParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => userId.hashCode ^ limit.hashCode ^ offset.hashCode;
}

/// 全散歩履歴取得パラメータ
class AllHistoryParams {
  final String userId;
  final int limit;

  AllHistoryParams({
    required this.userId,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllHistoryParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          limit == other.limit;

  @override
  int get hashCode => userId.hashCode ^ limit.hashCode;
}

/// 月別散歩回数取得パラメータ
class MonthlyCountParams {
  final String userId;
  final int year;
  final int month;

  MonthlyCountParams({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyCountParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => userId.hashCode ^ year.hashCode ^ month.hashCode;
}
