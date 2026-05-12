import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../screens/outing/route_detail_screen.dart';

/// 通知タップ後にホームの特定セクションへ auto-scroll させるためのキー名。
/// HomeTab 側で対応する GlobalKey を [pendingHomeScrollSection] と突き合わせる。
class HomeScrollSection {
  static const String todayRecommend = 'today_recommend';
}

/// 通知 data ペイロード → 画面遷移ルーティング解決（B1 §6.1）。
///
/// 設計書: docs/mvp_specs/B1_fcm_push_base.md
///
/// 通知の `data` payload の想定キー:
///
/// ```
/// {
///   "deep_link":      "route_detail" | "home" | "url",
///   "route_id":       <uuid>,             // route_detail 時
///   "url":            "https://...",      // url 時（A2 Universal Links と同形式想定）
///   "notification_log_id": <uuid>         // log_notification_opened RPC 用
/// }
/// ```
///
/// 共通の `MaterialApp` に `navigatorKey` を渡しておき、ここから push する設計。
class NotificationDeepLink {
  NotificationDeepLink._();

  /// 共通 navigatorKey（main.dart で MaterialApp に渡す）。
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// B2 通知タップで「ホームのどのセクションへ scroll するか」を保持。
  /// HomeTab が次回 build 時に読み取って消費する。
  static String? pendingHomeScrollSection;

  /// 通知タップで届く RemoteMessage を画面遷移に変換。
  ///
  /// 不明な deep_link は無視（ホームのまま）。
  static Future<void> handle(RemoteMessage message) async {
    final data = message.data;
    final deepLink = data['deep_link']?.toString();
    if (deepLink == null || deepLink.isEmpty) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (deepLink.startsWith('wanwalk://home')) {
      final uri = Uri.tryParse(deepLink);
      final section = uri?.queryParameters['section'];
      if (section != null && section.isNotEmpty) {
        pendingHomeScrollSection = section;
      }
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    switch (deepLink) {
      case 'route_detail':
        final routeId = data['route_id']?.toString();
        if (routeId != null && routeId.isNotEmpty) {
          await navigator.push(
            MaterialPageRoute(
              builder: (_) => RouteDetailScreen(routeId: routeId),
            ),
          );
        }
        break;
      case 'home':
        final section = data['section']?.toString();
        if (section != null && section.isNotEmpty) {
          pendingHomeScrollSection = section;
        }
        // 既にホーム想定。深い画面にいる場合だけ root まで戻す。
        navigator.popUntil((route) => route.isFirst);
        break;
      // 'url' は A2 Universal Links 側の handler に委譲。MVP では未実装。
      default:
        break;
    }
  }
}
