import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/dog_model.dart';
import '../../providers/dog_provider.dart';
import 'vaccination_info_widget.dart';

/// 愛犬編集画面
class DogEditScreen extends ConsumerStatefulWidget {
  final String userId;
  final DogModel? dog; // nullの場合は新規作成

  const DogEditScreen({
    super.key,
    required this.userId,
    this.dog,
  });

  @override
  ConsumerState<DogEditScreen> createState() => _DogEditScreenState();
}

class _DogEditScreenState extends ConsumerState<DogEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  
  DateTime? _birthDate;
  DogSize? _selectedSize;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _localPhotoPath;

  bool get isEditMode => widget.dog != null;

  @override
  void initState() {
    super.initState();
    if (widget.dog != null) {
      _nameController.text = widget.dog!.name;
      _breedController.text = widget.dog!.breed ?? '';
      _weightController.text = widget.dog!.weight?.toString() ?? '';
      _birthDate = widget.dog!.birthDate;
      _selectedSize = widget.dog!.size;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _saveDog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dog = DogModel(
        id: widget.dog?.id,
        userId: widget.userId,
        name: _nameController.text.trim(),
        breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
        size: _selectedSize,
        birthDate: _birthDate,
        weight: _weightController.text.trim().isEmpty
            ? null
            : double.tryParse(_weightController.text.trim()),
        photoUrl: widget.dog?.photoUrl,
      );

      if (isEditMode) {
        await ref.read(dogProvider.notifier).updateDog(
          widget.dog!.id!,
          {
            'name': dog.name,
            'breed': dog.breed,
            'size': dog.size?.name,
            'birth_date': dog.birthDate?.toIso8601String(),
            'weight': dog.weight,
          },
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('愛犬情報を更新しました')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // 新規登録
        final newDog = await ref.read(dogProvider.notifier).createDog(dog);
        
        if (mounted && newDog != null) {
          // まず現在の画面を閉じる
          Navigator.of(context).pop(true);
          
          // 少し待ってから編集画面を開く
          await Future.delayed(const Duration(milliseconds: 100));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('愛犬を登録しました。ワクチン情報を入力してください。')),
            );
            // 編集画面へ遷移してワクチン情報を入力できるようにする
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DogEditScreen(
                  userId: widget.userId,
                  dog: newDog,
                ),
              ),
            );
          }
        } else if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _changePhoto() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            if (widget.dog?.photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('写真を削除', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'delete') {
      setState(() {
        _localPhotoPath = null;
      });
      if (isEditMode && widget.dog?.photoUrl != null) {
        try {
          await ref.read(dogProvider.notifier).updateDog(
            widget.dog!.id!,
            {'photo_url': null},
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('写真を削除しました')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('削除に失敗しました: $e')),
            );
          }
        }
      }
      return;
    }

    setState(() => _isUploadingPhoto = true);

    try {
      final photoFile = await ref.read(dogProvider.notifier).pickImageFromGallery();
      
      if (photoFile != null) {
        setState(() => _localPhotoPath = photoFile.path);

        if (isEditMode && widget.dog?.id != null) {
          final photoUrl = await ref.read(dogProvider.notifier).uploadDogPhoto(
            file: photoFile,
            userId: widget.userId,
            dogId: widget.dog!.id!,
          );

          await ref.read(dogProvider.notifier).updateDog(
            widget.dog!.id!,
            {'photo_url': photoUrl},
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('写真を更新しました')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('写真のアップロードに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  ImageProvider? _getAvatarImage() {
    if (_localPhotoPath != null) {
      return FileImage(File(_localPhotoPath!));
    }
    if (widget.dog?.photoUrl != null) {
      return NetworkImage(widget.dog!.photoUrl!);
    }
    return null;
  }

  Future<void> _deleteDog() async {
    if (!isEditMode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('愛犬の削除'),
        content: Text(
          '${widget.dog!.name}を削除してもよろしいですか？\n\nこの操作は取り消すことができません。',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(dogProvider.notifier).deleteDog(widget.dog!.id!, widget.userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('愛犬を削除しました')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
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
          isEditMode ? '愛犬情報の編集' : '愛犬の登録',
          style: WanMapTypography.heading2,
        ),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 26),
              tooltip: '愛犬を削除',
              onPressed: _deleteDog,
            ),
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
              onPressed: _saveDog,
              child: const Text(
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(WanMapSpacing.medium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 写真
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingPhoto ? null : _changePhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: WanMapColors.accent.withOpacity(0.2),
                          backgroundImage: _getAvatarImage(),
                          child: _getAvatarImage() == null
                              ? const Icon(
                                  Icons.pets,
                                  size: 60,
                                  color: WanMapColors.accent,
                                )
                              : null,
                        ),
                        if (_isUploadingPhoto)
                          Positioned.fill(
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.black.withOpacity(0.5),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
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
                ),
                const SizedBox(height: WanMapSpacing.large),
                
                // 名前入力
                const Text('名前', style: WanMapTypography.heading3),
                const SizedBox(height: WanMapSpacing.small),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: '例：ポチ',
                    filled: true,
                    fillColor: isDark ? WanMapColors.cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '名前を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: WanMapSpacing.medium),
                
                // 犬種入力
                const Text('犬種', style: WanMapTypography.heading3),
                const SizedBox(height: WanMapSpacing.small),
                TextFormField(
                  controller: _breedController,
                  decoration: InputDecoration(
                    hintText: '例：柴犬',
                    filled: true,
                    fillColor: isDark ? WanMapColors.cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: WanMapSpacing.medium),
                
                // サイズ選択
                const Text('サイズ', style: WanMapTypography.heading3),
                const SizedBox(height: WanMapSpacing.small),
                Wrap(
                  spacing: 8,
                  children: DogSize.values.map((size) {
                    final isSelected = _selectedSize == size;
                    return ChoiceChip(
                      label: Text(
                        size.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedSize = selected ? size : null);
                      },
                      selectedColor: WanMapColors.accent,
                      backgroundColor: isDark ? WanMapColors.cardDark : Colors.grey[200],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    );
                  }).toList(),
                ),
                const SizedBox(height: WanMapSpacing.medium),
                
                // 誕生日選択
                const Text('誕生日', style: WanMapTypography.heading3),
                const SizedBox(height: WanMapSpacing.small),
                InkWell(
                  onTap: _selectBirthDate,
                  child: Container(
                    padding: const EdgeInsets.all(WanMapSpacing.medium),
                    decoration: BoxDecoration(
                      color: isDark ? WanMapColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: WanMapColors.accent,
                        ),
                        const SizedBox(width: WanMapSpacing.small),
                        Text(
                          _birthDate == null
                              ? '誕生日を選択'
                              : '${_birthDate!.year}年${_birthDate!.month}月${_birthDate!.day}日',
                          style: WanMapTypography.body,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: WanMapSpacing.medium),
                
                // 体重入力
                const Text('体重（kg）', style: WanMapTypography.heading3),
                const SizedBox(height: WanMapSpacing.small),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '例：5.5',
                    filled: true,
                    fillColor: isDark ? WanMapColors.cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixText: 'kg',
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final weight = double.tryParse(value.trim());
                      if (weight == null || weight <= 0) {
                        return '正しい体重を入力してください';
                      }
                    }
                    return null;
                  },
                ),
                
                // 予防接種情報セクション（編集モードのみ）
                if (isEditMode && widget.dog != null) ...[
                  const SizedBox(height: WanMapSpacing.xl),
                  VaccinationInfoWidget(
                    dog: widget.dog!,
                    userId: widget.userId,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
