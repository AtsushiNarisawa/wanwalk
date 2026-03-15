import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../utils/logger.dart';

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
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

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
          .select('display_name, bio, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _nameController.text = response['display_name'] ?? '';
        _bioController.text = response['bio'] ?? '';
        _avatarUrl = response['avatar_url'];
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
    if (kDebugMode) {
      appLog('📝 ProfileEdit: Save button pressed');
    }
    
    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) {
        appLog('📝 ProfileEdit: Validation failed');
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (kDebugMode) {
        appLog('📝 ProfileEdit: userId=$userId');
      }
      if (userId == null) {
        if (kDebugMode) {
          appLog('📝 ProfileEdit: userId is null, aborting');
        }
        return;
      }

      if (kDebugMode) {
        appLog('📝 ProfileEdit: Upserting profile data...');
      }
      
      // プロフィールを作成または更新（UPSERT）
      final currentUser = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'email': currentUser?.email ?? '',
        'display_name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'avatar_url': _avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        appLog('📝 ProfileEdit: Profile saved successfully');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
        Navigator.of(context).pop(true); // 更新成功を通知
      }
    } catch (e) {
      if (kDebugMode) {
        appLog('📝 ProfileEdit: Error saving profile: $e');
      }
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

  /// アバター写真を変更
  Future<void> _changeAvatar() async {
    try {
      if (kDebugMode) {
        appLog('📸 アバター変更開始...');
      }
      
      // 画像ソースを選択
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('アバター画像を選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで撮影'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選択'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // 画像を選択
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) {
        if (kDebugMode) {
          appLog('❌ 画像選択がキャンセルされました');
        }
        return;
      }

      setState(() => _isUploadingAvatar = true);

      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        if (kDebugMode) {
          appLog('❌ userId is null');
        }
        return;
      }

      if (kDebugMode) {
        appLog('📤 アバターをアップロード中...');
      }

      // Supabase Storageにアップロード
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$fileName';

      await Supabase.instance.client.storage
          .from('profile-avatars')
          .upload(filePath, File(image.path));

      // 公開URLを取得
      final publicUrl = Supabase.instance.client.storage
          .from('profile-avatars')
          .getPublicUrl(filePath);

      if (kDebugMode) {
        appLog('✅ アバターアップロード成功: $publicUrl');
      }

      setState(() {
        _avatarUrl = publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アバター画像を変更しました')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        appLog('❌ アバター変更エラー: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アバター変更に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
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
          'プロフィール編集',
          style: WanWalkTypography.heading2,
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
              child: const Text(
                '保存',
                style: TextStyle(
                  color: WanWalkColors.accent,
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
                padding: const EdgeInsets.all(WanWalkSpacing.medium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // アバター編集（Phase 6実装済み）
                      Center(
                        child: Stack(
                          children: [
                            _isUploadingAvatar
                                ? const CircleAvatar(
                                    radius: 60,
                                    child: CircularProgressIndicator(),
                                  )
                                : _avatarUrl != null
                                    ? CircleAvatar(
                                        radius: 60,
                                        backgroundImage: NetworkImage(_avatarUrl!),
                                      )
                                    : CircleAvatar(
                                        radius: 60,
                                        backgroundColor: WanWalkColors.accent.withOpacity(0.2),
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: WanWalkColors.accent,
                                        ),
                                      ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _isUploadingAvatar ? null : _changeAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: WanWalkColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: WanWalkSpacing.large),
                      
                      // 名前入力
                      const Text(
                        '名前',
                        style: WanWalkTypography.heading3,
                      ),
                      const SizedBox(height: WanWalkSpacing.small),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: '名前を入力してください',
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
                            return '名前を入力してください';
                          }
                          if (value.trim().length > 50) {
                            return '名前は50文字以内で入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: WanWalkSpacing.large),
                      
                      // 自己紹介入力
                      const Text(
                        '自己紹介',
                        style: WanWalkTypography.heading3,
                      ),
                      const SizedBox(height: WanWalkSpacing.small),
                      TextFormField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          hintText: '愛犬と一緒に散歩を楽しんでいます！',
                          filled: true,
                          fillColor: isDark ? WanWalkColors.cardDark : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(WanWalkSpacing.medium),
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
                      const SizedBox(height: WanWalkSpacing.large),
                      
                      // 注意事項
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
                                'プロフィール情報は他のユーザーに公開されます',
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
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
