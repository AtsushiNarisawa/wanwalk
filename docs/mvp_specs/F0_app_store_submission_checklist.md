# F0. App Store 審査申請 事前準備チェックリスト v1

**作成日**: 2026-05-15 (W3 day 19)
**目標**: 5/20 (火) 審査申請 → 5/27 (火) 頃 一般公開
**役割**: CEO 主導（App Store Connect 入力）+ CTO 支援（文案・素材準備）

---

## 0. このチェックリストの使い方

App Store 申請に必要な **すべて** の項目を抜け漏れなく整える。文案・スクショ要件は CTO 側で先行作成して、CEO は確認 → App Store Connect への投入に集中できる構成。

- ✅ = day 19 時点で完了
- 🟡 = day 20-21 で完成予定（CTO 主導）
- 🔴 = day 22-23 で CEO 投入必須

---

## 1. App Store Connect アプリ登録（既存確認）

| 項目 | 値 | 状態 |
|---|---|---|
| App Name | `WanWalk` | ✅ |
| Bundle ID | `com.doghub.wanwalk` | ✅ |
| SKU | （任意・既存値） | ✅ |
| Primary Language | Japanese | ✅ |
| Team | XJ3H4ASPGR | ✅ |
| App Store Connect API Key | `29JL2PYSY2` | ✅ |

---

## 2. バージョン情報（Version 1.1.0 として申請）

| 項目 | 入力値 | 状態 |
|---|---|---|
| Version | `1.1.0` | 🔴 day 23 |
| Build | `1.1.0+34`（day 22-23 で提出） | 🔴 day 23 |
| Copyright | `© 2026 DogHub` | 🟡 |
| Routing App Coverage File | （該当なし） | ✅ |
| Trade Representative Contact | CEO 個人情報・JP のみ | 🔴 day 22 |

---

## 3. アプリ説明文（CTO 文案 → CEO 確認）

### 3-1. Promotional Text（170 文字以内・後で変更可・必須ではない）

```
愛犬と歩く道を、もっと豊かに。鎌倉・箱根・伊豆など74ルートを厳選収録。
散歩中の写真・気づきを記録できる、犬と人のための散歩ノート。
```
（80 文字）

### 3-2. Description（4000 文字以内・推奨 800-1500 文字）

🟡 day 20 で CTO 仕上げ。wanwalk.jp の既存文言とトーン統一。骨子:

```
【概要 200 文字】
WanWalk は、愛犬と歩く散歩ルートを共有・記録するアプリです。
鎌倉、箱根、伊豆、軽井沢など全国 74 本の厳選散歩ルートを地図付きで配信。
GPS で散歩を自動記録し、写真と一緒に思い出を残せます。

【こんな方におすすめ 200 文字】
• 旅行先で愛犬と歩ける場所を探したい方
• 近所の新しい散歩コースを開拓したい方
• 散歩の記録を残したい方
• 愛犬と入れるカフェ・ドッグランを知りたい方

【主な機能 400 文字】
1. 公式ルート 74 本: ベテラン編集者が厳選した愛犬と歩けるコース
2. GPS 散歩記録: 距離・時間・ルートを自動保存
3. 写真記録: 散歩中の写真を地図上にピン留め
4. エリア検索: 関東・甲信越エリアを横断検索
5. 愛犬カフェ・ドッグラン情報: 散歩ルート上の犬連れスポット

【ルートの収録エリア 300 文字】
鎌倉 / 横浜 / 三浦 / 湘南 / 江ノ島 / 葉山 / 小田原 / 箱根（仙石原・芦ノ湖・強羅・宮ノ下・湯本）/
河口湖 / 山中湖 / 伊豆 / 房総 / 軽井沢 / 那須 / 日光 / 秩父 / お台場 / 井の頭 / 代官山 / 多摩川 / 葛西臨海

【今後の予定 200 文字】
利用者の声を反映しながら、エリア追加・機能改善を続けてまいります。
ルートのリクエストや改善提案はアプリ内「情報の修正を提案する」からお寄せください。
```
（合計約 1300 文字）

### 3-3. Keywords（100 文字以内・カンマ区切り）

```
犬,散歩,愛犬,ドッグ,お散歩,ルート,コース,ペット,ドッグラン,カフェ,旅行,箱根,鎌倉,伊豆
```
（53 文字）

### 3-4. Support URL

```
https://wanwalk.jp/about
```
（既存ページ・問い合わせ導線あり）

### 3-5. Marketing URL（任意）

```
https://wanwalk.jp
```

---

## 4. スクリーンショット（iPhone・必須）

### 4-1. 要件（iOS 17+ / 2026 年現在）

Apple 公式要件は **6.9" Display (iPhone 17 Pro Max)** か **6.5" Display (iPhone 11 Pro Max)** のいずれか **1 サイズ必須**。最大 10 枚。

| サイズ | デバイス例 | 解像度 | 状態 |
|---|---|---|---|
| 6.9" | iPhone 17 Pro Max / 16 Pro Max | 1290 × 2796 | 🟡 推奨：これで提出 |
| 6.5" | iPhone 11 Pro Max / 15 Plus | 1242 × 2688 | （6.9" 提出なら不要） |
| 5.5" | iPhone 8 Plus | 1242 × 2208 | （任意・2024 から推奨外） |

**CEO の iPhone 12 mini は 5.4" なので、Simulator iPhone 17 Pro Max でスクショ撮影 → そのまま提出が最速**。

### 4-2. 推奨 8 枚構成（CTO 撮影手順は day 20 で別途）

| # | 内容 | 推奨キャプション |
|---|---|---|
| 1 | ホーム画面（ルート一覧 + 統合フィード） | 愛犬と歩く 74 ルート |
| 2 | ルート詳細（写真 + 体験ストーリー） | 編集者が歩いた本物のコース |
| 3 | エリア選択画面（22 エリア） | 全国の散歩スポットを横断検索 |
| 4 | 地図画面（OSM タイル + ピン） | 地図でコースを確認しながら歩く |
| 5 | 散歩記録中（GPS トラッキング） | GPS で散歩を自動記録 |
| 6 | ピン投稿画面（写真 + コメント） | 写真で思い出を地図に残す |
| 7 | プロフィール画面（散歩履歴） | 散歩の記録を振り返る |
| 8 | スポット詳細（犬連れカフェ等） | 散歩ルート上の犬連れスポット |

### 4-3. iPad スクリーンショット

WanWalk は iPhone Only (`UIDeviceFamily = [1]`) なので **iPad スクショ不要**。`Info.plist` 確認済み。

---

## 5. App Privacy（最重要・Apple 厳格化中）

### 5-1. データ収集申告

App Store Connect → **App Privacy → Manage** で以下を申告:

| カテゴリ | 種別 | 用途 | Linked to User ? | Used for Tracking ? |
|---|---|---|---|---|
| Contact Info | Email | App Functionality (ログイン) | YES | NO |
| Location | Precise Location | App Functionality (散歩記録) | YES | NO |
| User Content | Photos or Videos | App Functionality (散歩写真) | YES | NO |
| User Content | Other User Content | App Functionality (コメント・ピン) | YES | NO |
| Identifiers | User ID | App Functionality (Supabase user_id) | YES | NO |
| Diagnostics | Crash Data | App Functionality (Sentry) | NO | NO |
| Diagnostics | Performance Data | App Functionality (Sentry) | NO | NO |

**注**:
- `Used for Tracking` はすべて NO（ATT 不要）
- `Linked to User` = ユーザーアカウントに紐付くか。Supabase 経由で全部紐付くので YES
- Sentry は `attachScreenshot=false` + `sendDefaultPii=false` で匿名化済み → Diagnostics は `Not Linked to User` 申告可

### 5-2. Privacy Policy URL

```
https://wanwalk.jp/privacy
```
（既存ページ・最終更新 2026-04-20・Apple 必須項目を網羅）

### 5-3. CTO 事前確認事項（🟡 day 20 確認）

- [ ] privacy ページに以下が記載されているか:
  - データ収集項目（Email / Location / Photos / User ID）
  - 利用目的
  - 第三者提供（Supabase / Firebase / Sentry / Google Maps）
  - 保存期間
  - ユーザーの権利（削除・開示請求）
  - 16 歳未満の同意条項
  - 連絡先（info@dog-hub.shop）

---

## 6. App Review Information（審査担当者向け）

### 6-1. Sign-in Information（審査用テストアカウント）

App は Supabase 認証必須なので、**審査用アカウントを必ず提供**:

| 項目 | 値 | 状態 |
|---|---|---|
| Sign-in required | YES | 🔴 必須 |
| User Name (email) | `apple-review@dog-hub.shop` ← 新規作成 | 🟡 day 21 |
| Password | （新規発行・強固） | 🟡 day 21 |
| Notes | ⬇ 下記 6-3 | 🟡 |

🟡 **CTO タスク**: day 21 までに以下を実施
1. Supabase Auth に `apple-review@dog-hub.shop` を作成（Email verify off）
2. プロフィール初期化（dog 1 頭登録・名前「Apple」）
3. 既存散歩データを 1-2 件 seed
4. パスワードを Vault に保存 + CEO へ手渡し

### 6-2. Contact Information

| 項目 | 値 |
|---|---|
| First Name | （CEO 入力） |
| Last Name | （CEO 入力） |
| Phone Number | （CEO 入力） |
| Email | `info@dog-hub.shop` |

### 6-3. Review Notes（審査担当者へのメモ・3500 文字以内）

🟡 day 20 で CTO 仕上げ。骨子:

```
Thank you for reviewing WanWalk.

WanWalk is a Japanese dog-walking route-sharing app for dog owners in Japan.

【Sign-in Account】
Please use the test account provided in the Sign-in Information section.

【Key Features to Test】
1. Tap "ルート" tab to view 74 curated walking routes
2. Tap any route to see details (photos, story, spots)
3. Tap "散歩を始める" to start GPS tracking
4. After walking, photos and route are saved to "ライブラリ" tab

【Notes on Permissions】
- Location: Required for GPS tracking during walks
- Camera: Optional, used for photo pins
- Photo Library: Optional, used to upload existing photos
- Notifications: Optional, used for daily walk reminders

【Notes on Content】
All content is user-generated or editorial. We have moderation in place via "情報の修正を提案する" feedback flow.

【Notes on Sentry / Analytics】
We use Sentry for crash reporting only. No tracking SDKs (Facebook Pixel, etc.) are included.

If you have any questions, please contact info@dog-hub.shop.
```

### 6-4. Demo Account 注意事項

- ❌ Apple は「Sign-in required で test account 未提供」を頻繁に reject 理由にする
- ✅ apple-review@ アカウントは審査専用・公開後も削除しない（再審査用）
- ✅ パスワードは英大小数字記号 12 文字以上

---

## 7. Age Rating

| 項目 | 値 |
|---|---|
| Age Rating | **4+** |
| Cartoon/Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic | None |
| Profanity/Crude Humor | None |
| Mature/Suggestive | None |
| Horror/Fear | None |
| Medical/Treatment Info | None |
| Gambling | None |
| Unrestricted Web Access | **No**（外部 URL ボタンは wanwalk.jp / Apple Maps のみ） |
| User Generated Content | **Yes**（ピン投稿・コメント） |
| Contests | None |

⚠️ **User Generated Content = Yes の場合の追加要件**:
- モデレーション機構（フィードバック報告ボタン）= ✅ 「情報の修正を提案する」で対応
- ブロック機能 = 🔴 V1 では未実装・Notes に「moderation via feedback flow only」と明記

---

## 8. Categories

| 項目 | 値 |
|---|---|
| Primary Category | **Travel** |
| Secondary Category | **Lifestyle** |

代替案: Primary `Lifestyle` / Secondary `Travel` も可。Travel カテゴリの方が観光客向けにリーチ広い。

---

## 9. Pricing & Availability

| 項目 | 値 |
|---|---|
| Price | **Free** |
| Availability | Japan のみ（最初は） |
| Pre-Order | No |
| In-App Purchases | None（V1 では IAP なし） |

---

## 10. Apple Developer Account 状態（前提確認）

🔴 **CEO day 20 確認必須**:
- [ ] Apple Developer Program 年間 $99 支払い有効（期限切れ注意）
- [ ] App Store Connect で WanWalk アプリ登録済
- [ ] Bundle ID `com.doghub.wanwalk` が Provisioning Profile に紐付き済
- [ ] Distribution Certificate 有効
- [ ] App-Specific Password 発行済（altool 用）

---

## 11. 提出当日（5/20 火）チェックリスト

CEO 投入手順（30-45 分・チェックリスト形式）:

- [ ] Build 34 が App Store Connect の **Builds** タブに表示されていること
- [ ] Version 1.1.0 を新規作成 → Build 34 を選択
- [ ] §3 のテキスト 4 種類を投入（Promotional Text / Description / Keywords / Support URL）
- [ ] §4 のスクショ 8 枚をアップロード（6.9" 必須）
- [ ] §5 App Privacy 設定完了
- [ ] §6 Review Information 投入（Sign-in Account 含む）
- [ ] §7 Age Rating 4+
- [ ] §8 Category: Travel / Lifestyle
- [ ] §9 Price: Free / Japan
- [ ] **Add for Review** → **Submit for Review**
- [ ] Submission ID をスクショ保存

---

## 12. 公開後タスク（5/27 公開判定後・参考）

- [ ] CEO 実機でストア検索 → ダウンロード確認
- [ ] Sentry Alert 受信確認（§Runbook §6 公開後 72 時間観測）
- [ ] App Store Connect で Sales / Trends 観測
- [ ] レビュー対応フロー確立

---

## 13. day 19-23 タスク分担まとめ

| 日 | CTO タスク | CEO タスク |
|---|---|---|
| day 19 (5/15 木) | ✅ チェックリスト v1 作成 + Sentry Runbook | （day 18 完遂） |
| day 20 (5/16 金) | 🟡 説明文最終化 / Review Notes 英訳 / privacy ページ確認 / スクショ撮影スクリプト | 🟡 §10 Developer Account 確認 |
| day 21 (5/17 土) | 🟡 apple-review@ アカウント seed / スクショ 8 枚撮影 + 加工 / Vault 格納 | 🟡 §5-2 privacy ページ最終確認 |
| day 22 (5/18 日) | 🟡 §7.2 残 4 件 + B1/B2 実機 E2E 並走サポート | 🔴 実機 E2E（手順書 v1） |
| day 23 (5/19 月) | 🔴 Build 34 提出（5-7 分） + 申請物最終確認 | 🔴 App Store Connect 入力着手 |
| day 24 (5/20 火) | 🔴 提出支援（質疑応答） | 🔴 Submit for Review |

---

## 14. 参照

- 既存 Privacy: `https://wanwalk.jp/privacy` / `wanwalk-app/lib/screens/legal/privacy_policy_screen.dart`
- 既存 Terms: `https://wanwalk.jp/terms` / `wanwalk-app/lib/screens/legal/terms_of_service_screen.dart`
- Sentry 運用 Runbook: `wanwalk-app/docs/runbook/sentry_postlaunch_operation.md`
- W4 §7.2 手順書: `wanwalk-app/docs/mvp_specs/W4_chaos_defer_procedure.md`
- 提出フロー: `.claude/skills/flutter-build.md §3 + Sentry section`

## 15. 改訂履歴

- v1 (2026-05-15 W3 day 19): 初版作成・5/20 提出に向けた全項目を網羅
