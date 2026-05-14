# F0 §6-1 apple-review@ アカウント seed 設計書 v1.0

**作成日**: 2026-05-15（W3 day 20）
**実施予定日**: 2026-05-17（W3 day 21）
**所要見積**: 30-45 分（CEO 並走パート 5 分 / CTO 単独パート 25-40 分）
**参照元**: [F0_app_store_submission_checklist.md §6-1](F0_app_store_submission_checklist.md#6-1-sign-in-information審査用テストアカウント)

---

## 0. このドキュメントの目的

App Store Review チームが審査時に実機ログインするためのテストアカウントを **day 21 中に作成し、Vault と F0 §6-1 に反映する** ための手順書。Review Notes で約束した「pre-loaded with one dog profile and one past walk record」の seed データ仕様も本書で確定する。

**day 20 で本書のみ作成 → day 21 で実装** という分業構造。

---

## 1. CEO 事前確認（day 20 中・5 分）

day 21 着手前に CEO に以下を確認する。すべて YES でなければ day 21 で stuck する。

- [ ] **DNS / メール受信**: `apple-review@dog-hub.shop` 宛のメールが現状受信可能か（Google Workspace のエイリアス or キャッチオール設定済みか）
  - 受信不可なら: ① Google Workspace で alias 作成（CEO admin 操作・5 分） ② Supabase Auth の Email confirmation を **off** にしてバイパス
  - **推奨は ②**（Apple Review はメール認証フローを通らない・確認メール送信は不要）
- [ ] **公開後の扱い**: apple-review@ アカウントは **公開後も削除しない**（次回審査・OS バージョン更新審査で同じアカウントを再利用するため）
- [ ] **データ完全性**: Apple Review が実機で「アカウント削除」を実行した場合 → アカウントは消える。**day 21 の seed スクリプトを冪等化** し、Vault に「再 seed コマンド」を残す（CEO 再発行不要）

---

## 2. アカウント作成手順（CTO 単独・day 21 morning）

### 2-1. Supabase Auth ユーザー作成

**方法 A: Dashboard 経由（推奨・5 分）**

1. https://supabase.com/dashboard/project/jkpenklhrlbctebkpvax/auth/users → "Add user" → "Create new user"
2. Email: `apple-review@dog-hub.shop`
3. Password: 後述 §3 の生成方針で発行
4. ☑ **Auto Confirm User**（メール認証バイパス・Email verify off 相当）
5. "Create user" → 作成された UUID をメモ（以下 `$REVIEW_UID`）

**方法 B: SQL 経由（CI 化したい場合・参考）**

```sql
-- 注: Supabase Auth は SQL から直接 auth.users INSERT は非推奨。
-- 必ず Dashboard or Admin API (supabase-js admin client) 経由で作成すること。
-- 本書では Dashboard 方式を採用。
```

### 2-2. プロフィール初期化

Dashboard で UUID を確認した後、SQL Editor で以下を実行（**冪等・再実行 OK**）:

```sql
-- $REVIEW_UID を実際の UUID に置換してから実行
DO $$
DECLARE
  v_uid uuid := '$REVIEW_UID';
  v_dog_id uuid;
  v_route_id uuid;
  v_walk_id uuid;
BEGIN
  -- profiles upsert
  INSERT INTO profiles (id, display_name, avatar_url, created_at)
  VALUES (v_uid, 'Apple Reviewer', NULL, now())
  ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name;

  -- 既存の dog があれば再作成しない
  SELECT id INTO v_dog_id FROM dogs WHERE owner_id = v_uid LIMIT 1;
  IF v_dog_id IS NULL THEN
    INSERT INTO dogs (owner_id, name, breed, birth_date, created_at)
    VALUES (v_uid, 'Apple', '柴犬', '2022-04-01', now())
    RETURNING id INTO v_dog_id;
  END IF;

  -- seed 用 walk が無ければ作る（公式ルート「鎌倉 由比ヶ浜」を選択）
  SELECT id INTO v_route_id FROM official_routes WHERE slug = 'kamakura-yuigahama' LIMIT 1;
  SELECT id INTO v_walk_id FROM walks WHERE user_id = v_uid LIMIT 1;
  IF v_walk_id IS NULL THEN
    INSERT INTO walks (
      user_id, dog_id, route_id, walk_type,
      started_at, ended_at, distance_meters, duration_seconds,
      created_at
    )
    VALUES (
      v_uid, v_dog_id, v_route_id, 'outing',
      now() - interval '2 days', now() - interval '2 days' + interval '45 minutes',
      3700, 2700,
      now() - interval '2 days'
    );
  END IF;

  -- 通知設定 OFF（Review が誤って通知許可しないように・任意）
  INSERT INTO notification_preferences (user_id, push_enabled, mode, updated_at)
  VALUES (v_uid, false, 'off', now())
  ON CONFLICT (user_id) DO UPDATE SET push_enabled = false, mode = 'off';
END $$;
```

**🟡 day 21 着手時の確認**:
- [ ] `dogs` テーブルのカラム名（`birth_date` / `birthdate` / `dob` のいずれか）
- [ ] `walks.walk_type` の有効値（`'outing'` / `'daily'`）
- [ ] `notification_preferences` テーブル存在 + `mode` カラムの enum 値
- [ ] `official_routes.slug = 'kamakura-yuigahama'` が公開済みか

実行前に `wanwalk-data-reporter` エージェントで上記 4 点を確認 → SQL 微修正。

### 2-3. 確認手順

1. iOS Simulator で Build 33 を起動 → サインイン
2. ホーム → 犬「Apple」が表示されること
3. ライブラリ → 散歩記録 1 件が表示されること
4. ルート詳細 → 体験ストーリー含めて表示されること
5. 設定 → 「アカウントを削除」項目が表示されること（**day 21 の B 作業で実装される予定**）

---

## 3. パスワード生成方針

### 3-1. 要件
- **12 文字以上**（Apple 推奨）
- **英大文字 + 英小文字 + 数字 + 記号** 4 種混在
- **辞書語回避**
- **`@`, `"`, `\`, スペース** は審査担当者のコピペ事故を考慮して除外

### 3-2. 生成コマンド（CTO ローカル）

```bash
# macOS: 16 文字・英大小数字 + 記号 (- _ ! # $ %) のみ
LC_ALL=C tr -dc 'A-Za-z0-9-_!#$%' </dev/urandom | head -c 16
echo
```

出力例（実物は別途）: `Wk7-Pq3$Mv9_Hx2N` の形式

### 3-3. Vault 格納

```sql
-- パスワードを Vault に格納（key 名は他の secret と統一）
SELECT vault.create_secret(
  '<生成したパスワード>',
  'APPLE_REVIEW_ACCOUNT_PASSWORD',
  'App Store Review (apple-review@dog-hub.shop) のログインパスワード。day 21 (2026-05-17) 発行。次回ローテーション: 公開後 6 ヶ月 or アカウント漏洩時。'
);

-- メールアドレスも一緒に格納（CEO 参照用）
SELECT vault.create_secret(
  'apple-review@dog-hub.shop',
  'APPLE_REVIEW_ACCOUNT_EMAIL',
  'App Store Review テストアカウント email。'
);
```

格納後に **secret_id をメモ**（W2 §B と同じ運用）→ 本書末尾 §6 改訂履歴に追記。

### 3-4. ローテーション方針

- **公開直後**: ローテーション不要
- **公開後 6 ヶ月**: 任意でローテーション（Apple は再審査時に必ずログインテストするので、パスワード変更したら App Store Connect §6-1 も即更新）
- **漏洩 / 流出疑い**: 即ローテ + Vault 上書き + App Store Connect §6-1 更新

---

## 4. App Store Connect §6-1 への反映

day 21 完了後、App Store Connect で以下を入力:

| App Store Connect 項目 | 入力値 |
|---|---|
| Sign-in required | ☑ YES |
| User Name | `apple-review@dog-hub.shop` |
| Password | `<Vault APPLE_REVIEW_ACCOUNT_PASSWORD>` |
| Notes | （§6-3 Review Notes 全文を貼り付け） |

---

## 5. day 21 タスクチェックリスト

CTO は day 21 着手時に本書を再読 + 以下を順番に実施:

- [ ] §1 CEO 事前確認 3 項目を再確認（YES でなければ stuck・CEO へ ping）
- [ ] §2-1 Supabase Dashboard で Auth ユーザー作成・Auto Confirm User ☑ ・UUID メモ
- [ ] §2-2 着手前に `dogs` / `walks` / `notification_preferences` のスキーマ確認 4 点（wanwalk-data-reporter）
- [ ] §2-2 SQL 実行 → エラーが出たらカラム名修正して再実行（冪等なので OK）
- [ ] §2-3 Simulator で実機確認 5 項目（アカウント削除項目は B 作業完了後に再確認）
- [ ] §3-2 パスワード生成 + メモ
- [ ] §3-3 Vault に 2 件格納（password + email）
- [ ] §6 本書改訂履歴に「day 21 実施完了・secret_id 〇〇」追記 + commit
- [ ] App Store Connect §6-1 に email + password 入力（CEO 操作 or CTO 操作）

---

## 6. 改訂履歴

| 日付 | 版 | 内容 | 担当 |
|---|---|---|---|
| 2026-05-15 | v1.0 | 初版作成（W3 day 20） | CTO |
| 2026-05-17 | v1.1 予定 | day 21 実施完了 + secret_id 記録 + UUID 記録 | CTO |

---

## 7. 参照

- [F0 App Store 審査申請チェックリスト v1](F0_app_store_submission_checklist.md)
- [F0 アカウント削除実装設計書 v1.0](F0_account_deletion_design.md) ← day 21 で並行実装
- App Store Review Guideline 5.1.1(v): https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage
- App Store Review Guideline 2.3.4 (Demo Account): https://developer.apple.com/app-store/review/guidelines/#performance
