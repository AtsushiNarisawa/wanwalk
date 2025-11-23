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
      // route_pinsテーブルからピンを取得
      final pinsResponse = await _supabase
          .from('route_pins')
          .select()
          .eq('route_id', routeId)
          .order('created_at', ascending: false);

      final pins = (pinsResponse as List).map((json) {
        // 写真URLを別途取得（JOINしていない場合）
        return RoutePin.fromJson(json);
      }).toList();

      // 各ピンの写真URLを取得
      for (var pin in pins) {
        try {
          final photosResponse = await _supabase
              .from('route_pin_photos')
              .select('photo_url')
              .eq('pin_id', pin.id)
              .order('sequence_number', ascending: true);

          final photoUrls = (photosResponse as List)
              .map((photo) => photo['photo_url'] as String)
              .toList();

          // ピンに写真URLを設定（copyWithで新しいインスタンスを作成）
          final index = pins.indexOf(pin);
          pins[index] = pin.copyWith(photoUrls: photoUrls);
        } catch (e) {
          print('Failed to fetch photos for pin ${pin.id}: $e');
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
      final response = await _supabase
          .from('route_pins')
          .select()
          .eq('id', pinId)
          .maybeSingle();

      if (response == null) return null;

      final pin = RoutePin.fromJson(response);

      // 写真URLを取得
      try {
        final photosResponse = await _supabase
            .from('route_pin_photos')
            .select('photo_url')
            .eq('pin_id', pinId)
            .order('sequence_number', ascending: true);

        final photoUrls = (photosResponse as List)
            .map((photo) => photo['photo_url'] as String)
            .toList();

        return pin.copyWith(photoUrls: photoUrls);
      } catch (e) {
        print('Failed to fetch photos for pin $pinId: $e');
        return pin;
      }
    } catch (e) {
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
      print('🔵 ピン作成開始: routeId=$routeId, userId=$userId');
      
      // 1. ピンレコードを作成
      final pinResponse = await _supabase.from('route_pins').insert({
        'official_route_id': routeId,  // カラム名を修正
        'user_id': userId,
        'location': 'SRID=4326;POINT($longitude $latitude)',  // PostGIS WKT形式
        'pin_type': pinType.value,
        'title': title,
        'comment': comment,
      }).select().single();

      print('✅ ピンレコード作成成功: ${pinResponse['id']}');

      final pin = RoutePin.fromJson(pinResponse);

      // 2. 写真があればアップロード
      if (photoFilePaths != null && photoFilePaths.isNotEmpty) {
        print('🔵 写真アップロード開始: ${photoFilePaths.length}枚');
        
        final photoUrls = await _storageService.uploadMultiplePinPhotos(
          filePaths: photoFilePaths,
          userId: userId,
          pinId: pin.id,
        );

        print('✅ 写真アップロード完了: ${photoUrls.length}枚');

        // 3. route_pin_photosテーブルに登録
        for (var i = 0; i < photoUrls.length; i++) {
          try {
            await _supabase.from('route_pin_photos').insert({
              'route_pin_id': pin.id,
              'photo_url': photoUrls[i],
              'display_order': i + 1,
            });
            print('✅ 写真レコード登録成功: ${i + 1}枚目');
          } catch (e) {
            print('❌ 写真レコード登録失敗: $e');
          }
        }

        return pin.copyWith(photoUrls: photoUrls);
      }

      print('✅ ピン作成完了（写真なし）');
      return pin;
    } catch (e) {
      print('❌ ピン作成エラー: $e');
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
