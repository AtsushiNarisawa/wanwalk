import 'package:supabase_flutter/supabase_flutter.dart';

/// ユーザープロフィール更新サービス
class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 散歩完了後にプロフィールを自動更新
  /// 
  /// [userId] - ユーザーID
  /// [distanceMeters] - 歩いた距離（メートル）
  /// [durationMinutes] - 所要時間（分）
  /// 
  /// Returns: 更新後のプロフィール情報（JSON）
  Future<Map<String, dynamic>?> updateWalkingProfile({
    required String userId,
    required double distanceMeters,
    required int durationMinutes,
  }) async {
    try {
      print('🔵 プロフィール更新開始: userId=$userId, distance=$distanceMeters, duration=$durationMinutes');
      
      // Supabase RPC関数を呼び出し
      final result = await _supabase.rpc(
        'update_user_walking_profile',
        params: {
          'p_user_id': userId,
          'p_distance_meters': distanceMeters,
          'p_duration_minutes': durationMinutes,
        },
      );

      print('✅ プロフィール更新成功: $result');
      return result as Map<String, dynamic>?;
    } catch (e) {
      print('❌ プロフィール更新エラー: $e');
      return null;
    }
  }

  /// ユーザーの散歩統計を取得
  /// 
  /// [userId] - ユーザーID
  /// 
  /// Returns: 散歩統計情報（JSON）
  Future<Map<String, dynamic>?> getUserWalkStatistics({
    required String userId,
  }) async {
    try {
      print('🔵 散歩統計取得開始: userId=$userId');
      
      // Supabase RPC関数を呼び出し
      final result = await _supabase.rpc(
        'get_user_walk_statistics',
        params: {
          'p_user_id': userId,
        },
      );

      print('✅ 散歩統計取得成功: $result');
      return result as Map<String, dynamic>?;
    } catch (e) {
      print('❌ 散歩統計取得エラー: $e');
      return null;
    }
  }
}
