import 'package:flutter/material.dart';

import '../config/error_messages.dart';
import '../config/wanwalk_colors.dart';
import '../config/wanwalk_spacing.dart';
import '../config/wanwalk_typography.dart';
import '../utils/error_handler.dart';

/// A3: 「問題を報告」フォーム画面。
///
/// MVP では Sentry へ feedback として送るだけのシンプル実装。
/// 個人情報マスキング方針（A3 §4.2）に合わせて email は送らない。
class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({
    super.key,
    this.contextHint,
  });

  /// 例外の `exceptionAsString()` 等のヒント。送信時に Sentry tag に乗せる。
  final String? contextHint;

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _screenLabel = 'その他';
  bool _submitting = false;
  bool _submitted = false;

  static const _screens = <String>[
    'ホーム',
    'ルート詳細',
    'エリア詳細',
    '散歩記録',
    'おでかけ記録',
    'ピン投稿',
    'プロフィール',
    '愛犬の登録',
    '履歴',
    '設定',
    'その他',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final description = _descriptionController.text.trim();
    try {
      await ErrorHandler.recordNonFatal(
        _UserReport(screen: _screenLabel, description: description),
        extra: {
          'kind': 'user_report',
          'screen': _screenLabel,
          'description': description,
          if (widget.contextHint != null) 'context_hint': widget.contextHint,
        },
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WanWalkColors.backgroundLight,
      appBar: AppBar(
        title: const Text('問題を報告'),
        backgroundColor: WanWalkColors.backgroundLight,
        foregroundColor: WanWalkColors.textPrimaryLight,
        elevation: 0,
      ),
      body: _submitted ? _buildThanks() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(WanWalkSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '気になった点を教えてください',
                style: WanWalkTypography.titleMedium.copyWith(
                  color: WanWalkColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: WanWalkSpacing.sm),
              Text(
                '送信内容は WanWalk の品質改善にのみ使用します。'
                'メールアドレスや位置情報は含まれません',
                style: WanWalkTypography.bodyMedium.copyWith(
                  color: WanWalkColors.textPrimaryLight.withValues(alpha: 0.7),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: WanWalkSpacing.xl),
              Text(
                'どの画面で起きましたか',
                style: WanWalkTypography.bodyMedium.copyWith(
                  color: WanWalkColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: WanWalkSpacing.xs),
              DropdownButtonFormField<String>(
                initialValue: _screenLabel,
                items: _screens
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _screenLabel = v);
                },
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: WanWalkSpacing.lg),
              Text(
                '内容（必須）',
                style: WanWalkTypography.bodyMedium.copyWith(
                  color: WanWalkColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: WanWalkSpacing.xs),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 8,
                maxLength: 500,
                decoration: _inputDecoration(
                  hint: '例：ルート詳細を開くと画面が真っ白になります',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '内容を入力してください' : null,
              ),
              const SizedBox(height: WanWalkSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WanWalkColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: WanWalkSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: WanWalkTypography.labelLarge,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('送信する'),
                ),
              ),
              const SizedBox(height: WanWalkSpacing.md),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: WanWalkColors.textPrimaryLight,
                  ),
                  child: Text(ErrorButtonLabels.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThanks() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(WanWalkSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ありがとうございました',
              style: WanWalkTypography.titleMedium.copyWith(
                color: WanWalkColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.md),
            Text(
              '送信しました。いただいた内容を改善に活用させていただきます',
              textAlign: TextAlign.center,
              style: WanWalkTypography.bodyMedium.copyWith(
                color: WanWalkColors.textPrimaryLight.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.xl),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: WanWalkColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: WanWalkSpacing.md,
                  horizontal: WanWalkSpacing.xl,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(ErrorButtonLabels.close),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: WanWalkColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.md,
        vertical: WanWalkSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: WanWalkColors.textPrimaryLight.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

/// Sentry に「ユーザ報告」として識別させるためのマーカー例外。
class _UserReport implements Exception {
  _UserReport({required this.screen, required this.description});
  final String screen;
  final String description;

  @override
  String toString() =>
      'UserReport(screen=$screen, len=${description.length})';
}

