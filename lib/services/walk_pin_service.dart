import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_pin.dart';

/// お出かけ散歩に紐づくピンを取得するサービス
class WalkPinService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// お出かけ散歩に紐づくピンを取得
  /// 
  /// Parameters:
  /// - [walkId]: 散歩ID
  /// - [userId]: ユーザーID（自分が投稿したピンのみ取得）
  /// 
  /// Returns: ピンのリスト（時系列順）
  Future<List<RoutePin>> getWalkPins({
    required String walkId,
    required String userId,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 Fetching pins for walkId: $walkId, userId: $userId');
      }

      // route_pinsテーブルから walk_id と user_id で絞り込み
      // route_pin_photosをJOINして写真も取得
      final response = await _supabase
          .from('route_pins')
          .select('''
            id,
            route_id,
            user_id,
            location,
            pin_type,
            title,
            comment,
            likes_count,
            comments_count,
            created_at,
            route_pin_photos(
              id,
              photo_url,
              display_order
            )
          ''')
          .eq('walk_id', walkId)
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      if (kDebugMode) {
        print('📦 Pins response: ${response.length} pins found');
      }

      final pins = (response as List<dynamic>).map((pinData) {
        // PostGIS POINT形式を解析
        final locationStr = pinData['location'] as String?;
        final location = locationStr != null
            ? _parsePostGISPoint(locationStr)
            : const LatLng(35.2034, 139.0315);

        // 写真URLを取得（display_orderでソート）
        final photos = (pinData['route_pin_photos'] as List<dynamic>?)
            ?.map((photo) => (photo['photo_url'] as String?) ?? '')
            .where((url) => url.isNotEmpty)
            .toList() ?? [];

        return RoutePin(
          id: (pinData['id'] as String?) ?? '',
          routeId: (pinData['route_id'] as String?) ?? '',
          userId: (pinData['user_id'] as String?) ?? '',
          location: location,
          pinType: PinType.fromString((pinData['pin_type'] as String?) ?? 'other'),
          title: (pinData['title'] as String?) ?? '',
          comment: (pinData['comment'] as String?) ?? '',
          photoUrls: photos,
          likesCount: (pinData['likes_count'] as int?) ?? 0,
          commentsCount: (pinData['comments_count'] as int?) ?? 0,
          createdAt: pinData['created_at'] != null
              ? DateTime.parse(pinData['created_at'] as String)
              : DateTime.now(),
        );
      }).toList();

      if (kDebugMode) {
        print('✅ Successfully parsed ${pins.length} pins');
      }

      return pins;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching walk pins: $e');
      }
      return [];
    }
  }

  /// PostGIS POINT形式を解析
  /// "POINT(longitude latitude)" -> LatLng
  LatLng _parsePostGISPoint(String pointStr) {
    try {
      // "POINT(139.7380 35.6762)" のような形式
      final regex = RegExp(r'POINT\(([-\d.]+)\s+([-\d.]+)\)');
      final match = regex.firstMatch(pointStr);
      
      if (match != null) {
        final lon = double.parse(match.group(1)!);
        final lat = double.parse(match.group(2)!);
        return LatLng(lat, lon);
      }
      
      // パースできない場合はデフォルト値（箱根）
      if (kDebugMode) {
        print('⚠️ Failed to parse PostGIS point: $pointStr, using default location');
      }
      return const LatLng(35.2034, 139.0315);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing PostGIS point: $e');
      }
      return const LatLng(35.2034, 139.0315);
    }
  }
}
