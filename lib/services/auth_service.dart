import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// 認証サービス
/// 
/// Supabaseを使用したユーザー認証機能を提供します。
class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// 現在のユーザーを取得
  User? get currentUser => _supabase.auth.currentUser;

  /// 認証状態の変更を監視するストリーム
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// ログイン状態を確認
  bool get isLoggedIn => currentUser != null;

  /// ユーザーIDを取得
  String? get userId => currentUser?.id;

  /// メールアドレスでサインアップ
  /// 
  /// [email] メールアドレス
  /// [password] パスワード（6文字以上推奨）
  /// [displayName] 表示名（ニックネーム）
  /// 
  /// 戻り値: AuthResponse（成功時はuserが含まれる）
  /// 例外: AuthException（サインアップ失敗時）
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Supabase Authでサインアップ
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );

      // サインアップ成功時、usersテーブルにプロフィール作成
      if (response.user != null) {
        await _supabase.from(SupabaseTables.users).insert({
          'id': response.user!.id,
          'email': email,
          'display_name': displayName,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return response;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('サインアップに失敗しました: $e');
    }
  }

  /// メールアドレスでログイン
  /// 
  /// [email] メールアドレス
  /// [password] パスワード
  /// 
  /// 戻り値: AuthResponse（成功時はuserが含まれる）
  /// 例外: AuthException（ログイン失敗時）
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('ログインに失敗しました: $e');
    }
  }

  /// ログアウト
  /// 
  /// 例外: AuthException（ログアウト失敗時）
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('ログアウトに失敗しました: $e');
    }
  }

  /// パスワードリセットメールを送信
  /// 
  /// [email] メールアドレス
  /// 
  /// 例外: AuthException（送信失敗時）
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('パスワードリセットメールの送信に失敗しました: $e');
    }
  }

  /// ユーザープロフィールを取得
  /// 
  /// [userId] ユーザーID（nullの場合は現在のユーザー）
  /// 
  /// 戻り値: ユーザープロフィール情報のMap
  Future<Map<String, dynamic>?> getUserProfile([String? userId]) async {
    try {
      final targetUserId = userId ?? this.userId;
      if (targetUserId == null) return null;

      final response = await _supabase
          .from(SupabaseTables.users)
          .select()
          .eq('id', targetUserId)
          .single();

      return response;
    } catch (e) {
      print('ユーザープロフィール取得エラー: $e');
      return null;
    }
  }

  /// ユーザープロフィールを更新
  /// 
  /// [displayName] 表示名
  /// [bio] 自己紹介
  /// [avatarUrl] アバター画像URL
  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      if (userId == null) throw Exception('ログインしていません');

      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) return;

      await _supabase
          .from(SupabaseTables.users)
          .update(updates)
          .eq('id', userId!);
    } catch (e) {
      throw Exception('プロフィール更新に失敗しました: $e');
    }
  }
}