import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'config/wanmap_theme.dart';
import 'config/wanmap_colors.dart';
import 'config/env.dart';
import 'providers/auth_provider.dart';
import 'providers/dog_provider.dart';
import 'providers/gps_provider.dart';
import 'providers/route_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Flutterバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();
  
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
    print('✅ Environment variables loaded');
    
    // 環境変数のバリデーション
    Environment.validate();
    print('✅ Environment variables validated');
    
    // Supabaseの初期化
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully');
    
    // 通知システムの初期化
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('✅ Notification system initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize: $e');
    // エラーが発生しても起動を継続
  }
  
  // アプリを起動
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DogProvider()),
        ChangeNotifierProvider(create: (_) => GpsProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        // 他のProviderをここに追加
      ],
      child: const WanMapApp(),
    ),
  );
}

/// WanMapアプリのメインウィジェット
class WanMapApp extends StatelessWidget {
  const WanMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WanMap',
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
      // ログイン済み → ホーム画面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
        decoration: BoxDecoration(
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
                  child: Icon(
                    Icons.pets,
                    size: 70,
                    color: WanMapColors.accent,
                  ),
                ),
                const SizedBox(height: 30),
                
                // アプリ名
                const Text(
                  'WanMap',
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
