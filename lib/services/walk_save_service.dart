import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_model.dart';
import '../models/walk_mode.dart';
import '../nav/route_nav_engine.dart' show NavCompletion, SpotVisit;
import '../utils/logger.dart';

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
      if (kDebugMode) {
        appLog('🔵 日常散歩保存開始: userId=$userId, points=${route.points.length}');
      }

      // 1. GeoJSON 形式に変換
      // PostGISはLineStringに最低2ポイント必要
      Map<String, dynamic>? pathGeoJson;
      if (route.points.length >= 2) {
        pathGeoJson = {
          'type': 'LineString',
          'coordinates': route.points.map((p) => [
            p.latLng.longitude,
            p.latLng.latitude,
          ]).toList(),
        };
      }

      // 2. walks テーブルに保存 (walk_type='daily')
      final walkResponse = await _supabase.from('walks').insert({
        'user_id': userId,
        'walk_type': 'daily',
        'route_id': null,
        'start_time': route.startedAt.toIso8601String(),
        'end_time': route.endedAt?.toIso8601String(),
        'distance_meters': route.distance,
        'duration_seconds': route.duration,
        'path_geojson': pathGeoJson,
      }).select().single();

      final walkId = walkResponse['id'] as String;
      if (kDebugMode) {
        appLog('✅ walks保存成功 (daily): walkId=$walkId');
      }

      return walkId;
    } catch (e) {
      if (kDebugMode) {
        appLog('❌ 日常散歩保存エラー: $e');
      }
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
    NavCompletion? completion,
  }) async {
    try {
      if (kDebugMode) {
        appLog('🔵 おでかけ散歩保存開始: userId=$userId, routeId=$officialRouteId');
      }

      // 1. GeoJSON 形式に変換
      // PostGISはLineStringに最低2ポイント必要
      Map<String, dynamic>? pathGeoJson;
      if (route.points.length >= 2) {
        pathGeoJson = {
          'type': 'LineString',
          'coordinates': route.points.map((p) => [
            p.latLng.longitude,
            p.latLng.latitude,
          ]).toList(),
        };
      }

      // 2. walks テーブルに保存 (walk_type='outing')
      // LAYER1_NAV_SPEC §5: 完走の生値（coverage/進捗/ゴール距離/完走フラグ）を保存。
      final insertData = <String, dynamic>{
        'user_id': userId,
        'walk_type': 'outing',
        'route_id': officialRouteId,
        'start_time': route.startedAt.toIso8601String(),
        'end_time': route.endedAt?.toIso8601String(),
        'distance_meters': route.distance,
        'duration_seconds': route.duration,
        'path_geojson': pathGeoJson,
      };
      if (completion != null) {
        insertData['coverage_pct'] = completion.coveragePct;
        insertData['max_progress_pct'] = completion.maxProgressPct;
        insertData['min_goal_distance_m'] = completion.minGoalDistanceM;
        insertData['is_route_completed'] = completion.isRouteCompleted;
      }
      final walkResponse = await _supabase.from('walks').insert(insertData).select().single();

      final walkId = walkResponse['id'] as String;
      if (kDebugMode) {
        appLog('✅ walks保存成功 (outing): walkId=$walkId');
      }

      return walkId;
    } catch (e) {
      if (kDebugMode) {
        appLog('❌ おでかけ散歩保存エラー: $e');
      }
      return null;
    }
  }

  /// LAYER1_NAV_SPEC §11: 散歩中に集めた立寄り記録を walk_spot_visits へ一括INSERTする。
  ///
  /// walk 保存が成功した後に1回だけ呼ぶ（散歩中は walk_id 未確定＋山間部圏外で失敗するため
  /// リアルタイム書込はしない）。立寄りは分析用途のデータなので、保存に失敗しても散歩本体
  /// （北極星=walks）は既に保存済み → エラーは握り潰して散歩完了フローを止めない。
  ///
  /// [startTime] は walk の開始時刻。各 SpotVisit の相対 ms を足して絶対 visited_at にする。
  Future<void> saveSpotVisits({
    required String walkId,
    required String userId,
    required List<SpotVisit> visits,
    required DateTime startTime,
  }) async {
    if (visits.isEmpty) return;
    try {
      final rows = visits
          .map((v) => <String, dynamic>{
                'walk_id': walkId,
                'route_spot_id': v.routeSpotId,
                'user_id': userId,
                'visited_at': startTime
                    .add(Duration(milliseconds: v.firstSeenMillis))
                    .toIso8601String(),
                'dwell_sec': v.dwellSec,
                if (v.minDistanceM != null) 'min_distance_m': v.minDistanceM,
              })
          .toList();
      await _supabase.from('walk_spot_visits').insert(rows);
      if (kDebugMode) {
        appLog('✅ 立寄り記録保存: ${rows.length}件 (walkId=$walkId)');
      }
    } catch (e) {
      // 立寄りは分析用途。保存失敗は致命的でない（散歩本体は既に保存済み）。
      if (kDebugMode) {
        appLog('⚠️ 立寄り記録の保存に失敗（無視）: $e');
      }
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
    NavCompletion? completion,
  }) async {
    if (kDebugMode) {
      appLog('🔵 散歩自動保存: mode=${walkMode.value}');
    }

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
        if (kDebugMode) {
          appLog('❌ おでかけ散歩にはofficialRouteIdが必要です');
        }
        return null;
      }
      return await saveRouteWalk(
        route: route,
        userId: userId,
        officialRouteId: officialRouteId,
        dogId: dogId,
        completion: completion,
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
      if (kDebugMode) {
        appLog('🔵 散歩削除開始: walkId=$walkId, mode=${walkMode.value}');
      }

      // walks テーブルから削除
      await _supabase.from('walks').delete().eq('id', walkId);

      if (kDebugMode) {
        appLog('✅ 散歩削除成功: walkId=$walkId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        appLog('❌ 散歩削除エラー: $e');
      }
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
      if (kDebugMode) {
        appLog('🔵 散歩履歴取得: userId=$userId, mode=${walkMode?.value}');
      }

      // walks テーブルから履歴を取得
      var queryBuilder = _supabase
          .from('walks')
          .select('*, routes(name, distance_km)')
          .eq('user_id', userId);

      // walk_mode でフィルター
      if (walkMode == WalkMode.daily) {
        queryBuilder = queryBuilder.eq('walk_type', 'daily');
      } else if (walkMode == WalkMode.outing) {
        queryBuilder = queryBuilder.eq('walk_type', 'outing');
      }

      final walks = await queryBuilder
          .order('start_time', ascending: false)
          .limit(limit);
      if (kDebugMode) {
        appLog('✅ 散歩履歴取得: ${(walks as List).length}件');
      }
      return List<Map<String, dynamic>>.from(walks);
    } catch (e) {
      if (kDebugMode) {
        appLog('❌ 散歩履歴取得エラー: $e');
      }
      return [];
    }
  }
}
