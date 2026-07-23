import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

/// 認証状態クラス
class AuthState {
  final User? currentUser;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isLoggedIn => currentUser != null;

  AuthState copyWith({
    User? currentUser,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      // clearUser=true のとき明示的に null へ（ログアウト反映用）。
      // ?? では nullable を消せないため clearError と同パターン
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      // clearError=true のとき明示的に null へ。?? では nullable を消せないため
      // (spot_review_provider.dart と同パターン)
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 認証状態を管理するRiverpod StateNotifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState()) {
    _init();
  }

  /// 初期化：認証状態の変更を監視
  void _init() {
    _authService.authStateChanges.listen(
      (authState) {
        final user = authState.session?.user;
        // signedOut 等で session=null のとき明示的にクリアしないと
        // copyWith の ?? が旧ユーザーを残す（ログアウト後UI不更新バグの真因）
        state = state.copyWith(currentUser: user, clearUser: user == null);
        if (kDebugMode) {
          appLog('🔐 Auth state changed: userId=${user?.id ?? "null"}');
        }
      },
      // オフライン時のトークンリフレッシュ失敗等が同じストリームに addError で
      // 流れてくる（gotrue 仕様）。握らないと Zone 未処理例外→Sentry ノイズ。
      onError: (Object e) {
        if (kDebugMode) appLog('🔐 Auth stream error: $e');
      },
    );

    // 現在のユーザーを取得
    final currentUser = Supabase.instance.client.auth.currentUser;
    state = state.copyWith(currentUser: currentUser);
    if (kDebugMode) {
      appLog('🔐 Initial auth state: userId=${currentUser?.id ?? "null"}');
    }
  }

  /// サインアップ
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = state.copyWith(currentUser: response.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// ログイン
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );
      state = state.copyWith(currentUser: response.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// Apple Sign In
  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authService.signInWithApple();
      state = state.copyWith(currentUser: response.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// Google Sign In
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authService.signInWithGoogle();
      state = state.copyWith(currentUser: response.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// §8: 散歩開始時にセッションを保証する（未ログインなら匿名サインイン）。
  ///
  /// 戻り値 true でセッションあり（既存 or 匿名新規）。匿名サインインが Supabase 側で
  /// 無効/オフラインなら false（呼び出し側は記録は続行し、保存時に再試行する）。
  /// 成功時は authStateChanges リスナーが currentUser を更新する。
  Future<bool> ensureSession() async {
    if (state.isLoggedIn) return true;
    final ok = await _authService.signInAnonymouslyIfNeeded();
    if (ok) {
      state = state.copyWith(
        currentUser: Supabase.instance.client.auth.currentUser,
      );
    }
    return ok;
  }

  /// ログアウト
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signOut();
      state = AuthState(isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// パスワードリセット
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// ユーザープロフィール取得
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      return await _authService.getUserProfile(userId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  /// エラーメッセージをクリア
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// AuthProvider（Riverpod版）
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// 現在のユーザーIDを取得するProvider
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.currentUser?.id;
});

/// 現在のユーザーを取得するProvider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.currentUser;
});

/// ログイン状態を取得するProvider
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isLoggedIn;
});
