# W3 day 4 — B1 Flutter 統合 + M1 修正 検証レポート

**日付**: 2026-05-12 (CTO スレッド W3 day 4)
**スコープ**: M1 1 行修正 + B1 Flutter 6 ファイル新規 + main.dart wrap

---

## 1. M1 修正検証: 🟢 PASS

### 修正内容
- `lib/services/route_service.dart:311-313`
- `searchOfficialRoutes` の Supabase クエリに `.eq('is_published', true)` を 1 行追加

### Simulator 検証
- **Before (day 3)**: ヘッダー「81件のルート」 / 距離順 1 位に非公開 `karuizawa-kumoba` (667m) が露出
- **After (day 4)**: ヘッダー「**74件のルート**」 / 距離順 1 位は公開 `浄蓮の滝〜わさび田 (432m)` (06_route_list.png)

### DB 真値（Supabase MCP execute_sql）
```
published   = 74
unpublished =  7
total       = 81
```
→ 74 件表示は DB 真値と完全一致。

---

## 2. B1 Flutter 統合: 6 ファイル新規 + 4 ファイル修正

### 新規 (6)
| パス | 役割 |
|---|---|
| `lib/services/push_notification_service.dart`        | FCM SDK ラッパ・トークン登録 RPC・タップ Stream |
| `lib/services/notification_permission_service.dart`  | プリ許可・OS 許可・recovery バナー判定 |
| `lib/providers/push_notification_provider.dart`      | Riverpod プロバイダ 4 本 |
| `lib/screens/onboarding/pre_permission_screen.dart`  | プリ許可画面（B1 §3.1）|
| `lib/screens/settings/notification_settings_screen.dart` | 通知設定画面（B1 §3.2）|
| `lib/widgets/notification_recovery_banner.dart`      | ホームバナー（B1 §3.3）|
| `lib/utils/notification_deep_link.dart`              | data payload → routing 解決 |

（utils も合わせて 7 ファイル新規）

### 修正 (4)
| パス | 内容 |
|---|---|
| `lib/main.dart`                                   | Firebase 初期化（try-catch・非ブロッキング）/ Sentry wrap / navigatorKey 渡し / postFrame で push initialize |
| `lib/screens/onboarding/welcome_screen.dart`      | welcome 完了後に `PrePermissionScreen` を挟む（shouldShowPrePrompt 真のときのみ）|
| `lib/screens/main/tabs/home_tab.dart`             | ホーム最上部に `NotificationRecoveryBanner` 表示 |
| `lib/screens/settings/settings_screen.dart`       | 通知行を SwitchTile → ListTile (NotificationSettingsScreen 遷移) に置換 |
| `lib/config/env.dart`                             | `SENTRY_DSN` 追加 |
| `lib/services/route_service.dart`                 | M1 1 行修正 (is_published フィルタ追加) |

---

## 3. main.dart wrap 順序（B1 §7.4 / A4 / A3 整合）

```
WidgetsFlutterBinding.ensureInitialized
  → initializeDateFormatting
  → FlutterError.onError (overflow 抑制)
  → dotenv.load
  → Environment.validate
  → SupabaseConfig.initialize
  → Firebase.initializeApp (try-catch → 失敗してもアプリ起動継続)
  → FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundEntry)
  → SentryFlutter.init(...) で wrap して runApp
     ↓
     ProviderScope(child: WanWalkApp)
       MaterialApp navigatorKey: NotificationDeepLink.navigatorKey
         SplashScreen
           postFrameCallback で _initPushNotifications
             → push.initialize() / onMessageOpened.listen(deep link)
             → 既許可なら registerCurrentDeviceToken()
```

設計書 §7.4 リグレッション観点遵守:
- Firebase 初期化失敗時にアプリがクラッシュしない ✅ (try-catch)
- FCM 初期化を起動クリティカルパスから外す ✅ (postFrameCallback)

---

## 4. flutter analyze 結果

- 新規ファイル 7 件の `error` / `warning`: **0**
- 新規ファイル `info` 7 件（`withOpacity` / `activeColor` deprecated）: リポジトリ全体で慣習的に使われているパターンと一致・新規警告ではない
- 既存 `error` / `warning` 件数は day 3 から変化なし（dead_null_aware_expression 1, unused_element 5, unused_import 1）

---

## 5. 残作業（W3 day 5 以降）

### 🟢 今すぐ着手可能
- **B2 Flutter 5 ファイル新規**（朝散歩リマインド・B1 基盤を流用）
- **A3 Flutter 4 ファイル新規**（クラッシュゼロ化・エラーバウンダリ／ Sentry breadcrumb）
- **A3 既存クラッシュ修正**: エリアフィルター軽井沢 → `firstWhere orElse 型エラー` (day 3 §副次発見 ①)

### 🟡 Supabase / CEO 依存
- **GoogleService-Info.plist 配置**: Supabase Storage `wanwalk-secrets/GoogleService-Info.plist` (874 bytes) を `ios/Runner/` に取り出す必要（W2 §B 完遂時にバックアップ済）
  - これがないと FCM の native 初期化が失敗 → 通知配信ができない
  - 今 day 4 は plist 不在でも Flutter side try-catch がアプリ起動継続を保証 → ホーム表示まで到達済（証拠 01_after_launch.png）
- **Supabase Edge Function**: `send_push` / `cron_morning_reminder` 2 本（B1 / B2）
- **pg_cron スケジュール登録** + **`supabase secrets set` で 3 件転送**

### 🟣 A1 残: M2-M5 + L1-L8
- M1 ✅
- M2-M5 (UI 微調整) + L1-L8 (見直し提案) 計 13 件

### 🔵 CEO 手動 E2E
- 横浜みなとみらいルートで Build 30 提出前 2 分の目視確認 (day 3 から継続)

---

## 6. エビデンス

`wanwalk-app/docs/mvp_specs/W3_day4_evidence/` 以下:

- `01_after_launch.png` — アプリ起動成功・ホーム表示（Firebase 初期化が plist 不在でも try-catch で受け止め）
- `02_area_list.png` — エリアから探す（既存画面）
- `03_after_tap_center_tab.png` — タブバー領域確認
- `04_back_to_home.png` — ホーム復帰
- `05_oshanpo_tab.png` — お散歩タブ ボトムシート
- `06_route_list.png` — **🟢 公式ルート一覧「74件のルート」表示** ← M1 修正の決定的証拠

---

## 7. CEO 確認ポイント

- M1 修正は 1 行追加で 3 表示連鎖（一覧 / ピン投稿 / 検索）が同時に解消（共通の `searchOfficialRoutes` 経由のため）
- B1 Flutter 統合の Firebase Messaging は **iOS only**（v0.3 で確定済・Android 非対応）
- プリ許可画面はオンボーディング完了後にしか出ない（welcome_screen の `_completeWelcome` 内で挟む）→ 既存ユーザーは Build 30 起動時、設定画面の通知行 タップで Notification Settings → システム設定アプリで導線可
- 通知許可率 60% 目標は W5 テスター期間に再評価

---

以上。
