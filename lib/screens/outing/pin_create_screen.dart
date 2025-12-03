import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/route_pin.dart';
import '../../providers/route_pin_provider.dart';

/// ピン作成画面
/// ユーザーが公式ルート上に体験・発見を投稿
class PinCreateScreen extends ConsumerStatefulWidget {
  final String routeId;
  final LatLng location;

  const PinCreateScreen({
    super.key,
    required this.routeId,
    required this.location,
  });

  @override
  ConsumerState<PinCreateScreen> createState() => _PinCreateScreenState();
}

class _PinCreateScreenState extends ConsumerState<PinCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  
  PinType _selectedType = PinType.scenery;
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  /// 写真を選択
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.length + _selectedImages.length > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('写真は最大5枚まで選択できます'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImages.addAll(images);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('写真の選択に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// カメラで写真を撮影
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (_selectedImages.length >= 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('写真は最大5枚まで選択できます'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImages.add(image);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('写真の撮影に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 写真を削除
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// ピンを投稿
  Future<void> _submitPin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログインが必要です'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ピンを作成
      final createPinUseCase = ref.read(createPinProvider);
      
      final pin = await createPinUseCase.createPin(
        routeId: widget.routeId,
        userId: userId,
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        pinType: _selectedType,
        title: _titleController.text.trim(),
        comment: _commentController.text.trim(),
        photoFilePaths: _selectedImages.map((img) => img.path).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ピンを投稿しました！'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(pin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('投稿に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
        title: const Text('ピンを投稿'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isSubmitting)
            TextButton(
              onPressed: _submitPin,
              child: Text(
                '投稿',
                style: WanMapTypography.bodyLarge.copyWith(
                  color: WanMapColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(WanMapSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ピン種類選択
                    _buildPinTypeSelector(isDark),

                    const SizedBox(height: WanMapSpacing.xl),

                    // タイトル入力
                    _buildTitleField(isDark),

                    const SizedBox(height: WanMapSpacing.lg),

                    // コメント入力
                    _buildCommentField(isDark),

                    const SizedBox(height: WanMapSpacing.xl),

                    // 写真選択
                    _buildPhotoSection(isDark),

                    const SizedBox(height: WanMapSpacing.xl),

                    // 位置情報表示
                    _buildLocationInfo(isDark),

                    const SizedBox(height: WanMapSpacing.xxxl),

                    // 投稿ボタン
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  /// ピン種類選択
  Widget _buildPinTypeSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ピンの種類',
          style: WanMapTypography.bodyLarge.copyWith(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanMapSpacing.md),
        Wrap(
          spacing: WanMapSpacing.sm,
          runSpacing: WanMapSpacing.sm,
          children: PinType.values.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WanMapSpacing.md,
                  vertical: WanMapSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? WanMapColors.accent
                      : (isDark ? WanMapColors.cardDark : WanMapColors.cardLight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? WanMapColors.accent
                        : (isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight),
                    width: 2,
                  ),
                ),
                child: Text(
                  type.label,
                  style: WanMapTypography.bodyMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? WanMapColors.textPrimaryDark
                            : WanMapColors.textPrimaryLight),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// タイトル入力フィールド
  Widget _buildTitleField(bool isDark) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'タイトル',
        hintText: '例：絶景の富士山ビュー',
        filled: true,
        fillColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: WanMapTypography.bodyLarge.copyWith(
        color: isDark
            ? WanMapColors.textPrimaryDark
            : WanMapColors.textPrimaryLight,
      ),
      maxLength: 50,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'タイトルを入力してください';
        }
        return null;
      },
    );
  }

  /// コメント入力フィールド
  Widget _buildCommentField(bool isDark) {
    return TextFormField(
      controller: _commentController,
      decoration: InputDecoration(
        labelText: 'コメント',
        hintText: 'この場所について教えてください',
        filled: true,
        fillColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: WanMapTypography.bodyMedium.copyWith(
        color: isDark
            ? WanMapColors.textPrimaryDark
            : WanMapColors.textPrimaryLight,
      ),
      maxLines: 5,
      maxLength: 500,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'コメントを入力してください';
        }
        return null;
      },
    );
  }

  /// 写真選択セクション
  Widget _buildPhotoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '写真（最大5枚）',
              style: WanMapTypography.bodyLarge.copyWith(
                color: isDark
                    ? WanMapColors.textPrimaryDark
                    : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: WanMapSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectedImages.length < 5 ? _takePhoto : null,
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: const Text('カメラ'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: _selectedImages.length < 5 
                            ? WanMapColors.accent 
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: WanMapSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectedImages.length < 5 ? _pickImages : null,
                    icon: const Icon(Icons.photo_library, size: 20),
                    label: const Text('ギャラリー'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: _selectedImages.length < 5 
                            ? WanMapColors.accent 
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: WanMapSpacing.md),
        if (_selectedImages.isEmpty)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: isDark
                        ? WanMapColors.textSecondaryDark
                        : WanMapColors.textSecondaryLight,
                  ),
                  const SizedBox(height: WanMapSpacing.sm),
                  Text(
                    '写真を追加',
                    style: WanMapTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanMapColors.textSecondaryDark
                          : WanMapColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _selectedImages.length - 1
                        ? WanMapSpacing.sm
                        : 0,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImages[index].path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// 位置情報表示
  Widget _buildLocationInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: WanMapColors.accent,
            size: 24,
          ),
          const SizedBox(width: WanMapSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '投稿位置',
                  style: WanMapTypography.caption.copyWith(
                    color: isDark
                        ? WanMapColors.textSecondaryDark
                        : WanMapColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '緯度: ${widget.location.latitude.toStringAsFixed(6)}\n経度: ${widget.location.longitude.toStringAsFixed(6)}',
                  style: WanMapTypography.bodySmall.copyWith(
                    color: isDark
                        ? WanMapColors.textPrimaryDark
                        : WanMapColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 投稿ボタン
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitPin,
        style: ElevatedButton.styleFrom(
          backgroundColor: WanMapColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: WanMapColors.accent.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send, size: 24),
            const SizedBox(width: WanMapSpacing.sm),
            Text(
              'ピンを投稿',
              style: WanMapTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
