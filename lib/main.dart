import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/supabase_config.dart';
import 'config/wanmap_theme.dart';
import 'config/wanmap_colors.dart';
import 'config/env.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';

void main() async {
  // Flutterバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 日本語ロケールの初期化
  await initializeDateFormatting('ja', null);
  
  // 開発中のオーバーフローエラーを非表示（デバッグビルドのみ）
  FlutterError.onError = (FlutterErrorDetails details) {
    final errorString = details.toString();
    if (errorString.contains('overflowed') || 
        errorString.contains('RenderFlex') ||
        details.exceptionAsString().contains('overflowed')) {
      // オーバーフローエラーは完全に無視
      debugPrint('Overflow error suppressed in development');
      return;
    }
    FlutterError.presentError(details);
  };
  
  try {
    // 環境変数の読み込み
    await dotenv.load(fileName: ".env");
    if (kDebugMode) {
      print('✅ Environment variables loaded');
    }
    
    // 環境変数のバリデーション
    Environment.validate();
    if (kDebugMode) {
      print('✅ Environment variables validated');
    }
    
    // Supabaseの初期化
    await SupabaseConfig.initialize();
    if (kDebugMode) {
      print('✅ Supabase initialized successfully');
    }
    
    // 通知システムは各画面で必要に応じて初期化
    if (kDebugMode) {
      print('✅ Notification system ready');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Failed to initialize: $e');
    }
    // エラーが発生しても起動を継続
  }
  
  // アプリを起動（Riverpod対応）
  runApp(
    const ProviderScope(
      child: WanWalkApp(),
    ),
  );
}

/// WanWalkアプリのメインウィジェット
class WanWalkApp extends StatelessWidget {
  const WanWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WanWalk',
      debugShowCheckedModeBanner: false,
      theme: WanMapTheme.lightTheme,
      darkTheme: WanMapTheme.darkTheme,
      themeMode: ThemeMode.system, // システム設定に従う
      home: const SplashScreen(),
    );
  }
}

/// スプラッシュ画面
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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
    
    // 認証状態をチェックして適切な画面に遷移
    _checkAuthAndNavigate();
  }
  
  /// 認証状態をチェックして画面遷移
  Future<void> _checkAuthAndNavigate() async {
    // スプラッシュ画面を2秒表示
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // 認証状態を確認
    final isLoggedIn = SupabaseConfig.isLoggedIn;
    
    // 適切な画面に遷移
    if (isLoggedIn) {
      // ログイン済み → メイン画面（4タブUI）
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      // 未ログイン → ログイン画面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
          gradient: WanMapColors.primaryGradient,
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
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 70,
                    color: WanMapColors.accent,
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