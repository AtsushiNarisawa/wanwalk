import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// AuthServiceのProvider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// 現在のユーザーのProvider
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((state) => state.session?.user);
});

/// ログイン状態のProvider
final isLoggedInProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// ユーザープロフィールのProvider
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  
  if (user == null) return null;
  
  return await authService.getUserProfile(user.id);
});

/// 認証状態管理用のStateNotifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((authState) {
      state = AsyncValue.data(authState.session?.user);
    });
  }

  /// サインアップ
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncValue.data(response.user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// ログイン
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// ログアウト
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// パスワードリセット
  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }
}

/// AuthNotifierのProvider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});