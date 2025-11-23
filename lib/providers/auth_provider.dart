import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

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
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
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
    _authService.authStateChanges.listen((authState) {
      state = state.copyWith(currentUser: authState.session?.user);
    });

    // 現在のユーザーを取得
    final currentUser = Supabase.instance.client.auth.currentUser;
    state = state.copyWith(currentUser: currentUser);
  }

  /// サインアップ
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

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
    state = state.copyWith(isLoading: true, errorMessage: null);

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
    state = state.copyWith(isLoading: true, errorMessage: null);

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
    state = state.copyWith(errorMessage: null);
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
