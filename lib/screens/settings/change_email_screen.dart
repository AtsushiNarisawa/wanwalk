import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';

/// メールアドレス変更画面
class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newEmailController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  /// 現在のメールアドレスを取得
  void _loadCurrentEmail() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentEmail = user.email;
      });
    }
  }

  /// メールアドレスを変更
  Future<void> _changeEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 現在のユーザー情報を取得
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('ユーザー情報が取得できません');
      }

      // 1. 現在のパスワードで再認証（パスワードが正しいか確認）
      await Supabase.instance.client.auth.signInWithPassword(
        email: currentUser.email!,
        password: _currentPasswordController.text,
      );

      // 2. メールアドレスを変更
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          email: _newEmailController.text.trim(),
        ),
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: WanMapSpacing.small),
                Text('確認メール送信'),
              ],
            ),
            content: Text(
              '${_newEmailController.text.trim()} に確認メールを送信しました。\n\nメール内のリンクをクリックして、メールアドレス変更を完了してください。',
              style: WanMapTypography.body,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ダイアログを閉じる
                  Navigator.of(context).pop(); // 画面を閉じる
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: WanMapColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = 'メールアドレス変更に失敗しました: ${e.message}';
        
        // エラーメッセージをより分かりやすく
        if (e.message.contains('Invalid login credentials')) {
          errorMessage = 'パスワードが正しくありません';
        } else if (e.message.contains('Email already in use')) {
          errorMessage = 'このメールアドレスは既に使用されています';
        } else if (e.message.contains('same as the old email')) {
          errorMessage = '現在のメールアドレスと同じです';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanMapColors.cardDark : Colors.white,
        elevation: 0,
        title: const Text(
          'メールアドレス変更',
          style: WanMapTypography.heading2,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(WanMapSpacing.medium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 注意事項
                Container(
                  padding: const EdgeInsets.all(WanMapSpacing.medium),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blue.shade900.withOpacity(0.3)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                      ),
                      const SizedBox(width: WanMapSpacing.small),
                      Expanded(
                        child: Text(
                          '新しいメールアドレスに確認メールが送信されます。メール内のリンクをクリックして変更を完了してください。',
                          style: WanMapTypography.caption.copyWith(
                            color: isDark
                                ? Colors.blue.shade200
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WanMapSpacing.large),

                // 現在のメールアドレス表示
                const Text(
                  '現在のメールアドレス',
                  style: WanMapTypography.heading3,
                ),
                const SizedBox(height: WanMapSpacing.small),
                Container(
                  padding: const EdgeInsets.all(WanMapSpacing.medium),
                  decoration: BoxDecoration(
                    color: isDark
                        ? WanMapColors.cardDark.withOpacity(0.5)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentEmail ?? '読み込み中...',
                    style: WanMapTypography.body.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: WanMapSpacing.large),

                // パスワード確認
                const Text(
                  'パスワード',
                  style: WanMapTypography.heading3,
                ),
                const SizedBox(height: WanMapSpacing.small),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '現在のパスワードを入力',
                    filled: true,
                    fillColor: isDark ? WanMapColors.cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: WanMapSpacing.medium,
                      vertical: WanMapSpacing.small,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: WanMapSpacing.large),

                // 新しいメールアドレス
                const Text(
                  '新しいメールアドレス',
                  style: WanMapTypography.heading3,
                ),
                const SizedBox(height: WanMapSpacing.small),
                TextFormField(
                  controller: _newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: '新しいメールアドレスを入力',
                    filled: true,
                    fillColor: isDark ? WanMapColors.cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: WanMapSpacing.medium,
                      vertical: WanMapSpacing.small,
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '新しいメールアドレスを入力してください';
                    }
                    // メールアドレスの簡易バリデーション
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return '正しいメールアドレス形式で入力してください';
                    }
                    if (value.trim() == _currentEmail) {
                      return '現在のメールアドレスと同じです';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: WanMapSpacing.xxl),

                // 変更ボタン
                ElevatedButton(
                  onPressed: _isLoading ? null : _changeEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WanMapColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: WanMapSpacing.medium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'メールアドレスを変更',
                          style: WanMapTypography.heading3.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
