import 'package:flutter/foundation.dart';
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

      // RPC returns a list with single object
      if (response is List && response.isNotEmpty) {
        final data = response[0] as Map<String, dynamic>;
        return UserStatistics.fromMap(data);
      } else if (response is Map<String, dynamic>) {
        return UserStatistics.fromMap(response);
      }
      
      return UserStatistics.empty;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user statistics: $e');
      }
      return UserStatistics.empty;
    }
  }
}
