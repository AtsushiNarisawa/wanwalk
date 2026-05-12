/// 距離表記の Single Source of Truth（A1 致命1 対応）。
///
/// 全カード / 詳細 / ピン投稿 / おすすめ / ホームフィード / Web 表示で
/// 同一文字列を出すために、距離フォーマットはこの関数を必ず経由する。
///
/// 仕様（docs/mvp_specs/A1_build30_integration.md §3 致命1）:
/// - 入力 `meters` は DB `official_routes.distance_meters`（ST_Length(route_line)）
/// - 1km 未満は `XXXm`（例: 432 → "432m"）
/// - 1km 以上は `X.Xkm`（例: 4340 → "4.3km" / 3657 → "3.7km" / 10112 → "10.1km"）
/// - Dart `toStringAsFixed(1)` 標準四捨五入
///
/// CEO 確定 DoD 5 サンプル（2026-05-19）:
/// - 雲場池 4,340m → "4.3km"
/// - 浄蓮の滝 432m → "432m"
/// - 南ヶ丘牧場 632m → "632m"
/// - 桃源台ロープウェイ 10,112m → "10.1km"
/// - 湘南平 3,657m → "3.7km"
library;

String formatDistance(int meters) {
  if (meters < 1000) {
    return '${meters}m';
  }
  final km = meters / 1000.0;
  return '${km.toStringAsFixed(1)}km';
}

/// nullable 用ヘルパ。DB 値が NULL の場合は "—" を返す（カード一覧で空白を埋める）。
String formatDistanceOrDash(int? meters) {
  if (meters == null || meters <= 0) return '—';
  return formatDistance(meters);
}
