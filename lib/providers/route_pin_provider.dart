import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_pin.dart';
import '../services/storage_service.dart';

/// Supabaseクライアントのインスタンス取得
final _supabase = Supabase.instance.client;

/// ルートIDでピン一覧を取得するProvider
final pinsByRouteProvider = FutureProvider.family<List<RoutePin>, String>(
  (ref, routeId) async {
    try {
      // route_pinsテーブルからピンを取得（locationフィールドは除外）
      final pinsResponse = await _supabase
          .from('route_pins')
          .select('id, route_id, user_id, pin_type, title, comment, likes_count, created_at')
          .eq('route_id', routeId)
          .order('created_at', ascending: false);

      final pins = <RoutePin>[];
      
      for (var json in (pinsResponse as List)) {
        try {
          // 位置情報を手動で取得（WKB形式を回避）
          final pinId = json['id'];
          final locationQuery = await _supabase.rpc(
            'get_pin_location',
            params: {'pin_id': pinId}
          );
          
          // locationQueryからlat/lonを取得してjsonに追加
          if (locationQuery != null && locationQuery is List && locationQuery.isNotEmpty) {
            final locationData = locationQuery[0];
            json['pin_lat'] = locationData['latitude'];
            json['pin_lon'] = locationData['longitude'];
          }
          
          pins.add(RoutePin.fromJson(json));
        } catch (e) {
          if (kDebugMode) {
            print('Failed to parse pin: $e');
          }
        }
      }

      // 各ピンの写真URLを取得
      for (var pin in pins) {
        try {
          final photosResponse = await _supabase
              .from('route_pin_photos')
              .select('photo_url')
              .eq('pin_id', pin.id)
              .order('display_order', ascending: true);

          final photoUrls = (photosResponse as List)
              .map((photo) => photo['photo_url'] as String)
              .toList();

          // ピンに写真URLを設定（copyWithで新しいインスタンスを作成）
          final index = pins.indexOf(pin);
          pins[index] = pin.copyWith(photoUrls: photoUrls);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to fetch photos for pin ${pin.id}: $e');
          }
        }
      }

      return pins;
    } catch (e) {
      throw Exception('Failed to fetch pins by route: $e');
    }
  },
);

/// ピンIDでピン詳細を取得するProvider
final pinByIdProvider = FutureProvider.family<RoutePin?, String>(
  (ref, pinId) async {
    try {
      // route_pinsテーブルからピンを取得（locationフィールドは除外）
      final response = await _supabase
          .from('route_pins')
          .select('id, route_id, user_id, pin_type, title, comment, likes_count, created_at')
          .eq('id', pinId)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) {
          print('❌ Pin not found: $pinId');
        }
        return null;
      }

      // 位置情報を手動で取得（WKB形式を回避）
      try {
        final locationQuery = await _supabase.rpc(
          'get_pin_location',
          params: {'pin_id': pinId}
        );
        
        // locationQueryからlat/lonを取得してresponseに追加
        if (locationQuery != null && locationQuery is List && locationQuery.isNotEmpty) {
          final locationData = locationQuery[0];
          response['pin_lat'] = locationData['latitude'];
          response['pin_lon'] = locationData['longitude'];
        } else {
          if (kDebugMode) {
            print('⚠️ Location not found for pin $pinId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to fetch location for pin $pinId: $e');
        }
      }

      final pin = RoutePin.fromJson(response);

      // 写真URLを取得
      try {
        final photosResponse = await _supabase
            .from('route_pin_photos')
            .select('photo_url')
            .eq('pin_id', pinId)
            .order('display_order', ascending: true);

        final photoUrls = (photosResponse as List)
            .map((photo) => photo['photo_url'] as String)
            .toList();

        if (kDebugMode) {
          print('✅ Pin loaded successfully: ${pin.title} (${photoUrls.length} photos)');
        }

        return pin.copyWith(photoUrls: photoUrls);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to fetch photos for pin $pinId: $e');
        }
        return pin;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch pin $pinId: $e');
      }
      throw Exception('Failed to fetch pin: $e');
    }
  },
);

/// ピンを作成するProvider
final createPinProvider = Provider((ref) => CreatePinUseCase());

class CreatePinUseCase {
  final StorageService _storageService = StorageService();

  /// ピンを作成（写真アップロード含む）
  Future<RoutePin> createPin({
    required String routeId,
    required String userId,
    required double latitude,
    required double longitude,
    required PinType pinType,
    required String title,
    required String comment,
    List<String>? photoFilePaths, // ローカルファイルパス
  }) async {
    try {
      if (kDebugMode) {
        print('🔵 ピン作成開始: routeId=$routeId, userId=$userId');
      }
      
      // 1. ピンレコードを作成
      final pinResponse = await _supabase.from('route_pins').insert({
        'route_id': routeId,
        'user_id': userId,
        'location': 'SRID=4326;POINT($longitude $latitude)',  // PostGIS WKT形式
        'pin_type': pinType.value,
        'title': title,
        'comment': comment,
      }).select().single();
      
      // 位置情報を手動で取得（WKB形式を回避）
      final pinId = pinResponse['id'];
      final locationQuery = await _supabase.rpc(
        'get_pin_location',
        params: {'pin_id': pinId}
      );
      
      // locationQueryからlat/lonを取得してpinResponseに追加
      // RPC関数はTABLEを返すため、結果は配列形式
      if (locationQuery != null && locationQuery is List && locationQuery.isNotEmpty) {
        final locationData = locationQuery[0];  // 最初の行を取得
        pinResponse['pin_lat'] = locationData['latitude'];
        pinResponse['pin_lon'] = locationData['longitude'];
      }

      if (kDebugMode) {
        print('✅ ピンレコード作成成功: ${pinResponse['id']}');
      }

      final pin = RoutePin.fromJson(pinResponse);

      // 2. 写真があればアップロード
      if (photoFilePaths != null && photoFilePaths.isNotEmpty) {
        if (kDebugMode) {
          print('🔵 写真アップロード開始: ${photoFilePaths.length}枚');
        }
        
        final photoUrls = await _storageService.uploadMultiplePinPhotos(
          filePaths: photoFilePaths,
          userId: userId,
          pinId: pin.id,
        );

        if (kDebugMode) {
          print('✅ 写真アップロード完了: ${photoUrls.length}枚');
        }

        // 3. route_pin_photosテーブルに登録
        for (var i = 0; i < photoUrls.length; i++) {
          try {
            await _supabase.from('route_pin_photos').insert({
              'pin_id': pin.id,
              'photo_url': photoUrls[i],
              'display_order': i + 1,
            });
            if (kDebugMode) {
              print('✅ 写真レコード登録成功: ${i + 1}枚目');
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ 写真レコード登録失敗: $e');
            }
          }
        }

        return pin.copyWith(photoUrls: photoUrls);
      }

      if (kDebugMode) {
        print('✅ ピン作成完了（写真なし）');
      }
      return pin;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ピン作成エラー: $e');
      }
      throw Exception('Failed to create pin: $e');
    }
  }
}

/// ピンにいいねするProvider
final likePinProvider = Provider((ref) => LikePinUseCase());

class LikePinUseCase {
  /// いいねをトグル（いいね/いいね解除）
  Future<bool> toggleLike({
    required String pinId,
    required String userId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'toggle_pin_like',
        params: {
          'p_pin_id': pinId,
          'p_user_id': userId,
        },
      );

      return response['liked'] as bool;
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }
}

/// ユーザーがピンにいいねしているか確認するProvider
final isPinLikedProvider = FutureProvider.family<bool, String>(
  (ref, pinId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('pin_likes')
          .select('id')
          .eq('pin_id', pinId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  },
);
