# W3 day 6 REPORT — 公開ブロッカー 4 件すべて完遂（2026-05-13）

W3 day 5 で plist 配置 + A3 軽井沢クラッシュ修正 + B2 Flutter 5 ファイル完遂を受けて、Supabase Edge Function 側の公開ブロッカー級 4 件をすべて完遂した。FCM HTTP v1 + OAuth2 経路全体の疎通検証も成功。

## 完遂サマリー

### 🟢 1. B1 Edge Function `send_push` 実装（3 ファイル）

- `supabase/functions/send_push/index.ts` — 275 lines
  - verify_jwt: true（service_role JWT 必須）
  - preferences チェック（カテゴリ ON + quiet_hours）+ override_preferences 対応
  - device_tokens 取得 → FCM 並列送信 → notification_log INSERT → invalid_registration revoke
- `supabase/functions/send_push/fcm_client.ts` — 184 lines
  - Web Crypto API (RSASSA-PKCS1-v1_5) で SA JSON の private_key を読んで JWT 署名
  - Google OAuth2 endpoint で access_token 交換 → /v1/projects/{id}/messages:send
  - 教訓: google-auth-library は Deno 互換性が不安定なため自前実装に倒した
  - access_token を in-memory cache（cold start ごと再取得）
  - UNREGISTERED / INVALID_ARGUMENT / 404 を invalid token として判定
- `supabase/functions/send_push/deno.json` — import map

**MCP deploy_edge_function 経由でデプロイ成功** (status=ACTIVE, version=1, ezbr_sha256=d4a902188d0585afdb3c2f45a6245ff392b710e7507ae201ae59fd556710424f)

### 🟢 2. B2 Edge Function `cron_morning_reminder` 実装（4 ファイル + deno.json）

- `index.ts` (300 lines) — メイン処理
  - GET / POST 両対応（GET = dry-run mode・x-dry-run header でも切替可）
  - 天気取得 → scenery_enabled 取得 → season 判定 → targets ループ → scenario → template → send_push
  - 重複送信防止: alreadySentToday で JST 当日 0:00 以降の log を head-only count
  - 起動遅延 5 分許容の 1 時間窓判定 (`[now - 5min, now + 60min)`)
  - send_push へは fetch で内部呼び出し（SUPABASE_URL + SERVICE_ROLE_KEY を EF env から取得）
- `sunrise.ts` (147 lines) — NOAA Solar 簡易版・東京 (35.6762, 139.6503) 固定
  - Flutter 側 `lib/utils/sunrise_calculator.dart` と挙動を揃えた（誤差 ±1 分以内）
  - `jstDateString()` / `jstNow()` で JST 日付/時刻ヘルパ
- `scenario_picker.ts` (52 lines) — 優先度: hot/cold > rainy > scenery > weekend/weekday > sunny
  - weather=null（API 失敗）の場合は天気軸スキップして scenery 以降の判定に進む
- `weather_client.ts` (85 lines) — OpenWeatherMap One Call API 3.0 + b2_weather_cache UPSERT
  - JST 当日キャッシュヒット時は API 呼ばずに即返却

**MCP deploy_edge_function 経由でデプロイ成功** (status=ACTIVE, version=1, ezbr_sha256=4611f69a444e636072c36cee5527afcb9aa064b7cb3f116f194ae94c01de1c21)

### 🟢 3. pg_cron スケジュール登録（active=false）

```sql
DO $$
DECLARE v_jobid bigint;
BEGIN
  PERFORM cron.unschedule(jobid) FROM cron.job WHERE jobname = 'morning-reminder-hourly';
  v_jobid := cron.schedule(
    'morning-reminder-hourly',
    '0 * * * *',
    $job$ SELECT net.http_post(
      url := 'https://jkpenklhrlbctebkpvax.supabase.co/functions/v1/cron_morning_reminder',
      headers := jsonb_build_object('Authorization', 'Bearer <ANON_KEY>', 'Content-Type', 'application/json'),
      body := '{}'::jsonb
    ) AS request_id; $job$
  );
  PERFORM cron.alter_job(job_id := v_jobid, active := false);
END $$;
```

検証: `SELECT * FROM cron.job` で `jobid=2, jobname='morning-reminder-hourly', schedule='0 * * * *', active=false` 確認。

#### 設計判断ログ
- **教訓 #45 cron.job 直接 UPDATE 不可**: `UPDATE cron.job SET active=false` は permission denied。`cron.alter_job(job_id, active=false)` RPC 経由が必須
- **教訓 #46 anon key で EF 発火**: service_role を vault に格納する代わりに、anon key（公開鍵）で発火・EF 内部で service_role に切替。Supabase の標準パターン。anon key は Flutter/web の全 frontend に既に埋め込まれているため秘匿不要
- **MVP 期間中は active=false**: 実ユーザー 0 名のため毎時起動は無駄。テスター配信開始 W5 月で `SELECT cron.alter_job((SELECT jobid FROM cron.job WHERE jobname='morning-reminder-hourly'), active := true);` で切替

### 🟢 4. EF Secrets 転送 2 件（Vault → EF env）

CEO 承認フロー: MCP execute_sql で Vault から取得 → /tmp/wanwalk_efenv.env（chmod 600）→ `supabase secrets set --env-file` → 即削除。

#### 投入結果
```
NAME                      | DIGEST (sha256)
FCM_SERVICE_ACCOUNT_JSON  | 6922ee2a961bd4d3a8331cba7a89372860f02fe9058b7fe17f4fc1c7eda9519d
OPENWEATHERMAP_API_KEY    | 59ca8f8cc05c39dd3ec7df231d4ee30373503e5f569cc0c1eed054d16213b00d
```
※ SENTRY_DSN は EF Sentry 報告を MVP 不採用とした CEO 判断により転送不要

#### 教訓 #47 dotenv multi-line JSON
- FCM_SERVICE_ACCOUNT_JSON は外側 JSON 整形改行を含む 2375 bytes
- `replace(replace(value, chr(13), ''), chr(10), '')` で外側改行のみ除去（private_key 内部の `\n` リテラル 2 文字は保持）
- single-quote で囲んで env file に書く（godotenv の single-quote は escape sequence 解釈しない）
- EF runtime で `Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')` → `JSON.parse(rawJson)` → `private_key` 内 `\n` 2 文字が PEM newline に変換される正常パス

## 疎通検証 6 ケース（全 PASS）

| # | テスト | リクエスト | レスポンス | 期待 | 結果 |
|---|---|---|---|---|---|
| 1 | cron dry-run | GET /cron_morning_reminder | `{stats:{total_targets:0, season:"spring", scenery_enabled:false, weather_available:true, jst_now:"2026-05-13 08:22"}}` | 200 + weather OK | ✅ PASS |
| 2 | invalid_category | POST {category:"bogus"} | `{"error":"invalid_category"}` 400 | 400 | ✅ PASS |
| 3 | no device_tokens | POST 実 user_id + 0 device_tokens | `{sent:0, failed:0, skipped:0, detail:{reason:"no_active_tokens"}}` 200 | 200 + skipped | ✅ PASS |
| 4 | missing user_id | POST without user_id | `{"error":"user_id_or_user_ids_required"}` 400 | 400 | ✅ PASS |
| 5 | unauthorized | POST without Authorization | `{"code":"UNAUTHORIZED_NO_AUTH_HEADER"}` 401 | 401 | ✅ PASS |
| 6 | FCM full path | POST 実 user + dummy token | `{sent:0, failed:1, skipped:0, revoked:1}` 200 | OAuth2 成功 + reject + log + revoke | ✅ PASS |

### ケース 6 の意義（FCM 経路全体の疎通確認）
1. FCM_SERVICE_ACCOUNT_JSON が EF env から正しく取得できた
2. parseServiceAccount() で JSON.parse 成功（private_key の改行も正常）
3. getAccessToken() で RS256 JWT 署名 → Google OAuth2 token 交換成功
4. sendMessageToToken() が FCM `/v1/projects/wanwalk-prod/messages:send` へ POST
5. FCM が `400 INVALID_ARGUMENT: registration token is not a valid FCM registration token` を返却
6. EF が invalid token と判定（isInvalidToken=true）
7. notification_log に `status='failed', error='400:INVALID_ARGUMENT:...'` 行 INSERT
8. device_tokens.revoked_at にタイムスタンプセット

→ 実 iOS デバイスから `register_device_token` RPC 経由で正規 FCM token を登録すれば、実 push 配信が CEO 端末に届く状態。

## エビデンス

- `01_cron_dry_run.json` — cron_morning_reminder GET レスポンス
- `02_send_push_no_tokens.json` — send_push 正常系（no tokens）レスポンス
- `03_secrets_list.txt` — EF env secrets 9 件（FCM/OWM 含む）のダイジェスト一覧

## 残作業 / 次の W3 day 7+

### 🔴 公開ブロッカー（消化）
- ~~B1 send_push EF~~ ✅
- ~~B2 cron_morning_reminder EF~~ ✅
- ~~pg_cron スケジュール~~ ✅
- ~~EF Secrets 転送~~ ✅

### 🟠 残実装（W3 day 7 〜 W4）
- **A3 Flutter 4 ファイル新規**: `error_handler.dart` / `error_buffer.dart` / `error_fallback_widget.dart` / `report_issue_screen.dart`
- **main.dart wrap 順序強化**: `runZonedGuarded → SentryFlutter.init → DeepLink init → Firebase.initializeApp → runApp`
- **A1 M2-M5**: 「閉じる」リネーム / タブ二度押し / お出かけ散歩ボタン文言 / 難易度バッジコントラスト
- **L1-L8 計 8 件**: マイナー修正

### 🔵 CEO 手動 E2E（Build 30 提出前）
- 実機で `register_device_token` を発火 → CEO 端末に W3 day 6 のテスト通知（curl で title/body 指定）を送ってもらい受信確認
  ```bash
  SVCROLE=<service_role_key>
  CEO_USER_ID=<CEO の auth.users.id>
  curl -s -X POST "https://jkpenklhrlbctebkpvax.supabase.co/functions/v1/send_push" \
    -H "Authorization: Bearer $SVCROLE" \
    -H "Content-Type: application/json" \
    -d "{\"user_id\":\"$CEO_USER_ID\",\"category\":\"morning_reminder\",\"title\":\"WanWalk 疎通\",\"body\":\"W3 day 6 のテスト通知です\"}"
  ```
- 軽井沢フィルター → クラッシュゼロ最終確認（day 3 副次発見 ①）
- 横浜みなとみらいルート 2 分目視（day 3 から継続）

### 🟢 W5 月（テスター配信開始時）
- pg_cron `morning-reminder-hourly` を `active=true` に切替:
  ```sql
  SELECT cron.alter_job(
    (SELECT jobid FROM cron.job WHERE jobname = 'morning-reminder-hourly'),
    active := true
  );
  ```
- W5 月初の日の出計算結果と比較ベンチ取得（5 名連続 7 日間配信ログ取得）

## 副次発見・備忘

### 教訓 #45 cron.job 直接 UPDATE 不可
Supabase managed Postgres では `UPDATE cron.job SET active=...` は `permission denied for table job`。`cron.alter_job(job_id, active=true|false)` RPC（SECURITY DEFINER）経由が必須。

### 教訓 #46 anon key で EF 発火が Supabase 標準
`verify_jwt: true` の EF を pg_cron 経由で呼ぶ際、anon key（公開鍵・全 frontend 埋め込み済）で発火し EF 内部で service_role に切替が Supabase 標準パターン。これにより service_role を vault に追加格納する追加作業が不要になる。

軽微なリスク: 「anon key で誰でも EF を発火できる」が、`cron_morning_reminder` は内部で alreadySentToday + frequency + time_window フィルタにより spam にならない。公開後に DDoS 対策が必要なら Cloudflare WAF / レート制限を追加検討。

### 教訓 #47 dotenv multi-line JSON 投入パターン
- Vault に格納された pretty-printed JSON は外側 `chr(10)` 改行を含む
- SQL の `replace(replace(value, chr(13), ''), chr(10), '')` で外側改行のみ除去（内部 `\n` リテラルは保持）
- single-quote で囲んで `.env` ファイルに 1 行で書く
- `supabase secrets set --env-file` で投入 → EF runtime で `Deno.env.get()` + `JSON.parse()` で復元

### Vault → EF env の最終形（4 回目の値露出について）
本 day 6 では FCM_SERVICE_ACCOUNT_JSON の private_key と anon key が再び Claude コンテキストに露出（W2 §B 教訓 2 回目漏洩で revoke せず継続使用とした同一 key）。CEO 承認内のフローのため新たな漏洩ではない。将来 Phase 3 以降では `psql` 直接ローカル接続でファイル生成（Claude が値を見ない）方式を検討余地あり（DB password の調達がブロッカー）。

## 参照
- W3 day 5: `project_w3_day5_2026_05_13.md`
- W3 day 4: `project_w3_day4_2026_05_12.md`
- W3 day 3: `project_w3_day3_2026_05_12.md`
- W3 day 1: `project_w3_kickoff_2026_05_12.md`
- W2 §B 完遂: `project_w2_section_b_completion_2026_05_12.md`
- B1 設計: `docs/mvp_specs/B1_fcm_push_base.md` v0.5
- B2 設計: `docs/mvp_specs/B2_morning_reminder.md` v0.5
- 実装: `supabase/functions/send_push/` (3 ファイル) + `supabase/functions/cron_morning_reminder/` (5 ファイル)
