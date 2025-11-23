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
        'get_user_statistics',
        params: {'p_user_id': userId},
      );

      if (response == null || (response as List).isEmpty) {
        return UserStatistics.empty;
      }

      final data = (response as List).first as Map<String, dynamic>;
      return UserStatistics.fromMap(data);
    } catch (e) {
      print('Error getting user statistics: $e');
      return UserStatistics.empty;
    }
  }
}
