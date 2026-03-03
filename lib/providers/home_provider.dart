import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/home_stats_service.dart';
import '../models/route_model.dart';

/// HomeStatsServiceのプロバイダー
final homeStatsServiceProvider = Provider<HomeStatsService>((ref) {
  return HomeStatsService();
});

/// おすすめルートプロバイダー
final recommendedRoutesProvider = FutureProvider.family<List<RouteModel>, String?>((ref, userId) async {
  if (userId == null) return [];
  
  final service = ref.read(homeStatsServiceProvider);
  return await service.getRecommendedRoutes(userId: userId, limit: 5);
});

/// 人気急上昇ルートプロバイダー
final trendingRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final service = ref.read(homeStatsServiceProvider);
  return await service.getTrendingRoutes(limit: 3);
});

/// 最近の思い出写真プロバイダー
final recentMemoriesProvider = FutureProvider.family<List<RecentMemory>, String?>((ref, userId) async {
  if (userId == null) return [];
  
  final service = ref.read(homeStatsServiceProvider);
  return await service.getRecentMemories(userId: userId, limit: 6);
});

/// エリア一覧プロバイダー
final areasListProvider = FutureProvider<List<AreaModel>>((ref) async {
  final service = ref.read(homeStatsServiceProvider);
  return await service.getAreas();
});

// [BUG-C01 修正] currentUserIdProvider は auth_provider.dart で定義済み。
// 重複定義を削除。正規の定義は auth_provider.dart:147 を参照。
// ※ このファイル自体が現在どこからもインポートされていないため、
//   将来的にファイル全体の整理を推奨。
