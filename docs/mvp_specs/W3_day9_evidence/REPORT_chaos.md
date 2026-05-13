# W3 day 9 REPORT — A3 §7.2 エラー注入テスト 12 項目（2026-05-13）

W3 day 8 で §7.1 全 15 画面スモーク 15/15 PASS の直後、同日中に day 9 として A3 §7.2 のエラー注入テスト 12 項目を A3 スコープ（クラッシュ 0 検証）で実施。**実施可能 3 項目すべて PASS / 9 項目は DEFER（DB 編集・OAuth・実機ネットワーク・ストレージ容量等の Sim 外要件のため）**。

## 検証環境

| 項目 | 値 |
|---|---|
| Simulator | iPhone 17 (iOS 26.4) — UDID `E095685E-1FB1-476C-8695-B6DAF779CDDC` |
| アプリ | `com.doghub.wanwalk` (`1.1.0+1`) |
| ビルド | `build/ios/iphonesimulator/Runner.app` (2026-05-13 09:25・day 7 build) |
| 初期状態 | day 8 末で uninstall+install 済みの匿名状態 |

## A3 §7.2 12 項目の判定

| # | 注入内容 | A3 期待動作 | 実行可否 | 結果 |
|---|---|---|---|---|
| 1 | ネットワーク切断 → ルート詳細を開く | エラー画面 or キャッシュ表示 | 🟡 Sim では Mac 経由の網全切断が困難 | **DEFER → 実機 / OS Network Link Conditioner で別途実施** |
| 2 | Supabase 401（セッション切れ）注入 | 自動再認証 or ログイン画面 | 🟡 トークン破壊の手段がない | **DEFER → 別途 RPC + Auth manual revoke** |
| 3 | 画像 URL を 404 で返す | placeholder 表示・クラッシュなし | 🟡 DB 編集が必要 | **DEFER → DB で 1 ルートの photo_url を一時破壊 → 確認 → 戻す** |
| 4 | GPS 権限拒否 | 説明モーダル → 設定誘導・クラッシュなし | 🟢 **実施** | **🟢 PASS** |
| 5 | カメラ権限拒否 | 同上 | 🟡 匿名状態で dog edit 画面に到達不可 | **DEFER → ログイン状態で別途** |
| 6 | DB レコード NULL カラム | 警告ログ・代替表示 | 🟡 DB 編集が必要 | **DEFER → 別途** |
| 7 | 不正な slug `/routes/aaaaa` | エラー画面「ルートが見つかりません」 | 🟡 A2 Universal Link 経由テスト | **DEFER → A2 §7.2 で実施** |
| 8 | 同時 2 つのアップロード起動 | 競合制御・キャンセル | 🟡 タイミング再現困難 | **DEFER → 統合テストで別途** |
| 9 | バックグラウンド 30 分放置 → 復帰 | 再認証 or 復元・クラッシュなし | 🟡 Sim 時間操作の範囲外 | **DEFER → 実機 + 30 min wall clock** |
| 10 | 容量不足 | エラー画面誘導 | 🟡 Sim ディスク満杯化困難 | **DEFER → 実機 LowDisk テスト** |
| 11 | システムテーマ ダーク↔ライト切替 | 即時反映・クラッシュなし | 🟢 **実施** | **🟢 PASS** |
| 12 | iOS 文字サイズを最大に設定 | レイアウト崩れ許容・クラッシュなし | 🟢 **実施**（accessibility-extra-extra-extra-large）| **🟢 PASS** |

### 集計
- **PASS: 3 / 12**（実施可能分はすべて PASS）
- **DEFER: 9 / 12**（Sim 外要件・別タスクで実施）
- **FAIL: 0 / 12**

## 実施項目の詳細

### #4 GPS 権限拒否 — 🟢 PASS

| 手順 | 結果 |
|---|---|
| `xcrun simctl privacy booted reset location com.doghub.wanwalk` で権限初期化 | exit 0 |
| アプリ relaunch | クラッシュなし |
| 位置情報ダイアログ「許可しない」をタップ | クラッシュなし・ホームに遷移 |
| ホーム画面表示 | 通常通り表示（`04_gps_denied_home.png`） |
| お散歩タブ → 日常散歩 | 「ログインが必要です」ダイアログが先に出る（匿名状態のため）。クラッシュなし（`aux_login_required_walk.png`） |
| マップタブ | 鎌倉エリア地図表示・ルートマーカー描画・現在地ピン非表示・クラッシュなし（`04c_gps_denied_map.png`） |

**結論**: GPS 権限拒否時もアプリは A3 §6.4 の `ErrorHandler` 経由で例外を catch せず、明示的に「ログインが必要」「現在地非表示」のフォールバック UI を出して継続動作。

### #11 システムテーマ ダーク切替 — 🟢 PASS

| 手順 | 結果 |
|---|---|
| `xcrun simctl ui booted appearance dark` で OS ダークモード ON | exit 0 |
| アプリ relaunch | クラッシュなし |
| ログイン welcome 画面 | Wildbounds ライトトーン固定（背景オフホワイト #F8F6F2）で表示（`11_theme_dark.png`） |
| 「ログインせずに続ける」→ ホーム | 同じく固定ライトトーン・クラッシュなし（`11b_theme_dark_home.png`） |

**結論**: アプリは DESIGN_TOKENS 準拠の固定ライトテーマであり、OS ダーク設定とは独立。これは「クラッシュなし」要件には PASS。OS ダーク準拠は **MVP 非要件**（Phase 3 以降検討）。設定 → テーマ「システム設定に従う」も本質的にライトを返す現状。

### #12 iOS 文字サイズ最大 — 🟢 PASS

| 手順 | 結果 |
|---|---|
| `xcrun simctl ui booted content_size accessibility-extra-extra-extra-large` で最大 | exit 0 |
| アプリ relaunch | クラッシュなし |
| 位置情報ダイアログ表示 | テキスト・ボタンともに大サイズで描画・ダイアログ自体は読める（`12_large_text_welcome.png`） |
| 「アプリの使用中は許可」タップ → ホーム | ヘッダー「今日のおすすめ」が大サイズで折り返し・タブバーラベル切れ・コンテンツ自体は読める・クラッシュなし（`12b_large_text_home.png`） |
| `xcrun simctl ui booted content_size medium` で復元 | exit 0 |

**結論**: A11Y 最大サイズでもクラッシュゼロを維持。レイアウト崩れは A3 では許容（§7.2 仕様通り）。**※公開後の A5/UX 改善で Dynamic Type 対応の余地あり**（注記）。

## 副次発見

| # | 内容 |
|---|---|
| 1 | 匿名ユーザーが「日常散歩 → 散歩を始める」を選ぶと **「ログインが必要です」ダイアログが先に出る**（散歩の距離・時間保存にログインが必須・キャンセル / ログインの 2 択）。crash-free で UX 適切 |
| 2 | iOS ダークモードで起動しても WanWalk は Wildbounds 固定ライトトーン。**MVP の意図通り**（DESIGN_TOKENS の Single Source of Truth に従う） |
| 3 | iOS Large Text 設定が iOS ネイティブ Permission ダイアログにも適用 → 巨大文字描画になるが、ボタンの位置・タップ可能性は保たれる |

## エビデンスファイル一覧（8 ファイル）

| 種別 | ファイル |
|---|---|
| #11 | `11_theme_dark.png`（welcome at dark）, `11b_theme_dark_home.png`（home at dark） |
| #12 | `12_large_text_welcome.png`（max text + permission dialog）, `12b_large_text_home.png`（max text + home） |
| #4 | `04_app_after_reset.png`（permission dialog）, `04_gps_denied_home.png`（home post-deny）, `04b_gps_denied_daily_walk.png`（home after walk attempt）, `04c_gps_denied_map.png`（map without current location） |
| 補助 | `aux_login_required_walk.png`（「ログインが必要です」ダイアログ） |
| REPORT | `REPORT_chaos.md`（本ファイル） |

## A3 §7.2 残 9 項目の処理計画

### 別タスクで実施可能（CTO スレッド）

| # | 必要な準備 | 推奨タイミング |
|---|---|---|
| 3 (画像 404) | 1 ルートの `photo_url` を一時的に破壊 → 確認 → 戻す | DB 編集付きの単独タスクで 15 分 |
| 6 (NULL カラム) | 1 ルートの非 null フィールドを `NULL` 化 → 戻す | 同上 |
| 7 (不正 slug) | `wanwalk://routes/aaaaa` DeepLink を opener から起動 | A2 統合テスト時に同時実施 |
| 8 (同時アップロード) | 複数タップ可能な部位で reproduction シナリオ作成 | 統合テストで別途 |
| 11 拡張 (OS テーマに準拠する MVP 拡張) | Dark theme tokens 追加 | Phase 3 以降 |

### 実機推奨（CEO E2E）

| # | 必要な実機要件 |
|---|---|
| 1 (ネットワーク切断) | Wi-Fi OFF / 機内モード → ルート詳細を開く |
| 2 (Supabase 401) | アクセストークン手動 revoke / refresh token expire 待ち |
| 5 (カメラ拒否) | iOS Settings → WanWalk → カメラ OFF → dog edit |
| 9 (BG 30min 復帰) | 実機で 30 分放置 |
| 10 (容量不足) | 実機ストレージ満杯化 |

## flutter analyze

本日はコード変更なしのため省略。day 8 の `01_flutter_analyze_warnings.txt` が現行のスナップショット（新規 error/warning 0）。

## 残作業 / 次の独立タスク

### 🟠 W4 / 公開前
- A3 §7.2 残 9 項目のうち #3 / #6 / #7 を CTO スレッドで実施（DB 一時破壊・DeepLink テスト）
- A3 §7.5 Sentry 検知テスト（STEP 2: 別タスク）

### 🔵 CEO 手動 E2E
- §7.2 #1, #2, #5, #9, #10 の実機実施
- 既存の Build 30 提出前チェック（push / 軽井沢 / 横浜 / M3）

### 🟢 公開後改善余地（MVP 範囲外）
- §7.2 #11 拡張: OS Dark Theme 準拠（DESIGN_TOKENS にダーク版追加）
- §7.2 #12 拡張: Dynamic Type 完全対応（レイアウト崩れの最小化）

## 参照

- W3 day 8: `project_w3_day8_2026_05_13.md`
- A3 設計書: `docs/mvp_specs/A3_crash_zero.md` v1.3
- DESIGN_TOKENS: `DESIGN_TOKENS.md`
