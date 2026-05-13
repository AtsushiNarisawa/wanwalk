# W3 day 9 STEP 2 REPORT — A3 §7.5 Sentry 検知テスト（2026-05-13）

W3 day 8 で §7.5 を「DSN 未設定のため送り」と報告した直後、同日中に STEP 2 として **Vault → `.env` → debug build → throw → Sentry envelope 送信** までを Simulator で完遂。**A3 §7.5 #1（debug build で throw → Sentry 受信）パイプラインの本稼働を確認**。

## 完遂サマリー

### 🟢 達成項目

| 項目 | 状態 | エビデンス |
|---|---|---|
| Vault から `SENTRY_DSN` 取得（W2 §D で格納済） | ✅ | `mcp__supabase-wanwalk__execute_sql` で `vault.decrypted_secrets` 参照 |
| `wanwalk-app/.env` に `SENTRY_DSN` 追記（gitignored） | ✅ | `.env` に 1 行追加・`.gitignore` 既存設定で除外確認済 |
| debug ビルドで SentryFlutter.init 成功 | ✅ | `sentry_init_and_envelope_log.txt` の `Starting SDK...` + `dsn:` + `environment: debug` + `releaseName: wanwalk@1.1.0+1` |
| 起動直後の自動エンベロープ 2 件送信（session start + transaction） | ✅ | Sentry SDK 自動送信。URL = `https://o4511375064629248.ingest.us.sentry.io/api/4511375077146624/envelope/` |
| **5 秒後の `ErrorHandler.recordNonFatal(Exception('A3 §7.5 verification...'))` 発火 → Sentry へ送信** | ✅ | `Writing envelope to path: ...1778639488.203162-00002...` + `Constructed request: ...envelope/` + `Deleting envelope and sending next.` |
| 例外発火後もアプリ正常動作（クラッシュなし） | ✅ | `sentry_app_alive_after_throw.png`（onboarding 表示） |
| 一時 throw トリガー削除 + クリーンリビルド + analyze 0 新規警告 | ✅ | `git diff lib/main.dart` 空・analyze 7 warnings（既存のみ） |

### 🟡 残：CEO 受信確認待ち

| 項目 | 必要な確認 |
|---|---|
| Sentry dashboard で event 受信確認 | https://wanwalk.sentry.io/issues/?project=4511375077146624 にログイン → 「A3 §7.5 verification — W3 day 9 — please ignore」イベントが存在することを確認 |
| 個人情報マスキング（email / GPS）が beforeSend で除外される確認（§7.5 #5） | event の `user.email` が空文字列で `geo` 等が含まれないことを Sentry dashboard で確認 |
| Slack 通知 5 分以内（§7.5 #4） | `#wanwalk-alerts` チャンネルが未作成のため別タスク（Sentry → Slack Integration の設定） |
| リリースビルド + TestFlight で同上（§7.5 #2） | Build 30 提出時に `environment: production` で再検証 |
| オフライン → flush（§7.5 #3） | Sim 切断手段が限定的なため実機 / Network Link Conditioner で実施 |

## 実施手順

### 1. DSN 取得（MCP 経由）

```sql
SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SENTRY_DSN';
-- → https://***REDACTED-DSN-KEY***@o4511375064629248.ingest.us.sentry.io/4511375077146624
```

### 2. `.env` に追記

```bash
printf '\n# Sentry (A3 §7.5 detection test enable)\nSENTRY_DSN=...\n' >> .env
# .gitignore で .env は除外済
```

### 3. main.dart に一時 throw トリガー追加（appRunner 内）

```dart
appRunner: () async {
  await ErrorHandler.markSentryReady();
  runApp(const ProviderScope(child: WanWalkApp()));
  // TODO(W3 day 9 §7.5 verification — REMOVE after CEO confirms receipt):
  Future.delayed(const Duration(seconds: 5), () {
    ErrorHandler.recordNonFatal(
      Exception('A3 §7.5 verification — W3 day 9 — please ignore'),
      stack: StackTrace.current,
      extra: {'phase': 'a3_7_5_smoke', 'day': 'W3 day 9'},
    );
  });
},
```

### 4. ビルド + 起動 + console-pty で 12 秒ストリーム

```bash
flutter build ios --simulator --no-codesign
xcrun simctl uninstall booted com.doghub.wanwalk
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch --console-pty booted com.doghub.wanwalk &
sleep 12 && kill $!
```

### 5. ログから確認した重要行

| timestamp | event |
|---|---|
| `1778639482.9904032` | `[Sentry] Starting SDK...` |
| `1778639482.991025` | `dsn: https://...`, `environment: debug`, `releaseName: wanwalk@1.1.0+1`, `sampleRate: 1` |
| `1778639483.065254` | **Envelope #1 書き出し** (session start) |
| `1778639483.728390` | **Envelope #2 書き出し** (transaction) |
| `1778639483.8373718` | Envelope #2 送信 → 削除 |
| `1778639488.203162` | **🎯 Envelope #3 書き出し**（≈ 5.2 秒後 = 我々の throw タイミングと一致） |
| `1778639488.204427` | **🎯 Envelope #3 が `https://o4511375064629248.ingest.us.sentry.io/api/4511375077146624/envelope/` に POST** |
| `1778639488.30107` | **🎯 Envelope #3 送信 → 削除（HTTP 受信成功）** |

→ **Sentry 受信パイプラインが本稼働している証拠**。HTTP リクエストの確実な成功は Sentry dashboard で event_id を直接確認することで最終確定（CEO 作業）。

### 6. 一時 throw トリガーをロールバック

```diff
-          appRunner: () async {
-            await ErrorHandler.markSentryReady();
-            runApp(const ProviderScope(child: WanWalkApp()));
-            // TODO(W3 day 9 §7.5 verification — REMOVE after CEO confirms receipt):
-            // Fire a non-fatal test exception 5s after launch to verify A3
-            // capture pipeline reaches Sentry. ErrorHandler.recordNonFatal()
-            // routes through Sentry.captureException with hint='manual'.
-            Future.delayed(const Duration(seconds: 5), () {
-              ErrorHandler.recordNonFatal(
-                Exception('A3 §7.5 verification — W3 day 9 — please ignore'),
-                stack: StackTrace.current,
-                extra: {'phase': 'a3_7_5_smoke', 'day': 'W3 day 9'},
-              );
-            });
-          },
+          appRunner: () async {
+            await ErrorHandler.markSentryReady();
+            runApp(const ProviderScope(child: WanWalkApp()));
+          },
```

`git diff lib/main.dart` → 空（リバート完全）。

### 7. クリーンリビルド + analyze

- `flutter build ios --simulator --no-codesign` exit 0（16 秒）
- `flutter analyze`: **319 issues / error 0 / 新規 warning 0**（既存 7 件のみ・day 7 以前から）

## SDK / 統合の確認事項

ログから確認できた SentryFlutter（sentry-cocoa 経由）の自動有効化:

- `enableCrashHandler: 1` — ネイティブクラッシュ収集
- `enableNetworkBreadcrumbs: 1` — URLSession breadcrumbs
- `enableAutoSessionTracking: 1` — セッション追跡
- `enableSwizzling: 1` — UIViewController トラッキング
- Integrations: SentrySessionReplayIntegration, SentryCrashIntegration, SentryAppStartTrackingIntegration, SentryFramesTrackingIntegration, SentryANRTrackingIntegration ほか 19 統合がアクティブ

## エビデンスファイル

- `sentry_init_and_envelope_log.txt` — SDK 初期化 + 3 件 envelope 送信ログ
- `sentry_app_alive_after_throw.png` — throw 後もアプリが onboarding を正常表示

## CEO 引き渡しタスク

### 必須（公開ブロッカー候補）

1. **Sentry dashboard 受信確認** — https://wanwalk.sentry.io/issues/?project=4511375077146624 にログイン
   - **検索クエリ**: `message:"A3 §7.5 verification"` または `release:wanwalk@1.1.0+1 environment:debug` で絞り込み
   - event がある → A3 §7.5 #1 **PASS 確定**
   - event がない → DSN タイポ / プロジェクト ID 不一致 → CTO に通知

2. **PII マスキング確認**（§7.5 #5）
   - 上記 event を開いて `user`, `extra` フィールドに email / GPS 座標 / 写真パス本体が **含まれていない** ことを確認

3. **Sentry Alert Rule 設定**（W2 §D 残課題）
   - Project Settings > Alerts > Create Alert
   - Condition: `affected_users` >= 5（A3 §1.1 仕様）
   - Action: Email + Slack（`#wanwalk-alerts` 作成後）

### 推奨

4. Sentry Trial → Developer Free Plan ダウングレード（W2 §D 残課題）

## 残作業 / 次の独立タスク

### 🟠 W4 / 公開前
- **Vault → CI / build-time `.env` 注入の仕組み確立**（現状は手動 `.env` 追記。チームに共有可能な再現フロー化）
- **Sentry → Slack Integration**（`#wanwalk-alerts` チャンネル作成 + Webhook）
- **シンボルマップ アップロード**（release ビルドの難読化対応・`flutter build ios --obfuscate --split-debug-info=./symbols/`）
- §7.5 残 4 項目（#2 リリース・#3 オフライン flush・#4 Slack 5 分・#5 PII マスキング自動検証）

### 🔵 CEO
- 上記「CEO 引き渡しタスク」3 件

## 参照

- W2 §D Sentry: `project_w2_runbook_resources_2026_05_19.md`（DSN Vault `secret f4e26e31`）
- A3 設計書: `docs/mvp_specs/A3_crash_zero.md` v1.3 §5.3, §7.5
- W3 day 7 A3 実装: `project_w3_day7_2026_05_13.md`（main.dart wrap 順序）
- W3 day 8 §7.1: `project_w3_day8_2026_05_13.md`
- W3 day 9 §7.2: `REPORT_chaos.md`（同 evidence ディレクトリ）
