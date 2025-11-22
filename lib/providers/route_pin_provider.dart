import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_pin.dart';

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
      // 1. ピンレコードを作成
      final pinResponse = await _supabase.from('route_pins').insert({
        'route_id': routeId,
        'user_id': userId,
        'location': {
          'type': 'Point',
          'coordinates': [longitude, latitude],
        },
        'pin_type': pinType.value,
        'title': title,
        'comment': comment,
      }).select().single();

      final pin = RoutePin.fromJson(pinResponse);

      // 2. 写真があればアップロード
      if (photoFilePaths != null && photoFilePaths.isNotEmpty) {
        final photoUrls = <String>[];
        for (var i = 0; i < photoFilePaths.length && i < 5; i++) {
          final filePath = photoFilePaths[i];
          final fileName = '${pin.id}_$i.jpg';
          final storagePath = 'pin_photos/$fileName';

          try {
            // Supabase Storageにアップロード
            await _supabase.storage.from('photos').upload(
                  storagePath,
                  // ローカルファイルをアップロード（実装はアプリ側で調整）
                  filePath as Object,
                );

            // 公開URLを取得
            final publicUrl = _supabase.storage.from('photos').getPublicUrl(storagePath);

            // route_pin_photosテーブルに登録
            await _supabase.from('route_pin_photos').insert({
              'pin_id': pin.id,
              'photo_url': publicUrl,
              'sequence_number': i + 1,
            });

            photoUrls.add(publicUrl);
          } catch (e) {
            print('Failed to upload photo $i: $e');
          }
        }

        return pin.copyWith(photoUrls: photoUrls);
      }

      return pin;
    } catch (e) {
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
