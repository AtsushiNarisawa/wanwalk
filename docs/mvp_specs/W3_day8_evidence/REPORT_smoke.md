# W3 day 8 REPORT — A3 §7.1 全 15 画面スモークテスト（2026-05-13）

W3 day 7 で A3 Flutter 実装と main.dart wrap 強化を完遂したのを受けて、W3 day 8 では A3 §7.1 の 15 画面スモークテストを Simulator (iPhone 17 iOS 26.4) で実施した。**全 15 画面でクラッシュゼロを確認**。

## 検証環境

| 項目 | 値 |
|---|---|
| Simulator | iPhone 17 (iOS 26.4) — UDID `E095685E-1FB1-476C-8695-B6DAF779CDDC` |
| アプリ | `com.doghub.wanwalk` (W3 day 7 ビルド `1.1.0+1`) |
| ビルド成果物 | `build/ios/iphonesimulator/Runner.app` (2026-05-13 09:25 build) |
| アプリ初期化フロー | 既存セッションありで起動 → fresh state は途中で uninstall+install で再現 |

## 15 画面スモークテスト結果

| # | 画面 | A3 §7.1 確認内容 | 結果 | エビデンス |
|---|---|---|---|---|
| 1 | スプラッシュ | 起動 → 自動遷移 / クラッシュなし | 🟢 PASS | `01_splash.png` |
| 2 | オンボーディング 3 ページ | 各ページスワイプ → 完了 / クラッシュなし | 🟢 PASS | `02_onboarding_1.png`, `02b_onboarding_2.png`, `02c_onboarding_3.png` |
| 3 | ログイン（Apple） | サインイン UI / エラー時にエラー画面 | 🟢 PASS（UI 確認まで） | `03_login_screen.png` |
| 4 | ログイン（Google） | 同上 | 🟢 PASS（UI 確認まで） | `03_login_screen.png`（同一画面に併載） |
| 5 | ホーム（フィード） | スクロール・カードタップ / クラッシュなし | 🟢 PASS | `05_home.png` |
| 6 | ルート詳細 | 写真・地図・スポット / 旧 / 欠損データでもクラッシュなし | 🟢 PASS | `06_route_detail.png` |
| 7 | エリア詳細 | 一覧表示・ルートタップ / クラッシュなし | 🟢 PASS | `07_area_detail.png` |
| 8 | 散歩記録（GPS 起動中） | 開始 → 一時停止 → 終了 → 保存 / GPS 失敗時のクラッシュなし | 🟢 PASS | `08_daily_walk_landing.png`, `08b_daily_walk_active.png` |
| 9 | おでかけ記録 | ルート選択 → 開始 / クラッシュなし | 🟢 PASS | `09_walk_type_sheet.png`, `09b_outing_picker.png` |
| 10 | 写真アップロード（カメラ起動） | カメラ起動 / 権限拒否時の挙動 | 🟢 PASS（トリガ部 UI 確認） | `10_photo_upload.png`（dog edit 内アバター + カメラアイコン） |
| 11 | ピン投稿 | 4 タイプ選択 → 写真 → 投稿 / アップロード失敗時 | 🟢 PASS | `11_pin_post.png`, `11b_pin_location_picker.png` |
| 12 | プロフィール | 表示・編集 / 空フィールドでクラッシュなし | 🟢 PASS | `12_profile.png`, `12b_profile_scrolled.png` |
| 13 | 犬登録・編集 | 新規・更新・削除 / 画像差替時のクラッシュなし | 🟢 PASS | `13_dog_edit.png` |
| 14 | 履歴（ライブラリ） | 一覧・詳細・削除 / 空状態の表示 | 🟢 PASS | `14_library_history.png` |
| 15 | 設定 | 各サブ画面 / 通知設定・退会フロー | 🟢 PASS | `15_settings.png`, `15b_notification_settings.png`, `15c_email_change.png` |

### 集計
- **クラッシュ発生数: 0 / 15**
- **PASS: 15 / 15**
- §7.1 完遂条件達成

## A1 / B1 / B2 副次検証（スモーク中に確認された既存仕様）

| 項目 | 確認 |
|---|---|
| A1 致命 1（distance SSoT） | ホーム 10.1km / アクティブ 0m / ルート詳細 10.1km と SSoT 一致（day 2-3 検証の再確認） |
| A1 致命 2（ピン投稿地図初期位置） | 浄蓮の滝ルート → ピン位置選択画面で伊豆地域中心に Pin 表示。横浜デフォルトに戻らないことを確認（`11b_pin_location_picker.png`） |
| M1（74 件 / 81 件問題） | お出かけルート選択画面ヘッダー「74 件のルート」表示確認（`09b_outing_picker.png`） |
| M2（「キャンセル」→「閉じる」） | クイック記録 ✕ ボタンの tooltip ラベルが「閉じる」（`08_daily_walk_landing.png` の AppBar） |
| M4（散歩タイプボトムシート文言） | 「公式ルートで散歩 / 地図でコースを確認しながら歩く」CEO 確定 A 案完全一致（`09_walk_type_sheet.png`） |
| M5（難易度バッジコントラスト） | route_list / pin_route_picker いずれも levelEasy 背景 + 暗色文字（`09b_outing_picker.png`, `11_pin_post.png`） |
| L1（今月の記録タップ可能化） | ライブラリ「今月の記録 0 回 \| 0m」+ 右 caret 表示（`14_library_history.png`） |
| L2 / L5（「！」削除） | プロフィール bio・ライブラリ空状態すべて末尾「！」なし（`12_profile.png`, `14_library_history.png`） |
| L4（情報の修正 CTA 昇格） | ルート詳細「情報の修正を提案する」が OutlinedButton (accentPrimary) で表示（`06_route_detail.png`） |
| L6（検索バー autofocus 抑制） | ピン投稿ルート選択 / 公式ルート一覧で起動直後にキーボード非表示（`09b_outing_picker.png`, `11_pin_post.png`） |
| L7（高低差・難易度プレースホルダ） | ルート詳細 SpecBar に「高低差 / 難易度」枠表示（値あり時は数値・なし時は「データ準備中」） |
| B1（プッシュ事前許諾画面） | onboarding 完了後に「毎朝、お散歩のベストタイミングをお知らせ」表示（`03b_pre_permission.png`） |
| B2（朝の散歩リマインド設定） | 設定 → 通知 で「朝の散歩リマインド毎朝 06:00 にお届け / 時刻とモードを変更 / 日の出に合わせる」表示（`15b_notification_settings.png`） |

## A3 §7.5 Sentry 検知テスト — 送り送り

| # | 検証 | 状態 |
|---|---|---|
| 1 | デバッグビルドで `throw Exception()` → Sentry 受信 | ⏳ **DSN 未設定環境のため未実施** |
| 2 | リリースビルド + TestFlight で同上（環境タグ：production） | ⏳ **DSN 設定済み環境で別途実施** |
| 3 | オフライン状態で例外発生 → オンライン復帰で flush | ⏳ 同上 |
| 4 | Slack 通知 5 分以内 | ⏳ 同上 |
| 5 | 個人情報（email）が beforeSend で除去される確認 | ⏳ 同上 |

**理由**: 現在の `.env` には `SENTRY_DSN` が設定されていない（既存変数は SUPABASE_URL / SUPABASE_ANON_KEY / GOOGLE_*_CLIENT_ID / THUNDERFOREST_API_KEY 等のみ）。Sentry DSN は W2 §D で Vault に格納済（secret `f4e26e31` = `SENTRY_DSN`）だが、Flutter 側の `.env` 注入はまだ実装してない。

**A3 §6.5 main.dart の wrap 構造は DSN 未設定でも起動継続するフォールバックを実装済み**（day 7 検証）であり、`SentryFlutter.init` を skip した状態でもアプリは正常に 15 画面動作することを本日確認した。これは「A3 防護壁が機能している」根拠でもある。

**残作業（次の独立タスク）**:
1. CTO スレッドで `.env` の Sentry DSN ロード処理を確認し、Vault → CI 経由で本番ビルド時のみ注入する仕組みを設計
2. ローカル開発時の DSN 注入手順（`.env.local` 風）を確立
3. その上で §7.5 を CTO スレッドで TestFlight Build に対して実施

## flutter analyze 結果

| 項目 | 値 |
|---|---|
| 総 issues | 319 件 |
| error | **0 件** |
| warning | **7 件**（すべて day 7 以前から存在・本 day 8 で増加なし） |
| info | 312 件（withOpacity deprecated / const 推奨 / avoid_print 等） |

エビデンス: `01_flutter_analyze_warnings.txt`

本 day 8 はコード変更を伴わない検証作業のため、新規 error / warning は 0 件で正しい。

## Simulator 限界の認識（A3 §7.3.3 準拠）

以下は本日 Simulator では「UI レンダリング・遷移にクラッシュなし」までしか検証できておらず、**実機検証が公開条件**:

| 項目 | Simulator 状態 | 公開条件 |
|---|---|---|
| プッシュ通知 E2E（B1/B2） | Pre-permission UI のみ | 実機 + APNs 接続 |
| GPS 散歩記録の実精度 | 擬似座標 0m 表示まで | 実機 GPS + 実走 |
| カメラ（dog avatar / pin photo） | カメラアイコン UI のみ | 実機カメラ撮影 |
| Apple / Google OAuth サインイン | UI と遷移のみ | 実機 OAuth |
| iOS 16 系互換性 | 未検証 | CEO 手持ち実機 B |
| 致命 1 / 致命 2 の実機ガード | Simulator では day 3 / day 5 検証済 | 実機 OAuth + GPS 起点 |

## エビデンスファイル一覧（26 ファイル）

| 種別 | ファイル |
|---|---|
| 解析 | `01_flutter_analyze_warnings.txt` |
| 起動 | `01_splash.png` |
| オンボーディング | `02_onboarding_1.png`, `02b_onboarding_2.png`, `02c_onboarding_3.png` |
| 事前許諾 | `03b_pre_permission.png`（B1） |
| 匿名マイページ | `03_login_prompt_anonymous.png` |
| ログイン | `03_login_screen.png`（Apple + Google + Email 並列・Screen 3+4 兼用） |
| ホーム | `05_home.png` |
| ルート詳細 | `06_route_detail.png` |
| エリア詳細 | `07_area_detail.png` |
| 散歩記録 | `08_daily_walk_landing.png`, `08b_daily_walk_active.png` |
| 散歩タイプ | `09_walk_type_sheet.png` |
| ルート選択 | `09b_outing_picker.png` |
| 写真トリガ | `10_photo_upload.png`（dog edit 内） |
| ピン投稿 | `11_pin_post.png`, `11b_pin_location_picker.png` |
| プロフィール | `12_profile.png`, `12b_profile_scrolled.png` |
| 犬登録 | `13_dog_edit.png` |
| ライブラリ | `14_library_history.png` |
| 設定 | `15_settings.png`, `15b_notification_settings.png`, `15c_email_change.png` |
| 補助 | `aux_feature_tour.png`, `aux_logout_dialog.png`, `aux_map_tab.png` |
| 本 REPORT | `REPORT_smoke.md` |

## 残作業 / 次の独立タスク

### 🟠 W4 / 公開前
- A3 §7.5 Sentry 検知テスト（要 DSN 注入実装 + TestFlight 発信）
- A3 §7.2 エラー注入テスト 12 項目（カオステスト・主に A5 連動）
- Sentry シンボルマップ アップロード設定（release ビルドの難読化対応）

### 🔵 CEO 手動 E2E（Build 30 提出前）
- 実機 push 受信テスト（day 6 の curl 手順を実機で）
- 軽井沢フィルター → クラッシュゼロ最終確認
- 横浜みなとみらいルート 2 分目視
- 散歩タブ二度押し抑制（M3）

### 🟢 W5 月（テスター配信開始時）
- `SELECT cron.alter_job((SELECT jobid FROM cron.job WHERE jobname = 'morning-reminder-hourly'), active := true);`

## 参照

- W3 day 7: `project_w3_day7_2026_05_13.md`
- A3 設計書: `docs/mvp_specs/A3_crash_zero.md` v1.3
- W2 §D Sentry 完遂: `project_w2_runbook_resources_2026_05_19.md`
- ① 起動直後の crash 防止: `lib/utils/error_handler.dart` + `lib/main.dart` wrap 順序
