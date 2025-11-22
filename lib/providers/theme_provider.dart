import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// テーマモードの状態を管理するProvider
/// ChangeNotifierを使用してProviderパッケージと連携
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  static const String _key = 'theme_mode';

  ThemeProvider() {
    _loadThemeMode();
  }

  /// 現在のテーマモード
  ThemeMode get themeMode => _themeMode;

  /// 保存されたテーマモードを読み込む
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_key);
      
      if (themeModeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('テーマモード読み込みエラー: $e');
    }
  }

  /// テーマモードを変更して保存
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.toString());
    } catch (e) {
      debugPrint('テーマモード保存エラー: $e');
    }
  }

  /// ライトモードに切り替え
  Future<void> setLight() => setThemeMode(ThemeMode.light);

  /// ダークモードに切り替え
  Future<void> setDark() => setThemeMode(ThemeMode.dark);

  /// システム設定に従う
  Future<void> setSystem() => setThemeMode(ThemeMode.system);
}
