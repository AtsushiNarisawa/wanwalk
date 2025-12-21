// ==================================================
// Password Reset Screen for WanWalk v2
// ==================================================
// Author: AI Assistant
// Created: 2025-11-21
// Purpose: Allow users to reset their password via email
// ==================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../widgets/wanmap_button.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// メールアドレスのバリデーション
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '有効なメールアドレスを入力してください';
    }
    return null;
  }

  /// パスワードリセットメールを送信
  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();

      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://wanmap.app/auth/reset-password', // TODO: 実際のディープリンクURLに変更
      );

      if (!mounted) return;

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('パスワードリセット用のメールを $email に送信しました'),
          backgroundColor: WanMapColors.success,
          duration: const Duration(seconds: 5),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String errorMessage;
      switch (e.statusCode) {
        case '400':
          errorMessage = 'メールアドレスが正しくありません';
          break;
        case '429':
          errorMessage = 'リクエストが多すぎます。しばらく待ってから再度お試しください';
          break;
        default:
          errorMessage = 'エラーが発生しました: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: WanMapColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('予期しないエラーが発生しました: $e'),
          backgroundColor: WanMapColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('パスワードリセット'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: WanMapSpacing.screenPadding,
            child: _emailSent ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  /// フォーム表示
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // アイコン
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: WanMapColors.accent,
          ),
          const SizedBox(height: WanMapSpacing.xl),

          // タイトル
          Text(
            'パスワードをお忘れですか？',
            style: WanMapTypography.headlineMedium.copyWith(
              color: WanMapColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WanMapSpacing.md),

          // 説明文
          Text(
            '登録済みのメールアドレスを入力してください。\nパスワードリセット用のリンクをお送りします。',
            style: WanMapTypography.bodyMedium.copyWith(
              color: WanMapColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WanMapSpacing.xl),

          // メールアドレス入力
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'メールアドレス',
              hintText: 'example@example.com',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: WanMapSpacing.xl),

          // 送信ボタン
          WanMapButton(
            text: 'リセットメールを送信',
            icon: Icons.send,
            size: WanMapButtonSize.large,
            fullWidth: true,
            loading: _isLoading,
            onPressed: _isLoading ? null : _sendResetEmail,
          ),
          const SizedBox(height: WanMapSpacing.md),

          // ログイン画面に戻る
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: const Text('ログイン画面に戻る'),
          ),
        ],
      ),
    );
  }

  /// 送信成功画面
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 成功アイコン
        const Icon(
          Icons.check_circle,
          size: 100,
          color: WanMapColors.success,
        ),
        const SizedBox(height: WanMapSpacing.xl),

        // タイトル
        Text(
          'メールを送信しました',
          style: WanMapTypography.headlineMedium.copyWith(
            color: WanMapColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: WanMapSpacing.md),

        // 説明文
        Text(
          '${_emailController.text.trim()} にパスワードリセット用のメールを送信しました。\n\nメール内のリンクをクリックして、新しいパスワードを設定してください。',
          style: WanMapTypography.bodyMedium.copyWith(
            color: WanMapColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: WanMapSpacing.md),

        // 注意事項
        Container(
          padding: const EdgeInsets.all(WanMapSpacing.md),
          decoration: BoxDecoration(
            color: WanMapColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: WanMapColors.secondary,
                size: 20,
              ),
              const SizedBox(width: WanMapSpacing.sm),
              Expanded(
                child: Text(
                  'メールが届かない場合は、迷惑メールフォルダをご確認ください。',
                  style: WanMapTypography.bodySmall.copyWith(
                    color: WanMapColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WanMapSpacing.xl),

        // ログイン画面に戻るボタン
        WanMapButton(
          text: 'ログイン画面に戻る',
          icon: Icons.arrow_back,
          size: WanMapButtonSize.large,
          fullWidth: true,
          variant: WanMapButtonVariant.outlined,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        const SizedBox(height: WanMapSpacing.md),

        // メールを再送信
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: const Text('メールを再送信'),
        ),
      ],
    );
  }
}
