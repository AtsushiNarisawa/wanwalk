import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// ローカル通知サービス
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 通知サービスの初期化
  Future<void> initialize() async {
    if (_initialized) return;

    // タイムゾーンデータの初期化
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    // Android設定
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS設定
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('通知サービスが初期化されました');
  }

  /// 通知がタップされた時の処理
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('通知がタップされました: \${response.payload}');
    // TODO: ルーティング処理を追加
  }

  /// 通知権限のリクエスト（iOS用）
  Future<bool> requestPermission() async {
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Androidは自動的に権限が付与される
    return true;
  }

  /// 即座に通知を表示
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'wanmap_channel',
      'WanMap通知',
      channelDescription: 'WanMapからの通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// スケジュール通知（指定時刻）
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'wanmap_reminder_channel',
      'WanMapリマインダー',
      channelDescription: '散歩のリマインダー通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint('通知をスケジュールしました: \$scheduledDate');
  }

  /// 毎日繰り返し通知
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'wanmap_daily_reminder_channel',
      'WanMap毎日リマインダー',
      channelDescription: '毎日の散歩リマインダー',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // 今日の時刻が過ぎていたら明日に設定
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    debugPrint('毎日通知をスケジュールしました: \${time.hour}:\${time.minute}');
  }

  /// 特定の通知をキャンセル
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('通知 ID:\$id をキャンセルしました');
  }

  /// すべての通知をキャンセル
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('すべての通知をキャンセルしました');
  }

  /// スケジュール済み通知の一覧を取得
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

/// 通知ID定数
class NotificationIds {
  static const int dailyWalkReminder = 1;
  static const int favoriteRouteUpdate = 2;
  static const int weeklyStats = 3;
}
