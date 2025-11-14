#!/usr/bin/env python3
"""
コンパイルエラーを修正するスクリプト
"""

import os
import re

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))

def fix_route_detail_screen():
    """route_detail_screen.dart のエラーを修正"""
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'screens', 'routes', 'route_detail_screen.dart')
    
    if not os.path.exists(filepath):
        print(f"⚠️  File not found: {filepath}")
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # CommentModel を import に追加
    if "import '../../../models/comment_model.dart';" not in content:
        # import セクションを探して追加
        import_pattern = r"(import '[^']+';[\s\n]+)"
        imports = re.findall(import_pattern, content)
        if imports:
            last_import = imports[-1]
            content = content.replace(
                last_import,
                last_import + "import '../../../models/comment_model.dart';\n"
            )
    
    # _loadComments メソッドを追加（まだ存在しない場合）
    if 'Future<void> _loadComments()' not in content:
        load_comments_method = '''
  Future<void> _loadComments() async {
    try {
      final comments = await supabase
          .from('comments')
          .select('*, profiles(*)')
          .eq('route_id', widget.route.id)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _comments = (comments as List)
              .map((json) => CommentModel.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
    }
  }
'''
        # initState の後に追加
        content = re.sub(
            r'(\n\s+super\.initState\(\);\s*\n\s+\})',
            r'\1' + load_comments_method,
            content
        )
    
    # _postComment メソッドを追加（まだ存在しない場合）
    if 'Future<void> _postComment()' not in content:
        post_comment_method = '''
  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      await supabase.from('comments').insert({
        'route_id': widget.route.id,
        'user_id': user.id,
        'content': _commentController.text.trim(),
      });
      
      _commentController.clear();
      await _loadComments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('コメントを投稿しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }
'''
        content = re.sub(
            r'(\n\s+Future<void> _loadComments\(\).*?\n\s+\})',
            r'\1' + post_comment_method,
            content,
            flags=re.DOTALL
        )
    
    # _deleteComment メソッドを追加（まだ存在しない場合）
    if 'Future<void> _deleteComment(' not in content:
        delete_comment_method = '''
  Future<void> _deleteComment(String commentId) async {
    try {
      await supabase.from('comments').delete().eq('id', commentId);
      await _loadComments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('コメントを削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }
'''
        content = re.sub(
            r'(\n\s+Future<void> _postComment\(\).*?\n\s+\})',
            r'\1' + delete_comment_method,
            content,
            flags=re.DOTALL
        )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Fixed: {filepath}")

def fix_public_routes_screen():
    """public_routes_screen.dart のエラーを修正"""
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'screens', 'routes', 'public_routes_screen.dart')
    
    if not os.path.exists(filepath):
        print(f"⚠️  File not found: {filepath}")
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # filteredRoutes getter を追加（まだ存在しない場合）
    if 'List<RouteModel> get filteredRoutes' not in content:
        filtered_routes_getter = '''
  List<RouteModel> get filteredRoutes {
    if (_searchQuery.isEmpty) {
      return _routes;
    }
    return _routes.where((route) {
      return route.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (route.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }
'''
        # State クラスのフィールド定義の後に追加
        content = re.sub(
            r'(class _PublicRoutesScreenState.*?\{[\s\n]+.*?List<RouteModel> _routes = \[\];)',
            r'\1' + filtered_routes_getter,
            content,
            flags=re.DOTALL
        )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Fixed: {filepath}")

def fix_favorites_screen():
    """favorites_screen.dart のエラーを修正"""
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'screens', 'routes', 'favorites_screen.dart')
    
    if not os.path.exists(filepath):
        print(f"⚠️  File not found: {filepath}")
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # filteredRoutes getter を追加（まだ存在しない場合）
    if 'List<RouteModel> get filteredRoutes' not in content:
        filtered_routes_getter = '''
  List<RouteModel> get filteredRoutes {
    if (_searchQuery.isEmpty) {
      return _routes;
    }
    return _routes.where((route) {
      return route.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (route.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }
'''
        # State クラスのフィールド定義の後に追加
        content = re.sub(
            r'(class _FavoritesScreenState.*?\{[\s\n]+.*?List<RouteModel> _routes = \[\];)',
            r'\1' + filtered_routes_getter,
            content,
            flags=re.DOTALL
        )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Fixed: {filepath}")

def main():
    print("🔧 Fixing compile errors...")
    print("=" * 60)
    
    fix_route_detail_screen()
    fix_public_routes_screen()
    fix_favorites_screen()
    
    print("\n✅ All fixes applied!")
    print("\n次のコマンドを実行してください:")
    print("  flutter run -d macos")

if __name__ == '__main__':
    main()
