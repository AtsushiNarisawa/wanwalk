/// エリア・タクソノミー定数（AREA_TAXONOMY_SPEC.md の正本に対応）
///
/// DB `areas.tier` / `areas.group_key` と対になる定数群。
/// 並び順の二重定義ズレを避けるため、表示順はすべてここに集約する。
library;

/// `areas.tier` の値（DBの CHECK 制約と一致させること）。
class AreaTier {
  static const String region = 'region'; // 広域エリア（ホーム露出）
  static const String sub = 'sub'; // 広域配下の地区（現状は箱根のみ）
  static const String spot = 'spot'; // 単独公園・施設（ホーム主動線から外す）
}

/// sub を束ねる group_key（現状は箱根のみ）。
class AreaGroupKey {
  static const String hakone = 'hakone';
}

/// ホーム「エリアから探す」chip の固定表示順（需要×地理順）。
///
/// 先頭は合成された「箱根」親チップ（slug 'hakone'）。以降は tier='region' の slug。
/// `created_at` 新着順を置き換えるのが目的（AREA_TAXONOMY_SPEC.md §5）。
/// ここに無い region は末尾扱い → ルート数降順で並ぶ（新エリア追加時の保険）。
const List<String> kHomeRegionOrder = [
  'hakone', // 合成親チップ
  'kamakura', // 鎌倉
  'yokohama', // 横浜
  'izu', // 伊豆
  'kawaguchiko', // 河口湖・山中湖
  'chichibu-nagatoro', // 秩父・長瀞
  'miura', // 三浦半島
  'shonan', // 湘南
  'karuizawa', // 軽井沢
  'nasu', // 那須高原
  'nikko', // 日光
  'enoshima', // 江ノ島
  'odawara', // 小田原
  'hayama', // 葉山
  'boso', // 房総半島
];

/// ホーム「東京の身近な公園」ミニ枠に出す高需要 spot（GA4 実需上位）。
/// 多摩川=90日78PV(全エリア2位) / 葛西臨海=51PV（決定3で温存）。
const List<String> kHomeTokyoParkSlugs = [
  'tamagawa', // 多摩川河川敷
  'kasai-rinkai', // 葛西臨海公園
];

/// 都道府県の需要順（Web /areas と App 一覧で共有する基準）。
/// ここに無い県は末尾でアルファベット順。
const List<String> kPrefectureOrder = [
  '神奈川県',
  '東京都',
  '山梨県',
  '静岡県',
  '埼玉県',
  '栃木県',
  '長野県',
  '千葉県',
  '群馬県',
  '茨城県',
];

/// 並び替え用の index（見つからなければ大きい値＝末尾）。
int homeRegionOrderIndex(String? slug) {
  if (slug == null) return 9999;
  final i = kHomeRegionOrder.indexOf(slug);
  return i < 0 ? 9999 : i;
}

/// 都道府県の並び順 index（見つからなければ大きい値＝末尾）。
int prefectureOrderIndex(String? prefecture) {
  if (prefecture == null) return 9999;
  final i = kPrefectureOrder.indexOf(prefecture);
  return i < 0 ? 9999 : i;
}
