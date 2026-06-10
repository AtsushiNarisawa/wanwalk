import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'config/supabase_config.dart';
import 'config/wanwalk_theme.dart';
import 'config/wanwalk_colors.dart';
import 'config/env.dart';
import 'providers/analytics_provider.dart';
import 'providers/push_notification_provider.dart';
import 'screens/main/main_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/auth/auth_selection_screen.dart';
import 'screens/outing/route_detail_screen.dart';
import 'services/deep_link_service.dart';
import 'services/notification_permission_service.dart';
import 'services/onboarding_service.dart';
import 'services/push_notification_service.dart';
import 'utils/error_handler.dart';
import 'utils/logger.dart';
import 'utils/notification_deep_link.dart';
import 'utils/pii_scrubber.dart';
import 'widgets/error_fallback_widget.dart';

/// Firebase Messaging のバックグラウンドハンドラ。
///
/// top-level / static でないと OS から呼べないため main.dart に置く。
/// 中身は services/push_notification_service.dart に定義したものを呼ぶ。
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundEntry(RemoteMessage message) async {
  await firebaseMessagingBackgroundHandler(message);
}

void main() {
  // A3 wrap 順序（設計書 §6.5 + W3 day 7 強化版）：
  //   runZonedGuarded（最外）
  //     └── ErrorHandler.register（FlutterError.onError + PlatformDispatcher）
  //         └── dotenv / Supabase / Firebase 初期化（失敗しても継続）
  //             └── SentryFlutter.init（DSN 設定時のみ）
  //                 └── ErrorWidget.builder 置換
  //                     └── runApp（ProviderScope > WanWalkApp）
  //
  // runZonedGuarded を最外に置くことで、SentryFlutter.init 中に発生した未捕捉例外も
  // ErrorHandler 経由でバッファ→Sentry へ遅延送信できる。
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      ErrorHandler.register();

      // A18: 致命例外（async/platform/zone）時の白画面放置を避け、
      // 既存の共通 navigatorKey 経由でフォールバック画面へ誘導する。
      // material/widget 依存をここに閉じ込め、ErrorHandler は callback を呼ぶだけにする。
      ErrorHandler.onFatalError = () {
        final nav = NotificationDeepLink.navigatorKey.currentState;
        if (nav == null) {
          // navigator 未マウント（起動超初期）は誘導不能。Sentry 記録のみで継続。
          ErrorHandler.fatalFallbackActive = false;
          return;
        }
        nav
            .push(
              MaterialPageRoute(
                settings: const RouteSettings(name: 'error_fallback'),
                builder: (_) => ErrorFallbackWidget(
                  // フラグは push の .then(pop 完了時)で false に戻すため、
                  // ここでは触らない（reset→pop の順序差による二重 push 窓を回避）。
                  onRetry: () {
                    final n = NotificationDeepLink.navigatorKey.currentState;
                    if (n != null && n.canPop()) n.pop();
                  },
                  onGoHome: () {
                    final n = NotificationDeepLink.navigatorKey.currentState;
                    if (n != null) n.popUntil((route) => route.isFirst);
                  },
                ),
              ),
            )
            .then((_) => ErrorHandler.fatalFallbackActive = false);
      };

      await initializeDateFormatting('ja', null);

      try {
        await dotenv.load(fileName: '.env');
        if (kDebugMode) appLog('✅ Environment variables loaded');
        Environment.validate();
        if (kDebugMode) appLog('✅ Environment variables validated');

        await SupabaseConfig.initialize();
        if (kDebugMode) appLog('✅ Supabase initialized successfully');

        // Firebase 初期化（B1: FCM プッシュ通知基盤）。失敗しても起動は継続。
        try {
          await Firebase.initializeApp();
          FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundEntry);
          if (kDebugMode) appLog('✅ Firebase initialized');
        } catch (e, st) {
          if (kDebugMode) appLog('⚠️ Firebase init failed (non-fatal): $e');
          await ErrorHandler.recordNonFatal(e,
              stack: st, extra: {'phase': 'firebase_init'});
        }
      } catch (e, st) {
        if (kDebugMode) appLog('❌ Failed to initialize: $e');
        await ErrorHandler.recordNonFatal(e,
            stack: st, extra: {'phase': 'bootstrap'});
        // 起動は継続
      }

      // A3: ビルド時例外のフォールバック画面を差し替え。
      ErrorWidget.builder = wanwalkErrorWidgetBuilder;

      final dsn = Environment.sentryDsn;
      if (dsn.isEmpty) {
        if (kDebugMode) appLog('⚠️ SENTRY_DSN unset — Sentry disabled');
        runApp(const ProviderScope(child: WanWalkApp()));
      } else {
        // W3 day 20: pubspec.yaml の version を SSoT 化。
        // 取得失敗時は 'wanwalk@unknown' フォールバックで Sentry 起動継続。
        String releaseTag = 'wanwalk@unknown';
        try {
          final pkg = await PackageInfo.fromPlatform();
          releaseTag = 'wanwalk@${pkg.version}+${pkg.buildNumber}';
        } catch (e, st) {
          await ErrorHandler.recordNonFatal(e,
              stack: st, extra: {'phase': 'sentry_release_resolve'});
        }

        await SentryFlutter.init(
          (options) {
            options.dsn = dsn;
            options.environment = kReleaseMode ? 'production' : 'debug';
            options.release = releaseTag;
            options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;
            options.debug = kDebugMode;
            options.attachScreenshot = false; // 個人情報配慮
            options.maxBreadcrumbs = 30;
            // A15: PII マスキング。SDK の native 自動 PII 付与を明示的に無効化し、
            // アプリが積む payload（不具合報告の自由記述・例外メッセージ・breadcrumb・extra）を
            // beforeSend で一律 redact する。ReportIssue の「個人情報は含まれません」表記と整合。
            options.sendDefaultPii = false;
            options.beforeSend = (event, hint) => scrubSentryEvent(event);
          },
          appRunner: () async {
            await ErrorHandler.markSentryReady();
            runApp(const ProviderScope(child: WanWalkApp()));
          },
        );
      }
    },
    (Object error, StackTrace stack) {
      ErrorHandler.captureZoneError(error, stack);
    },
  );
}

/// WanWalkアプリのメインウィジェット
class WanWalkApp extends ConsumerWidget {
  const WanWalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GA4 自動 screen_view 計測のための Navigator observer。
    // Service singleton 経由で同一 observer を取得する（late final で memoize 済）。
    final analyticsObserver = ref.read(analyticsServiceProvider).observer;

    return MaterialApp(
      title: 'WanWalk',
      debugShowCheckedModeBanner: false,
      theme: WanWalkTheme.lightTheme,
      // CEO決定 (2026-04-20): ライトモードのみ強制（Wildbounds哲学）。
      // ダークモード対応は v1 スコープ外とし、DESIGN_TOKENS.md にダーク用トークンが定義されるまで一律ライト表示。
      themeMode: ThemeMode.light,
      // B1: 通知タップで送られる deep link を受けるための共通 navigatorKey
      navigatorKey: NotificationDeepLink.navigatorKey,
      navigatorObservers: [analyticsObserver],
      // A6: pushNamed で参照される named route を登録（未登録だと実行時クラッシュ）。
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/settings':
            return MaterialPageRoute(
                builder: (_) => const SettingsScreen());
          case '/login':
            return MaterialPageRoute(
                builder: (_) => const AuthSelectionScreen());
          case '/route_detail':
            final routeId = settings.arguments as String?;
            if (routeId != null) {
              return MaterialPageRoute(
                  builder: (_) => RouteDetailScreen(routeId: routeId));
            }
            return null;
          default:
            return null;
        }
      },
      home: const SplashScreen(),
    );
  }
}

/// スプラッシュ画面
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // アニメーションの設定
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    // FCM 初期化は起動クリティカルパスから外す（B1 §7.4 / A4 起動速度）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPushNotifications();
      _initAnalytics();
      _initDeepLinks();
    });

    // 認証状態をチェックして適切な画面に遷移
    _checkAuthAndNavigate();
  }

  Future<void> _initAnalytics() async {
    try {
      await ref.read(analyticsServiceProvider).initialize();
    } catch (e) {
      if (kDebugMode) appLog('[main] analytics init failed: $e');
    }
  }

  /// A2 Universal Links 受信を初期化（getInitialLink で cold-start URL を保留 + stream 購読）。
  /// 保留分はメイン画面遷移後に [DeepLinkService.processPendingColdStartLink] で消費する。
  Future<void> _initDeepLinks() async {
    try {
      await ref.read(deepLinkServiceProvider).init();
    } catch (e) {
      if (kDebugMode) appLog('[main] deep link init failed: $e');
    }
  }

  Future<void> _initPushNotifications() async {
    try {
      final push = ref.read(pushNotificationServiceProvider);
      await push.initialize();
      // A27: 通知タップで画面遷移 + 開封ログ送信。onMessageOpened は
      // getInitialMessage(コールド起動) と onMessageOpenedApp(BG復帰) の両経路を
      // 流すため、ここ一箇所で両方の開封を計測できる（foreground 受信は対象外）。
      push.onMessageOpened.listen((message) {
        NotificationDeepLink.handle(message);
        final logId = message.data['notification_log_id']?.toString();
        if (logId != null && logId.isNotEmpty) {
          unawaited(push.logNotificationOpened(logId));
        }
      });

      // 既に許可済なら APNs/FCM トークン登録（ログイン済時）
      final permState =
          await ref.read(notificationPermissionServiceProvider).syncFromOs();
      if (permState == NotificationPermissionState.granted) {
        await push.registerCurrentDeviceToken();
      }
    } catch (e) {
      if (kDebugMode) appLog('[main] push init failed: $e');
    }
  }
  
  /// 認証状態をチェックして画面遷移
  Future<void> _checkAuthAndNavigate() async {
    // スプラッシュ画面を2秒表示
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // ウェルカムスライド未完了 → ウェルカム画面へ
    final welcomeCompleted = await OnboardingService.isWelcomeCompleted();
    if (!mounted) return;

    if (!welcomeCompleted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } else {
      // ウェルカム済み → メイン画面へ
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
      // A2: cold-start で保留した Universal Link をメイン画面の上に push して消費。
      // （オンボーディング未完了の WelcomeScreen 経路では呼ばない＝初回はオンボ優先）
      unawaited(ref.read(deepLinkServiceProvider).processPendingColdStartLink());
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: WanWalkColors.primaryGradient,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アイコン
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
  PhosphorIcons.dog(),
                    size: 70,
                    color: WanWalkColors.accent,
                  ),
                ),
                const SizedBox(height: 30),
                
                // アプリ名
                const Text(
                  'WanWalk',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 12),
                
                // サブタイトル
                const Text(
                  '愛犬の散歩ルート共有アプリ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 50),
                
                // ローディングインジケーター
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}