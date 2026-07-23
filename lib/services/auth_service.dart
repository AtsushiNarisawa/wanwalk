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

  /// 匿名ユーザー（signInAnonymously で作られた一時アカウント）か。
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// LAYER1_NAV_SPEC §8: 散歩開始時に匿名セッションを付与（転換装置の入口修理）。
  ///
  /// 既にログイン済み（匿名含む）なら何もしない。匿名サインインが Supabase 側で無効、
  /// またはオフラインの場合は false を返す（呼び出し側は記録継続→保存時に再試行）。
  /// ⚠️ 事前条件: Supabase Auth 設定で「Anonymous Sign-ins」を有効化（CEO 手動）。
  Future<bool> signInAnonymouslyIfNeeded() async {
    if (currentUser != null) return true;
    try {
      final res = await _supabase.auth.signInAnonymously();
      if (kDebugMode) {
        appLog('🟢 [AuthService] 匿名サインイン: user.id=${res.user?.id}');
      }
      return res.user != null;
    } on AuthException catch (e) {
      if (kDebugMode) {
        appLog('🔴 [AuthService] 匿名サインイン失敗: ${e.message} (code=${e.code})');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        appLog('🔴 [AuthService] 匿名サインイン例外: $e');
      }
      return false;
    }
  }

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

      // §8 匿名→本登録の引き継ぎ: 現在が匿名ユーザーなら updateUser で同一 uid を維持し、
      // 匿名中に貯めた散歩記録（walks）を引き継ぐ。単純 signUp だと新 uid が作られ
      // 匿名 uid が孤立する（申し送りの linkIdentity 必須に対応）。
      // ⚠️ Supabase で「Confirm email」が ON の場合、email 反映は確認後（uid は即時維持）。
      final AuthResponse response;
      if (isAnonymous) {
        if (kDebugMode) {
          appLog('🔵 [AuthService] 匿名→本登録（updateUser で引き継ぎ）');
        }
        final updated = await _supabase.auth.updateUser(
          UserAttributes(
            email: email,
            password: password,
            data: {'display_name': displayName},
          ),
        );
        response = AuthResponse(
          session: _supabase.auth.currentSession,
          user: updated.user,
        );
      } else {
        // Supabase Authでサインアップ
        response = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'display_name': displayName,
          },
        );
      }

      if (kDebugMode) {
        appLog('🟢 [AuthService] signUp成功！');
      }
      if (kDebugMode) {
        appLog('🟢 [AuthService] user.id: ${response.user?.id}');
      }
      if (kDebugMode) {
        appLog('🟢 [AuthService] user.email: ${response.user?.email}');
      }

      // サインアップ成功時、profiles にプロフィール作成（A13: 読込先と統一）。
      // upsert で冪等化（再試行・トリガとの競合に強い）。
      if (response.user != null) {
        await _supabase.from(SupabaseTables.profiles).upsert({
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

      // §8 匿名→本登録: 匿名セッション中なら identity を link して同一 uid を維持
      // （匿名中の散歩を引き継ぐ）。既に別アカウントに紐づく Apple ID の場合
      // （＝既存ユーザーの再ログイン）は通常サインインにフォールバック。
      final response = await _signInOrLinkIdToken(
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

      // §8 匿名→本登録: 匿名セッション中なら link（同一 uid 維持）、既存紐づけなら通常サインイン。
      final response = await _signInOrLinkIdToken(
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
          .from(SupabaseTables.profiles)
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from(SupabaseTables.profiles).insert({
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

  /// §8: idToken サインイン or 匿名→本登録の identity link。
  ///
  /// 匿名セッション中は [linkIdentityWithIdToken] で同一 uid を維持し、匿名中に貯めた
  /// 散歩記録を引き継ぐ（単純 signIn だと匿名 uid が孤立する・申し送り）。
  /// link が失敗（その Apple/Google ID が既に別アカウントに紐づく＝既存ユーザーの
  /// 再ログイン）した場合は通常の signInWithIdToken にフォールバックする。
  /// ⚠️ 事前条件: Supabase Auth 設定で「Manual Linking」を有効化（CEO 手動）。
  Future<AuthResponse> _signInOrLinkIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) async {
    if (isAnonymous) {
      try {
        if (kDebugMode) {
          appLog('🔵 [AuthService] 匿名→本登録（linkIdentityWithIdToken: ${provider.name}）');
        }
        return await _supabase.auth.linkIdentityWithIdToken(
          provider: provider,
          idToken: idToken,
          accessToken: accessToken,
          nonce: nonce,
        );
      } on AuthException catch (e) {
        // 既存アカウントに紐づく identity 等 → 既存アカウントへの通常ログインとして扱う。
        if (kDebugMode) {
          appLog('⚠️ [AuthService] link 失敗→通常サインインにフォールバック: ${e.message} (code=${e.code})');
        }
      }
    }
    return _supabase.auth.signInWithIdToken(
      provider: provider,
      idToken: idToken,
      accessToken: accessToken,
      nonce: nonce,
    );
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
    } on AuthRetryableFetchException {
      // gotrue の signOut はローカルセッション削除 + signedOut 発火を
      // サーバー側 revoke より先に行う。オフライン等で revoke だけ失敗しても
      // ローカルのログアウトは完了しているため成功扱いにする
      // （「ログアウトに失敗しました」と未ログインUIの矛盾表示を防ぐ）。
      if (kDebugMode) {
        appLog('⚠️ [AuthService] server-side signOut skipped (offline)');
      }
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
          .from(SupabaseTables.profiles)
          .select()
          .eq('id', targetUserId)
          .maybeSingle();

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
          .from(SupabaseTables.profiles)
          .update(updates)
          .eq('id', userId!);
    } catch (e) {
      throw Exception('プロフィール更新に失敗しました: $e');
    }
  }

  /// 現在ログイン中ユーザーの認証プロバイダーを返す
  /// 'email' / 'apple' / 'google' / null
  String? get primaryProvider {
    final user = currentUser;
    if (user == null) return null;
    final identities = user.identities;
    if (identities == null || identities.isEmpty) {
      return user.appMetadata['provider'] as String?;
    }
    // email 提供あれば最優先
    for (final identity in identities) {
      if (identity.provider == 'email') return 'email';
    }
    return identities.first.provider;
  }

  /// パスワード再認証
  /// email/password ユーザー専用。Apple/Google ユーザーは呼び出さない。
  /// 戻り値: 成功時 true、失敗時 false
  Future<bool> reauthenticateWithPassword(String password) async {
    final email = currentUser?.email;
    if (email == null) return false;
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      if (kDebugMode) {
        appLog('🔴 [AuthService] reauth failed: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        appLog('🔴 [AuthService] reauth exception: $e');
      }
      return false;
    }
  }

  /// アカウントを削除（App Store Review Guideline 5.1.1(v)）
  ///
  /// Edge Function `delete-user` を呼び出して以下を実行:
  ///   ① NO ACTION テーブル 4 種を明示削除
  ///   ② Storage バケット 4 種から uid 配下を再帰削除
  ///   ③ auth.admin.deleteUser(uid) で CASCADE 連鎖削除
  ///
  /// 成功時は signOut を実行（戻り値 true）
  /// 失敗時は throw Exception
  Future<bool> deleteAccount() async {
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }
    try {
      if (kDebugMode) {
        appLog('🔵 [AuthService] deleteAccount: invoke delete-user');
      }
      final response = await _supabase.functions.invoke('delete-user');
      final status = response.status;
      final data = response.data;
      if (kDebugMode) {
        appLog('🟢 [AuthService] delete-user status=$status data=$data');
      }
      if (status != 200) {
        throw Exception('アカウント削除に失敗しました (status: $status)');
      }
      if (data is Map && data['ok'] != true) {
        throw Exception('アカウント削除に失敗しました: ${data['error'] ?? 'unknown'}');
      }
      // 成功 → signOut（local session クリア）。エラーが出てもユーザーは既に削除済みなので無視
      try {
        await _supabase.auth.signOut();
      } catch (e) {
        if (kDebugMode) {
          appLog('⚠️ [AuthService] signOut after delete failed (ignored): $e');
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        appLog('🔴 [AuthService] deleteAccount Exception: $e');
      }
      rethrow;
    }
  }
}