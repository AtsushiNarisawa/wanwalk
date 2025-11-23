import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/auth_provider.dart';

/// プロフィール編集画面
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('display_name, bio')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _nameController.text = response['display_name'] ?? '';
        _bioController.text = response['bio'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('プロフィールの読み込みに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'display_name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
        Navigator.of(context).pop(true); // 更新成功を通知
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
        title: Text(
          'プロフィール編集',
          style: WanMapTypography.heading2,
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                '保存',
                style: TextStyle(
                  color: WanMapColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(WanMapSpacing.medium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // アバター編集（将来実装）
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: WanMapColors.accent.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: WanMapColors.accent,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: WanMapColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: WanMapSpacing.large),
                      
                      // 名前入力
                      Text(
                        '名前',
                        style: WanMapTypography.heading3,
                      ),
                      const SizedBox(height: WanMapSpacing.small),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: '名前を入力してください',
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
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '名前を入力してください';
                          }
                          if (value.trim().length > 50) {
                            return '名前は50文字以内で入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: WanMapSpacing.large),
                      
                      // 自己紹介入力
                      Text(
                        '自己紹介',
                        style: WanMapTypography.heading3,
                      ),
                      const SizedBox(height: WanMapSpacing.small),
                      TextFormField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          hintText: '愛犬と一緒に散歩を楽しんでいます！',
                          filled: true,
                          fillColor: isDark ? WanMapColors.cardDark : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(WanMapSpacing.medium),
                        ),
                        maxLines: 5,
                        maxLength: 200,
                        validator: (value) {
                          if (value != null && value.trim().length > 200) {
                            return '自己紹介は200文字以内で入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: WanMapSpacing.large),
                      
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
                                'プロフィール情報は他のユーザーに公開されます',
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
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
