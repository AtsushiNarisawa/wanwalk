// ==================================================
// Local Notification Service for WanWalk v2
// ==================================================
// Author: AI Assistant
// Created: 2025-11-21
// Purpose: Handle local push notifications using flutter_local_notifications
// ==================================================

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 通知システムを初期化
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('LocalNotificationService already initialized');
      return;
    }

    try {
      // タイムゾーンデータを初期化
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

      // Android設定
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS設定
      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      // 初期化設定
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      // 通知プラグインを初期化
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      _initialized = true;
      debugPrint('✅ LocalNotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ LocalNotificationService initialization failed: $e');
      rethrow;
    }
  }

  /// iOS用: 古いバージョンでのローカル通知受信ハンドラ
  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('iOS Local Notification Received: id=$id, title=$title');
  }

  /// 通知をタップした時のハンドラ
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: payload=${response.payload}');
    // TODO: ペイロードに基づいて画面遷移などの処理を実装
  }

  /// 通知権限をリクエスト
  Future<bool> requestPermission() async {
    try {
      // iOS
      final bool? resultIOS = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Android (Android 13+)
      final bool? resultAndroid = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      debugPrint('Notification Permission: iOS=$resultIOS, Android=$resultAndroid');
      return resultIOS ?? resultAndroid ?? true;
    } catch (e) {
      debugPrint('❌ Request permission failed: $e');
      return false;
    }
  }

  /// 即座に通知を表示
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'wanmap_channel',
        'WanWalk通知',
        channelDescription: 'WanWalkからの通知',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('✅ Notification shown: id=$id, title=$title');
    } catch (e) {
      debugPrint('❌ Show notification failed: $e');
      rethrow;
    }
  }

  /// 毎日決まった時刻に通知をスケジュール
  Future<void> scheduleDailyNotification({
    required String id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // 通知IDを生成（idの文字列をハッシュ化）
      final int notificationId = id.hashCode;

      // 今日の指定時刻を計算
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // もし指定時刻が過去なら、明日の同時刻にスケジュール
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'wanmap_daily_channel',
        'WanWalk毎日の通知',
        channelDescription: '毎日のお散歩リマインダー',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      debugPrint('✅ Daily notification scheduled: id=$id, time=${time.hour}:${time.minute}');
    } catch (e) {
      debugPrint('❌ Schedule daily notification failed: $e');
      rethrow;
    }
  }

  /// 特定の通知をキャンセル
  Future<void> cancelNotification(String id) async {
    try {
      final int notificationId = id.hashCode;
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      debugPrint('✅ Notification cancelled: id=$id');
    } catch (e) {
      debugPrint('❌ Cancel notification failed: $e');
      rethrow;
    }
  }

  /// すべての通知をキャンセル
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Cancel all notifications failed: $e');
      rethrow;
    }
  }

  /// アクティブな通知のリストを取得
  Future<List<ActiveNotification>> getActiveNotifications() async {
    try {
      final List<ActiveNotification> activeNotifications =
          await _flutterLocalNotificationsPlugin.getActiveNotifications();
      debugPrint('Active notifications: ${activeNotifications.length}');
      return activeNotifications;
    } catch (e) {
      debugPrint('❌ Get active notifications failed: $e');
      return [];
    }
  }

  /// ペンディング中の通知リクエストを取得
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint('Pending notifications: ${pendingNotifications.length}');
      return pendingNotifications;
    } catch (e) {
      debugPrint('❌ Get pending notifications failed: $e');
      return [];
    }
  }

  /// リソースを解放
  void dispose() {
    debugPrint('LocalNotificationService disposed');
    // flutter_local_notificationsは明示的なdisposeが不要
  }
}
