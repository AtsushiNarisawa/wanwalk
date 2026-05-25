# Firebase Analytics 有効化 + GA4 連携 Runbook

> 作成: 2026-05-25 / 対象: WanWalk iOS アプリ (Build 36 以降)
> 目的: W2 §B で OFF にしていた Firebase Analytics を有効化し、wanwalk-web と同一の GA4 プロパティで Web/App データ統合分析を実現する

---

## 前提情報（既に判明済み）

| 項目 | 値 |
|---|---|
| Firebase プロジェクト ID | `wanwalk-prod` |
| Project Number / GCM Sender ID | `720664998327` |
| iOS Bundle ID | `com.doghub.wanwalk` |
| iOS App ID | `1:720664998327:ios:71782af3f6a29c45d3f832` |
| 既存 wanwalk-web GA4 Measurement ID | `G-LMC1P9D35E` |
| 現在の `IS_ANALYTICS_ENABLED` | `false`（GoogleService-Info.plist） |
| App Privacy 申告 | Tracking=No / Linked=Yes（W2 day 22 確定） |
| 公開予定 v1.0.0 (Build 34 / 1.1.0+34) | 2026-05-27 火・手動リリース |
| 本 Build 36 (1.1.2+36) 提出予定 | 2026-05-28 以降 |

---

## STEP 1 — Google Analytics 管理画面で前提確認（CEO 作業・5分）

Firebase Console で「既存 GA4 プロパティを選択」するには、**Firebase に接続する Google アカウントが対象の Analytics アカウントの編集権限を持っている**必要がある。

### 確認手順

1. https://analytics.google.com にアクセス（CEO の Google アカウントでログイン）
2. 左下の歯車アイコン「管理」をクリック
3. 上部のアカウント / プロパティ プルダウンで **Measurement ID = `G-LMC1P9D35E`** に該当するプロパティを探す
   - プロパティ名は「wanwalk」「wanwalk-web」「dog-hub.shop」等のいずれかの可能性が高い
4. 該当プロパティを選択 → 「プロパティの設定」で以下を確認：
   - **プロパティ ID**（数字9桁）: 控える
   - **プロパティ名**: 控える
   - **Analytics アカウント名**（上位階層）: 控える

### 接続性チェック

- プロパティ詳細の「アクセス管理」で、CEO（narisawa@dog-hub.shop）が **「編集者」または「管理者」** ロールを持っているか確認
- 持っていない場合、別の Google アカウント（妻のアカウント等）に管理権限がある可能性 → その場合は STEP 2 でそのアカウントで Firebase Console にログイン

### 取得情報を CTO にチャットで共有

```
GA4 プロパティ名: __________________
GA4 プロパティ ID: __________________
Analytics アカウント名: __________________
編集権限保有: Yes / No
```

---

## STEP 2 — Firebase Console で Analytics 有効化（CEO 作業・10分）

### 2-1. プロジェクト設定

1. https://console.firebase.google.com/project/wanwalk-prod にアクセス
2. 左メニュー上部の歯車アイコン → 「プロジェクトの設定」
3. 「統合」タブをクリック
4. **「Google アナリティクス」** カードの「リンク」ボタンをクリック

### 2-2. GA4 プロパティ選択ダイアログ

「Google アナリティクスの設定」ダイアログが開く：

- 「**既存の Google アナリティクス プロパティを選択**」ラジオボタンを選択
- プロパティ プルダウンで **STEP 1 で控えたプロパティ名** を選択
  - 見つからない場合: STEP 1 のアカウント権限を再確認、または「新規プロパティを作成」を選択（この場合 Web プロパティとは別管理になる・要 CTO 相談）
- 「アナリティクスの利用規約」のチェックボックスにチェック
- 「アナリティクスを有効にする」ボタンをクリック

### 2-3. iOS データストリーム自動作成

Firebase が自動的に：
- 既存 GA4 プロパティに **新しい iOS データストリーム** を追加
- ストリーム名: `WanWalk (iOS)`
- App Store ID: 未設定（公開後に設定可能）
- Bundle ID: `com.doghub.wanwalk`

→ この時点で **GA4 プロパティ管理画面で「データストリーム」を見ると、Web + iOS の2つが並ぶ**状態になる（これが正常）

### 2-4. 新しい GoogleService-Info.plist のダウンロード

1. 左メニュー上部の歯車アイコン → 「プロジェクトの設定」
2. 「全般」タブ → 「マイアプリ」セクション → **iOS app** カード
3. 「**GoogleService-Info.plist**」リンクをクリックしてダウンロード
4. ファイル名は `GoogleService-Info.plist`（重複防止用に `(1)` 等が付いたらリネーム）

### 2-5. CTO への受け渡し

ダウンロードした `GoogleService-Info.plist` を **チャットにドラッグ&ドロップ** で CTO に共有。

CTO 側で確認するポイント：
- `IS_ANALYTICS_ENABLED` が `true` になっていること
- `BUNDLE_ID = com.doghub.wanwalk` が一致していること
- `GOOGLE_APP_ID = 1:720664998327:ios:71782af3f6a29c45d3f832` が変わっていないこと（FCM への影響なし）

---

## STEP 3 — Supabase Vault バックアップ更新（CTO 作業・5分）

W2 §B で `GOOGLESERVICE_INFO_PLIST_LOCATION` (Secret ID: `7bf9cdce-6865-4e00-8a45-886a37fef71d`) として参照を Vault に格納してあるため、新 plist の **Storage 上書き** + Vault 内容変更不要。

1. Supabase Dashboard → Storage → `wanwalk-secrets` バケット
2. 既存 `GoogleService-Info.plist` を **新しいファイルで上書きアップロード**
3. 更新日時を確認

---

## STEP 4 — GA4 管理画面でカスタムディメンション登録（CEO 作業・15分）

Web 側 P0③ で実装済みのイベントパラメータと同名のカスタムディメンションを登録。**Web/App 共通**で利用される。

### 4-1. GA4 管理画面アクセス

1. https://analytics.google.com → wanwalk プロパティ選択
2. 左下の歯車「管理」→ 「カスタム定義」

### 4-2. カスタムディメンション 6 個（Event スコープ）

「カスタムディメンションを作成」ボタンから以下を登録：

| ディメンション名 | スコープ | イベントパラメータ | 説明 |
|---|---|---|---|
| `route_slug` | イベント | route_slug | ルートのスラッグ |
| `area_slug` | イベント | area_slug | エリアのスラッグ |
| `spot_slug` | イベント | spot_slug | スポットのスラッグ |
| `source_page` | イベント | source_page | 発火元ページ識別子 |
| `channel` | イベント | channel | 共有チャネル |
| `surface` | イベント | surface | spot カード露出面 |

### 4-3. カスタムディメンション 2 個（User スコープ）

| ディメンション名 | スコープ | ユーザー プロパティ | 説明 |
|---|---|---|---|
| `traffic_type` | ユーザー | traffic_type | internal / external 判定 |
| `app_platform` | ユーザー | app_platform | web / ios / android 判定（Web 側でも別途設定推奨） |

### 4-4. Key Event（コンバージョン）指定

「管理」→「Key Event」（旧称 Conversions）で以下を「Mark as Key Event」化：

- `share_open`
- `share_channel_click`
- `route_feedback_submit`
- `route_bookmark_toggle`
- `route_start_walk` ← App 固有
- `walk_complete` ← App 固有
- `pin_create` ← App 固有

---

## STEP 5 — 内部トラフィック除外（CEO 作業・5分）

App は Web と違って IP ベース除外が効きにくいため、`traffic_type=internal` user property で除外する仕組みを採用。

### 5-1. GA4 でフィルタ追加（Web 側既存フィルタの拡張）

1. 管理 → データ設定 → データフィルタ
2. 既存「Internal Traffic」フィルタを開く
3. 条件に `traffic_type = internal` の **OR** 条件を追加（User スコープ）
4. 状態を「テスト中」のまま保存（Web の運用と揃える）

### 5-2. App 内で CEO 端末を「内部」に設定する手順（CEO 作業・初回のみ）

CTO 側で「設定 → アプリについて」画面に **8回連続タップで開発者モード起動 → 内部ユーザーモードトグル** を実装予定。

実装完了後、CEO 端末で以下を実施：
1. 設定 → アプリについて
2. バージョン番号を 8 回連続タップ
3. 「内部ユーザーモード」を ON
4. アプリ再起動
5. GA4 DebugView で `traffic_type=internal` が user property として送信されているか確認

---

## STEP 6 — App Store Connect App Privacy 申告更新（CEO 作業・10分）

Firebase Analytics 追加で **新規収集データなし**（既に Linked=Yes で他カテゴリ申告済）と判定できる場合は不要。ただし以下の追加判定を推奨：

### 6-1. ASC App Privacy で確認

1. https://appstoreconnect.apple.com → WanWalk → App Privacy
2. 「収集するデータ」を確認

### 6-2. 追加判定（CTO が下記実装方針で送信するため Tracking=No 維持可能）

| Firebase Analytics データ | App Privacy カテゴリ | 申告状況 |
|---|---|---|
| Firebase Installation ID | Identifiers → User ID | **既に Linked=Yes 申告済** |
| Crashes | Diagnostics → Crash Data | Sentry で申告済（重複申告不要） |
| Usage Data (画面遷移・タップ) | Usage Data → Product Interaction | **追加申告必要** |
| Performance Data | Diagnostics → Performance Data | **追加申告必要**（自動収集される） |

**判定**: 「Usage Data → Product Interaction」**Linked=Yes / Tracking=No** + 「Diagnostics → Performance Data」**Linked=No / Tracking=No** を追加申告

### 6-3. 申告変更後の挙動

- ASC で「審査用に追加」してから提出（Build 36 提出時に同時に審査される）
- 申告変更だけで再審査が走るわけではない（次の Build 提出に紐付く）

---

## STEP 7 — TestFlight Build 36 提出（CTO 作業・1h）

CTO 側で以下完了済みを前提：

- pubspec.yaml: `firebase_analytics: ^11.3.3` 追加
- pubspec.yaml: `version: 1.1.2+36` に bump
- main.dart: Analytics 初期化追加
- `ios/Runner/GoogleService-Info.plist`: STEP 2 で受領した新 plist に差し替え
- 全 15 種類カスタムイベント注入完了
- `flutter analyze` PASS
- Sim 動作確認 PASS

### 7-1. flutter-build.md スキルに従って提出

1. `flutter build ipa --release`
2. `xcrun altool --upload-app`
3. Sentry symbol upload
4. ASC で Build 36 確認 → 1.1.2 バージョン作成 → メタデータ自動コピー
5. **Sign In Information は Build 34 と同じ apple-review@dog-hub.shop**
6. Submit For Review

### 7-2. 公開戦略

- Build 36 が審査通過後、**手動リリース**にする（Build 34 リリース後 1 週間程度観測してから 36 を公開する余裕を確保）
- 自動リリースだと 34 公開→36 即時公開でユーザー混乱の可能性

---

## STEP 8 — 公開後の効果測定（CMO 作業・継続）

### 8-1. GA4 Realtime で初動確認（Build 36 公開後 1 時間）

- Realtime レポート → デバイス → 「app」フィルタ
- 各イベントが秒単位で流入するか観測
- カスタムディメンション 6 個が「探索」で利用可能になるまで **24-48時間**

### 8-2. 1 週間後の Looker Studio Phase 2 ダッシュボード

- Web/App 統合の回遊ファネル：
  - Web: `home → areas → area_detail → route_detail → spot_detail`
  - App: `app_home → app_route_detail → app_walk_started → app_walk_complete`
- DAU/WAU/MAU を `app_platform=ios` で App 限定集計
- ルートごとの「Web 経由閲覧 vs App 経由閲覧」ヒートマップ

### 8-3. 月次レポートへの追加（2026-06-15 想定）

`docs/marketing/marketing_report_2026_06_15.md` に App セクション追加：
- App 起動数 / セッション数 / 平均セッション時間
- 散歩開始数 / 散歩完了数 / 完了率
- ピン投稿数 / 共有数
- ルート別 App 内閲覧トップ 10

---

## ロールバック手順

万一、Build 36 公開後に Analytics 起因の不具合が発生した場合：

1. **即時対応**: Firebase Console → Analytics → データストリーム → iOS ストリーム → 「無効化」（即時反映・既存データは保持）
2. **コード対応**: `setAnalyticsCollectionEnabled(false)` で remote 動的制御（Build 37 hotfix）
3. **GoogleService-Info.plist ロールバック**: `IS_ANALYTICS_ENABLED=false` 版で再ビルド（最終手段）

---

## 参照

- 設計書: `docs/runbook/firebase_analytics_setup.md`（本ファイル）
- W2 §B 完遂メモリ: `project_w2_section_b_completion_2026_05_12.md`
- Web P0③ 実装メモリ: `project_p0_3_ga4_click_events_2026_05_16.md`
- App Privacy 申告履歴: `docs/mvp_specs/F0_app_store_submission_checklist.md` §App Privacy
- Sentry 公開後 Runbook: `docs/runbook/sentry_postlaunch_operation.md`（参考フォーマット）
