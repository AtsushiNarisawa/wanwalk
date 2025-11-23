import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/dog_model.dart';

/// 犬情報管理サービス
class DogService {
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

  /// 犬の写真をアップロード
  Future<String?> uploadDogPhoto({
    required File file,
    required String userId,
    String? dogId,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'dogs/$userId/$fileName';

      // Supabase Storageにアップロード
      await _supabase.storage
          .from('dog-photos')
          .upload(filePath, file);

      // 公開URLを取得
      final publicUrl = _supabase.storage
          .from('dog-photos')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('犬の写真アップロードエラー: $e');
      return null;
    }
  }

  /// 犬情報を作成
  Future<DogModel?> createDog(DogModel dog) async {
    try {
      final response = await _supabase
          .from('dogs')
          .insert(dog.toInsertJson())
          .select()
          .single();

      return DogModel.fromJson(response);
    } catch (e) {
      print('犬情報作成エラー: $e');
      return null;
    }
  }

  /// ユーザーの犬一覧を取得
  Future<List<DogModel>> getUserDogs(String userId) async {
    try {
      final response = await _supabase
          .from('dogs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DogModel.fromJson(json))
          .toList();
    } catch (e) {
      print('犬一覧取得エラー: $e');
      rethrow; // エラーを上位に伝播させる
    }
  }

  /// 犬情報を取得
  Future<DogModel?> getDogById(String dogId) async {
    try {
      final response = await _supabase
          .from('dogs')
          .select()
          .eq('id', dogId)
          .single();

      return DogModel.fromJson(response);
    } catch (e) {
      print('犬情報取得エラー: $e');
      return null;
    }
  }

  /// 犬情報を更新
  Future<DogModel?> updateDog(String dogId, Map<String, dynamic> updates) async {
    try {
      // updated_atを自動更新
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('dogs')
          .update(updates)
          .eq('id', dogId)
          .select()
          .single();

      return DogModel.fromJson(response);
    } catch (e) {
      print('犬情報更新エラー: $e');
      return null;
    }
  }

  /// 犬情報を削除
  Future<bool> deleteDog(String dogId, String userId) async {
    try {
      // 犬の写真URLを取得
      final dog = await getDogById(dogId);
      if (dog == null) return false;

      // Storageから写真を削除（存在する場合）
      if (dog.photoUrl != null && dog.photoUrl!.isNotEmpty) {
        try {
          // publicURLからストレージパスを抽出
          final uri = Uri.parse(dog.photoUrl!);
          final pathSegments = uri.pathSegments;
          // /storage/v1/object/public/dog-photos/dogs/userId/filename.jpg
          // から dogs/userId/filename.jpg を抽出
          final storagePathIndex = pathSegments.indexOf('dog-photos');
          if (storagePathIndex != -1 && storagePathIndex < pathSegments.length - 1) {
            final storagePath = pathSegments.sublist(storagePathIndex + 1).join('/');
            await _supabase.storage
                .from('dog-photos')
                .remove([storagePath]);
          }
        } catch (e) {
          print('犬の写真削除エラー（処理は継続）: $e');
        }
      }

      // データベースから削除
      await _supabase
          .from('dogs')
          .delete()
          .eq('id', dogId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('犬情報削除エラー: $e');
      return false;
    }
  }

  /// 犬の写真を更新
  Future<String?> updateDogPhoto({
    required String dogId,
    required String userId,
    required File file,
  }) async {
    try {
      // 既存の犬情報を取得
      final dog = await getDogById(dogId);
      if (dog == null) return null;

      // 古い写真を削除（存在する場合）
      if (dog.photoUrl != null && dog.photoUrl!.isNotEmpty) {
        try {
          final uri = Uri.parse(dog.photoUrl!);
          final pathSegments = uri.pathSegments;
          final storagePathIndex = pathSegments.indexOf('dog-photos');
          if (storagePathIndex != -1 && storagePathIndex < pathSegments.length - 1) {
            final storagePath = pathSegments.sublist(storagePathIndex + 1).join('/');
            await _supabase.storage
                .from('dog-photos')
                .remove([storagePath]);
          }
        } catch (e) {
          print('古い写真削除エラー（処理は継続）: $e');
        }
      }

      // 新しい写真をアップロード
      final newPhotoUrl = await uploadDogPhoto(
        file: file,
        userId: userId,
        dogId: dogId,
      );

      if (newPhotoUrl == null) return null;

      // データベースを更新
      await updateDog(dogId, {'photo_url': newPhotoUrl});

      return newPhotoUrl;
    } catch (e) {
      print('犬の写真更新エラー: $e');
      return null;
    }
  }
}
