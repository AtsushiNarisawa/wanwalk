import 'package:shared_preferences/shared_preferences.dart';

/// オンボーディング（初回チュートリアル）の表示管理
class OnboardingService {
  static const _keyWelcomeCompleted = 'welcome_completed';
  static const _keyCoachMarkCompleted = 'coach_mark_completed';

  /// ウェルカムスライドが完了済みかどうか
  static Future<bool> isWelcomeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWelcomeCompleted) ?? false;
  }

  /// ウェルカムスライドを完了としてマーク
  static Future<void> markWelcomeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWelcomeCompleted, true);
  }

  /// コーチマークが完了済みかどうか
  static Future<bool> isCoachMarkCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCoachMarkCompleted) ?? false;
  }

  /// コーチマークを完了としてマーク
  static Future<void> markCoachMarkCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCoachMarkCompleted, true);
  }

  /// 全てリセット（デバッグ用）
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWelcomeCompleted);
    await prefs.remove(_keyCoachMarkCompleted);
  }
}
