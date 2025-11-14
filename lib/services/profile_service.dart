import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  /// プロフィールを取得
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return ProfileModel.fromJson(response);
    } catch (e) {
      print('❌ Error getting profile: $e');
      return null;
    }
  }

  /// プロフィールを作成（新規ユーザー登録時）
  Future<bool> createProfile({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'display_name': displayName ?? email.split('@')[0], // デフォルトはメールの@前
      });

      print('✅ Profile created for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error creating profile: $e');
      return false;
    }
  }

  /// プロフィールを更新
  Future<bool> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (displayName != null) updates['display_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) {
        print('⚠️ No updates provided');
        return false;
      }

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);

      print('✅ Profile updated for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error updating profile: $e');
      return false;
    }
  }

  /// アバター画像をアップロード
  Future<String?> uploadAvatar({
    required File file,
    required String userId,
  }) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // Supabase Storageにアップロード
      await _supabase.storage
          .from('profile-avatars')
          .upload(filePath, file);

      // 公開URLを取得
      final publicUrl = _supabase.storage
          .from('profile-avatars')
          .getPublicUrl(filePath);

      print('✅ Avatar uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading avatar: $e');
      return null;
    }
  }

  /// 既存のアバター画像を削除
  Future<bool> deleteAvatar(String storagePath) async {
    try {
      await _supabase.storage
          .from('profile-avatars')
          .remove([storagePath]);

      print('✅ Avatar deleted: $storagePath');
      return true;
    } catch (e) {
      print('❌ Error deleting avatar: $e');
      return false;
    }
  }
}
