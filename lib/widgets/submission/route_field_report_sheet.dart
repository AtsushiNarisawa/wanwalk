import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/submission_constants.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../providers/analytics_provider.dart';
import '../../services/submission_service.dart';

/// 既存公式ルートへの実走報告（type='field_report'）を集めるボトムシート。
///
/// route_detail の情報フィードバック、散歩完了（お出かけ）、過去のお出かけ散歩詳細から
/// 共通で使う。カテゴリ＋本文を reason に合成し、公開名・同意とともに route_submissions へ
/// 単一INSERTする。target_route_id は必須（既存ルートに紐づく報告のため）。
class RouteFieldReportSheet extends ConsumerStatefulWidget {
  const RouteFieldReportSheet({
    super.key,
    required this.targetRouteId,
    this.walkId,
    this.entryPoint,
    this.scaffoldMessenger,
  });

  final String targetRouteId;
  final String? walkId;
  final String? entryPoint;

  /// シートを閉じた後に完了/失敗スナックバーを出すための親 Messenger（任意）。
  final ScaffoldMessengerState? scaffoldMessenger;

  @override
  ConsumerState<RouteFieldReportSheet> createState() =>
      _RouteFieldReportSheetState();
}

class _RouteFieldReportSheetState
    extends ConsumerState<RouteFieldReportSheet> {
  final SubmissionService _service = SubmissionService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _publicNameController = TextEditingController();

  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  String _selectedCategory = 'other';
  bool _agreed = false;
  bool _submitting = false;

  static const Map<String, String> _categories = {
    'parking': '駐車場',
    'surface': '道の状態',
    'water_station': '水飲み場',
    'restroom': 'トイレ',
    'pet_facilities': 'ペット施設',
    'other': 'その他',
  };

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => _openUrl(SubmissionConstants.termsUrl);
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => _openUrl(SubmissionConstants.privacyUrl);
    _prefillPublicName();
    unawaited(ref.read(analyticsServiceProvider).logSubmitStart(
          entryPoint: widget.entryPoint ?? 'route_detail',
          submissionType: SubmissionType.fieldReport,
          theme: SubmissionConstants.activeTheme,
        ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _publicNameController.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _prefillPublicName() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final prof = await Supabase.instance.client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();
      final dn = (prof?['display_name'] as String?)?.trim();
      if (dn != null && dn.isNotEmpty && mounted) {
        _publicNameController.text = dn;
      }
    } catch (_) {
      // 初期値は空でも可
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool get _canSubmit =>
      _messageController.text.trim().isNotEmpty &&
      _publicNameController.text.trim().isNotEmpty &&
      _agreed &&
      !_submitting;

  void _notify(String message) {
    final messenger = widget.scaffoldMessenger ?? ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _notify('報告を送るにはログインが必要です');
      return;
    }
    setState(() => _submitting = true);
    final categoryLabel = _categories[_selectedCategory] ?? 'その他';
    final reason = '[$categoryLabel] ${_messageController.text.trim()}';
    try {
      await _service.createFieldReport(
        userId: userId,
        targetRouteId: widget.targetRouteId,
        reason: reason,
        publicName: _publicNameController.text.trim(),
        walkId: widget.walkId,
        entryPoint: widget.entryPoint,
      );
      unawaited(ref.read(analyticsServiceProvider).logSubmitComplete(
            entryPoint: widget.entryPoint ?? 'route_detail',
            submissionType: SubmissionType.fieldReport,
            theme: SubmissionConstants.activeTheme,
          ));
      if (!mounted) return;
      Navigator.of(context).pop();
      _notify('ご報告ありがとうございます。確認後に反映します。');
    } on SubmissionException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _notify(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        _notify('送信に失敗しました。もう一度お試しください。');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textPrimary = isDark
        ? WanWalkColors.textPrimaryDark
        : WanWalkColors.textPrimaryLight;
    final textSecondary = isDark
        ? WanWalkColors.textSecondaryDark
        : WanWalkColors.textSecondaryLight;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: WanWalkSpacing.lg,
          right: WanWalkSpacing.lg,
          top: WanWalkSpacing.lg,
          bottom: bottomInset + WanWalkSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.lg),
            Text(
              'この道の最新情報を報告',
              style: WanWalkTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '実際に歩いた方の情報をお待ちしています。',
              style: WanWalkTypography.bodySmall.copyWith(color: textSecondary),
            ),
            const SizedBox(height: WanWalkSpacing.lg),

            // カテゴリ
            Text(
              'カテゴリ',
              style: WanWalkTypography.bodySmall
                  .copyWith(fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.entries.map((entry) {
                final selected = _selectedCategory == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  selectedColor:
                      WanWalkColors.accentPrimary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: selected
                        ? WanWalkColors.accentPrimary
                        : textSecondary,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: selected
                        ? WanWalkColors.accentPrimary
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedCategory = entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: WanWalkSpacing.lg),

            // 本文
            Text(
              '報告内容',
              style: WanWalkTypography.bodySmall
                  .copyWith(fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: _fieldDecoration(
                isDark,
                hint: '例: 駐車場は現在500円に値上がりしています',
              ),
              style: WanWalkTypography.bodyMedium.copyWith(color: textPrimary),
            ),
            const SizedBox(height: WanWalkSpacing.sm),

            // 公開名
            Text(
              '掲載時のお名前（公開名）',
              style: WanWalkTypography.bodySmall
                  .copyWith(fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            TextField(
              controller: _publicNameController,
              maxLength: 30,
              onChanged: (_) => setState(() {}),
              decoration: _fieldDecoration(isDark, hint: 'ニックネームで構いません'),
              style: WanWalkTypography.bodyMedium.copyWith(color: textPrimary),
            ),
            const SizedBox(height: WanWalkSpacing.sm),

            // 同意
            _buildConsent(textSecondary),
            const SizedBox(height: WanWalkSpacing.md),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WanWalkColors.accentPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      WanWalkColors.accentPrimary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('報告する',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsent(Color textColor) {
    final linkStyle = WanWalkTypography.bodySmall.copyWith(
      color: WanWalkColors.accentPrimary,
      decoration: TextDecoration.underline,
    );
    final baseStyle = WanWalkTypography.bodySmall.copyWith(color: textColor);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Checkbox(
            value: _agreed,
            activeColor: WanWalkColors.accentPrimary,
            onChanged: (v) => setState(() => _agreed = v ?? false),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                style: baseStyle,
                children: [
                  const TextSpan(text: '私は18歳以上であり、'),
                  TextSpan(text: '利用規約', style: linkStyle, recognizer: _termsTap),
                  const TextSpan(text: 'および'),
                  TextSpan(
                      text: 'プライバシーポリシー',
                      style: linkStyle,
                      recognizer: _privacyTap),
                  const TextSpan(
                    text: 'に同意します。報告した内容を、WanWalk編集部が確認・編集のうえ掲載に用いることに同意します。',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(bool isDark, {required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: (isDark
                ? WanWalkColors.textSecondaryDark
                : WanWalkColors.textSecondaryLight)
            .withValues(alpha: 0.5),
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WanWalkColors.accentPrimary),
      ),
      contentPadding: const EdgeInsets.all(12),
    );
  }
}
