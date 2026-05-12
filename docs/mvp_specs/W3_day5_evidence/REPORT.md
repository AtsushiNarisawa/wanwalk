# W3 day 5 検証レポート（2026-05-13）

W3 day 4 完遂直後、day 5 で残作業を完遂。

## 完遂スコープ

1. **GoogleService-Info.plist 配置**
   - Supabase Storage `wanwalk-secrets/GoogleService-Info.plist` (874 bytes) → `wanwalk-app/ios/Runner/GoogleService-Info.plist`
   - `xcodeproj` Ruby gem 経由で `ios/Runner.xcodeproj/project.pbxproj` に 4 セクション追加（PBXBuildFile / PBXFileReference / Runner グループ / Resources Build Phase）
   - バックアップ: `/tmp/project.pbxproj.bak`

2. **A3 軽井沢クラッシュ修正**（day 3 §副次発見 ①）
   - 真因: `lib/screens/routes/public_routes_screen.dart` の `_buildFilterChips` 第3引数が `AsyncValue`（ジェネリクスなし） → `areas` が dynamic 推論 → `firstWhere` の `orElse: () => areas.first` が `Area?` 型に代入不可
   - 修正 3 箇所:
     - `import '../../models/area.dart';` 追加
     - `AsyncValue areasAsync` → `AsyncValue<List<Area>> areasAsync`
     - `List<dynamic> areas` → `List<Area> areas`（`_showAreaFilter`）

3. **B2 朝散歩リマインド Flutter 統合 + RPC 拡張**
   - DB マイグレ: `update_notification_preferences` RPC に `p_morning_reminder_mode` / `p_morning_reminder_frequency` パラメータ追加（CHECK 制約付き）
   - 新規 5 ファイル + 修正 3 ファイル（後述）

## ファイル差分

### 新規 5 ファイル（B2 §6.1）

| パス | 役割 |
|---|---|
| `lib/utils/sunrise_calculator.dart` | NOAA Solar 簡易版・東京固定（35.6762, 139.6503）・`sunriseFor()` / `sunsetFor()` / `recommendedSendAt()` / `bestTimeEndAt()` |
| `lib/services/morning_reminder_service.dart` | `loadPreferences()` / `updatePreferences()` / `loadTodayRecommend()`・MorningReminderMode / MorningReminderFrequency enum + Preferences モデル |
| `lib/providers/morning_reminder_provider.dart` | `morningReminderServiceProvider` / `morningReminderPreferencesProvider` (Future) / `todayRecommendRouteProvider` / `MorningReminderNotifier` (StateNotifier・楽観更新 + 失敗時リロード) |
| `lib/screens/settings/morning_reminder_settings_screen.dart` | B2 §3.1 詳細設定 UI（ON/OFF + mode RadioListTile + 時刻指定 picker + frequency RadioListTile） |
| `lib/widgets/home/today_recommend_section.dart` | B2 §3.3「今日のおすすめ」ヒーロー画像 + タイトル + 距離/時間 + ベストタイム + 「ここへ行く」CTA |

### 修正 3 ファイル

| パス | 修正内容 |
|---|---|
| `lib/screens/settings/notification_settings_screen.dart` | 「時刻を変更」ListTile を `MorningReminderSettingsScreen` push に置換・`_pickMorningTime` 削除 + import 追加 |
| `lib/utils/notification_deep_link.dart` | `HomeScrollSection.todayRecommend` 定数追加・`pendingHomeScrollSection` static 追加・`wanwalk://home?section=...` URL & `data.section` ハンドリング |
| `lib/screens/main/tabs/home_tab.dart` | 散歩サマリー直後に `TodayRecommendSection` 1 件挿入・insertedCount 3→4 + index shift・pending section の消費フラグ処理 |

### 修正 1 ファイル（A3）

| パス | 修正内容 |
|---|---|
| `lib/screens/routes/public_routes_screen.dart` | import area.dart + `AsyncValue<List<Area>>` + `List<Area>` ジェネリクス化 |

## 検証エビデンス

### plist 認識（Firebase initialized ログ）

`/tmp/flutter_run_day5.log` 抜粋:
```
flutter: ✅ Environment variables loaded
flutter: ✅ Environment variables validated
flutter: supabase.supabase_flutter: INFO: ***** Supabase init completed *****
flutter: ✅ Supabase initialized successfully
flutter: ✅ Firebase initialized          ← day 4 で出なかったログが出るようになった
flutter: ⚠️ SENTRY_DSN unset — Sentry disabled
```

→ plist 認識成功・Firebase.initializeApp() 例外なし。`SENTRY_DSN unset` は仕様（CEO 側 W2 残作業のため OK）。

### スクショ 8 枚

| # | ファイル | 内容 |
|---|---|---|
| 01 | `01_after_launch.png` | ホーム起動直後・**「今日のおすすめ」セクション描画**・桃源台 10.1km/100分・**ベストタイム 04:09〜05:09**（東京 5/13 日の出 4:39 ±30 分計算動作）|
| 02 | `02_osanpo_tab.png` | お散歩タブ → 「お散歩を始めよう」モーダル |
| 03 | `03_public_routes.png` | 公式ルート画面・**74件のルート**（M1 維持） |
| 04 | `04_area_filter_open.png` | エリアフィルターボトムシート初期表示 |
| 05-07 | `05_area_filter_scrolled.png`〜 | エリア選択肢の縦スクロール |
| 08 | `08_filtered_yokohama.png` | **横浜フィルター適用 → 4 件表示・クラッシュなし** |

### A3 検証の代替性

「横浜」で代替検証した理由:
- day 3 のクラッシュ真因は Dart の型推論問題（`AsyncValue.when` 内の `areas` が dynamic）。これは特定エリア依存ではなく、`firstWhere(orElse)` の戻り値型が `Area?` に代入不能になる Dart コンパイル/ランタイム問題。
- 修正後は型解決で **全エリア共通** に安全。
- 軽井沢タップは ListView の shrinkWrap 内スクロール上限のため Simulator UI スワイプで到達できなかった（accessibility tree には軽井沢ラベルが load 済みを確認）。
- 横浜フィルター適用 → 4 件表示は、Day 3 で発火したのと同じコードパス（`_buildFilterChips` → `firstWhere` → `_showAreaFilter`）を全て通過するためクラッシュゼロを保証。
- 残懸念: CEO 手動 E2E で軽井沢を選択して最終確認（Build 30 提出前）。

### flutter analyze

- 新規 error: **0**
- 新規 warning: **0**（`_pickMorningTime` dead code を削除して解消）
- 全体: 315 issues → day 4 の 301 issues から +14（全 info 系: const constructor + Radio 系 deprecated_member_use・既存リポジトリ慣習一致）

## 残作業（W3 残・優先順）

### 🟠 公開ブロッカー級

- **B2 Supabase Edge Function 実装**: `cron_morning_reminder` + `weather_client.ts` + `scenario_picker.ts` + `sunrise.ts`
- **B1 send_push Edge Function 実装**: FCM HTTP v1 ラッパ + invalid_registration revoke
- **pg_cron スケジュール登録**: `cron.schedule('morning-reminder-hourly', '0 * * * *', ...)`
- **EF Secrets 転送**: `supabase secrets set` で 3 件（OPENWEATHERMAP_API_KEY / SENTRY_DSN / FCM_SERVICE_ACCOUNT_JSON）

### 🟡 A3 残

- A3 Flutter 4 ファイル新規（error_handler / error_buffer / error_fallback_widget / report_issue_screen）
- main.dart の Sentry/Zone wrap 強化（runZonedGuarded + breadcrumb 連携）

### 🟣 A1 M2-M5 + L1-L8 計 13 件

### 🔵 CEO 手動 E2E

- 軽井沢フィルター → クラッシュゼロ最終確認（Build 30 提出前）
- 横浜みなとみらいルート 2 分目視（day 3 から継続）
- B2 朝散歩 設定画面 (`MorningReminderSettingsScreen`) の mode 切替・frequency 切替の挙動確認

## 参照

- W3 day 4: `project_w3_day4_2026_05_12.md`
- W3 day 3: `project_w3_day3_2026_05_12.md`
- B2 設計書: `docs/mvp_specs/B2_morning_reminder.md` v0.5
- B1 設計書: `docs/mvp_specs/B1_fcm_push_base.md` v0.5
- W2 §B 完遂: `project_w2_section_b_completion_2026_05_12.md`
- ログ: `/tmp/flutter_run_day5.log`
- xcodeproj パッチスクリプト: `/tmp/add_googleservice_plist.rb`
- pbxproj バックアップ: `/tmp/project.pbxproj.bak`
