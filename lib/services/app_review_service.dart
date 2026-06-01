import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// レビュー促進（in_app_review）の表示判断を一元管理する。
///
/// 方針（2026-06-01 CEO 確定・閲覧主体ユーザー前提）:
/// 散歩する人は多くないと見込まれるため、閲覧（browser）が到達する複数の
/// ポジティブな瞬間 — ルート詳細を累計 [_routeViewThreshold] 件閲覧 /
/// ブックマーク追加 / 散歩完了 — のいずれか初到達時に1回だけ要求する。
///
/// ガード:
/// - 初回セッションは除外（[_minLaunchCount]）
/// - 前回要求から [_cooldown] 以内は出さない
/// - 実際の表示可否は Apple(SKStoreReviewController) が年最大3回でレート制限する
///
/// `requestReview()` は Sim/Debug ではダイアログが出ず、本番(App Store配信)で
/// のみ表示される。検証は [shouldPrompt] の単体テストと実機ログで行う。
class AppReviewService {
  AppReviewService._();
  static final AppReviewService instance = AppReviewService._();

  static const _kLaunchCount = 'app_review_launch_count';
  static const _kRouteViews = 'app_review_route_views';
  static const _kLastPromptMs = 'app_review_last_prompt_ms';

  /// 初回セッションを除外するための最小起動回数。
  static const int _minLaunchCount = 2;

  /// ルート詳細の累計閲覧数の閾値。
  static const int _routeViewThreshold = 5;

  /// 前回要求からの最小間隔（Apple の年最大3回 ≒ 122日 に合わせる）。
  static const Duration _cooldown = Duration(days: 120);

  InAppReview _inAppReview = InAppReview.instance;

  /// テスト用に依存を差し替える。
  @visibleForTesting
  set debugInAppReview(InAppReview value) => _inAppReview = value;

  /// レビュー要求の純粋な可否判定（プラットフォーム非依存・単体テスト対象）。
  @visibleForTesting
  static bool shouldPrompt({
    required int launchCount,
    required int? lastPromptMs,
    required DateTime now,
    int minLaunchCount = _minLaunchCount,
    Duration cooldown = _cooldown,
  }) {
    if (launchCount < minLaunchCount) return false; // 初回セッション除外
    if (lastPromptMs != null && lastPromptMs > 0) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      if (now.difference(last) < cooldown) return false; // cooldown 中
    }
    return true;
  }

  /// アプリ起動時に1回呼ぶ（セッション数のカウント）。
  Future<void> recordLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = (prefs.getInt(_kLaunchCount) ?? 0) + 1;
      await prefs.setInt(_kLaunchCount, n);
    } catch (_) {
      // 計測の失敗は致命的でないため握りつぶす
    }
  }

  /// ルート詳細を閲覧したとき。累計が閾値に達したらレビュー要求を検討する。
  Future<void> onRouteDetailViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = (prefs.getInt(_kRouteViews) ?? 0) + 1;
      await prefs.setInt(_kRouteViews, n);
      if (n >= _routeViewThreshold) {
        await _maybeRequest();
      }
    } catch (e) {
      appLog('⭐ onRouteDetailViewed skip: $e');
    }
  }

  /// ブックマーク追加・散歩完了など、それ単体で十分なポジティブシグナル。
  Future<void> onStrongPositiveSignal() async {
    await _maybeRequest();
  }

  Future<void> _maybeRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final launchCount = prefs.getInt(_kLaunchCount) ?? 0;
      final lastMs = prefs.getInt(_kLastPromptMs);

      if (!shouldPrompt(
        launchCount: launchCount,
        lastPromptMs: lastMs,
        now: DateTime.now(),
      )) {
        return;
      }

      if (!await _inAppReview.isAvailable()) return;

      await _inAppReview.requestReview();
      await prefs.setInt(
        _kLastPromptMs,
        DateTime.now().millisecondsSinceEpoch,
      );
      appLog('⭐ requestReview を要求しました');
    } catch (e) {
      appLog('⭐ requestReview skip: $e');
    }
  }
}
