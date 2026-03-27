import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../models/route_pin.dart';
import '../../providers/route_pin_provider.dart';
import '../../providers/recent_pins_provider.dart';

/// ピン作成画面（写真ファースト）
/// 「作業」ではなく「瞬間のシェア」体験を提供
class PinCreateScreen extends ConsumerStatefulWidget {
  final String routeId;
  final LatLng location;
  final String? areaName;
  final bool fromWalking; // 散歩中のFABから開いたかどうか

  const PinCreateScreen({
    super.key,
    required this.routeId,
    required this.location,
    this.areaName,
    this.fromWalking = false,
  });

  @override
  ConsumerState<PinCreateScreen> createState() => _PinCreateScreenState();
}

class _PinCreateScreenState extends ConsumerState<PinCreateScreen> {
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();

  PinType _selectedType = PinType.scenery;
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  bool _hasOpenedCamera = false;

  final ImagePicker _imagePicker = ImagePicker();

  // 種類ごとの設定
  static const _pinTypeConfig = {
    PinType.scenery: _PinTypeInfo('🏔️', '景色', 'どんな景色が見えましたか？'),
    PinType.shop: _PinTypeInfo('☕', 'カフェ・お店', '犬OKでしたか？おすすめは？'),
    PinType.encounter: _PinTypeInfo('🐕', 'わんこの出会い', 'どんなわんちゃんでしたか？'),
    PinType.other: _PinTypeInfo('📸', '発見', '何を見つけましたか？'),
  };

  // facilityはotherに統合
  static const _displayTypes = [
    PinType.scenery,
    PinType.shop,
    PinType.encounter,
    PinType.other,
  ];

  @override
  void initState() {
    super.initState();
    // タイトルの初期値を自動生成
    _updateAutoTitle();
    // 散歩中のFABからなら即カメラ起動
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasOpenedCamera) {
        _hasOpenedCamera = true;
        if (widget.fromWalking) {
          _takePhoto();
        } else {
          _showPhotoChoice();
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _updateAutoTitle() {
    final area = widget.areaName ?? '';
    final config = _pinTypeConfig[_selectedType];
    if (config != null && area.isNotEmpty) {
      _titleController.text = '$areaの${config.label}';
    } else if (config != null) {
      _titleController.text = config.label;
    }
  }

  void _showPhotoChoice() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920, maxHeight: 1920, imageQuality: 85,
      );
      if (images.length + _selectedImages.length > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真は最大5枚まで'), backgroundColor: Colors.orange),
          );
        }
        return;
      }
      setState(() { _selectedImages.addAll(images); });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('写真の選択に失敗: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera, maxWidth: 1920, maxHeight: 1920, imageQuality: 85,
      );
      if (image == null) return;
      if (_selectedImages.length >= 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真は最大5枚まで'), backgroundColor: Colors.orange),
          );
        }
        return;
      }
      setState(() { _selectedImages.add(image); });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('撮影に失敗: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() { _selectedImages.removeAt(index); });
  }

  Future<void> _submitPin() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です'), backgroundColor: Colors.red),
      );
      return;
    }

    // タイトルが空なら自動生成値を使う
    if (_titleController.text.trim().isEmpty) {
      _updateAutoTitle();
    }

    setState(() { _isSubmitting = true; });

    try {
      final createPinUseCase = ref.read(createPinProvider);
      final pin = await createPinUseCase.createPin(
        routeId: widget.routeId,
        userId: userId,
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        pinType: _selectedType,
        title: _titleController.text.trim(),
        comment: _commentController.text.trim().isEmpty
            ? ''
            : _commentController.text.trim(),
        photoFilePaths: _selectedImages.map((img) => img.path).toList(),
      );

      if (mounted) {
        ref.invalidate(recentPinsProvider);

        // 初回投稿かチェック
        final pinCount = await _getUserPinCount(userId);

        if (pinCount <= 1) {
          // 初めてのピン投稿 → 祝福ダイアログ
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎉', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text(
                    '初めてのピン投稿！',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'あなたの発見が、次の散歩を探す\n誰かの参考になります。',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ピンを投稿しました！'), backgroundColor: Colors.green),
          );
        }

        if (mounted) Navigator.of(context).pop(pin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿に失敗: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  Future<int> _getUserPinCount(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('route_pins')
          .select('id')
          .eq('user_id', userId)
          .eq('is_official', false);
      return (response as List).length;
    } catch (_) {
      return 999; // エラー時は祝福を出さない
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
      appBar: AppBar(
        title: const Text('ピンを投稿'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isSubmitting)
            TextButton(
              onPressed: _submitPin,
              child: Text(
                '投稿',
                style: WanWalkTypography.bodyLarge.copyWith(
                  color: WanWalkColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ① 写真（大きく表示・画面上部）
                  _buildPhotoSection(isDark),

                  Padding(
                    padding: const EdgeInsets.all(WanWalkSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ② 種類選択（アイコン4個）
                        _buildPinTypeSelector(isDark),

                        const SizedBox(height: WanWalkSpacing.lg),

                        // ③ タイトル（自動生成・編集可）
                        _buildTitleField(isDark),

                        const SizedBox(height: WanWalkSpacing.md),

                        // ④ ひとこと（任意）
                        _buildCommentField(isDark),

                        const SizedBox(height: WanWalkSpacing.xl),

                        // ⑤ 投稿ボタン
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 写真セクション（画面上部に大きく）
  Widget _buildPhotoSection(bool isDark) {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap: _showPhotoChoice,
        child: Container(
          height: 250,
          width: double.infinity,
          color: isDark ? WanWalkColors.cardDark : const Color(0xFFF5F5F5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 56,
                color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textTertiaryLight,
              ),
              const SizedBox(height: WanWalkSpacing.md),
              Text(
                '写真を追加',
                style: WanWalkTypography.bodyLarge.copyWith(
                  color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'タップして撮影 or ギャラリーから選択',
                style: WanWalkTypography.bodySmall.copyWith(
                  color: isDark ? WanWalkColors.textTertiaryDark : WanWalkColors.textTertiaryLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 写真あり → 大きく表示
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(_selectedImages[index].path),
                    fit: BoxFit.cover,
                  ),
                  // 削除ボタン
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // 写真追加ボタン
          if (_selectedImages.length < 5)
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: _showPhotoChoice,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_photo_alternate, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_selectedImages.length}/5',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // ページインジケーター
          if (_selectedImages.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _selectedImages.length,
                  (i) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: i == 0 ? 1.0 : 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 種類選択（アイコン4個を横並び）
  Widget _buildPinTypeSelector(bool isDark) {
    return Row(
      children: _displayTypes.map((type) {
        final config = _pinTypeConfig[type]!;
        final isSelected = _selectedType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = type;
                _updateAutoTitle();
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? WanWalkColors.accent.withValues(alpha: 0.1)
                    : (isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? WanWalkColors.accent
                      : (isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(config.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    config.label,
                    style: WanWalkTypography.bodySmall.copyWith(
                      color: isSelected
                          ? WanWalkColors.accent
                          : (isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight),
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// タイトル（自動生成・編集可・控えめ）
  Widget _buildTitleField(bool isDark) {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        hintText: 'タイトル（自動入力済み・編集可）',
        hintStyle: WanWalkTypography.bodyMedium.copyWith(
          color: isDark ? WanWalkColors.textTertiaryDark : WanWalkColors.textTertiaryLight,
        ),
        filled: true,
        fillColor: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        counterText: '',
      ),
      style: WanWalkTypography.bodyMedium.copyWith(
        color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
      ),
      maxLength: 50,
    );
  }

  /// ひとこと（任意）
  Widget _buildCommentField(bool isDark) {
    final config = _pinTypeConfig[_selectedType];
    return TextField(
      controller: _commentController,
      decoration: InputDecoration(
        hintText: config?.hint ?? 'ひとこと（任意）',
        hintStyle: WanWalkTypography.bodySmall.copyWith(
          color: isDark ? WanWalkColors.textTertiaryDark : WanWalkColors.textTertiaryLight,
        ),
        filled: true,
        fillColor: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        counterText: '',
      ),
      style: WanWalkTypography.bodySmall.copyWith(
        color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
      ),
      maxLines: 3,
      maxLength: 500,
    );
  }

  /// 投稿ボタン
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitPin,
        style: ElevatedButton.styleFrom(
          backgroundColor: WanWalkColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
          shadowColor: WanWalkColors.accent.withValues(alpha: 0.3),
        ),
        child: Text(
          'ピンを投稿',
          style: WanWalkTypography.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PinTypeInfo {
  final String icon;
  final String label;
  final String hint;

  const _PinTypeInfo(this.icon, this.label, this.hint);
}
