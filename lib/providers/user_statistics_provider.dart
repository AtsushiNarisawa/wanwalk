import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_statistics.dart';
import '../services/user_statistics_service.dart';

/// UserStatisticsService プロバイダー
final userStatisticsServiceProvider = Provider<UserStatisticsService>((ref) {
  return UserStatisticsService(Supabase.instance.client);
});

/// ユーザー統計プロバイダー
final userStatisticsProvider = FutureProvider.family<UserStatistics, String>(
  (ref, userId) async {
    final service = ref.read(userStatisticsServiceProvider);
    return await service.getUserStatistics(userId: userId);
  },
);
