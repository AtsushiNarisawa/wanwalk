import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

/// Supabase Storage 写真アップロードサービス
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // ストレージバケット名
  static const String pinPhotosBucket = 'pin_photos';

  /// 写真をアップロードして公開URLを返す
  /// 
  /// [filePath] - ローカルファイルパス
  /// [userId] - ユーザーID（フォルダ名に使用）
  /// [pinId] - ピンID（ファイル名に使用）
  /// 
  /// Returns: 公開URL、失敗時はnull
  Future<String?> uploadPinPhoto({
    required String filePath,
    required String userId,
    required String pinId,
  }) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('❌ ファイルが存在しません: $filePath');
        return null;
      }

      // ファイル拡張子を取得
      final extension = path.extension(filePath).toLowerCase();
      
      // ファイル名を生成（ユーザーID/ピンID_タイムスタンプ.拡張子）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/${pinId}_$timestamp$extension';

      print('🔵 写真アップロード開始: $fileName');

      // ファイルをバイト配列として読み込み
      final bytes = await file.readAsBytes();

      // Supabase Storageにアップロード
      final uploadPath = await _supabase.storage
          .from(pinPhotosBucket)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: false,
            ),
          );

      print('✅ アップロード成功: $uploadPath');

      // 公開URLを取得
      final publicUrl = _supabase.storage
          .from(pinPhotosBucket)
          .getPublicUrl(fileName);

      print('✅ 公開URL取得: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('❌ 写真アップロードエラー: $e');
      return null;
    }
  }

  /// 複数の写真をアップロード
  /// 
  /// [filePaths] - ローカルファイルパスのリスト
  /// [userId] - ユーザーID
  /// [pinId] - ピンID
  /// 
  /// Returns: 公開URLのリスト
  Future<List<String>> uploadMultiplePinPhotos({
    required List<String> filePaths,
    required String userId,
    required String pinId,
  }) async {
    final List<String> uploadedUrls = [];

    for (final filePath in filePaths) {
      final url = await uploadPinPhoto(
        filePath: filePath,
        userId: userId,
        pinId: pinId,
      );

      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    print('✅ 複数写真アップロード完了: ${uploadedUrls.length}/${filePaths.length}枚');
    return uploadedUrls;
  }

  /// ファイル拡張子からContent-Typeを取得
  String _getContentType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// 写真を削除
  /// 
  /// [photoUrl] - 削除する写真の公開URL
  /// 
  /// Returns: 成功時はtrue
  Future<bool> deletePinPhoto({
    required String photoUrl,
  }) async {
    try {
      // URLからファイルパスを抽出
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      
      // 最後のセグメントがファイル名
      if (pathSegments.length < 2) {
        print('❌ 無効なURL: $photoUrl');
        return false;
      }

      // バケット名以降のパスを取得
      final bucketIndex = pathSegments.indexOf(pinPhotosBucket);
      if (bucketIndex == -1) {
        print('❌ バケット名が見つかりません: $photoUrl');
        return false;
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      print('🔵 写真削除開始: $filePath');

      // Supabase Storageから削除
      await _supabase.storage
          .from(pinPhotosBucket)
          .remove([filePath]);

      print('✅ 写真削除成功: $filePath');
      return true;
    } catch (e) {
      print('❌ 写真削除エラー: $e');
      return false;
    }
  }
}
