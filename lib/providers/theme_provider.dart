import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// テーマモードの状態を管理するRiverpod StateNotifier
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _key = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// 保存されたテーマモードを読み込む
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_key);

      if (themeModeString != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      debugPrint('テーマモード読み込みエラー: $e');
    }
  }

  /// テーマモードを変更して保存
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;

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

/// ThemeProvider（Riverpod版）
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
