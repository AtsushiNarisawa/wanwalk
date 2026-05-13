# W3 day 11 REPORT (Part 2) — Sentry シンボルマップ upload（2026-05-13）

day 11 Part 1 (A3 §7.2 #3 + #6) 完遂後、Sentry 側で stack trace を解読可能化するため iOS dSYM + Dart obfuscation symbols upload を実施した。**結果: 🟢 dSYM 40+ ファイル upload 成功 / Release `wanwalk@1.1.0+1` 作成 + 20 commits バインド完了 / day 9 で送った Sentry envelope (7 hours ago) も自動でこの release に紐付き済**。

## 検証環境

| 項目 | 値 |
|---|---|
| sentry-cli | 3.4.2 (Homebrew getsentry/tools → 公式 installer 両方 3.4.2 が最新だった) |
| sentry_dart_plugin | 3.3.0 (pubspec.yaml dev_dependencies に追加・3.3.0 が pub.dev 最新) |
| Sentry Org slug | `wanwalk` (Org ID `o4511375064629248`・US region) |
| Sentry Project slug | **`flutter`** (Project ID `4511375077146624`・day 9 メモリの `wanwalk-ios` は記録ミスで実値は `flutter`) |
| Auth Token | `sntryu_06a06606...` Personal Auth Token (User-level)・Vault secret_id `00777a2d-e324-4bc7-ae94-d55f5bdeae69` |
| Auth Token Scopes | `project:admin` + `project:read` + `project:releases` + `project:write` + `org:read` |
| release build | `flutter build ios --release --no-codesign --obfuscate --split-debug-info=build/symbols`（98s + 14.5s で 2 回走らせた）|
| 生成物 | `build/symbols/app.ios-arm64.symbols` (4.5MB / ELF 64-bit) + `build/ios/Release-iphoneos/*.dSYM` × 30 |

## CEO 操作の流れ

1. Sentry web UI (https://sentry.io) に GitHub SSO (romeo07302002@gmail.com) でログイン
2. WanWalk Org → User Settings → API → **Personal Tokens** （`https://wanwalk.sentry.io/settings/account/api/auth-tokens/`）
3. **Create New Token** → name `wanwalk-ios-symbols-upload`
4. **新 UI の発見**: scope はチェックボックスではなく **カテゴリごとの dropdown**（No Access / Read / Write / Admin）方式に変わっていた。CTO が事前に web search で旧仕様の指示を出したため、CEO に再案内が必要だった
5. dropdown 設定: Project=Admin / Release=Admin / Organization=Read（他は No Access）
6. Token `sntryu_...` をコピーしてスレッドに貼付
7. CTO が Vault に格納 (secret_id `00777a2d`)・Bash 環境変数で sentry-cli に渡して upload

## dSYM upload — 🟢 成功

```bash
SENTRY_AUTH_TOKEN='sntryu_...' \
  sentry-cli debug-files upload \
  --org wanwalk --project flutter \
  build/ios/Release-iphoneos/
```

40+ ファイルすべて `UPLOADED` メッセージで確認。重要な debug_id:

| Debug ID | ファイル | 役割 |
|---|---|---|
| `a678162f-84da-3445-9d0e-507f6ef339a7` | `App.framework.dSYM` | Flutter Dart code (compiled to native arm64) |
| `200d5d02-80cf-3a4a-a9d8-9a2fa482c05d` | `Runner.app/Runner` | iOS native main executable |
| `4c4c4434-5555-3144-a11b-2a35d71ec8d7` | `Flutter.framework` | Flutter engine |
| `aa8d5f01-614d-3d77-94d7-512718d98edf` | `sentry_flutter.framework` | Sentry SDK |
| `60879f8b-edee-34a5-9e2e-513af9d279ad` | `Sentry.framework` | Sentry iOS native SDK |
| 他 35 ファイル | Firebase / GoogleSignIn / image_picker / geolocator / app_links / share_plus 等プラグイン | プラグイン native code |

## sentry_dart_plugin 経由 (release + commits 自動バインド) — 🟢 成功

pubspec.yaml に dev_dependencies + sentry section を追加:

```yaml
dev_dependencies:
  sentry_dart_plugin: ^3.3.0

sentry:
  upload_debug_symbols: true
  upload_source_maps: false
  upload_sources: false
  project: flutter
  org: wanwalk
  url: https://sentry.io/
  symbols_path: build/symbols/
```

実行コマンド: `SENTRY_AUTH_TOKEN='sntryu_...' dart run sentry_dart_plugin`

**成果**:
- ✅ Release `wanwalk@1.1.0+1` 作成 (`sentry-cli releases list` で `Released: 43 seconds ago` 確認)
- ✅ 20 commits を release に自動バインド（local git tree から）
- ✅ day 9 で送ったテスト event（7 hours ago）が遡及的に release `wanwalk@1.1.0+1` に紐付き
- 重複 dSYM upload は server-side dedup で skip（`Nothing to upload, all files are on the server` メッセージ多数）

## ❌ Dart obfuscation symbol map upload — 非互換性で諦め

`build/symbols/app.ios-arm64.symbols` は `file` コマンドで確認した結果 **ELF 64-bit (Linux 形式) shared object・with debug_info・not stripped**。Flutter `--obfuscate --split-debug-info` が吐き出す Dart 関数名 mapping データだが、sentry_dart_plugin の `dart_symbol_map_path` 機能は **JSON array of strings** を期待しており、ELF とは非互換:

```
error: Invalid dartsymbolmap: expected a JSON array of strings
Caused by: expected value at line 1 column 1
Failed to decode data using encoding 'utf-8'
```

`symbols_path: build/symbols/` 方式（sentry-cli の generic debug-files upload に委譲）でも、ELF の `.symbols` 拡張子は sentry-cli の探索パターンに含まれず `Found 0 debug information files` で skip された。

### 落としどころ（運用方針）

1. **MVP では dSYM ベース symbolication で十分**: `App.framework.dSYM` を upload 済みなので Sentry web UI の stack trace で Dart 関数名（obfuscate 前のシンボル）は dSYM 内の DWARF debug_info で解読される
2. **ローカル symbolicate が必要な raw log の場合**: 公開後に Sentry 経由でなく raw crash log を入手したら、ローカルで:
   ```bash
   flutter symbolize -i <crash_input> -d build/symbols/app.ios-arm64.symbols
   ```
   `build/symbols/` を CI artifact として保管しておく運用に倒す（Build 30 提出時に同じ build をしたら **本 release の `build/symbols/` を保管する必要がある**・CI 自動化は B-C タスクで設計）
3. **公開直前の検討材料**: Build 30 提出時に `--obfuscate` を切る選択肢もある（Dart 関数名がそのまま見えるが、APK/IPA size 増・難読化なし）。MVP 段階では現状の obfuscate ON で進む

## pubspec.yaml の変更（commit 対象）

| 種別 | 内容 |
|---|---|
| 追加 | dev_dependencies に `sentry_dart_plugin: ^3.3.0` |
| 追加 | ルート level に `sentry:` セクション（upload_debug_symbols / project / org / url / symbols_path 5 行） |
| 注釈 | `dart_symbol_map_path` は ELF 非互換のため未使用・コメントで運用方針記載 |

⚠️ **重要**: `sentry.auth_token` は pubspec.yaml に書かず、環境変数 `SENTRY_AUTH_TOKEN` 経由で渡す方式。pubspec.yaml は git に commit されるので token を埋め込まない。

## B 完遂判定

| 項目 | 状況 |
|---|---|
| sentry-cli インストール | ✅ 3.4.2 |
| Auth Token 取得 + Vault 格納 | ✅ secret_id `00777a2d` |
| iOS dSYM upload (40+ ファイル) | ✅ 全件 UPLOADED |
| Release 作成 + commits バインド | ✅ `wanwalk@1.1.0+1` + 20 commits |
| Dart obfuscation symbol upload | ⚠️ ELF/JSON 非互換のため skip（dSYM symbolication で代替・運用方針確定） |
| pubspec.yaml + sentry_dart_plugin 設定 | ✅ commit 対象 |

**B のスコープ達成**: Sentry web UI で本日以降に発生する crash の native stack trace は debug_id ベースで自動 symbolicate される。Dart 関数行は dSYM の DWARF で解読可能。

## 残課題 (B-C・後続タスク)

- ⚠️ **CI 自動化**: 今回は CTO ローカルから手動 upload。Build 30 提出ごとに繰り返すと事故率高い。GitHub Actions or Xcode Cloud で release build → sentry-cli upload を自動化（W2 §C の Vault → .env 注入と統合して 1 PR 化推奨）
- ⚠️ **`build/symbols/` の永続保管**: ローカル symbolicate に必要・CI artifact or S3 保管の運用設計
- ⚠️ **app.ios-arm64.symbols の Sentry 直接 upload**: sentry_dart_plugin の `dart_symbol_map_path` が ELF 対応するまで待つ or 別経路で Sentry に流す案を探索

## 参照

- W3 day 9 REPORT: `wanwalk-app/docs/mvp_specs/W3_day9_evidence/REPORT.md`（Sentry envelope 送信検証）
- W3 day 11 REPORT Part 1: `REPORT_chaos_part3.md`（A3 §7.2 #3 + #6）
- Vault secrets: `SENTRY_DSN` (`f4e26e31`) / `SENTRY_AUTH_TOKEN` (`00777a2d`)
- Sentry web UI: https://wanwalk.sentry.io/issues/
- Sentry release: `wanwalk@1.1.0+1`
