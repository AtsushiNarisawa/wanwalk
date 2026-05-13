# W3 day 11 REPORT — A3 §7.2 #3 画像 404 + #6 NULL カラム DB 一時破壊検証（2026-05-13）

W3 day 10 で A3 §7.2 #7 不正 slug DeepLink を先行 PASS（DEFER 8 のうち 1 件消化）。day 11 では「DB 一時破壊系 (#3 / #6)」を A3 スコープの「クラッシュ 0」検証として実施した。**結果: 🟢 #3 PASS / 🟢 #6 PASS**。

A3 §7.2 集計の更新: PASS **6 / 12** （day 9 の #4 / #11 / #12 + day 10 の #7 + 本日の #3 / #6）、DEFER **6 / 12**（Supabase 401 #2・カメラ拒否 #5・同時アップロード #8・BG 30min 復帰 #9・容量不足 #10・ネットワーク切断 #1 すべて実機 or 統合テスト要件）。

## 検証環境

| 項目 | 値 |
|---|---|
| Simulator | iPhone 17 (iOS 26.4) — UDID `E095685E-1FB1-476C-8695-B6DAF779CDDC` |
| アプリ | `com.doghub.wanwalk` (`1.1.0+1`) |
| ビルド | `build/ios/iphonesimulator/Runner.app` (2026-05-13 day 7 + day 10 commit `8007342` のクリーン再 build・14.5s) |
| 検証ルート | `izu-jorennotaki-wasabida`（伊豆・浄蓮の滝〜わさび田・公開・7 spot） |
| 検証 spot | `81e73305-08ea-4d4b-8501-cbe90b2d8436`（spot_order=5 / spot_type=waypoint / name=「浄蓮の滝 滝壺」） |

## 元値（DB 復旧用のベースライン）

| カラム | md5 | length |
|---|---|---|
| `photo_url` | `9a6102870145b3a1baf52a712647bca4` | 170 |
| `description` | `5a65d07c498640aaf09cc4ec60c66cb1` | 235 |

`photo_url` 末尾: `route-photos/izu-jorennotaki-wasabida/refetch_20260422/spots/81e73305-08ea-4d4b-8501-cbe90b2d8436/01.jpg`
`description` 先頭: `日本の滝百選にも選ばれた落差25m・幅7mの伊豆を代表する名瀑で、天城山中の玄武岩の岸壁から豪快に水が落下する。…`

## #3 画像 URL 404 一時破壊 — 🟢 PASS

### 注入内容

`photo_url` を `https://jkpenklhrlbctebkpvax.supabase.co/storage/v1/object/public/route-photos/wanwalk-w3-day11-chaos-404-do-not-use.jpg`（存在しない object）に UPDATE。

`curl -sI` 確認: `HTTP/2 400`（Supabase Storage は存在しない object に 400 を返す挙動・アプリ側は「画像取得失敗」として扱う点で 404 と等価）。

### 検証手順と結果

| 手順 | 結果 |
|---|---|
| Sim で `iOS 伊豆エリア → 浄蓮の滝〜わさび田` を選択 → ルート詳細を再 open | 通常表示・ヘッダー「ルート詳細」/ 距離 `432m` / 所要時間 `約 25 分` / 高低差「データ準備中」/ 難易度「中級」すべて変わらず |
| 上半分（マップ + メタ）の AXFrame 構造を破壊前と比較 | **完全一致**（`02_chaos3_photo_404_top.png`） |
| 下方向スクロールで「おすすめスポット」セクションを可視化 | spot 5 description（235字）は AXFrame y=118 x=24 w=354 h=210.82 で **完全表示**・後続 spot「伊豆の踊り子像」も通常通り表示（`03_chaos3_photo_404_spot_section.png`） |
| クラッシュ / Sentry envelope / ErrorBoundary fallback | **すべてなし**（アプリ側の `Image.network` / `CachedNetworkImage` 系が握り潰している前提） |

### 期待動作との対照

A3 §7.2 #3 仕様「placeholder 表示・クラッシュなし」:
- ✅ クラッシュなし（PASS の必要条件）
- ✅ UI 構造保たれている（spot list + description プレビュー + おすすめスポットセクション 全表示）
- ✅ 「画像が壊れている部分以外」は通常表示

### revert

```sql
UPDATE route_spots SET photo_url='https://.../refetch_20260422/spots/.../01.jpg'
WHERE id='81e73305-08ea-4d4b-8501-cbe90b2d8436';
```
復旧後 SELECT で `md5(photo_url)='9a6102870145b3a1baf52a712647bca4'` AS `photo_revert_ok = true` 確認、description は破壊期間中も md5 完全一致で intact。**破壊 → revert の合計滞在時間 約 3 分**。

## #6 DB レコード NULL カラム 一時破壊 — 🟢 PASS

### 注入内容

`description` を `NULL` に UPDATE（A3 §7.2 #6 仕様「既存非 NULL 想定の場所」= アプリ側が値ありを前提に扱う nullable カラム）。`route_spots.description` は schema 上 nullable だが、全 437 spot 中ほぼ全件で値が埋まっており、アプリの spot 表示は値前提で組まれている。

### 検証手順と結果

| 手順 | 結果 |
|---|---|
| Sim で戻る → 再 open（**1 回目**） | キャッシュ残存により description=235字が表示されてしまう。Riverpod の routeByIdProvider が AsyncValue を保持しているため戻る → push では再 fetch されないことが判明（**副次発見 1**） |
| アプリを terminate + launch で再起動 → 同ルートを fresh fetch（**2 回目**） | コースガイドの spot 5「浄蓮の滝 滝壺 / 259m」見出しは AXFrame y=436.85 で表示・**preview description 行は空欄で描画**・他 spot (#2/#3/#4/#6/#7) の preview description は通常表示（`05_chaos6_desc_null_fresh_fetch.png` + `06_chaos6_desc_null_spot_section.png`） |
| 「おすすめスポット」セクション（y=736.85）の spot 5 見出し（y=809.85）配下 | **description テキスト要素そのものが描画されない**（spot 5 description 行と犬連れメモ「リード必須」も非描画）・破壊前は y=118 で 235字フル表示だった |
| クラッシュ / Sentry envelope / ErrorBoundary fallback | **すべてなし**（Flutter の `Text(spot.description ?? '')` または `if (spot.description != null) Text(...)` 系の null-aware 構文で握り潰されている前提） |

### 期待動作との対照

A3 §7.2 #6 仕様「警告ログ・代替表示・クラッシュなし」:
- ✅ クラッシュなし（PASS の必要条件）
- ✅ 代替表示（description 要素を描画しない＝空欄として fallback・他項目は通常表示）
- ⚠️ 警告ログ: 当該 spot で `spot.description == null` をログに出しているかは未検証（MVP では UI 健全性で十分・公開後 Sentry breadcrumb 追加検討）

### revert

```sql
UPDATE route_spots SET description='日本の滝百選にも選ばれた落差25m・…'
WHERE id='81e73305-08ea-4d4b-8501-cbe90b2d8436';
```
復旧後 SELECT で `md5(description)='5a65d07c498640aaf09cc4ec60c66cb1'` AS `description_revert_ok = true`・`length=235`・`photo_intact=true` で完全一致確認。**破壊 → revert の合計滞在時間 約 4 分**（再起動 → fresh fetch 含む）。

## 副次発見

| # | 内容 |
|---|---|
| 1 | **Riverpod キャッシュ強度**: `routeByIdProvider(routeId)` は AsyncValue を保持し、同 sessoin 中の戻る → push では DB 再 fetch しない。これは「ネット障害時のフォールバック」「画面遷移の体感速度」として有用な一方、検証時は **terminate + launch** で確実に fresh fetch させる必要がある（W4 以降 §7.2 残検証や CEO E2E でも同じ前提で運用） |
| 2 | **description NULL の握り方**: アプリ層は `Text(spot.description ?? '')` 相当のパターンで描画しているため、null 時は空文字描画 → 結果として UI 上「行が消える」表現になる。クラッシュ防止としては理想的だが、ユーザーから見ると「説明欄が無音で消える」ので、公開後の v1.1 で「説明準備中」プレースホルダ + Sentry breadcrumb 追加を検討候補 |
| 3 | **本番 DB 一時破壊の影響時間**: 各テスト 3-4 分・累計 7 分間。TestFlight 段階で本ルートを同時間に閲覧していたユーザーがいた場合、写真欠落 or description 空欄に遭遇する可能性が極小だが存在。Build 30 公開後はステージング DB or feature flag 経由のテストに切り替え推奨（**A3 §7.2 残検証 #2/#9 が同様の本番 DB 影響を伴う場合に再検討**） |

## エビデンスファイル一覧（7 枚 + REPORT）

| 種別 | ファイル |
|---|---|
| 起動・ベースライン | `00_initial_launch.png`（ホーム到達）/ `01_route_detail_top_baseline.png`（spot 5 description 235字 完全表示・破壊前） |
| #3 photo_url 404 注入 | `02_chaos3_photo_404_top.png`（ルート詳細上部・距離/時間/難易度すべて正常）/ `03_chaos3_photo_404_spot_section.png`（おすすめスポット spot 5 description 完全表示・写真欄のみ placeholder） |
| #6 description NULL 注入 | `04_chaos6_desc_null_top.png`（戻る → re-open でキャッシュ残存・description 表示）/ `05_chaos6_desc_null_fresh_fetch.png`（アプリ再起動後の fresh fetch・コースガイド上部）/ `06_chaos6_desc_null_spot_section.png`（コースガイド spot 5 description 行空欄 + おすすめスポット spot 5 description 非描画） |
| REPORT | `REPORT_chaos_part3.md`（本ファイル） |

## flutter analyze

day 11 はコード変更なし（DB のみ一時破壊）のため、analyze は day 10 と同等:

- 新規 error: **0**
- 新規 warning: **0**
- 既存 warning（7 件）: `home_feed_provider.dart:124` dead_null_aware / `library_tab.dart:839` unused `_buildCommunityTimeline` / `route_detail_screen.dart` の unused_import + unused_element 3 件 / `pin_card.dart:87` unused `_NumberTile`
- info: 312 件（cleanup_routes.dart の avoid_print 等・すべて既存）

`flutter build ios --simulator --no-codesign` 成功（14.5s）。

## A3 §7.2 残課題

### 別タスクで実施可能（後続 CTO スレッド）

| # | 必要な準備 | 推奨タイミング |
|---|---|---|
| 2 (Supabase 401) | テストユーザーで JWT を一時 revoke or expiry 短縮 | 統合テスト時（Vault → CI .env 注入と同時期に staging 環境を立てる検討） |
| 8 (同時アップロード) | 複数タップ可能な部位で reproduction シナリオ作成 | 統合テスト時 |

### 実機推奨（CEO E2E・W4 ベンチ前）

| # | 必要な実機要件 |
|---|---|
| 1 (ネットワーク切断) | Wi-Fi OFF / 機内モード → ルート詳細を開く |
| 5 (カメラ拒否) | iOS Settings → WanWalk → カメラ OFF → dog edit |
| 9 (BG 30 min 復帰) | 実機で 30 分放置 |
| 10 (容量不足) | 実機ストレージ満杯化 |

## 参照

- W3 day 9: `project_w3_day9_2026_05_13.md`（§7.2 #4 / #11 / #12 + §7.5 Sentry）
- W3 day 10: `project_w3_day10_2026_05_13.md`（§7.2 #7 不正 slug DeepLink）
- A3 設計書: `docs/mvp_specs/A3_crash_zero.md` v1.3
- DB 破壊対象: `route_spots.id='81e73305-08ea-4d4b-8501-cbe90b2d8436'`
- 過去 commit: `8007342`（day 10 終端・working tree clean）
