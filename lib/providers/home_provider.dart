import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

/// 現在のユーザーIDプロバイダー
final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});
