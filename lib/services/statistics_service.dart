// ==================================================
// Statistics Service for WanMap v2
// ==================================================
// Author: AI Assistant
// Created: 2024-11-17
// Purpose: Service layer for statistics and reporting features
// ==================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/statistics_model.dart';

class StatisticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================================================
  // 1. 期間別統計の取得
  // ==================================================
  
  /// 指定期間の統計データを取得
  /// [startDate] 開始日時
  /// [endDate] 終了日時
  /// [dogId] 犬のID（オプション。指定すると特定の犬の統計のみ取得）
  Future<PeriodStatistics> getPeriodStatistics({
    required DateTime startDate,
    required DateTime endDate,
    String? dogId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'get_user_statistics',
        params: {
          'p_user_id': userId,
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
          'p_dog_id': dogId,
        },
      );

      // PostgreSQL関数は単一の行を返すため、直接パース
      if (response == null || (response is List && response.isEmpty)) {
        // データがない場合はゼロ統計を返す
        return PeriodStatistics(
          totalRoutes: 0,
          totalDistance: 0,
          totalDuration: 0,
          avgDistance: 0,
          avgDuration: 0,
        );
      }

      // レスポンスが配列の場合は最初の要素を取得
      final data = response is List ? response.first : response;
      return PeriodStatistics.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('期間別統計の取得に失敗しました: $e');
    }
  }

  /// 今日の統計を取得
  Future<PeriodStatistics> getTodayStatistics({String? dogId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getPeriodStatistics(
      startDate: startOfDay,
      endDate: endOfDay,
      dogId: dogId,
    );
  }

  /// 今週の統計を取得
  Future<PeriodStatistics> getThisWeekStatistics({String? dogId}) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    return getPeriodStatistics(
      startDate: startOfDay,
      endDate: now,
      dogId: dogId,
    );
  }

  /// 今月の統計を取得
  Future<PeriodStatistics> getThisMonthStatistics({String? dogId}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    return getPeriodStatistics(
      startDate: startOfMonth,
      endDate: now,
      dogId: dogId,
    );
  }

  /// 今年の統計を取得
  Future<PeriodStatistics> getThisYearStatistics({String? dogId}) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    
    return getPeriodStatistics(
      startDate: startOfYear,
      endDate: now,
      dogId: dogId,
    );
  }

  // ==================================================
  // 2. 月別統計の取得
  // ==================================================
  
  /// 過去N ヶ月分の月別統計を取得（デフォルト: 12ヶ月）
  /// [months] 取得する月数
  /// [dogId] 犬のID（オプション）
  Future<List<MonthlyStatistics>> getMonthlyStatistics({
    int months = 12,
    String? dogId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'get_monthly_statistics',
        params: {
          'p_user_id': userId,
          'p_months': months,
          'p_dog_id': dogId,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => MonthlyStatistics.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('月別統計の取得に失敗しました: $e');
    }
  }

  // ==================================================
  // 3. 週別統計の取得
  // ==================================================
  
  /// 過去N週間分の週別統計を取得（デフォルト: 8週間）
  /// [weeks] 取得する週数
  /// [dogId] 犬のID（オプション）
  Future<List<WeeklyStatistics>> getWeeklyStatistics({
    int weeks = 8,
    String? dogId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'get_weekly_statistics',
        params: {
          'p_user_id': userId,
          'p_weeks': weeks,
          'p_dog_id': dogId,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => WeeklyStatistics.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('週別統計の取得に失敗しました: $e');
    }
  }

  // ==================================================
  // 4. エリア別統計の取得
  // ==================================================
  
  /// エリア別統計を取得（よく行くエリアのランキング）
  /// [startDate] 開始日時（オプション）
  /// [endDate] 終了日時（オプション）
  /// [dogId] 犬のID（オプション）
  /// [limit] 取得する上位件数（デフォルト: 10）
  Future<List<AreaStatistics>> getAreaStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? dogId,
    int limit = 10,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'get_area_statistics',
        params: {
          'p_user_id': userId,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
          'p_dog_id': dogId,
          'p_limit': limit,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => AreaStatistics.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('エリア別統計の取得に失敗しました: $e');
    }
  }

  // ==================================================
  // 5. 愛犬別統計の取得
  // ==================================================
  
  /// 登録している全ての犬の統計を取得
  /// [startDate] 開始日時（オプション）
  /// [endDate] 終了日時（オプション）
  Future<List<DogStatistics>> getDogStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'get_dog_statistics',
        params: {
          'p_user_id': userId,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => DogStatistics.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('愛犬別統計の取得に失敗しました: $e');
    }
  }

  // ==================================================
  // 6. 時間帯別統計の取得
  // ==================================================
  
  /// 時間帯別統計を取得（0-23時の各時間帯の活動状況）
  /// [startDate] 開始日時（オプション）
  /// [endDate] 終了日時（オプション）
  /// [dogId] 犬のID（オプション）
  Future<List<HourlyStatistics>> getHourlyStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? dogId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'get_hourly_statistics',
        params: {
          'p_user_id': userId,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
          'p_dog_id': dogId,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => HourlyStatistics.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('時間帯別統計の取得に失敗しました: $e');
    }
  }

  // ==================================================
  // 7. 累計統計の取得
  // ==================================================
  
  /// 全期間の累計統計を取得
  /// [dogId] 犬のID（オプション）
  Future<LifetimeStatistics> getLifetimeStatistics({String? dogId}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'get_lifetime_statistics',
        params: {
          'p_user_id': userId,
          'p_dog_id': dogId,
        },
      );

      if (response == null || (response is List && response.isEmpty)) {
        // データがない場合はゼロ統計を返す
        return LifetimeStatistics(
          totalRoutes: 0,
          totalDistance: 0,
          totalDuration: 0,
          uniqueAreas: 0,
          uniquePrefectures: 0,
        );
      }

      // レスポンスが配列の場合は最初の要素を取得
      final data = response is List ? response.first : response;
      return LifetimeStatistics.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('累計統計の取得に失敗しました: $e');
    }
  }

  // ==================================================
  // 8. 統合統計ダッシュボードデータの取得
  // ==================================================
  
  /// ダッシュボード表示用の統合統計データを一度に取得
  /// 複数のAPIコールを並行実行して効率化
  Future<Map<String, dynamic>> getDashboardStatistics({String? dogId}) async {
    try {
      // 並行して複数の統計を取得
      final results = await Future.wait([
        getTodayStatistics(dogId: dogId),
        getThisWeekStatistics(dogId: dogId),
        getThisMonthStatistics(dogId: dogId),
        getLifetimeStatistics(dogId: dogId),
        getMonthlyStatistics(months: 6, dogId: dogId),
        getAreaStatistics(limit: 5, dogId: dogId),
      ]);

      return {
        'today': results[0] as PeriodStatistics,
        'thisWeek': results[1] as PeriodStatistics,
        'thisMonth': results[2] as PeriodStatistics,
        'lifetime': results[3] as LifetimeStatistics,
        'monthlyTrend': results[4] as List<MonthlyStatistics>,
        'topAreas': results[5] as List<AreaStatistics>,
      };
    } catch (e) {
      throw Exception('ダッシュボード統計の取得に失敗しました: $e');
    }
  }
}
