import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';

/// お問い合わせフォーム画面
class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedCategory = 'general';
  bool _isLoading = false;

  final Map<String, String> _categories = {
    'general': '一般的な質問',
    'bug': 'バグ報告',
    'feature': '機能要望',
    'account': 'アカウント関連',
    'other': 'その他',
  };

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// お問い合わせを送信
  Future<void> _submitContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('ログインしていません');
      }

      // お問い合わせ内容をSupabaseに保存
      // 注: contact_messagesテーブルが必要
      await Supabase.instance.client.from('contact_messages').insert({
        'user_id': user.id,
        'email': user.email,
        'category': _selectedCategory,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: WanWalkSpacing.small),
                Text('送信完了'),
              ],
            ),
            content: const Text(
              'お問い合わせを受け付けました。\n\n通常、2〜3営業日以内にご登録のメールアドレス宛に返信いたします。',
              style: WanWalkTypography.body,
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
                    color: WanWalkColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信に失敗しました: $e'),
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
          ? WanWalkColors.backgroundDark
          : WanWalkColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanWalkColors.cardDark : Colors.white,
        elevation: 0,
        title: const Text(
          'お問い合わせ',
          style: WanWalkTypography.heading2,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(WanWalkSpacing.medium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 案内メッセージ
                Container(
                  padding: const EdgeInsets.all(WanWalkSpacing.medium),
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
                      const SizedBox(width: WanWalkSpacing.small),
                      Expanded(
                        child: Text(
                          'お問い合わせ内容を確認後、2〜3営業日以内にご返信いたします。',
                          style: WanWalkTypography.caption.copyWith(
                            color: isDark
                                ? Colors.blue.shade200
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WanWalkSpacing.large),

                // カテゴリ選択
                const Text(
                  'お問い合わせ種類',
                  style: WanWalkTypography.heading3,
                ),
                const SizedBox(height: WanWalkSpacing.small),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.medium),
                  decoration: BoxDecoration(
                    color: isDark ? WanWalkColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: isDark ? WanWalkColors.cardDark : Colors.white,
                      items: _categories.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style: WanWalkTypography.body,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: WanWalkSpacing.large),

                // 件名
                const Text(
                  '件名',
                  style: WanWalkTypography.heading3,
                ),
                const SizedBox(height: WanWalkSpacing.small),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: '件名を入力してください',
                    filled: true,
                    fillColor: isDark ? WanWalkColors.cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: WanWalkSpacing.medium,
                      vertical: WanWalkSpacing.small,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '件名を入力してください';
                    }
                    if (value.trim().length > 100) {
                      return '件名は100文字以内で入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: WanWalkSpacing.large),

                // お問い合わせ内容
                const Text(
                  'お問い合わせ内容',
                  style: WanWalkTypography.heading3,
                ),
                const SizedBox(height: WanWalkSpacing.small),
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'お問い合わせ内容を詳しく入力してください',
                    filled: true,
                    fillColor: isDark ? WanWalkColors.cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(WanWalkSpacing.medium),
                  ),
                  maxLines: 10,
                  maxLength: 1000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'お問い合わせ内容を入力してください';
                    }
                    if (value.trim().length < 10) {
                      return '10文字以上入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: WanWalkSpacing.large),

                // 送信ボタン
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WanWalkColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: WanWalkSpacing.medium,
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
                          '送信する',
                          style: WanWalkTypography.heading3.copyWith(
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
