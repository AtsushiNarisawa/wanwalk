import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

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
      print('画像選択エラー: $e');
      return null;
    }
  }

  /// カメラで写真を撮影
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print('カメラ撮影エラー: $e');
      return null;
    }
  }

  /// 写真をアップロード
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
      print('写真アップロードエラー: $e');
      return null;
    }
  }

  /// ルートの写真一覧を取得
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
      print('写真一覧取得エラー: $e');
      return [];
    }
  }

  /// 写真を削除
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
      print('写真削除エラー: $e');
      return false;
    }
  }
}

/// 写真モデル
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
