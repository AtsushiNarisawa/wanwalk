import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_statistics.dart';

/// ユーザー統計サービス
class UserStatisticsService {
  final SupabaseClient _supabase;

  UserStatisticsService(this._supabase);

  /// ユーザー統計取得
  Future<UserStatistics> getUserStatistics({
    required String userId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_user_walk_statistics',
        params: {'p_user_id': userId},
      );

      if (response == null) {
        return UserStatistics.empty;
      }

      // RPC returns a single object, not a list
      final data = response as Map<String, dynamic>;
      return UserStatistics.fromMap(data);
    } catch (e) {
      print('Error getting user statistics: $e');
      return UserStatistics.empty;
    }
  }
}
