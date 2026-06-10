import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger.dart';

/// 2026-05-25: GA4 連携用 Analytics サービス
///
/// 設計書: docs/runbook/firebase_analytics_setup.md
///
/// 責務:
/// - Firebase Analytics SDK のラッパ（型安全な logXxx メソッド）
/// - Web 側 P0③（src/lib/analytics.ts）と同名 10 イベント + App 固有 5 イベントを統合
/// - 内部ユーザー判定（traffic_type=internal user property）
/// - 設定画面のデバッグ項目から ON/OFF 切替（SharedPreferences 永続化）
///
/// イベント命名は GA4 制約:
/// - 40 文字以下 / 英数字 + アンダースコア / 英字始まり
/// - 予約済 prefix: `firebase_` / `ga_` / `google_` は使用不可
/// - `screen_view` は FirebaseAnalyticsObserver で自動収集
class AnalyticsService {
  AnalyticsService._(this._analytics);

  factory AnalyticsService.create() {
    return AnalyticsService._(FirebaseAnalytics.instance);
  }

  final FirebaseAnalytics _analytics;

  static const _internalTrafficPrefKey = 'wanwalk_internal_user';

  bool _isInternalTraffic = false;
  bool get isInternalTraffic => _isInternalTraffic;

  StreamSubscription<AuthState>? _authSub;

  /// アプリ起動時に呼ぶ。SharedPreferences から内部トラフィックフラグを復元し、
  /// `traffic_type` / `app_platform` user property を初期送信する。
  /// Supabase auth state にも subscribe して user_id を GA4 に紐付ける。
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isInternalTraffic = prefs.getBool(_internalTrafficPrefKey) ?? false;

      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.setUserProperty(
        name: 'traffic_type',
        value: _isInternalTraffic ? 'internal' : 'external',
      );
      await _analytics.setUserProperty(
        name: 'app_platform',
        value: 'ios',
      );

      // 起動時に既ログインなら user_id を即時セット
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await setAuthUserId(currentUser.id);
      }

      // Auth state 変化を購読（login / logout / token refresh）
      _authSub?.cancel();
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final user = data.session?.user;
        unawaited(setAuthUserId(user?.id));
      });

      if (kDebugMode) {
        appLog('[Analytics] initialized (internal=$_isInternalTraffic)');
      }
    } catch (e, st) {
      if (kDebugMode) appLog('[Analytics] init failed: $e');
      // Sentry 経由で記録（非致命）。Analytics 失敗は起動を止めない。
      debugPrintStack(stackTrace: st);
    }
  }

  void dispose() {
    _authSub?.cancel();
  }

  /// 設定画面のデバッグ項目から呼ぶ。永続化して次回起動でも反映。
  Future<void> setInternalTraffic(bool isInternal) async {
    _isInternalTraffic = isInternal;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_internalTrafficPrefKey, isInternal);
      await _analytics.setUserProperty(
        name: 'traffic_type',
        value: isInternal ? 'internal' : 'external',
      );
      if (kDebugMode) {
        appLog('[Analytics] traffic_type=${isInternal ? 'internal' : 'external'}');
      }
    } catch (e) {
      if (kDebugMode) appLog('[Analytics] setInternalTraffic failed: $e');
    }
  }

  /// 認証成功時に呼ぶ（Supabase user.id を user_id として紐付け）。
  Future<void> setAuthUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      if (kDebugMode) appLog('[Analytics] setAuthUserId failed: $e');
    }
  }

  /// Navigator observer 用のインスタンス。MaterialApp.navigatorObservers に渡す。
  /// 毎回 build で参照されるため late final で 1 度だけ生成し、以降は同一参照を返す。
  late final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: _analytics,
  );

  // ───────────────────────────────────────────────────────────
  // ★ Web 同名 10 イベント（src/lib/analytics.ts と完全同名）
  // ───────────────────────────────────────────────────────────

  Future<void> logRouteCardClick({
    required String routeSlug,
    String? areaSlug,
    required AppSourcePage sourcePage,
  }) =>
      _log('route_card_click', {
        'route_slug': routeSlug,
        if (areaSlug != null) 'area_slug': areaSlug,
        'source_page': sourcePage.value,
      });

  Future<void> logAreaCardClick({
    required String areaSlug,
    required AppSourcePage sourcePage,
  }) =>
      _log('area_card_click', {
        'area_slug': areaSlug,
        'source_page': sourcePage.value,
      });

  Future<void> logSpotCardClick({
    required String spotSlug,
    required String spotCategory,
    String? routeSlug,
    required AppSourcePage sourcePage,
    required SpotSurface surface,
  }) =>
      _log('spot_card_click', {
        'spot_slug': spotSlug,
        'spot_category': spotCategory,
        if (routeSlug != null) 'route_slug': routeSlug,
        'source_page': sourcePage.value,
        'surface': surface.value,
      });

  Future<void> logRouteBookmarkToggle({
    required String routeSlug,
    required BookmarkAction action,
  }) =>
      _log('route_bookmark_toggle', {
        'route_slug': routeSlug,
        'action': action.value,
      });

  Future<void> logShareOpen({
    required ShareKind shareKind,
    required String shareSlug,
  }) =>
      _log('share_open', {
        'share_kind': shareKind.value,
        'share_slug': shareSlug,
      });

  Future<void> logShareChannelClick({
    required ShareKind shareKind,
    required String shareSlug,
    required ShareChannel channel,
  }) =>
      _log('share_channel_click', {
        'share_kind': shareKind.value,
        'share_slug': shareSlug,
        'channel': channel.value,
      });

  Future<void> logRouteFeedbackOpen({required String routeSlug}) =>
      _log('route_feedback_open', {'route_slug': routeSlug});

  Future<void> logRouteFeedbackSubmit({
    required String routeSlug,
    required String feedbackCategory,
  }) =>
      _log('route_feedback_submit', {
        'route_slug': routeSlug,
        'feedback_category': feedbackCategory,
      });

  Future<void> logFilterApplySeason({
    required String season,
    required AppSourcePage sourcePage,
    String? areaSlug,
  }) =>
      _log('filter_apply_season', {
        'season': season,
        'source_page': sourcePage.value,
        if (areaSlug != null) 'area_slug': areaSlug,
      });

  Future<void> logFilterApplyCart({
    required AppSourcePage sourcePage,
    String? areaSlug,
  }) =>
      _log('filter_apply_cart', {
        'source_page': sourcePage.value,
        if (areaSlug != null) 'area_slug': areaSlug,
      });

  // ───────────────────────────────────────────────────────────
  // ★ App 固有 5 イベント
  // ───────────────────────────────────────────────────────────

  /// ルート詳細画面の表示（screen_view と意味が違う：意味的「閲覧」）
  Future<void> logRouteView({
    required String routeSlug,
    String? areaSlug,
    required AppSourcePage source,
  }) =>
      _log('route_view', {
        'route_slug': routeSlug,
        if (areaSlug != null) 'area_slug': areaSlug,
        'source_page': source.value,
      });

  /// 散歩記録開始（Outing モード起動）
  /// walkMode は models/walk_mode.dart の WalkMode.value を渡す（'daily' or 'outing'）
  Future<void> logRouteStartWalk({
    String? routeSlug,
    required String walkMode,
  }) =>
      _log('route_start_walk', {
        if (routeSlug != null) 'route_slug': routeSlug,
        'walk_mode': walkMode,
      });

  /// 散歩完了
  Future<void> logWalkComplete({
    String? routeSlug,
    required String walkMode,
    required int distanceM,
    required int durationSec,
  }) =>
      _log('walk_complete', {
        if (routeSlug != null) 'route_slug': routeSlug,
        'walk_mode': walkMode,
        'distance_m': distanceM,
        'duration_sec': durationSec,
      });

  /// ピン投稿（UGC 写真）
  Future<void> logPinCreate({
    String? routeSlug,
    required String pinType,
  }) =>
      _log('pin_create', {
        if (routeSlug != null) 'route_slug': routeSlug,
        'pin_type': pinType,
      });

  /// App Store 評価リクエスト表示
  Future<void> logAppStoreReviewPrompt({required String context}) =>
      _log('app_store_review_prompt', {'context': context});

  /// A2 Universal Links 経由でアプリが起動・遷移したときの計測（設計書 §4.3）。
  /// [urlPath] は `/routes/xxx` のようなパス（クエリ・スラッグ値は含めない方針なら呼び出し側で正規化）。
  /// [coldStart] はアプリ未起動からの起動か。GA4 はパラメータに bool 非対応のため int(1/0) で送る。
  Future<void> logDeepLinkOpen({
    required String urlPath,
    required bool coldStart,
    required bool loggedIn,
  }) =>
      _log('deep_link_open', {
        'url_path': urlPath,
        'cold_start': coldStart ? 1 : 0,
        'auth_state': loggedIn ? 'logged_in' : 'logged_out',
      });

  // ───────────────────────────────────────────────────────────
  // 内部 helper
  // ───────────────────────────────────────────────────────────

  Future<void> _log(String name, Map<String, Object> params) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
      if (kDebugMode) {
        appLog('[Analytics] $name $params');
      }
    } catch (e) {
      if (kDebugMode) appLog('[Analytics] logEvent($name) failed: $e');
    }
  }
}

// ───────────────────────────────────────────────────────────
// 型定義（Web 側と命名統一）
// ───────────────────────────────────────────────────────────

/// 発火元の画面識別子。Web 側 SourcePage と命名統一（app_ prefix で区別）。
enum AppSourcePage {
  home('app_home'),
  areasList('app_areas_list'),
  areaDetail('app_area_detail'),
  routesList('app_routes_list'),
  routeDetail('app_route_detail'),
  spotDetail('app_spot_detail'),
  map('app_map'),
  history('app_history'),
  walkRecording('app_walk_recording'),
  pinPost('app_pin_post'),
  profile('app_profile'),
  search('app_search');

  const AppSourcePage(this.value);
  final String value;
}

enum SpotSurface {
  title('title'),
  photo('photo'),
  detailCta('detail_cta'),
  timeline('timeline'),
  areaHighlight('area_highlight'),
  nearby('nearby');

  const SpotSurface(this.value);
  final String value;
}

enum BookmarkAction {
  add('add'),
  remove('remove');

  const BookmarkAction(this.value);
  final String value;
}

enum ShareKind {
  route('route'),
  area('area'),
  spot('spot'),
  pin('pin');

  const ShareKind(this.value);
  final String value;
}

enum ShareChannel {
  native('native'),
  copy('copy'),
  x('x'),
  facebook('facebook'),
  line('line');

  const ShareChannel(this.value);
  final String value;
}

