# W3 day 21 Phase A-D エビデンスレポート

**実施日**: 2026-05-15
**目的**: F0_account_deletion_design.md v1.0 Phase A-E の Phase A-D 動作確認
**根拠**: App Store Review Guideline 5.1.1(v) — In-App アカウント削除

---

## Phase A: スキーマ事前確認

### FK 構造（pg_constraint で精密取得）
- 🔴 **NO ACTION（明示削除必須・4 テーブル）**
  - `pin_bookmarks.user_id → auth.users(id)`
  - `route_favorites.user_id → auth.users(id)`
  - `route_pins.user_id → auth.users(id)`
  - `user_badges.user_id → auth.users(id)`
- 🟢 **CASCADE（auth.users 削除で連鎖消滅）**: 24 件
  - profiles / favorite_routes / notifications / pin_likes / route_feedback / route_likes / route_photos / route_pin_bookmarks / route_pin_comments / route_pin_likes / spot_reviews / trips / user_bookmarks / user_follows×2 / user_walking_profiles / walk_photos / walks / public.users / + profiles 経由 6 件（comments / device_tokens / notification_log / notification_permissions / notification_preferences / routes）
- 🟡 **SET NULL**: `route_pin_comments.reply_to_user_id` (他人の発言への返信履歴は NULL 化)
- 🟢 **route_pins 子テーブル全 CASCADE**: route_pin_likes / comments / bookmarks / photos / spot_reviews

### 設計書の誤情報修正
- `route_favorites` の "二重定義" は誤り。実際は `favorite_routes`（CASCADE）と `route_favorites`（NO ACTION）の別テーブル

### Storage パス規約
| バケット | パス規約 | プレフィックス |
|---|---|---|
| `user-avatars` | `{uid}/avatar_{ts}.jpg` | `{uid}` |
| `walk-photos` | `{uid}/{walk_id}/{ts}.jpg` | `{uid}` (サブフォルダあり) |
| `pin_photos` | `{uid}/{pin_id}_{ts}.{ext}` | `{uid}` |
| `dog-photos` | `dogs/{uid}/{ts}.jpg` および `dogs/{uid}/{dog_id}/vaccinations/...` | **`dogs/{uid}`** ←要注意 |

---

## Phase B: Edge Function 実装 + 疎通テスト

### デプロイ
- 関数名: `delete-user`
- version: 1
- status: ACTIVE
- verify_jwt: true
- entrypoint_path: `supabase/functions/delete-user/index.ts`

### 削除順序（実装）
1. `device_tokens` の `revoked_at` を update（通知中削除の保険）
2. NO ACTION 4 テーブルを順序 (子→親) で明示 DELETE
3. Storage 4 バケットから prefix 配下を再帰削除
4. `admin.auth.admin.deleteUser(uid)` で CASCADE 連鎖

### 疎通テスト結果
| Case | 期待 | 実測 | 判定 |
|---|---|---|---|
| ① 認証なし | 401 | 401 `UNAUTHORIZED_NO_AUTH_HEADER` | 🟢 PASS |
| ② 正常削除 | 200 + auth_deleted=true | 200 / `{ok:true, auth_deleted:true, errors_count:0}` | 🟢 PASS |
| ③ 他人の uid 注入 | 構造的に不可 | uid は body 不参照・JWT のみ抽出（コード保証） | 🟢 構造的 PASS |

### 削除痕跡確認（テストユーザー uid: `c6ba1d31-25f2-464d-8535-6fef5f532229`）
```sql
SELECT 'auth.users', COUNT(*) FROM auth.users WHERE id = 'c6ba1d31-...'  -- 0
UNION SELECT 'profiles', COUNT(*) FROM profiles WHERE id = 'c6ba1d31-...'  -- 0
```
両方 0 件 → CASCADE 連鎖削除成功 🟢

---

## Phase C: Flutter UI 実装

### 新規ファイル
- `lib/screens/settings/account_deletion_screen.dart`（約 280 行）

### 修正ファイル
- `lib/services/auth_service.dart`
  - `deleteAccount()` 追加（Edge Function 呼び出し + signOut）
  - `reauthenticateWithPassword()` 追加（email/password 再認証）
  - `primaryProvider` getter 追加（email/apple/google 判定）
- `lib/screens/settings/settings_screen.dart`
  - 「アカウントを削除」項目追加（赤強調）
  - `_buildSettingsTile` に `titleColor` 引数追加
- `lib/screens/settings/help_screen.dart`
  - 案内文言「アカウント削除」→「アカウントを削除」へ実装と一致（教訓 #55）

### flutter analyze
- 新規 error/warning **0** ✓
- 既存 RadioListTile の `groupValue` deprecated warning 6 件は触っていないコード

---

## Phase D: Sim 動作確認

### 環境
- Simulator: iPhone 17 / iOS 26.4
- ログインユーザー: test@dog-hub.shop（email/password）
- アプリ: 1.1.0 (33) Build

### 検証フロー
| # | 確認内容 | エビデンス | 判定 |
|---|---|---|---|
| 1 | アプリ起動 → ホーム表示 | 01_launch.png | 🟢 |
| 2 | プロフィールタブ遷移 | 02_profile_tab.png | 🟢 |
| 3 | プロフィール下部スクロール → 「設定」メニュー表示 | 03_profile_scrolled.png | 🟢 |
| 4 | 設定画面 → 「アカウントを削除」項目（赤強調・ゴミ箱アイコン）| 04_settings.png | 🟢 |
| 5 | Step 1: 削除データ 5 項目リスト + 警告ボックス + 2 ボタン | 05_step1.png | 🟢 |
| 6 | Step 1 → Step 2 遷移（「続行する」タップ）| 06_step2.png | 🟢 |
| 7 | email ユーザー判定: 「パスワードを入力してください」表示 | 06_step2.png | 🟢 |
| 8 | パスワード入力でボタン enable | 07_step2_with_password.png | 🟢 |
| 9 | 間違った PW 送信 → エラー表示「パスワードが正しくありません。」| 09_step2_error_displayed.png | 🟢 |
| 10 | retry 可能（ボタン引き続き enable・キャンセル可）| 09_step2_error_displayed.png | 🟢 |

### 実削除フロー（Step 3 → LoginScreen redirect）
- **本検証では Sim 上では実行せず**。理由: test@dog-hub.shop を消すと後続 Sim 検証ができなくなる。CEO B 案（推奨）で「間違った PW でエラー表示のみ確認 + Phase B 疎通テストで実削除担保」を採用。
- Phase B 疎通で `auth_deleted=true` + DB 0 件確認済 → 実削除コードパス担保

---

## 教訓 #55 順守（Review Notes 文言と実装の完全一致）

- privacy_policy_screen.dart:142 「設定 → アカウントを削除」 ✓ 完全一致
- help_screen.dart:79 「アカウント削除」→「アカウントを削除」へ修正 ✓ 完全一致
- Review Notes の `Settings → "アカウントを削除"` も実装と完全一致

---

## 残作業（day 21 完遂に向けて）

### Phase E: Build 34 提出（30-45 分）
- pubspec.yaml 1.1.0+33 → 1.1.0+34 bump
- `flutter build ipa --release --obfuscate --split-debug-info=build/symbols`
- altool upload + sentry-cli debug-files upload + dart run sentry_dart_plugin
- symbols 保管 + commit + push

### 並行: apple-review@ アカウント seed
- F0_apple_review_account_seed.md §2-3 順次実行
- CEO 並走: DNS dog-hub.shop 受信可否確認

### スクショ 8 枚撮影 + 加工（CEO 主導）
- F0_app_store_submission_checklist.md §4-2 参照

---

## エビデンスファイル一覧
- 01_launch.png — アプリ起動 / ホーム表示
- 02_profile_tab.png — プロフィールタブ上部
- 03_profile_scrolled.png — スクロール後「設定」メニュー表示
- 04_settings.png — 設定画面「アカウントを削除」項目表示
- 05_step1.png — 削除画面 Step 1（説明 + 同意）
- 06_step2.png — Step 2 初期表示（パスワード入力欄空・ボタン disabled）
- 07_step2_with_password.png — パスワード入力後ボタン enable
- 08_step2_wrong_password_error.png — 1回目タップ（座標ズレで空打ち）
- 09_step2_error_displayed.png — 2回目タップ → エラー「パスワードが正しくありません。」

---

## commit / push

- commit `091d4f4` — Phase A-C 実装（Edge Function + Flutter UI）
- push 済（origin/main）
