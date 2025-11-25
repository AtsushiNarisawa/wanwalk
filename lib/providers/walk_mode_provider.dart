import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/walk_mode.dart';

/// 現在の散歩モードを管理するProvider
/// Daily（日常の散歩）とOuting（おでかけ散歩）を切り替える
class WalkModeNotifier extends StateNotifier<WalkMode> {
  WalkModeNotifier() : super(WalkMode.daily) {
    _loadMode();
  }

  static const String _storageKey = 'walk_mode';

  /// SharedPreferencesから前回のモードを読み込み
  Future<void> _loadMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeValue = prefs.getString(_storageKey);
      if (modeValue != null) {
        state = WalkMode.fromString(modeValue);
      }
    } catch (e) {
      // エラーが発生してもデフォルト値（daily）を維持
      if (kDebugMode) {
        print('Failed to load walk mode: $e');
      }
    }
  }

  /// モードを変更してSharedPreferencesに保存
  Future<void> setMode(WalkMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, mode.value);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save walk mode: $e');
      }
    }
  }

  /// Dailyモードに切り替え
  Future<void> switchToDaily() => setMode(WalkMode.daily);

  /// Outingモードに切り替え
  Future<void> switchToOuting() => setMode(WalkMode.outing);

  /// モードをトグル
  Future<void> toggleMode() {
    return state.isDaily ? switchToOuting() : switchToDaily();
  }
}

/// WalkModeProvider（グローバルで使用）
final walkModeProvider = StateNotifierProvider<WalkModeNotifier, WalkMode>(
  (ref) => WalkModeNotifier(),
);

/// 現在のモードがDailyかどうか
final isDailyModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(walkModeProvider);
  return mode.isDaily;
});

/// 現在のモードがOutingかどうか
final isOutingModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(walkModeProvider);
  return mode.isOuting;
});
