import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../providers/auth_provider.dart';
import '../../screens/main/main_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// 認証選択画面
/// ソーシャルログイン（Apple/Google）とメール認証の導線を提供
class AuthSelectionScreen extends ConsumerStatefulWidget {
  const AuthSelectionScreen({super.key});

  @override
  ConsumerState<AuthSelectionScreen> createState() =>
      _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends ConsumerState<AuthSelectionScreen> {
  bool _isLoading = false;

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithApple();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted && !e.toString().contains('キャンセル')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('サインインに失敗しました'),
            backgroundColor: WanWalkColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted && !e.toString().contains('キャンセル')) {
        final errorDetail = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('サインイン失敗: $errorDetail'),
            backgroundColor: WanWalkColors.error,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // 戻るボタン
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark
                      ? WanWalkColors.textPrimaryDark
                      : WanWalkColors.textPrimaryLight,
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: const EdgeInsets.all(16),
              ),
            ),
            // メインコンテンツ
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ロゴ
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: WanWalkColors.primary,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.pets,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // タイトル
                      Text(
                        'WanWalk',
                        textAlign: TextAlign.center,
                        style: WanWalkTypography.headlineLarge.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: WanWalkColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '愛犬との散歩をもっと楽しく',
                        textAlign: TextAlign.center,
                        style: WanWalkTypography.bodyMedium.copyWith(
                          color: isDark
                              ? WanWalkColors.textSecondaryDark
                              : WanWalkColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // ローディング表示
                      if (_isLoading) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: WanWalkColors.primary,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Apple Sign In（iOSのみ）
                        if (Platform.isIOS) ...[
                          _AppleSignInButton(onPressed: _handleAppleSignIn),
                          const SizedBox(height: 12),
                        ],

                        // Google Sign In
                        _GoogleSignInButton(
                          onPressed: _handleGoogleSignIn,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 28),

                        // 区切り線
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? WanWalkColors.borderDark
                                    : WanWalkColors.borderLight,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'または',
                                style: WanWalkTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? WanWalkColors.textSecondaryDark
                                      : WanWalkColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? WanWalkColors.borderDark
                                    : WanWalkColors.borderLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // メールで新規登録
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WanWalkColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'メールアドレスで新規登録',
                              style: WanWalkTypography.buttonLarge,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // メールでログイン
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: WanWalkColors.primary,
                              side: const BorderSide(
                                color: WanWalkColors.primary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'メールアドレスでログイン',
                              style: WanWalkTypography.buttonLarge.copyWith(
                                color: WanWalkColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),

                      // ログインせずに続ける
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? WanWalkColors.textSecondaryDark
                              : WanWalkColors.textSecondaryLight,
                        ),
                        child: Text(
                          'ログインせずに続ける',
                          style: WanWalkTypography.bodyMedium.copyWith(
                            decoration: TextDecoration.underline,
                            color: isDark
                                ? WanWalkColors.textSecondaryDark
                                : WanWalkColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apple Sign In ボタン（Apple HIG準拠の黒ボタン）
class _AppleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AppleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple, size: 22),
            const SizedBox(width: 10),
            Text(
              'Appleでサインイン',
              style: WanWalkTypography.buttonLarge.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google Sign In ボタン（Googleブランドガイドライン準拠）
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDark;

  const _GoogleSignInButton({
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF3D3D3D) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          side: BorderSide(
            color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" ロゴ（SVGの代わりにテキストで再現）
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'G',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4285F4),
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Googleでサインイン',
              style: WanWalkTypography.buttonLarge.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
