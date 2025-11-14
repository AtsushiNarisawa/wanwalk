/// 環境変数設定
/// 
/// 本番環境では、これらの値を実際の認証情報に置き換えてください。
/// セキュリティのため、本番環境ではenv_prod.dartを作成し、
/// .gitignoreに追加することを推奨します。
class Environment {
  // Supabase設定
  // TODO: 実際のSupabase URLに置き換えてください
  static const String supabaseUrl = 'https://jkpenklhrlbctebkpvax.supabase.co';
  
  // TODO: 実際のSupabase Anon Keyに置き換えてください
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8';
  
  // Cloudflare R2設定（画像ストレージ）
  // TODO: 実際のR2認証情報に置き換えてください
  static const String r2AccountId = 'your-r2-account-id';
  static const String r2AccessKeyId = 'your-r2-access-key-id';
  static const String r2SecretAccessKey = 'your-r2-secret-access-key';
  static const String r2BucketName = 'wanmap-photos';
  static const String r2PublicUrl = 'https://your-bucket.r2.dev';
  
  // アプリ設定
  static const String appName = 'WanMap';
  static const String appVersion = '1.0.0';
  
  // デバッグモード
  static const bool isDebugMode = true;
  
  // マップ設定
  static const double defaultLatitude = 35.6762; // 東京（デフォルト位置）
  static const double defaultLongitude = 139.6503;
  static const double defaultZoom = 14.0;
  
  // GPS設定
  static const int locationUpdateInterval = 5000; // ミリ秒
  static const double minDistanceFilter = 10.0; // メートル
}
