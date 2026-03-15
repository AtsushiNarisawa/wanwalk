import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/logger.dart';

/// 写真管理サービス
class PhotoService {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  /// ギャラリーから写真を選択
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      if (kDebugMode) {
        appLog('画像選択エラー: $e');
      }
      return null;
    }
  }

  /// カメラで写真を撮影
  /// iOS Simulatorではギャラリーから選択（実機ではカメラが使用される）
  Future<File?> takePhoto() async {
    try {
      // iOS Simulatorではカメラが使えないため、ギャラリーから選択
      // 実機では Platform.isIOS && !Platform.environment.containsKey('SIMULATOR_DEVICE_NAME')
      // でカメラを使用可能
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,  // Simulatorでも動作するようにgalleryを使用
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      if (kDebugMode) {
        appLog('カメラ撮影エラー: $e');
      }
      return null;
    }
  }

  /// 散歩中の写真をアップロード（Phase 3新機能）
  Future<String?> uploadWalkPhoto({
    required File file,
    required String walkId,
    required String userId,
    String? caption,
    int displayOrder = 1,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$walkId/$fileName';

      if (kDebugMode) {
        appLog('📸 散歩写真アップロード開始: $filePath');
      }

      // Supabase Storageにアップロード (walk-photos バケット)
      await _supabase.storage
          .from('walk-photos')
          .upload(filePath, file);

      if (kDebugMode) {
        appLog('✅ Storage アップロード成功');
      }

      // walk_photosテーブルに記録
      await _supabase.from('walk_photos').insert({
        'walk_id': walkId,
        'user_id': userId,
        'photo_url': filePath,
        'caption': caption,
        'display_order': displayOrder,
      });

      if (kDebugMode) {
        appLog('✅ データベース記録成功');
      }

      // 公開URLを取得
      final publicUrl = _supabase.storage
          .from('walk-photos')
          .getPublicUrl(filePath);

      if (kDebugMode) {
        appLog('🌐 公開URL: $publicUrl');
      }

      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        appLog('❌ 散歩写真アップロードエラー: $e');
      }
      return null;
    }
  }

  /// ルート写真をアップロード（既存機能・使用されていない）
  @deprecated
  Future<String?> uploadPhoto({
    required File file,
    required String routeId,
    required String userId,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$routeId/$fileName';

      // Supabase Storageにアップロード
      await _supabase.storage
          .from('route-photos')
          .upload(filePath, file);

      // route_photosテーブルに記録
      await _supabase.from('route_photos').insert({
        'route_id': routeId,
        'user_id': userId,
        'storage_path': filePath,
      });

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        appLog('写真アップロードエラー: $e');
      }
      return null;
    }
  }

  /// 散歩の写真一覧を取得（Phase 3新機能）
  Future<List<WalkPhoto>> getWalkPhotos(String walkId) async {
    try {
      final response = await _supabase
          .from('walk_photos')
          .select()
          .eq('walk_id', walkId)
          .order('display_order', ascending: true);

      return (response as List).map((json) {
        final photoUrl = json['photo_url'] as String;
        final publicUrl = _supabase.storage
            .from('walk-photos')
            .getPublicUrl(photoUrl);

        return WalkPhoto(
          id: json['id'] as String,
          walkId: json['walk_id'] as String,
          userId: json['user_id'] as String,
          photoUrl: photoUrl,
          publicUrl: publicUrl,
          caption: json['caption'] as String?,
          displayOrder: json['display_order'] as int? ?? 1,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        appLog('散歩写真一覧取得エラー: $e');
      }
      return [];
    }
  }

  /// ルートの写真一覧を取得（既存機能）
  @deprecated
  Future<List<RoutePhoto>> getRoutePhotos(String routeId) async {
    try {
      final response = await _supabase
          .from('route_photos')
          .select()
          .eq('route_id', routeId)
          .order('display_order', ascending: true);

      return (response as List).map((json) {
        final storagePath = json['storage_path'] as String;
        final publicUrl = _supabase.storage
            .from('route-photos')
            .getPublicUrl(storagePath);

        return RoutePhoto(
          id: json['id'] as String,
          routeId: json['route_id'] as String,
          userId: json['user_id'] as String,
          storagePath: storagePath,
          publicUrl: publicUrl,
          caption: json['caption'] as String?,
          displayOrder: json['display_order'] as int? ?? 0,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        appLog('写真一覧取得エラー: $e');
      }
      return [];
    }
  }

  /// 散歩写真を削除（Phase 3新機能）
  Future<bool> deleteWalkPhoto({
    required String photoId,
    required String photoUrl,
    required String userId,
  }) async {
    try {
      // Storageから削除
      await _supabase.storage
          .from('walk-photos')
          .remove([photoUrl]);

      // データベースから削除
      await _supabase
          .from('walk_photos')
          .delete()
          .eq('id', photoId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        appLog('散歩写真削除エラー: $e');
      }
      return false;
    }
  }

  /// 写真を削除（既存機能）
  @deprecated
  Future<bool> deletePhoto({
    required String photoId,
    required String storagePath,
    required String userId,
  }) async {
    try {
      // Storageから削除
      await _supabase.storage
          .from('route-photos')
          .remove([storagePath]);

      // データベースから削除
      await _supabase
          .from('route_photos')
          .delete()
          .eq('id', photoId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        appLog('写真削除エラー: $e');
      }
      return false;
    }
  }
}

/// 散歩写真モデル（Phase 3新機能）
class WalkPhoto {
  final String id;
  final String walkId;
  final String userId;
  final String photoUrl;
  final String publicUrl;
  final String? caption;
  final int displayOrder;
  final DateTime createdAt;

  WalkPhoto({
    required this.id,
    required this.walkId,
    required this.userId,
    required this.photoUrl,
    required this.publicUrl,
    this.caption,
    required this.displayOrder,
    required this.createdAt,
  });
}

/// ルート写真モデル（既存機能）
class RoutePhoto {
  final String id;
  final String routeId;
  final String userId;
  final String storagePath;
  final String publicUrl;
  final String? caption;
  final int displayOrder;
  final DateTime createdAt;

  RoutePhoto({
    required this.id,
    required this.routeId,
    required this.userId,
    required this.storagePath,
    required this.publicUrl,
    this.caption,
    required this.displayOrder,
    required this.createdAt,
  });
}
