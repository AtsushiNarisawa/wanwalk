import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

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
      appLog('🔵 [AuthService] signUp開始');
    }
    if (kDebugMode) {
      appLog('🔵 [AuthService] email: $email');
    }
    if (kDebugMode) {
      appLog('🔵 [AuthService] displayName: $displayName');
    }
    
    try {
      if (kDebugMode) {
        appLog('🔵 [AuthService] Supabase signUp呼び出し中...');
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
        appLog('🟢 [AuthService] signUp成功！');
      }
      if (kDebugMode) {
        appLog('🟢 [AuthService] user.id: ${response.user?.id}');
      }
      if (kDebugMode) {
        appLog('🟢 [AuthService] user.email: ${response.user?.email}');
      }

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
      if (kDebugMode) {
        appLog('🔴 [AuthService] AuthException: ${e.message}');
      }
      if (kDebugMode) {
        appLog('🔴 [AuthService] statusCode: ${e.statusCode}');
      }
      throw AuthException(e.message);
    } catch (e) {
      if (kDebugMode) {
        appLog('🔴 [AuthService] Exception: $e');
      }
      if (kDebugMode) {
        appLog('🔴 [AuthService] Type: ${e.runtimeType}');
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
      appLog('🔵 [AuthService] signIn開始');
    }
    if (kDebugMode) {
      appLog('🔵 [AuthService] email: $email');
    }
    
    try {
      if (kDebugMode) {
        appLog('🔵 [AuthService] Supabase signIn呼び出し中...');
      }
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (kDebugMode) {
        appLog('🟢 [AuthService] signIn成功！');
      }
      if (kDebugMode) {
        appLog('🟢 [AuthService] user.id: ${response.user?.id}');
      }
      
      return response;
    } on AuthException catch (e) {
      if (kDebugMode) {
        appLog('🔴 [AuthService] AuthException: ${e.message}');
      }
      if (kDebugMode) {
        appLog('🔴 [AuthService] statusCode: ${e.statusCode}');
      }
      throw AuthException(e.message);
    } catch (e) {
      if (kDebugMode) {
        appLog('🔴 [AuthService] Exception: $e');
      }
      throw Exception('ログインに失敗しました: $e');
    }
  }

  /// Apple IDでサインイン
  Future<AuthResponse> signInWithApple() async {
    if (kDebugMode) {
      appLog('🔵 [AuthService] Apple Sign In開始');
    }

    try {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Apple Sign Inに失敗しました');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (kDebugMode) {
        appLog('🟢 [AuthService] Apple Sign In成功！ user.id: ${response.user?.id}');
      }

      // プロフィール作成（初回のみ）
      if (response.user != null) {
        await _ensureProfileExists(
          userId: response.user!.id,
          email: response.user!.email ?? credential.email ?? '',
          displayName: _getAppleDisplayName(credential) ?? 'WanWalkユーザー',
        );
      }

      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('キャンセルされました');
      }
      if (kDebugMode) {
        appLog('🔴 [AuthService] Apple Sign In Error: ${e.message}');
      }
      throw Exception('Apple Sign Inに失敗しました: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        appLog('🔴 [AuthService] Apple Sign In Exception: $e');
      }
      rethrow;
    }
  }

  /// Google アカウントでサインイン
  Future<AuthResponse> signInWithGoogle() async {
    if (kDebugMode) {
      appLog('🔵 [AuthService] Google Sign In開始');
    }

    try {
      final googleSignIn = GoogleSignIn(
        clientId: Environment.googleIosClientId,
        serverClientId: Environment.googleWebClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('キャンセルされました');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Google Sign Inに失敗しました');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (kDebugMode) {
        appLog('🟢 [AuthService] Google Sign In成功！ user.id: ${response.user?.id}');
      }

      // プロフィール作成（初回のみ）
      if (response.user != null) {
        await _ensureProfileExists(
          userId: response.user!.id,
          email: response.user!.email ?? googleUser.email,
          displayName: googleUser.displayName ?? 'WanWalkユーザー',
        );
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        appLog('🔴 [AuthService] Google Sign In Exception: $e');
      }
      rethrow;
    }
  }

  /// ソーシャルログイン時のプロフィール作成（既に存在する場合はスキップ）
  Future<void> _ensureProfileExists({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    try {
      final existing = await _supabase
          .from(SupabaseTables.users)
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from(SupabaseTables.users).insert({
          'id': userId,
          'email': email,
          'display_name': displayName,
          'created_at': DateTime.now().toIso8601String(),
        });
        if (kDebugMode) {
          appLog('🟢 [AuthService] 新規プロフィール作成: $displayName');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        appLog('⚠️ [AuthService] プロフィール作成エラー（無視）: $e');
      }
    }
  }

  /// Apple認証情報から表示名を取得
  String? _getAppleDisplayName(AuthorizationCredentialAppleID credential) {
    final givenName = credential.givenName;
    final familyName = credential.familyName;
    if (givenName != null || familyName != null) {
      return [familyName, givenName].where((s) => s != null).join(' ').trim();
    }
    return null;
  }

  /// ランダムなnonce文字列を生成
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
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
      if (kDebugMode) {
        appLog('ユーザープロフィール取得エラー: $e');
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