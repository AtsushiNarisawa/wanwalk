import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wanmap/services/notification_service.dart';

/// 通知設定の状態
class NotificationSettings {
  final bool enabled;
  final bool dailyReminderEnabled;
  final TimeOfDay dailyReminderTime;
  final bool favoriteUpdateEnabled;

  const NotificationSettings({
    this.enabled = false,
    this.dailyReminderEnabled = false,
    this.dailyReminderTime = const TimeOfDay(hour: 10, minute: 0),
    this.favoriteUpdateEnabled = false,
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? dailyReminderEnabled,
    TimeOfDay? dailyReminderTime,
    bool? favoriteUpdateEnabled,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      favoriteUpdateEnabled:
          favoriteUpdateEnabled ?? this.favoriteUpdateEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'dailyReminderEnabled': dailyReminderEnabled,
      'dailyReminderHour': dailyReminderTime.hour,
      'dailyReminderMinute': dailyReminderTime.minute,
      'favoriteUpdateEnabled': favoriteUpdateEnabled,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? false,
      dailyReminderEnabled: json['dailyReminderEnabled'] ?? false,
      dailyReminderTime: TimeOfDay(
        hour: json['dailyReminderHour'] ?? 10,
        minute: json['dailyReminderMinute'] ?? 0,
      ),
      favoriteUpdateEnabled: json['favoriteUpdateEnabled'] ?? false,
    );
  }
}

/// 通知設定プロバイダー
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        (ref) {
  return NotificationSettingsNotifier();
});

/// 通知設定の状態管理
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings()) {
    _loadSettings();
  }

  static const String _key = 'notification_settings';
  final _notificationService = NotificationService();

  /// 設定を読み込む
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString != null) {
        final json = Map<String, dynamic>.from(
          Uri.splitQueryString(jsonString),
        );
        state = NotificationSettings.fromJson(json);
        
        // 設定に基づいて通知を再スケジュール
        if (state.dailyReminderEnabled) {
          await _scheduleDailyReminder();
        }
      }
    } catch (e) {
      debugPrint('通知設定読み込みエラー: $e');
    }
  }

  /// 設定を保存
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = state.toJson();
      final queryString = Uri(queryParameters: json.map(
        (key, value) => MapEntry(key, value.toString()),
      )).query;
      await prefs.setString(_key, queryString);
    } catch (e) {
      debugPrint('通知設定保存エラー: $e');
    }
  }

  /// 通知の有効/無効を切り替え
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      // 通知権限をリクエスト
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        debugPrint('通知権限が拒否されました');
        return;
      }
      
      await _notificationService.initialize();
    } else {
      // すべての通知をキャンセル
      await _notificationService.cancelAllNotifications();
    }

    state = state.copyWith(enabled: enabled);
    await _saveSettings();
  }

  /// 毎日のリマインダーを設定
  Future<void> setDailyReminderEnabled(bool enabled) async {
    if (enabled && state.enabled) {
      await _scheduleDailyReminder();
    } else {
      await _notificationService.cancelNotification(
        NotificationIds.dailyWalkReminder,
      );
    }

    state = state.copyWith(dailyReminderEnabled: enabled);
    await _saveSettings();
  }

  /// リマインダー時刻を設定
  Future<void> setDailyReminderTime(TimeOfDay time) async {
    state = state.copyWith(dailyReminderTime: time);
    
    if (state.dailyReminderEnabled && state.enabled) {
      await _scheduleDailyReminder();
    }
    
    await _saveSettings();
  }

  /// お気に入りルート更新通知を設定
  Future<void> setFavoriteUpdateEnabled(bool enabled) async {
    state = state.copyWith(favoriteUpdateEnabled: enabled);
    await _saveSettings();
  }

  /// 毎日のリマインダーをスケジュール
  Future<void> _scheduleDailyReminder() async {
    await _notificationService.scheduleDailyNotification(
      id: NotificationIds.dailyWalkReminder,
      title: '散歩の時間です 🐕',
      body: '今日もワンちゃんと楽しく散歩しましょう！',
      time: state.dailyReminderTime,
    );
  }

  /// テスト通知を送信
  Future<void> sendTestNotification() async {
    if (!state.enabled) {
      await setEnabled(true);
    }

    await _notificationService.showNotification(
      id: 999,
      title: 'テスト通知 🔔',
      body: 'WanMapからの通知が正常に動作しています！',
    );
  }
}
