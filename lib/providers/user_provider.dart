import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

/// 現在のユーザーIDを提供するProvider
final currentUserIdProvider = Provider<String?>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  return user?.id;
});

/// 現在のユーザーのProfileModelを提供するProvider
final currentUserProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  
  final profile = await ProfileService().getProfile(userId);
  
  // プロフィールが存在しない場合は新規作成
  if (profile == null) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.email != null) {
      await ProfileService().createProfile(
        userId: userId,
        email: user.email!,
      );
      return await ProfileService().getProfile(userId);
    }
  }
  
  return profile;
});

/// ユーザープロフィールを取得するProvider（family版）
final userProfileProvider = FutureProvider.family<ProfileModel?, String>(
  (ref, userId) async {
    return await ProfileService().getProfile(userId);
  },
);
