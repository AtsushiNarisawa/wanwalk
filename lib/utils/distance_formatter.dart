/// 距離表記の Single Source of Truth（A1 致命1 対応 / Cross 統一 B案）。
///
/// 全カード / 詳細 / ピン投稿 / おすすめ / ホームフィード / Web 表示で
/// 同一文字列を出すために、ルート総距離フォーマットはこの関数を必ず経由する。
///
/// 仕様（DESIGN_TOKENS.md §9 / 2026-06-02 CEO 確定・F26 再検討の結果 B案）:
/// - 入力 `meters` は DB `official_routes.distance_meters`（ST_Length(route_line)）
/// - **ルート総距離は km に統一・小数第1位**（1km 未満も km で出す）
///   - 例: 432 → "0.4km" / 632 → "0.6km" / 920 → "0.9km"
///   - 例: 4340 → "4.3km" / 3657 → "3.7km" / 10112 → "10.1km"
/// - Dart `toStringAsFixed(1)` 標準四捨五入
/// - 背景: 散歩アプリ（非フィットネス）はメートル精度を前面に出さず、
///   競合（犬散歩 onedog・AllTrails）も「1km 未満も 0.6km」表記のため km 統一を採用。
/// - **マップ内のスポットまでの距離（タイムライン）は m/km 切替を維持**する。
///   km 統一すると先頭スポットが "0.0km" になり機能不全になるため。
///   → `route_timeline.dart` の `_formatDistance` / `route_spot.dart` の
///     `formattedDistance`（Web の `formatSpotDistance` 相当）が担当。この関数は通さない。
///
/// CEO 確定 DoD サンプル（2026-06-02・B案）:
/// - 雲場池 4,340m → "4.3km"
/// - 浄蓮の滝 432m → "0.4km"
/// - 南ヶ丘牧場 632m → "0.6km"
/// - 桃源台ロープウェイ 10,112m → "10.1km"
/// - 湘南平 3,657m → "3.7km"
library;

/// ルート総距離。常に km・小数第1位（1km 未満も "0.4km"）。
String formatDistance(int meters) {
  final km = meters / 1000.0;
  return '${km.toStringAsFixed(1)}km';
}

/// nullable 用ヘルパ。DB 値が NULL / 0 以下の場合は "—" を返す（カード一覧で空白を埋める）。
String formatDistanceOrDash(int? meters) {
  if (meters == null || meters <= 0) return '—';
  return formatDistance(meters);
}
