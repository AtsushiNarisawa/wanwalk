/// ルート description を一覧表示向けに整形するヘルパ。
///
/// 体験ストーリー本文には著者が「【出発】」「【メイン】」「【帰着】」等の
/// 構造マーカーを残しているケースがある。詳細画面では段落単位で活きるが、
/// 一覧カードの 1〜2 行プレビューでは目障りになるため、本ヘルパで除去する。
///
/// L8（CEO 2026-05-19 確定 / W3 day 7 実装）：一覧カードのみ除去・詳細画面は不変。
class RouteDescriptionFormatter {
  RouteDescriptionFormatter._();

  /// `【〜】` 形式のセクションマーカー全般。
  static final RegExp _markerPattern = RegExp(r'【[^】]{1,16}】');

  /// 連続する空白の整理用。
  static final RegExp _multiSpace = RegExp(r'[ 　]{2,}');

  /// カード用 description（先頭段落・マーカー除去・末尾省略）。
  ///
  /// [maxLength] を超える場合は末尾を `…` で打ち切る（既存 100 文字運用を踏襲）。
  static String forCard(String description, {int maxLength = 100}) {
    if (description.isEmpty) return description;

    final firstParagraph = description
            .split('\n')
            .map((p) => p.trim())
            .firstWhere((p) => p.isNotEmpty, orElse: () => description);

    final stripped = firstParagraph
        .replaceAll(_markerPattern, '')
        .replaceAll(_multiSpace, ' ')
        .trim();

    if (stripped.length <= maxLength) return stripped;
    return '${stripped.substring(0, maxLength)}…';
  }
}
