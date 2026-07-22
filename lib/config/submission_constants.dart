/// 投稿プログラム v1（推薦フォーム・実走報告）の定数。
///
/// 仕様の正本: SUBMISSION_PROGRAM_SPEC.md / HANDOFF_SUBMISSION_V1.md /
/// memory project_submission_v1_schema_2026_07_22。
/// DBスキーマ（route_submissions）と一致させること。
class SubmissionConstants {
  SubmissionConstants._();

  /// 季節の出題（GA4 theme ディメンション・route_submissions.theme）。
  /// 締切なしの常設運用のため、キャンペーン名ではなく「季節の出題」識別子。
  /// 初回値＝秋（決定9「秋、愛犬と歩きたくなった近所の道」）。
  static const String themeAutumnNeighborhood2026 = 'autumn_neighborhood_2026';

  /// 現在アクティブな出題。フォームはこれを既定で使う。
  static const String activeTheme = themeAutumnNeighborhood2026;

  /// 同意時に記録する規約バージョン（2026-07-22 改訂・第5条の2 新設）。
  /// route_submissions.terms_version に保存。
  static const String termsVersion = '2026-07-22';

  /// 新ルート推薦（new_route）の必須写真枚数。
  static const int requiredPhotoCount = 3;

  /// 実走報告（field_report）の任意写真上限。
  static const int fieldReportMaxPhotos = 3;

  /// 発着点トリミング: 生の端点から自動除去する半径（メートル）。
  static const double trimAutoRadiusMeters = 120.0;

  /// 発着点トリミング: これより内側（生端点寄り）へは戻せない下限半径（メートル）。
  static const double trimMinRadiusMeters = 60.0;

  /// 規約リンク（同意欄）。
  static const String termsUrl = 'https://wanwalk.jp/terms';
  static const String privacyUrl = 'https://wanwalk.jp/privacy';
}

/// route_submissions.type の許可値（DB CHECK と一致）。
class SubmissionType {
  SubmissionType._();
  static const String newRoute = 'new_route';
  static const String fieldReport = 'field_report';
}

/// route_submissions.entry_point の許可値（DB CHECK: walk_end|walk_detail|campaign|null）。
class SubmissionEntryPoint {
  SubmissionEntryPoint._();

  /// 散歩完了シートから。
  static const String walkEnd = 'walk_end';

  /// 過去の散歩詳細から。
  static const String walkDetail = 'walk_detail';

  /// 募集ページ等のキャンペーン導線から。
  static const String campaign = 'campaign';
}
