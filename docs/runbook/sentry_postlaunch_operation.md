# Sentry 公開後 運用 Runbook v1

**作成日**: 2026-05-15 (W3 day 19)
**対象**: WanWalk iOS app 公開後の Sentry エラー監視・hotfix 運用
**前提**: Build 33 以降の release は `dart run sentry_dart_plugin` で自動 Finalize 済み

---

## 0. この Runbook の使い方

公開後のクラッシュ・エラー監視で「いつ・誰が・何をするか」を即決するための運用書。Sentry ダッシュボードの操作は CTO が中心、Alert 設定と承認は CEO で完結する役割分担にする。

- 公開当日〜公開後 72 時間: 観測リズムは §6
- 通常時の運用: §1 アラート設計 + §4 インシデント対応フロー
- 緊急 hotfix が必要になったら: §5

---

## 1. アラート設計

### 1-1. 設定する Alert Rule（公開直前必須）

Sentry の **Alerts → Create Alert** から **Issue Alert** で作成。組織: `wanwalk` / プロジェクト: `flutter`。

| # | Alert 名 | トリガ条件 | 通知先 | 重要度 |
|---|---|---|---|---|
| A1 | `affected-users-5plus` | When `Number of users affected` is more than `5` in `1h` | Slack #wanwalk-alerts + Email CEO + CTO | 🔴 High |
| A2 | `new-issue-first-seen` | When `A new issue is created` (any) | Email CTO | 🟡 Medium |
| A3 | `crash-rate-spike` | When `Number of events` is more than `50` in `1h` and `level=fatal` | Slack #wanwalk-alerts + Email CEO + CTO | 🔴 High |
| A4 | `release-spike` | When `Issue is unresolved` and `Release` matches current release | Email CTO | 🟡 Medium |

**A1 が最重要**: 「5 人以上に影響している issue」は公開直後の感覚で「広範囲」のシグナル。閾値は公開後 1-2 週間で実測値を見て調整（DAU の 1-2% 目安）。

### 1-2. CEO 設定手順（所要 10-15 分）

1. https://wanwalk.sentry.io にログイン
2. **Settings → Projects → flutter → Alerts** を開く
3. **Create Alert** ボタン → **Issue Alert** を選択
4. 上記 A1〜A4 を順に設定:
   - Conditions: 表の「トリガ条件」を入力
   - Actions: 「Send a notification to integration」で Slack + 「Send a notification via Email」
   - 名前: 表の「Alert 名」
5. **Notification Integration**: 事前に Sentry → Slack Integration を Connect しておく（`slack.com/oauth` 経由）
   - Slack チャンネル `#wanwalk-alerts` がない場合は CEO が新規作成
6. 各 Alert を **Save** → 一覧で `Active` 表示を確認

### 1-3. 動作確認（テスト発火）

CTO 側で `recordNonFatal` を一時的に複数回呼ぶ debug build を作って疎通確認可能。本番 Alert で検証するのは避ける（誤通知でオオカミ少年化するため）。

---

## 2. PII マスキング確認

### 2-1. 既存の保護設計（Build 33 時点）

`wanwalk-app/lib/main.dart:88-103` の `SentryFlutter.init`:

```dart
options.attachScreenshot = false;  // ✅ スクショ送信オフ
options.maxBreadcrumbs = 30;        // breadcrumbs 上限
// sendDefaultPii は未設定 (デフォルト false) ✅
// beforeSend フィルタ未設定 ⚠️
```

### 2-2. PII 漏洩リスクと対策

| データ種別 | リスク | 対策状態 |
|---|---|---|
| スクリーンショット | 高（位置・氏名・写真） | ✅ `attachScreenshot=false` |
| User Email | 中（個人特定） | ⚠️ `sendDefaultPii=false` だが Sentry が Supabase JWT から拾う可能性 → §2-3 確認 |
| Breadcrumb 内 URL | 中（API path に user_id 含む） | ⚠️ Supabase REST URL に user_id 入る場合あり |
| stack trace の引数値 | 低（基本は型のみ） | ✅ Dart obfuscation で関数名は seed 化 |
| 位置情報 | 高（GPS 座標） | ✅ 明示的に extra に渡していなければ送信されない |

### 2-3. CEO 確認手順（テスト event 受信後・所要 5 分）

1. Sentry → **Issues** → 最新の test event を開く
2. **Tags** タブで以下を確認:
   - `user.email` が **載っていないこと** ← 載っていたら 🔴 §2-4 で `beforeSend` 追加
   - `user.id` は UUID なら OK（個人特定不能）
3. **Breadcrumbs** タブで以下を確認:
   - URL に `eyJ...` (JWT) が含まれていないこと
   - 位置座標が含まれていないこと
4. **Stack Trace** で関数名が `xa0xb()` 等の obfuscated になっているか確認（dSYM 未 upload なら raw）

### 2-4. 🔴 PII が漏洩していた場合の応急処置

`main.dart` の `SentryFlutter.init` に `beforeSend` を追加:

```dart
options.beforeSend = (event, hint) {
  // user.email を削除
  if (event.user != null) {
    event.user = event.user!.copyWith(
      email: null,
      ipAddress: null,
    );
  }
  // breadcrumbs から JWT 削除
  event.breadcrumbs = event.breadcrumbs?.map((b) {
    if (b.data?['url']?.toString().contains('eyJ') ?? false) {
      return b.copyWith(data: {...?b.data, 'url': '[REDACTED]'});
    }
    return b;
  }).toList();
  return event;
};
```

修正後は Build N+1 で再提出 → 24 時間以内に公開（App Store 審査は通常通り）。

---

## 3. SLO（段階目標）

W3 day 1 設計通り:

| 期間 | Crash-Free Sessions | Crash-Free Users |
|---|---|---|
| 公開直後 (week 1) | **99.5%** | 99.0% |
| 公開 1 ヶ月後 | **99.7%** | 99.5% |
| 公開 3 ヶ月後 | **99.9%** | 99.7% |

**測定方法**: Sentry → **Releases** → 該当 release → **Health** タブで自動表示。

**SLO 違反時の対応**:
- 99.5% を割った場合: 24 時間以内に原因 issue を特定 → hotfix or 公開後 patch（§5）
- 連続 2 日違反: A3 章「公開ブロッカー」相当として扱い・新規 release は止める

---

## 4. インシデント対応フロー（症状別）

### 4-1. 共通の初動（Alert 受信から 15 分以内）

1. Sentry ダッシュボードで該当 issue を開く
2. **Events** タブで以下を確認:
   - 影響ユーザー数（unique users affected）
   - 影響デバイス（iPhone 12 mini など）
   - 影響 OS（iOS 26.4 など）
   - 発生時刻分布（初回 vs 連続発生）
3. **Stack Trace** で発生箇所特定
4. **Breadcrumbs** で再現手順を逆引き
5. CTO スレッドに `Sentry: <issue id> / <affected users> / <症状要約>` を投稿

### 4-2. 症状別フローチャート

#### A. クラッシュ（fatal level）

```
Alert A1/A3 発火
  │
  ▼
影響ユーザー数 >= 50 ? ─── YES ───▶ 🔴 緊急 hotfix (§5)・1h 以内に着手
  │
  NO
  ▼
影響ユーザー数 >= 5 ? ─── YES ───▶ 🟡 24h 以内に hotfix・Build N+1
  │
  NO
  ▼
🟢 次の release で fix・Issue を `Assigned` にする
```

#### B. API エラー（recordNonFatal warning level）

```
頻度 > 100 events/h ? ─── YES ───▶ Supabase 障害疑い・Status Page 確認
  │                                  └ Supabase 側障害なら user 通知のみ
  NO
  ▼
特定 endpoint に集中 ? ─── YES ───▶ Supabase migration/RLS 確認・修正
  │
  NO
  ▼
🟢 次の release で fix
```

#### C. GPS 関連エラー

```
GPS permission denied ? ─── YES ───▶ 🟢 仕様通り (A3 §7.2 #4 PASS 済)
  │
  NO
  ▼
GPS timeout 大量発生 ? ─── YES ───▶ 🟡 端末/iOS 偏り確認
  │                                  └ 特定機種に偏れば device-specific fix
  NO
  ▼
GPS 座標が 0,0 ? ─── YES ───▶ 🟡 初期化タイミング bug 候補・調査
```

#### D. 写真アップロードエラー

```
ストレージ容量不足 ? ─── YES ───▶ 🟢 §7.2 #10 仕様通り
  │
  NO
  ▼
Supabase Storage 4xx/5xx ? ─── YES ───▶ Storage policy or bucket size 確認
  │
  NO
  ▼
ネットワーク timeout ? ─── YES ───▶ 🟢 §7.2 #1 仕様通り
```

### 4-3. Issue の triage ラベル運用

Sentry の Issue に label を付けて状態管理:
- `triage:critical` — §5 hotfix 即着手
- `triage:next-release` — 次の通常 release で fix
- `triage:wont-fix` — 仕様通り（§7.2 #1/#4/#5/#10 等）
- `triage:supabase-side` — backend 起因・wanwalk-admin 側で対応

---

## 5. Hotfix → Build N+1 提出フロー

### 5-1. 判断基準

| 条件 | 対応 |
|---|---|
| Crash-Free Sessions < 99.5% かつ 24 時間内 | 🔴 即 hotfix |
| 単一 issue で affected_users >= 50 | 🔴 即 hotfix |
| affected_users 5-49 で再現可能 | 🟡 24 時間以内に hotfix |
| affected_users < 5 | 🟢 次の release |
| Issue が仕様通り（§7.2 PASS 項目） | `wont-fix` ラベル付け |

### 5-2. Hotfix 提出フロー（所要 30-60 分）

day 16 確立の提出フロー再利用（`skills/flutter-build.md §3 + Sentry section`）:

```bash
cd ~/projects/wanwalk/wanwalk-app

# 1. fix コミット
git add <修正ファイル>
git commit -m "hotfix: <Sentry issue id> <症状要約>"

# 2. pubspec.yaml の build number を +1
# version: 1.1.0+33 → 1.1.0+34

# 3. Vault から SENTRY_AUTH_TOKEN 取得
export SENTRY_AUTH_TOKEN='sntryu_...'  # vault id 00777a2d-...

# 4. release build (obfuscate)
flutter build ipa --release \
  --obfuscate --split-debug-info=build/symbols \
  --export-options-plist=ios/ExportOptions.plist

# 5. TestFlight upload
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/wanwalk.ipa \
  --apiKey 29JL2PYSY2 \
  --apiIssuer 2d33a886-31f7-444e-b682-df68940d782b

# 6. dSYM upload to Sentry
sentry-cli debug-files upload \
  --org wanwalk --project flutter \
  build/ios/Release-iphoneos/

# 7. Sentry release Finalize
dart run sentry_dart_plugin

# 8. symbols 保管
cp build/symbols/app.ios-arm64.symbols \
   ~/Documents/DogHub/wanwalk-symbols/$(date +%Y%m%d_%H%M%S)_hotfix.symbols

# 9. 提出 commit を push
git push
```

### 5-3. Hotfix 後の App Store Connect 操作

1. App Store Connect → **My Apps → WanWalk → App Store** タブ
2. **+ Version or Platform** で新バージョン作成（例: `1.1.1`）
3. **Build** セクションで Build N+1 を選択
4. **Update Notes** に簡潔な日本語修正説明:
   - 例: 「特定の操作で稀にアプリが終了する不具合を修正しました」
   - **絶対に Sentry issue id や stack trace は載せない**
5. **Submit for Review**
6. 通常審査 24-48 時間・**Expedited Review** を申請する場合は §5-4

### 5-4. Expedited Review（緊急審査優先）申請

クラッシュで影響大の場合 Apple に審査優先を依頼可能（年 2-3 回まで）:
1. App Store Connect → **Contact Us → App Review → Request Expedited Review**
2. 理由欄に「Critical crash affecting X% of users in production. Hotfix submitted as build N+1.」
3. 承認されれば通常 6-24 時間で審査完了
4. **乱発禁止** — 真に critical な場合のみ

---

## 6. 公開後 72 時間の観測リズム

| 時刻 | チェック | 担当 |
|---|---|---|
| 公開後 1 時間 | Sentry ダッシュボードに event 0-3 件 ? | CTO |
| 公開後 6 時間 | Crash-Free Sessions 99.5%+ ? | CTO |
| 公開後 24 時間 | 新規 issue top 5 を triage 完了 | CTO + CEO |
| 公開後 48 時間 | SLO 維持 ? Alert A1 発火なし ? | CTO |
| 公開後 72 時間 | 週次レビュー準備（CEO 報告） | CTO |

**最重要観測ポイント**: 公開直後 6 時間。新規ユーザーの初回起動でこける issue は dot pattern で連続発生するので、breadcrumbs から再現手順を逆引きできる時間帯。

---

## 7. 既知の DEFER 4 件（§7.2 残）の事後検知運用

`docs/mvp_specs/A3_crash_zero.md §7.2` の DEFER 4 件は公開後 Sentry テレメトリで検知:

| # | Sentry での観測ポイント | アクション |
|---|---|---|
| 1 ネットワーク切断 | `DioError: NoConnection` 系の頻度 | 🟢 既知仕様 → `wont-fix` |
| 5 カメラ権限拒否 | `CameraException(permissionDenied)` | 🟢 既知仕様 → `wont-fix` |
| 9 30 分バックグラウンド | アプリ復帰直後のクラッシュ | 🟡 Sentry で初観測なら調査 |
| 10 容量不足 | `PathAccessException: No space left` | 🟢 既知仕様 → `wont-fix` |

W4 で実機 E2E PASS していれば §7.2 12/12 完遂・公開後は監視のみ。

---

## 8. 参照

- 既存 Sentry 統合: `wanwalk-app/lib/utils/error_handler.dart`
- Sentry init: `wanwalk-app/lib/main.dart:83-103`
- dSYM upload 手順: `.claude/skills/flutter-build.md §Sentry Symbols Upload`
- 提出フロー: 同 §3 + 末尾 Sentry section
- §7.2 仕様: `wanwalk-app/docs/mvp_specs/A3_crash_zero.md §7.2`
- W4 残 4 件手順書: `wanwalk-app/docs/mvp_specs/W4_chaos_defer_procedure.md`

## 9. 重要な値

| 項目 | 値 |
|---|---|
| Sentry Org | `wanwalk` |
| Sentry Project | `flutter` |
| Sentry DSN Vault ID | `f4e26e31-...` (W2 §D) |
| Sentry Auth Token Vault ID | `00777a2d-e324-4bc7-ae94-d55f5bdeae69` |
| Bundle ID | `com.doghub.wanwalk` |
| Team ID | `XJ3H4ASPGR` |
| App Store Connect API Key | `29JL2PYSY2` / `2d33a886-31f7-444e-b682-df68940d782b` |
| dSYM 保管先 | `~/Documents/DogHub/wanwalk-symbols/` |

---

## 10. 改訂履歴

- v1 (2026-05-15 W3 day 19): 初版作成・公開直前必須項目を網羅
