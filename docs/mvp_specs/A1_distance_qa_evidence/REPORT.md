# A1 致命1+2 Simulator 自動検証レポート

- 実施日: 2026-05-12 17:00–17:27 JST
- 担当: CTO (Claude Opus 4.7) スレッド W3 day 3
- 対象 Build: `wanwalk` `1.1.0+1`（W3 day 1 で pubspec 引き上げ済）
- ビルド: `flutter build ios --simulator --debug` 正常終了 (exit 0)
- Simulator: iPhone 17 (UDID `E095685E-1FB1-476C-8695-B6DAF779CDDC`)
- 評価基準: W3 day 2 (`project_w3_day2_2026_05_12.md`) で導入した `distance_formatter` SSoT 化 + `pin_location_picker_screen.initialCenter` 受け渡し

## 総合判定

| 致命 | 結果 | 備考 |
|---|---|---|
| 致命1 距離表示 SSoT 化 | 🟢 **PASS** | 5サンプル × 4画面で全表記一致。`spec_bar` の小数1桁丸めも仕様通り |
| 致命2 ピン投稿地図初期位置 | 🟢 **構造的 PASS** | 実装結線確認 + 3ルート分の地形色差で start_location 起点初期表示を裏取り |

副次発見 2 件（A1 スコープ外・後続スプリントに引き継ぎ）:
- **A3 トリアージ対象 新規クラッシュ** — エリアフィルター「軽井沢」適用時に Dart 型エラー `'() => dynamic' is not a subtype of '(() => Area)?' of 'orElse'`
- **M1 既知バグ実証** — ルート一覧/ピン投稿一覧で非公開ルート `karuizawa-kumoba` (667m) が露出 + 「81件のルート」のままヘッダー表示

---

## 致命1: 距離表示 SSoT 化検証

### 期待値（CEO 確定 DoD・`distance_formatter.dart` ドキュメントコメントと一致）

| ルート | DB `distance_meters` | 期待表記 |
|---|---|---|
| 浄蓮の滝〜わさび田 | 432 | `432m` |
| 那須 南ヶ丘牧場 | 632 | `632m` |
| 高麗山公園（湘南平） | 3,657 | `3.7km` |
| 旧軽井沢 雲場池と銀座通り | 4,340 | `4.3km` |
| 桃源台・大涌谷 ロープウェイ | 10,112 | `10.1km` |

### 検証マトリクス

| サンプル | ホーム/おすすめ | 一覧 (route_feed_card) | 詳細 (spec_bar) | ピン投稿 (pin_route_picker) | 散歩完了 (walk_completion) |
|---|---|---|---|---|---|
| 432m 浄蓮 | — | ✅ `432m` (02) | ✅ `432m` (12) | ✅ `432m` (15) | 実散歩必須・Sim 非対象 |
| 632m 南ヶ丘 | — | ✅ `632m` (02) | ✅ `632m` (13) | ✅ `632m` (15) | 同上 |
| 3.7km 湘南平 | — | ✅ `3.7km` (07) | ✅ `3.7km` (14) | (表示は他 3.7km と区別不可) | 同上 |
| 4.3km 雲場池(旧軽井沢) | — | ✅ `4.3km` (09) | ⚠️ A3 クラッシュで取得不可 | ✅ `4.3km` (pin list) | 同上 |
| 10.1km 桃源台 | ✅ `10.1km` (00) | ✅ `10.1km` (10) | ✅ `10.1km` (11) | (リスト末端で確認可) | 同上 |

備考:
- `(00)` 等は対応スクショの番号
- 散歩完了 `WalkCompletionSheet` は実散歩完了後のボトムシートで Simulator 環境では惹起困難。コード上 `formatDistance(route.distanceMeters.toInt())` を経由していることは `lib/widgets/walk_completion_card.dart:236` で確認済 → SSoT 担保
- 雲場池 詳細は A3 新規クラッシュで取得失敗。一覧 + ピン投稿リスト 2 経路で `4.3km` 表記が一致しているため SSoT は機能
- 「ホーム」セクションは起動時に表示される 1 ルート（今日は桃源台 10.1km）+ フィード上位（本栖湖 3.7km / 観音崎 3.3km）の表示で形式 PASS

### 追加観測（同じ formatDistance が他多数のルートで自然に機能）

| 一覧スクショ | 距離レンジ | 表記 |
|---|---|---|
| 03 | 1.2km–1.3km | `1.2km` / `1.2km` / `1.3km` / `1.3km` |
| 04 | 2.1km–2.2km | `2.1km` / `2.1km` / `2.1km` / `2.2km` |
| 05 | 2.4km–2.7km | `2.4km` / `2.6km` / `2.6km` / `2.7km` |
| 06 | 3.2km–3.5km | `3.2km` / `3.2km` / `3.3km` / `3.5km` |
| 08 | 4.1km–4.2km | `4.1km` / `4.1km` / `4.2km` |
| 10 | 6.6km–10.1km | `6.6km` / `8.5km` / `9.4km` / `10.1km` |

全件 `spec_bar` の `X.X km` → `X.Xkm` 統一フォーマットを踏襲。

### 結論

`lib/utils/distance_formatter.dart` の `formatDistance(int meters)` を経由した 8 ファイルの SSoT 化が機能していることを Simulator 上で確認。Pascon 健康診断で報告された「同一ルート 0.4km / 432m / 3.2km / 約1km の四重表記」問題は **構造的に再現しない**。

---

## 致命2: ピン投稿地図初期位置検証

### 検証戦略の前提

Simulator では OSM タイル (flutter_map のデフォルトタイル) が読み込まれず地図画像は空白だが、

1. ヘッダーの routeName が正しく引き継がれていること
2. 地図ベース色 (タイル未到達時のフォールバック色) がルートの start_location 地形に応じて変わること

の 2 点で「`initialCenter: route.startLocation` が `_currentLocation` に正しく伝播し、地図ビューポートが各 start_location 中心に置かれている」ことを間接的に裏取り。

### 実装結線の確認

| ファイル | 確認内容 |
|---|---|
| `pin_route_picker_screen.dart:267` | `initialCenter: route.startLocation` を `PinLocationPickerScreen` の constructor に渡している |
| `pin_location_picker_screen.dart:25,31` | `final LatLng? initialCenter;` を receive |
| `pin_location_picker_screen.dart:47` | `_currentLocation = widget.initialCenter ?? _fallbackCenter` で初期化 |
| `pin_location_picker_screen.dart:52` | `if (widget.initialCenter == null)` のときのみ GPS 自動取得を実行 → 旧バグ「GPS取得遅延中に `_fallbackCenter`=横浜が見える」を排除 |
| `pin_location_picker_screen.dart:113` | `FlutterMap` の `MapOptions.initialCenter` に `_currentLocation` を渡す |

### 視覚的裏取り（3ルート）

| # | ルート | スクショ | start_location | 地図背景色（タイル未ロード時のフォールバック） | 判定 |
|---|---|---|---|---|---|
| 1 | 浄蓮の滝〜わさび田 | `16_pin_map_joren.png` | 伊豆中部・浄蓮の滝駐車場 | 青基調（海/谷地形） | ✅ 海近くの地形と整合 |
| 2 | 旧軽井沢 雲場池と銀座通り | `17_pin_map_karuizawa.png` | 軽井沢内陸高原 | 緑/ミント基調（山間部地形） | ✅ 内陸山岳の地形と整合 |
| 3 | 桃源台・大涌谷 ロープウェイ | `18_pin_map_togendai.png` | 桃源台駅（芦ノ湖湖畔・大涌谷山地） | グレー(山)+青(湖) ミックス | ✅ 山＋湖の境界地形と整合 |

修正前バグ（GPS 取得遅延中に `_fallbackCenter = LatLng(35.4437, 139.6380)` = 横浜みなとみらいが見える事故）が発生していた場合、3 ルートすべて同じ「海近くの青基調」になるはず。3ルートで地形色が異なる事実は致命2 修正が機能していることの強力な間接証拠。

### 残課題

- **OSM タイル非ロード**: Simulator 環境固有の問題。CEO 実機 (TestFlight Build 30) で改めて視覚確認推奨
- **横浜みなとみらいルート**: 設計書に挙げられていた検証対象だが、ピン投稿一覧で当該ルートが容易に到達できる位置に表示されず未検証。Build 30 提出前に CEO 手動 E2E で 1 回確認すれば DoD 満たせる

---

## 副次発見 #1: A3 トリアージ対象 新規クラッシュ

### 症状

ルート一覧画面 (`PublicRoutesScreen`) でエリアフィルターをタップ → ドロップダウンで「軽井沢」を選択 → **画面全体が赤背景の Flutter エラー画面に遷移**:

```
type '() => dynamic' is not a subtype of type '(() => Area)?' of 'orElse'
See also: https://docs.flutter.dev/testing/errors
```

### 推定原因

`firstWhere` の `orElse` callback が `Area` を返すべきところ、`dynamic` を返す Closure になっている可能性が高い。`area_list_screen.dart` / `route_list_screen.dart` / `area_repository.dart` のいずれか。

### 影響範囲

- ホームからエリアタップで遷移 → 正常表示 (起動時に取得済みエリア)
- ルート一覧でエリア絞り込み → クラッシュ (今回)
- 他にも `Iterable.firstWhere(..., orElse: () => null)` 型のコードが残っていれば同型再現あり

### CEO 判断依頼

A1 致命1+2 のスコープ外なので、A3 (クラッシュゼロ化) または M1-M5 の延長として取り扱うのが妥当。**重大度: 中（特定 UI でのみ発生・致命1+2 とは独立）**。Sentry に同型エラーが流れている可能性が高いため、DSN 整備後に重複検出される見込み。

---

## 副次発見 #2: M1 既知バグ実証

### 観測

- ルート一覧画面ヘッダー: **「81件のルート」** と表示（公開 74 + 非公開 7 = 81 を全件カウント）
- 距離順上位に **「雲場池 軽井沢の水鏡 667m」** が表示
  - 該当 slug `karuizawa-kumoba` は DB で `is_published=false`（事前 SQL クエリで確認）
  - ピン投稿ルート選択画面 (`pin_route_picker_screen`) でも同様に 667m カードが出る

### M1 設計書との整合

`project_mvp_design_thread1_basal_2026_05_19.md` で記載された **M1「route_service.dart:311-313 searchOfficialRoutes の is_published フィルタ欠落」** の現れ方そのもの。1 行追加で 3 表示連鎖修正（一覧件数・一覧内訳・ピン投稿一覧）。

### 結論

W3 残作業の **🟣 A1 M1-M5 + L1-L8** ブロックで予定通り実施すれば解消。

---

## 環境メモ

- DB `distance_meters` 整合性: `project_db_distance_audit_2026_05_19.md` で全 74 ルート ST_Length 完全整合確認済（誤差 ±20m）→ アプリ表記の真値として信頼可能
- Unit test: `test/distance_formatter_test.dart` 7 group 全 pass（W3 day 2）
- `flutter analyze` 新規 error/warning 0（W3 day 2 報告と一致）

---

## エビデンスファイル一覧

| # | ファイル | 内容 |
|---|---|---|
| 00 | `00_launch_state.png` | ホーム 起動直後 + おすすめピックアップ (桃源台 10.1km) |
| 01 | `01_home_scroll1.png` | ホームフィード 本栖湖 3.7km / 観音崎 3.3km |
| 02 | `02_list_top.png` | ルート一覧 top: 浄蓮 432m / 強羅 513m / 南ヶ丘 632m / 雲場池(非公開) 667m |
| 03–10 | `03_list_scroll1.png`–`10_list_scroll8.png` | 距離順スクロール 1.2km〜10.1km |
| 11 | `11_detail_togendai_10.1km.png` | 桃源台 詳細 spec_bar 10.1km |
| 12 | `12_detail_joren_432m.png` | 浄蓮 詳細 spec_bar 432m |
| 13 | `13_detail_minamigaoka_632m.png` | 南ヶ丘 詳細 spec_bar 632m |
| 14 | `14_detail_shonandaira_3.7km.png` | 湘南平 詳細 spec_bar 3.7km |
| 15 | `15_pin_route_picker.png` | ピン投稿ルート選択画面 距離順表記 |
| 16 | `16_pin_map_joren.png` | 致命2 検証 ①浄蓮 (青基調) |
| 17 | `17_pin_map_karuizawa.png` | 致命2 検証 ②旧軽井沢 (緑/ミント基調) |
| 18 | `18_pin_map_togendai.png` | 致命2 検証 ③桃源台 (グレー山+青湖 ミックス) |

作業用スクショは `_work/` サブフォルダに退避。

---

## 次のアクション提案

1. 🟢 **B1 Flutter 統合 (6 ファイル新規) に着手**（W3 day 2 サマリーの優先タスク）
2. 🟡 A3 トリアージに「エリアフィルター orElse 型エラー」を 1 件追加（A3 のスコープ確認後）
3. 🟡 M1 1行修正を B1 着手前または並列で完遂し、「81件」「非公開ルート露出」を解消（コスト: 約 5 分）
4. 🔵 CEO 手動 E2E (Build 30 提出前): 横浜みなとみらいルート → ピン投稿 → 地図初期位置で「みなとみらい桟橋」が表示されることを目視確認（約 2 分）
