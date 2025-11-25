import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// プロフィール情報の状態クラス
class ProfileData {
  final String id;
  final String email;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;

  ProfileData({
    required this.id,
    required this.email,
    this.displayName,
    this.bio,
    this.avatarUrl,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// プロフィール取得プロバイダー
final profileProvider = FutureProvider.family<ProfileData?, String>((ref, userId) async {
  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ProfileData.fromJson(response);
  } catch (e) {
    print('プロフィール取得エラー: $e');
    return null;
  }
});
