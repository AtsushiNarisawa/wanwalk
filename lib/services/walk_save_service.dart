import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_model.dart';
import '../models/walk_mode.dart';

/// 散歩記録保存サービス
/// GPS記録をSupabaseに保存する
class WalkSaveService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 日常散歩を保存
  /// 
  /// [route] - GPS記録データ
  /// [userId] - ユーザーID
  /// [dogId] - 犬ID
  /// 
  /// Returns: 保存成功時はwalkId、失敗時はnull
  Future<String?> saveDailyWalk({
    required RouteModel route,
    required String userId,
    String? dogId,
  }) async {
    try {
      print('🔵 日常散歩保存開始: userId=$userId, points=${route.points.length}');

      // 1. daily_walksテーブルに保存
      final walkResponse = await _supabase.from('daily_walks').insert({
        'user_id': userId,
        'dog_id': dogId,
        'walked_at': route.startedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'distance_meters': route.distance,
        'duration': route.duration,
      }).select().single();

      final walkId = walkResponse['id'] as String;
      print('✅ daily_walks保存成功: walkId=$walkId');

      // 2. daily_walk_pointsテーブルにGPSポイントを保存
      if (route.points.isNotEmpty) {
        final pointsData = route.points.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          
          return {
            'daily_walk_id': walkId,
            'sequence': index,
            'point': 'SRID=4326;POINT(${point.latLng.longitude} ${point.latLng.latitude})',
            'altitude': point.altitude,
            'timestamp': point.timestamp.toIso8601String(),
          };
        }).toList();

        // バッチ挿入（最大1000件ずつ）
        for (var i = 0; i < pointsData.length; i += 1000) {
          final batch = pointsData.skip(i).take(1000).toList();
          await _supabase.from('daily_walk_points').insert(batch);
          print('✅ daily_walk_points保存: ${batch.length}件');
        }

        print('✅ 全GPSポイント保存完了: ${route.points.length}件');
      }

      return walkId;
    } catch (e) {
      print('❌ 日常散歩保存エラー: $e');
      return null;
    }
  }

  /// おでかけ散歩を保存
  /// 
  /// [route] - GPS記録データ
  /// [userId] - ユーザーID
  /// [dogId] - 犬ID
  /// [officialRouteId] - 公式ルートID
  /// 
  /// Returns: 保存成功時はwalkId、失敗時はnull
  Future<String?> saveRouteWalk({
    required RouteModel route,
    required String userId,
    required String officialRouteId,
    String? dogId,
  }) async {
    try {
      print('🔵 おでかけ散歩保存開始: userId=$userId, routeId=$officialRouteId');

      // route_walksテーブルに保存
      final walkResponse = await _supabase.from('route_walks').insert({
        'official_route_id': officialRouteId,
        'user_id': userId,
        'dog_id': dogId,
        'walked_at': route.startedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'actual_distance_meters': route.distance,
        'actual_duration_minutes': (route.duration / 60).ceil(),
        'completed': true,
      }).select().single();

      final walkId = walkResponse['id'] as String;
      print('✅ route_walks保存成功: walkId=$walkId');

      return walkId;
    } catch (e) {
      print('❌ おでかけ散歩保存エラー: $e');
      return null;
    }
  }

  /// 散歩を自動保存（モードに応じて適切なテーブルに保存）
  /// 
  /// [route] - GPS記録データ
  /// [userId] - ユーザーID
  /// [walkMode] - 散歩モード
  /// [dogId] - 犬ID
  /// [officialRouteId] - 公式ルートID（outingモードの場合）
  /// 
  /// Returns: 保存成功時はwalkId、失敗時はnull
  Future<String?> saveWalk({
    required RouteModel route,
    required String userId,
    required WalkMode walkMode,
    String? dogId,
    String? officialRouteId,
  }) async {
    print('🔵 散歩自動保存: mode=${walkMode.value}');

    if (walkMode == WalkMode.daily) {
      // 日常散歩として保存
      return await saveDailyWalk(
        route: route,
        userId: userId,
        dogId: dogId,
      );
    } else {
      // おでかけ散歩として保存
      if (officialRouteId == null) {
        print('❌ おでかけ散歩にはofficialRouteIdが必要です');
        return null;
      }
      return await saveRouteWalk(
        route: route,
        userId: userId,
        officialRouteId: officialRouteId,
        dogId: dogId,
      );
    }
  }

  /// 散歩記録を削除
  /// 
  /// [walkId] - 散歩ID
  /// [walkMode] - 散歩モード
  /// 
  /// Returns: 削除成功時はtrue
  Future<bool> deleteWalk({
    required String walkId,
    required WalkMode walkMode,
  }) async {
    try {
      print('🔵 散歩削除開始: walkId=$walkId, mode=${walkMode.value}');

      if (walkMode == WalkMode.daily) {
        // daily_walksから削除（daily_walk_pointsはCASCADE削除される）
        await _supabase.from('daily_walks').delete().eq('id', walkId);
      } else {
        // route_walksから削除
        await _supabase.from('route_walks').delete().eq('id', walkId);
      }

      print('✅ 散歩削除成功: walkId=$walkId');
      return true;
    } catch (e) {
      print('❌ 散歩削除エラー: $e');
      return false;
    }
  }

  /// ユーザーの散歩履歴を取得
  /// 
  /// [userId] - ユーザーID
  /// [walkMode] - 散歩モード（nullの場合は全モード）
  /// [limit] - 取得件数
  /// 
  /// Returns: 散歩記録のリスト
  Future<List<Map<String, dynamic>>> getWalkHistory({
    required String userId,
    WalkMode? walkMode,
    int limit = 50,
  }) async {
    try {
      print('🔵 散歩履歴取得: userId=$userId, mode=${walkMode?.value}');

      if (walkMode == null || walkMode == WalkMode.daily) {
        // 日常散歩履歴を取得
        final dailyWalks = await _supabase
            .from('daily_walks')
            .select()
            .eq('user_id', userId)
            .order('walked_at', ascending: false)
            .limit(limit);

        print('✅ 日常散歩履歴取得: ${(dailyWalks as List).length}件');
        return List<Map<String, dynamic>>.from(dailyWalks);
      } else {
        // おでかけ散歩履歴を取得
        final routeWalks = await _supabase
            .from('route_walks')
            .select('*, official_routes(title, distance_meters)')
            .eq('user_id', userId)
            .order('walked_at', ascending: false)
            .limit(limit);

        print('✅ おでかけ散歩履歴取得: ${(routeWalks as List).length}件');
        return List<Map<String, dynamic>>.from(routeWalks);
      }
    } catch (e) {
      print('❌ 散歩履歴取得エラー: $e');
      return [];
    }
  }
}
