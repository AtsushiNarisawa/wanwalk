import 'package:flutter/foundation.dart';
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
    if (kDebugMode) {
      print('🔵 [AuthService] signUp開始');
    }
    if (kDebugMode) {
      print('🔵 [AuthService] email: $email');
    }
    if (kDebugMode) {
      print('🔵 [AuthService] displayName: $displayName');
    }
    
    try {
      if (kDebugMode) {
        print('🔵 [AuthService] Supabase signUp呼び出し中...');
      }
      
      // Supabase Authでサインアップ
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );

      if (kDebugMode) {
        print('🟢 [AuthService] signUp成功！');
      }
      if (kDebugMode) {
        print('🟢 [AuthService] user.id: ${response.user?.id}');
      }
      if (kDebugMode) {
        print('🟢 [AuthService] user.email: ${response.user?.email}');
      }

      // サインアップ成功時、profilesテーブルにプロフィール作成
      // [BUG-H05 修正] プロフィール作成失敗時もサインアップは成功扱いとし、
      // 後でプロフィール編集画面のUPSERTで自動補完される設計に変更
      if (response.user != null) {
        try {
          await _supabase.from(SupabaseTables.users).upsert({
            'id': response.user!.id,
            'email': email,
            'display_name': displayName,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (profileError) {
          // プロフィール作成失敗はログに記録するが、サインアップ自体は成功とする
          // profile_edit_screen のUPSERTが次回アクセス時に補完する
          if (kDebugMode) {
            print('⚠️ [AuthService] プロフィール作成失敗（後で自動補完）: $profileError');
          }
        }
      }

      return response;
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('🔴 [AuthService] AuthException: ${e.message}');
      }
      if (kDebugMode) {
        print('🔴 [AuthService] statusCode: ${e.statusCode}');
      }
      throw AuthException(e.message);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [AuthService] Exception: $e');
      }
      if (kDebugMode) {
        print('🔴 [AuthService] Type: ${e.runtimeType}');
      }
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
    if (kDebugMode) {
      print('🔵 [AuthService] signIn開始');
    }
    if (kDebugMode) {
      print('🔵 [AuthService] email: $email');
    }
    
    try {
      if (kDebugMode) {
        print('🔵 [AuthService] Supabase signIn呼び出し中...');
      }
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (kDebugMode) {
        print('🟢 [AuthService] signIn成功！');
      }
      if (kDebugMode) {
        print('🟢 [AuthService] user.id: ${response.user?.id}');
      }
      
      return response;
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('🔴 [AuthService] AuthException: ${e.message}');
      }
      if (kDebugMode) {
        print('🔴 [AuthService] statusCode: ${e.statusCode}');
      }
      throw AuthException(e.message);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [AuthService] Exception: $e');
      }
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

      // [BUG-H01 修正] .single() → .maybeSingle()（データ不在時のクラッシュ防止）
      final response = await _supabase
          .from(SupabaseTables.users)
          .select()
          .eq('id', targetUserId)
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('ユーザープロフィール取得エラー: $e');
      }
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