import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 環境変数設定
/// 
/// .envファイルから環境変数を読み込みます。
/// セキュリティのため、.envファイルはGit管理対象外(.gitignore)に設定してください。
class Environment {
  // Supabase設定
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  
  // Thunderforest地図タイル
  static String get thunderforestApiKey => dotenv.get('THUNDERFOREST_API_KEY', fallback: '');
  
  // アプリ設定
  static String get appName => dotenv.get('APP_NAME', fallback: 'WanMap');
  static String get appVersion => dotenv.get('APP_VERSION', fallback: '1.0.0');
  
  // デバッグモード
  static bool get isDebugMode => dotenv.get('DEBUG_MODE', fallback: 'true') == 'true';
  
  // マップ設定
  static double get defaultLatitude => 
    double.tryParse(dotenv.get('DEFAULT_LATITUDE', fallback: '35.6762')) ?? 35.6762;
  static double get defaultLongitude => 
    double.tryParse(dotenv.get('DEFAULT_LONGITUDE', fallback: '139.6503')) ?? 139.6503;
  static double get defaultZoom => 
    double.tryParse(dotenv.get('DEFAULT_ZOOM', fallback: '14.0')) ?? 14.0;
  
  // GPS設定
  static int get locationUpdateInterval => 
    int.tryParse(dotenv.get('LOCATION_UPDATE_INTERVAL', fallback: '5000')) ?? 5000;
  static double get minDistanceFilter => 
    double.tryParse(dotenv.get('MIN_DISTANCE_FILTER', fallback: '10.0')) ?? 10.0;
  
  /// 環境変数のバリデーション
  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL環境変数が設定されていません');
    }
    if (supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY環境変数が設定されていません');
    }
    if (thunderforestApiKey.isEmpty || thunderforestApiKey == 'your-api-key-here') {
      if (kDebugMode) {
        print('⚠️ Warning: THUNDERFOREST_API_KEY環境変数が設定されていません。地図タイルが表示されない可能性があります。');
      }
    }
  }
}
