/// LAYER1_NAV_SPEC §1 / §4 / §6: 第1層ナビの段階リリース用フィーチャーフラグ。
///
/// Build 42 は B(スポット接近ガイド) / D(ルート復帰サポート) を「コード同梱・既定オフ」で出す。
/// 接近・逸脱の検出ロジック（エンジン）は常時走るが、カード表示・通知・関連計測は
/// このフラグが true の時だけ発火する。Build 43 で true 化（将来は §10 nav_params の
/// リモート設定に置き換え、ノービルドで切り替える）。
///
/// A(進捗・残距離) / C(完走判定) / E(駐車場に戻る) は段階リリース対象外＝常時オン。
class NavFlags {
  const NavFlags._();

  /// §4 B: スポット接近カード / 通知 / nav_spot_approach・nav_spot_card_view 計測。
  /// Build 42 = false（既定オフ）。Build 43 = true。
  static const bool approachGuideEnabled = false;

  /// §6 D: ルート復帰サポート（逸脱バナー・点線 + off_route_event 計測）。
  /// Build 42 = false（既定オフ）。Build 43 = true。
  static const bool recoveryEnabled = false;
}
