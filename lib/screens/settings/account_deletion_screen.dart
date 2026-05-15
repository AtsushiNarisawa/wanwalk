import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

/// アカウント削除画面
///
/// 設計書: docs/mvp_specs/F0_account_deletion_design.md v1.0
/// 根拠: App Store Review Guideline 5.1.1(v)
///
/// 3 ステップ構成:
///   Step 1: 説明 + 同意
///   Step 2: 再認証
///     - email/password: パスワード再入力
///     - Apple/Google: 「DELETE」と入力
///   Step 3: 実行中 → 完了 → LoginScreen にスタッククリア push
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _deleteWordController = TextEditingController();

  int _step = 1; // 1: 説明, 2: 再認証, 3: 実行中
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _deleteWordController.dispose();
    super.dispose();
  }

  bool get _isPasswordUser => _authService.primaryProvider == 'email';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanWalkColors.cardDark : Colors.white,
        elevation: 0,
        title: const Text('アカウントを削除', style: WanWalkTypography.heading2),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WanWalkSpacing.medium),
          child: _step == 1
              ? _buildStep1(isDark)
              : _step == 2
                  ? _buildStep2(isDark)
                  : _buildStep3(isDark),
        ),
      ),
    );
  }

  // ------------------------------ Step 1 ------------------------------

  Widget _buildStep1(bool isDark) {
    final secondaryText = isDark ? Colors.white70 : Colors.black87;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade700, size: 28),
            const SizedBox(width: WanWalkSpacing.small),
            const Expanded(
              child: Text(
                'アカウントを削除します',
                style: WanWalkTypography.heading2,
              ),
            ),
          ],
        ),
        const SizedBox(height: WanWalkSpacing.medium),
        Text(
          '以下のデータが完全に消去されます:',
          style: WanWalkTypography.body.copyWith(color: secondaryText),
        ),
        const SizedBox(height: WanWalkSpacing.small),
        _bulletItem('プロフィール', isDark),
        _bulletItem('登録した愛犬の情報', isDark),
        _bulletItem('散歩記録（写真を含む）', isDark),
        _bulletItem('投稿したピン', isDark),
        _bulletItem('お気に入りに追加したルート', isDark),
        const SizedBox(height: WanWalkSpacing.medium),
        Container(
          padding: const EdgeInsets.all(WanWalkSpacing.medium),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: WanWalkSpacing.small),
              Expanded(
                child: Text(
                  '削除後の復元はできません。',
                  style: WanWalkTypography.body.copyWith(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('キャンセル'),
              ),
            ),
            const SizedBox(width: WanWalkSpacing.medium),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _step = 2;
                    _errorMessage = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('続行する'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bulletItem(String text, bool isDark) {
    final secondaryText = isDark ? Colors.white70 : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('・', style: WanWalkTypography.body.copyWith(color: secondaryText)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                style: WanWalkTypography.body.copyWith(color: secondaryText)),
          ),
        ],
      ),
    );
  }

  // ------------------------------ Step 2 ------------------------------

  Widget _buildStep2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isPasswordUser ? 'パスワードを入力してください' : '「DELETE」と入力してください',
          style: WanWalkTypography.heading2,
        ),
        const SizedBox(height: WanWalkSpacing.small),
        Text(
          _isPasswordUser
              ? '本人確認のため、ログインに使用しているパスワードを入力してください。'
              : 'アカウント削除を確定するため、半角大文字で「DELETE」と入力してください。',
          style: WanWalkTypography.caption.copyWith(
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: WanWalkSpacing.large),
        if (_isPasswordUser)
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            enabled: !_isProcessing,
            onChanged: (_) => setState(() => _errorMessage = null),
            decoration: const InputDecoration(
              labelText: 'パスワード',
              border: OutlineInputBorder(),
            ),
          )
        else
          TextField(
            controller: _deleteWordController,
            autofocus: true,
            enabled: !_isProcessing,
            onChanged: (_) => setState(() => _errorMessage = null),
            decoration: const InputDecoration(
              labelText: 'DELETE',
              border: OutlineInputBorder(),
            ),
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: WanWalkSpacing.small),
          Text(
            _errorMessage!,
            style: WanWalkTypography.caption
                .copyWith(color: Colors.red.shade700),
          ),
        ],
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('キャンセル'),
              ),
            ),
            const SizedBox(width: WanWalkSpacing.medium),
            Expanded(
              child: ElevatedButton(
                onPressed: _canSubmitStep2() ? _onConfirmDelete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('アカウントを削除'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _canSubmitStep2() {
    if (_isProcessing) return false;
    if (_isPasswordUser) {
      return _passwordController.text.isNotEmpty;
    }
    return _deleteWordController.text == 'DELETE';
  }

  Future<void> _onConfirmDelete() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Step A: email/password ユーザーは再認証
    if (_isPasswordUser) {
      final ok = await _authService
          .reauthenticateWithPassword(_passwordController.text);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'パスワードが正しくありません。';
        });
        return;
      }
    }

    // Step B: 実行画面に遷移
    setState(() {
      _step = 3;
    });

    // Step C: Edge Function 呼び出し
    try {
      await _authService.deleteAccount();
      if (!mounted) return;
      // 成功 → LoginScreen にスタッククリア push
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アカウントを削除しました')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = 2;
        _isProcessing = false;
        _errorMessage = '削除に失敗しました。時間をおいて再度お試しください。\n問題が続く場合はサポートまでご連絡ください。';
      });
    }
  }

  // ------------------------------ Step 3 ------------------------------

  Widget _buildStep3(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: WanWalkSpacing.large),
          Text(
            'アカウントを削除しています...',
            style: WanWalkTypography.body.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
