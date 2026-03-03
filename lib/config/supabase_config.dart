import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

/// Supabase設定とヘルパー
class SupabaseConfig {
  // Supabaseクライアントのシングルトンインスタンス
  static SupabaseClient get client => Supabase.instance.client;
  
  /// Supabaseの初期化
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
      debug: Environment.isDebugMode,
    );
  }
  
  /// 認証状態の変更を監視
  static Stream<AuthState> get authStateChanges {
    return client.auth.onAuthStateChange;
  }
  
  /// 現在のユーザーを取得
  static User? get currentUser {
    return client.auth.currentUser;
  }
  
  /// ログイン状態の確認
  static bool get isLoggedIn {
    return currentUser != null;
  }
  
  /// ユーザーIDを取得
  static String? get userId {
    return currentUser?.id;
  }
  
  /// ユーザーメールアドレスを取得
  static String? get userEmail {
    return currentUser?.email;
  }
}

/// Supabaseテーブル名の定数
class SupabaseTables {
  // [BUG-C02 修正] 'users' → 'profiles' に統一
  // Supabase Auth が auth.users を管理するため、公開プロフィールは profiles テーブルを使用
  static const String users = 'profiles';
  static const String dogs = 'dogs';
  static const String routes = 'routes';
  static const String routePoints = 'route_points';
  static const String tripPlans = 'trip_plans';
  static const String favorites = 'favorites';
  static const String comments = 'comments';
  static const String photos = 'photos';
}

/// Supabaseストレージバケット名の定数
class SupabaseBuckets {
  static const String dogPhotos = 'dog-photos';
  static const String routePhotos = 'route-photos';
  static const String userAvatars = 'user-avatars';
}
