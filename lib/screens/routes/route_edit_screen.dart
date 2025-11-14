import 'package:flutter/material.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';

/// ルート編集画面
class RouteEditScreen extends StatefulWidget {
  final RouteModel route;

  const RouteEditScreen({
    super.key,
    required this.route,
  });

  @override
  State<RouteEditScreen> createState() => _RouteEditScreenState();
}

class _RouteEditScreenState extends State<RouteEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isPublic;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.route.title);
    _descriptionController = TextEditingController(text: widget.route.description ?? '');
    _isPublic = widget.route.isPublic;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // バリデーション
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('タイトルを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await RouteService().updateRoute(
        routeId: widget.route.id!,
        userId: widget.route.userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        isPublic: _isPublic,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ルートを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // 更新成功を通知
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('更新に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ルート編集'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: '保存',
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル入力
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                hintText: 'ルートのタイトルを入力',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 100,
              enabled: !_isSaving,
            ),
            
            const SizedBox(height: 16),
            
            // 説明入力
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明（任意）',
                hintText: 'ルートの説明を入力',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 500,
              enabled: !_isSaving,
            ),
            
            const SizedBox(height: 24),
            
            // 公開設定
            Card(
              child: SwitchListTile(
                title: const Text(
                  '公開設定',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _isPublic 
                      ? '他のユーザーがこのルートを閲覧できます' 
                      : 'このルートは非公開です',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                value: _isPublic,
                onChanged: _isSaving ? null : (value) {
                  setState(() => _isPublic = value);
                },
                secondary: Icon(
                  _isPublic ? Icons.public : Icons.lock,
                  color: _isPublic ? Colors.green : Colors.grey,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 保存ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? '保存中...' : '変更を保存',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
