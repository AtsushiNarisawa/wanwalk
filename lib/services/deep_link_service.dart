import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/analytics_provider.dart';
import '../screens/outing/route_detail_screen.dart';
import '../utils/logger.dart';
import '../utils/notification_deep_link.dart';
import 'analytics_service.dart';
import 'route_service.dart';

/// Universal Link の解析結果種別。
enum DeepLinkType {
  /// ホーム（フィード）。
  home,

  /// ルート詳細（[DeepLinkTarget.slug] に slug を持つ）。
  routeSlug,

  /// アプリが扱わない URL。Web フォールバック対象。
  unsupported,
}

/// 受信 URL の解析結果（不変・純粋関数 [parseDeepLink] が返す）。
@immutable
class DeepLinkTarget {
  const DeepLinkTarget(this.type, {this.slug});

  final DeepLinkType type;
  final String? slug;

  static const home = DeepLinkTarget(DeepLinkType.home);
  static const unsupported = DeepLinkTarget(DeepLinkType.unsupported);
}

/// 許可ホスト。AASA は wanwalk.jp のみ claim。www は念のため許可（実体は非www へ 301）。
const _allowedHosts = {'wanwalk.jp', 'www.wanwalk.jp'};

/// 受信した [uri] を [DeepLinkTarget] に変換する純粋関数（単体テスト対象）。
///
/// AASA で claim しているのは `/routes/*` と `/`（ホーム）のみ。
/// それ以外（/areas・/spots・/about・不明）は [DeepLinkType.unsupported] とし、
/// 呼び出し側が Web フォールバックする（アプリ未実装画面に半端遷移しない）。
DeepLinkTarget parseDeepLink(Uri uri) {
  // 想定外ホスト（万一カスタムスキーム等が混在した場合）は扱わない。
  if (uri.host.isNotEmpty && !_allowedHosts.contains(uri.host)) {
    return DeepLinkTarget.unsupported;
  }

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) {
    return DeepLinkTarget.home;
  }
  if (segments[0] == 'routes' &&
      segments.length >= 2 &&
      segments[1].isNotEmpty) {
    return DeepLinkTarget(DeepLinkType.routeSlug, slug: segments[1]);
  }
  return DeepLinkTarget.unsupported;
}

/// 直近に処理した URL と同一かつ短時間内なら重複起動とみなす（純粋関数・単体テスト対象）。
///
/// 同じ URL タップで複数経路（getInitialLink と stream 等）から二重に届くケースを吸収する。
bool isDuplicateDeepLink({
  required Uri incoming,
  required Uri? lastUri,
  required DateTime? lastAt,
  required DateTime now,
  Duration window = const Duration(seconds: 2),
}) {
  if (lastUri == null || lastAt == null) return false;
  return lastUri == incoming && now.difference(lastAt) < window;
}

/// GA4 用にスラッグ値を含めない正規化パス（カーディナリティ抑制・純粋関数）。
/// 例: `/routes/hakone-...` → `/routes/:slug`、`/` → `/`。
String deepLinkLogPath(Uri uri) {
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return '/';
  if (segments[0] == 'routes') return '/routes/:slug';
  return '/${segments[0]}';
}

/// A2 Universal Links 受信サービス（iOS）。
///
/// 設計書: docs/mvp_specs/A2_universal_links.md
///
/// - cold start: [AppLinks.getInitialLink] で取得した URL は navigator 未マウントのため
///   保留し、スプラッシュの画面遷移後に [processPendingColdStartLink] で消費する。
/// - warm start: [AppLinks.uriLinkStream] を購読して即時遷移。
/// - 重複起動は [isDuplicateDeepLink] で抑制。
/// - **認証ゲートはしない**：アプリは未ログインでもルート閲覧可（既存の通知ディープリンクと同方針）。
///   北極星「体験到達」を妨げないため、ログイン要求でブロックしない。
class DeepLinkService {
  DeepLinkService({
    required RouteService routeService,
    required AnalyticsService analytics,
    required GlobalKey<NavigatorState> navigatorKey,
    AppLinks? appLinks,
  })  : _routeService = routeService,
        _analytics = analytics,
        _navigatorKey = navigatorKey,
        _appLinks = appLinks ?? AppLinks();

  final RouteService _routeService;
  final AnalyticsService _analytics;
  final GlobalKey<NavigatorState> _navigatorKey;
  final AppLinks _appLinks;

  StreamSubscription<Uri>? _sub;
  Uri? _lastUri;
  DateTime? _lastAt;
  Uri? _pendingColdStartUri;
  bool _initialized = false;

  /// スプラッシュ起動時（postFrame）に 1 度だけ呼ぶ。
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // cold start を先に取得して保留（stream が初期リンクを再発火する実装差への保険）。
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _pendingColdStartUri = initial;
        if (kDebugMode) appLog('[DeepLink] pending cold-start uri: $initial');
      }
    } catch (e) {
      if (kDebugMode) appLog('[DeepLink] getInitialLink failed: $e');
    }

    // warm start: バックグラウンド復帰時の URL を購読。
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handle(uri, coldStart: false)),
      onError: (Object e) {
        if (kDebugMode) appLog('[DeepLink] uriLinkStream error: $e');
      },
    );
  }

  /// スプラッシュがメイン画面へ遷移した直後に呼ぶ。保留中の cold-start URL を消費。
  /// オンボーディング未完了で WelcomeScreen へ遷移した場合は呼ばない
  /// （初回ユーザーはオンボーディングを優先。保留 URL はそのまま破棄される）。
  Future<void> processPendingColdStartLink() async {
    final uri = _pendingColdStartUri;
    if (uri == null) return;
    _pendingColdStartUri = null;
    await _handle(uri, coldStart: true);
  }

  Future<void> _handle(Uri uri, {required bool coldStart}) async {
    final now = DateTime.now();
    if (isDuplicateDeepLink(
        incoming: uri, lastUri: _lastUri, lastAt: _lastAt, now: now)) {
      return;
    }
    _lastUri = uri;
    _lastAt = now;

    final target = parseDeepLink(uri);

    // 計測（auth_state は記録のみ・導線は妨げない）。
    final loggedIn =
        Supabase.instance.client.auth.currentSession != null;
    unawaited(_analytics.logDeepLinkOpen(
      urlPath: deepLinkLogPath(uri),
      coldStart: coldStart,
      loggedIn: loggedIn,
    ));

    switch (target.type) {
      case DeepLinkType.home:
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
        break;
      case DeepLinkType.routeSlug:
        final routeId =
            await _routeService.getOfficialRouteIdBySlug(target.slug!);
        if (routeId != null) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => RouteDetailScreen(routeId: routeId),
            ),
          );
        } else {
          // slug を解決できない（削除済み等）→ Web で開く。
          await _openInBrowser(uri);
        }
        break;
      case DeepLinkType.unsupported:
        await _openInBrowser(uri);
        break;
    }
  }

  Future<void> _openInBrowser(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) appLog('[DeepLink] launchUrl fallback failed: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

/// アプリ生存期間で 1 インスタンス（root の ProviderScope に保持される）。
/// スプラッシュで [DeepLinkService.init] を呼び、stream 購読をアプリ寿命中維持する。
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService(
    routeService: RouteService(),
    analytics: ref.read(analyticsServiceProvider),
    navigatorKey: NotificationDeepLink.navigatorKey,
  );
  ref.onDispose(service.dispose);
  return service;
});
