import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_model.dart';

/// ホーム画面の統計とおすすめルートを取得するサービス
class HomeStatsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// おすすめルートを取得
  /// 
  /// ユーザーのプロファイルに基づいて最適なルートを提案
  /// 
  /// Parameters:
  /// - [userId]: ユーザーID
  /// - [limit]: 取得件数（デフォルト5件）
  /// 
  /// Returns: おすすめルートのリスト
  Future<List<RouteModel>> getRecommendedRoutes({
    required String userId,
    int limit = 5,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_recommended_routes',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) {
        return RouteModel(
          id: item['route_id'] as String,
          name: item['route_name'] as String,
          areaName: item['area_name'] as String? ?? '',
          distance: (item['distance_meters'] as num?)?.toDouble() ?? 0.0,
          duration: item['estimated_minutes'] as int? ?? 0,
          difficulty: item['difficulty_level'] as String? ?? 'easy',
          description: item['reason'] as String? ?? '',
          thumbnailUrl: item['thumbnail_url'] as String?,
          features: (item['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ?? [],
          totalPins: item['total_pins'] as int? ?? 0,
          averageRating: (item['average_rating'] as num?)?.toDouble(),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching recommended routes: $e');
      }
      return [];
    }
  }

  /// 人気急上昇ルートを取得
  /// 
  /// 直近1週間のピン数が多いルートを返す
  /// 
  /// Parameters:
  /// - [limit]: 取得件数（デフォルト3件）
  /// 
  /// Returns: 人気急上昇ルートのリスト
  Future<List<RouteModel>> getTrendingRoutes({
    int limit = 3,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_trending_routes',
        params: {
          'p_limit': limit,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) {
        return RouteModel(
          id: item['route_id'] as String,
          name: item['route_name'] as String,
          areaName: item['area_name'] as String? ?? '',
          distance: (item['distance_meters'] as num?)?.toDouble() ?? 0.0,
          duration: item['estimated_minutes'] as int? ?? 0,
          difficulty: item['difficulty_level'] as String? ?? 'easy',
          description: '',
          thumbnailUrl: item['thumbnail_url'] as String?,
          features: (item['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ?? [],
          totalPins: item['total_pins'] as int? ?? 0,
          recentPinsCount: item['recent_pins_count'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching trending routes: $e');
      }
      return [];
    }
  }

  /// 最近の思い出写真を取得
  /// 
  /// ホーム画面のプレビュー用に最新の写真を取得
  /// 
  /// Parameters:
  /// - [userId]: ユーザーID
  /// - [limit]: 取得件数（デフォルト6件）
  /// 
  /// Returns: 思い出写真のリスト
  Future<List<RecentMemory>> getRecentMemories({
    required String userId,
    int limit = 6,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_recent_memories',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => RecentMemory.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching recent memories: $e');
      }
      return [];
    }
  }

  /// エリア一覧を取得
  /// 
  /// Returns: エリアのリスト
  Future<List<AreaModel>> getAreas() async {
    try {
      final response = await _supabase
          .from('areas')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List<dynamic>)
          .map((item) => AreaModel.fromJson(item))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching areas: $e');
      }
      return [];
    }
  }

  /// エリア別ルートを取得
  /// 
  /// Parameters:
  /// - [areaId]: エリアID
  /// - [userId]: ユーザーID（歩いたことがあるか判定用）
  /// - [limit]: 取得件数
  /// 
  /// Returns: ルートのリスト
  Future<List<RouteModel>> getRoutesByArea({
    required String areaId,
    String? userId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_routes_by_area_enhanced',
        params: {
          'p_area_id': areaId,
          'p_user_id': userId,
          'p_limit': limit,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) {
        return RouteModel(
          id: item['route_id'] as String,
          name: item['route_name'] as String,
          areaName: '',
          distance: (item['distance_meters'] as num?)?.toDouble() ?? 0.0,
          duration: item['estimated_minutes'] as int? ?? 0,
          difficulty: item['difficulty_level'] as String? ?? 'easy',
          description: item['description'] as String? ?? '',
          thumbnailUrl: item['thumbnail_url'] as String?,
          features: (item['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ?? [],
          totalPins: item['total_pins'] as int? ?? 0,
          averageRating: (item['average_rating'] as num?)?.toDouble(),
          hasWalked: item['has_walked'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching routes by area: $e');
      }
      return [];
    }
  }
}

/// 最近の思い出写真モデル
class RecentMemory {
  final String walkId;
  final String routeId;
  final String routeName;
  final DateTime walkedAt;
  final String photoUrl;
  final int pinCount;

  RecentMemory({
    required this.walkId,
    required this.routeId,
    required this.routeName,
    required this.walkedAt,
    required this.photoUrl,
    required this.pinCount,
  });

  factory RecentMemory.fromJson(Map<String, dynamic> json) {
    return RecentMemory(
      walkId: json['walk_id'] as String,
      routeId: json['route_id'] as String,
      routeName: json['route_name'] as String,
      walkedAt: DateTime.parse(json['walked_at'] as String),
      photoUrl: json['photo_url'] as String,
      pinCount: json['pin_count'] as int? ?? 0,
    );
  }
}

/// エリアモデル
class AreaModel {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final int routeCount;

  AreaModel({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    required this.routeCount,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id'] as String,
      name: json['display_name'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      routeCount: json['route_count'] as int? ?? 0,
    );
  }
}
