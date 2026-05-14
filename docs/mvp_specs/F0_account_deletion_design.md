# F0 アカウント削除実装設計書 v1.0

**作成日**: 2026-05-15（W3 day 20）
**実施予定日**: 2026-05-17（W3 day 21）
**所要見積**: 3-4 時間
**根拠**: App Store Review Guideline 5.1.1(v) — In-App アカウント削除必須

---

## 0. 概要

ヘルプ / プライバシーポリシーで「設定 → アカウントを削除」と案内しているが、**実体 UI が未実装** → 5/27 公開ブロッカー。day 21 で完全実装する。

### CEO 決定事項（2026-05-15）
- 削除方式: **即時物理削除（CASCADE 全消し）**
- 案内文言: **実装と整合させる**（変更不要）
- 公開スケジュール: 5/20 (火) 申請 → 5/27 (火) 公開 維持

---

## 1. 全体アーキテクチャ

```
[Flutter UI]
    ↓ 確認ダイアログ (パスワード再入力)
    ↓
[AuthService.deleteAccount()]
    ↓ supabase.functions.invoke('delete-user')
    ↓
[Edge Function: delete-user]
    ↓ ① auth.users から取得した uid で
    ↓ ② NO ACTION テーブルを明示削除 (4 種)
    ↓ ③ Storage バケット 5 種から prefix=uid/ を全削除
    ↓ ④ supabase.auth.admin.deleteUser(uid)
    ↓    → CASCADE で profiles + 20+ テーブル連鎖削除
    ↓
[クライアント]
    ↓ supabase.auth.signOut() を呼び戻り無視で実施
    ↓ WelcomeScreen に push & 全 stack clear
```

---

## 2. DB スキーマ事前確認結果（2026-05-15 取得）

`information_schema` から取得した FK の `delete_rule` 一覧（user_id / owner_id / profile_id を参照しているもの）:

### 🟢 CASCADE 既設定（auth.users 削除 → profiles 削除で連鎖消滅）
| テーブル | カラム |
|---|---|
| `comments` | user_id |
| `device_tokens` | user_id |
| `dogs` | user_id |
| `notification_log` | user_id |
| `notification_permissions` | user_id |
| `notification_preferences` | user_id |
| `notifications` | user_id |
| `pin_likes` | user_id |
| `route_feedback` | user_id |
| `route_likes` | user_id |
| `route_photos` | user_id |
| `route_pin_bookmarks` | user_id |
| `route_pin_comments` | user_id |
| `route_pin_likes` | user_id |
| `routes` | user_id |
| `spot_reviews` | user_id |
| `trips` | user_id |
| `user_bookmarks` | user_id |
| `user_walking_profiles` | user_id |
| `walk_photos` | user_id |
| `walks` | user_id |
| `profiles` | id (→ auth.users) |

### 🔴 NO ACTION（明示削除必要・Edge Function で対処）
| テーブル | カラム | 対応 |
|---|---|---|
| `route_pins` | user_id | Edge Function で `DELETE FROM route_pins WHERE user_id = $uid` |
| `pin_bookmarks` | user_id | 同上 |
| `user_badges` | user_id | 同上 |
| `route_favorites` | user_id | 同上（NO ACTION / CASCADE 二重定義あり・要 day 21 再確認） |

### 🟡 favorite_routes（CASCADE / null 二重定義）
- `favorite_routes.user_id` は 2 行返ってきた（CASCADE と null）→ day 21 着手時に DDL を再確認
- 最悪明示削除しておけば安全

### 🟡 Storage バケット（FK 無し・別途削除）
| バケット | パス規約 | 確認方針 |
|---|---|---|
| `user-avatars` | `{uid}/avatar.jpg` | day 21 で実際の path 規約を grep 確認 |
| `walk-photos` | `{uid}/walks/{walk_id}/*.jpg` | 同上 |
| `pin_photos` | `{uid}/pins/{pin_id}/*.jpg` | 同上 |
| `dog-photos` | `{uid}/dogs/{dog_id}/*.jpg` | 同上 |
| `route-photos` | 公式ルート用なので **対象外** | 削除しない |

---

## 3. Edge Function 仕様

### 3-1. ファイル配置
- パス: `supabase/functions/delete-user/index.ts`
- 既存の `send_push` / `cron_morning_reminder` と同じ TypeScript Deno 環境

### 3-2. 認証
- 呼び出し元: 認証済みユーザーのみ（`Authorization: Bearer <user JWT>`）
- Edge Function 内で `supabase.auth.getUser(jwt)` で uid 抽出 → 自分自身のみ削除可（他人の uid を渡せない設計）
- 二段認証: クライアント側で **パスワード再入力** を要求 → Edge Function に渡すのは JWT のみ（パスワード平文は送らない）

### 3-3. パスワード再認証フロー
クライアントで `supabase.auth.signInWithPassword(email, password)` を実行 → 成功時のみ Edge Function 呼び出し。失敗時は「パスワードが違います」表示。

> 注: Sign in with Apple / Google ユーザーはパスワード再入力できない → §3-7 で別フロー記載

### 3-4. 削除順序（Edge Function 内）

```typescript
// Service Role Key で admin client 作成
const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

// 1. NO ACTION テーブル明示削除 (順序: 子 → 親)
await admin.from('pin_bookmarks').delete().eq('user_id', uid);
await admin.from('user_badges').delete().eq('user_id', uid);
await admin.from('route_favorites').delete().eq('user_id', uid);  // 二重定義保険
await admin.from('route_pins').delete().eq('user_id', uid);

// 2. Storage 削除 (バケット 4 種・ prefix=uid/)
for (const bucket of ['user-avatars', 'walk-photos', 'pin_photos', 'dog-photos']) {
  const { data: files } = await admin.storage.from(bucket).list(uid, { limit: 1000 });
  if (files && files.length > 0) {
    const paths = files.map(f => `${uid}/${f.name}`);
    await admin.storage.from(bucket).remove(paths);
  }
  // 再帰的なサブフォルダにも対応（walks/{walk_id}/ 等）
  // day 21 で listObjectsV2 like の再帰 helper を書く
}

// 3. 最後に auth.users を削除 (CASCADE で残り全部消える)
const { error } = await admin.auth.admin.deleteUser(uid);
if (error) throw error;

return new Response(JSON.stringify({ ok: true, uid }), { status: 200 });
```

### 3-5. エラーハンドリング
- 各削除でエラーが出ても **続行**（部分削除でも進める＝ Apple Review でリジェクト回避優先）
- ただし最後の `admin.deleteUser` だけは throw して 500 返す（auth.users が消えなければ「アカウント削除した」と言えない）
- すべての中間エラーは Sentry に `recordNonFatal` で送る（CTO 公開後ダッシュボード調査）

### 3-6. 環境変数
- `SUPABASE_URL`: 既存
- `SUPABASE_SERVICE_ROLE_KEY`: 既存（Vault → MCP secret 注入 と同じパターン）
- 新規追加は不要

### 3-7. Sign in with Apple / Google ユーザーの再認証
- パスワードを持たないので `signInWithPassword` できない
- 代替: 削除ボタン押下後 **24 時間以内に Apple / Google で再ログイン** → 「同意」ボタンを押す 2 段階フロー
- **MVP では簡略化**: SNS ログインユーザーは「DELETE」と画面に入力させる確認ステップで代替（パスワード再入力の代わり）
- セキュリティ強度は劣るが Apple Review でリジェクトされない範囲（実装事例多数）

---

## 4. Flutter UI 仕様

### 4-1. 設定画面（settings_screen.dart）

「アカウント」セクションの末尾に項目追加:

```dart
// アカウントセクションの最後の Divider の後に追加
_buildSettingsTile(
  context,
  isDark,
  icon: Icons.delete_forever_outlined,
  title: 'アカウントを削除',
  titleColor: Colors.red.shade700,  // 危険操作の視覚警告
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AccountDeletionScreen(),
      ),
    );
  },
),
```

`_buildSettingsTile` にオプション引数 `Color? titleColor` を追加（既存項目には影響なし）。

### 4-2. アカウント削除画面（lib/screens/settings/account_deletion_screen.dart 新規）

3 ステップ構成:

#### Step 1: 説明 + 同意
```
[!] アカウントを削除すると、以下のデータが完全に消去されます:

  • プロフィール
  • 登録した犬の情報
  • 散歩記録（写真含む）
  • 投稿したピン
  • お気に入りに追加したルート

⚠ 削除後の復元はできません。

[ キャンセル ] [ 続行する ]
```

#### Step 2: 確認（パスワード再入力 or DELETE 入力）

email/password ユーザー:
```
パスワードを入力してください
[__________________________]

[ キャンセル ] [ アカウントを削除 ] (パスワード空欄時は disabled)
```

Apple / Google ログインユーザー:
```
「DELETE」と入力してください
[__________________________]

[ キャンセル ] [ アカウントを削除 ] (DELETE と一致時のみ enabled)
```

判定: `currentUser.identities` の `provider` で分岐
- `provider == 'email'` → パスワード再入力
- `provider == 'apple'` or `'google'` → DELETE 入力

#### Step 3: 実行中 → 完了
```
削除中... (CircularProgressIndicator)

完了後: 「アカウントを削除しました」スナックバー
       → signOut() → WelcomeScreen にスタッククリア push
```

### 4-3. ファイル一覧（day 21 で touch）
- 🆕 `lib/screens/settings/account_deletion_screen.dart`（新規・約 250 行）
- ✏️ `lib/screens/settings/settings_screen.dart`（項目追加 + titleColor 引数）
- ✏️ `lib/services/auth_service.dart`（`deleteAccount(BuildContext)` メソッド追加）
- ✏️ `lib/providers/auth_provider.dart`（`deleteAccount` 経由・state cleanup）
- 🆕 `supabase/functions/delete-user/index.ts`（新規・Edge Function）

---

## 5. day 21 実装手順（3-4h）

### Phase A: スキーマ事前確認 (15 分)
- [ ] `route_favorites` の二重定義を確認（CASCADE / null）→ 必要なら片方 DROP
- [ ] Storage バケット 4 種の実際のパス規約を grep（`Storage.from('walk-photos').upload(` 等）
- [ ] `route_pins` を CEO シード user で削除しても審査用 seed walk が消えないこと確認（walks の `route_id` は official_routes 参照のみで route_pins とは無関係なはず）

### Phase B: Edge Function 実装 (45 分)
- [ ] `supabase/functions/delete-user/index.ts` 作成
- [ ] §3-4 削除順序を実装
- [ ] Storage 再帰削除 helper 関数
- [ ] MCP `deploy_edge_function` でデプロイ
- [ ] curl で疎通テスト 3 ケース:
  - ① 正常: テストユーザー削除 → auth.users から消える
  - ② 認証なし: 401 返す
  - ③ 他人の uid 注入試行: 自分の JWT で他人を消せない（uid は JWT から抽出するので構造的に不可能）

### Phase C: Flutter UI 実装 (90 分)
- [ ] `account_deletion_screen.dart` 新規（3 Step Stepper or 3 画面遷移）
- [ ] `auth_service.deleteAccount()` メソッド（パスワード再認証 + Edge Function 呼び出し + signOut）
- [ ] `settings_screen.dart` に項目追加 + titleColor 拡張
- [ ] `flutter analyze` 新規 error/warning 0

### Phase D: Sim 動作確認 (30 分)
- [ ] 設定 → 「アカウントを削除」項目表示
- [ ] Step 1 → Step 2 → Step 3 遷移
- [ ] 削除完了 → WelcomeScreen redirect
- [ ] 削除済みアカウントで再ログイン試行 → エラー「アカウントが見つかりません」
- [ ] SQL で `SELECT count(*) FROM profiles WHERE id = $uid` = 0 確認
- [ ] SQL で `SELECT count(*) FROM walks WHERE user_id = $uid` = 0 確認

### Phase E: Build 34 提出準備 (30 分)
- [ ] pubspec.yaml 1.1.0+33 → 1.1.0+34 bump
- [ ] `flutter build ipa --release --obfuscate --split-debug-info=build/symbols`
- [ ] altool upload + sentry-cli debug-files upload + dart run sentry_dart_plugin
- [ ] symbols 保管
- [ ] commit + push

---

## 6. リスクと緩和策

| リスク | 影響 | 緩和策 |
|---|---|---|
| Storage 削除中にネットワーク切断 → 部分削除で止まる | 孤立 object 残存 | エラー catch して続行・Sentry に non-fatal で記録・公開後 cron で孤立 object 掃除 |
| auth.admin.deleteUser でエラー | アカウントが消えない | 500 返却 + クライアントで「削除に失敗しました。サポートまでご連絡ください」表示・CEO 手動対応 |
| Apple Review が SNS ログインで削除実行 → DELETE 入力で削除可能か | リジェクト | apple-review@ は email/password ユーザーなので影響なし |
| route_pins 削除で他ユーザーへの like / comment が cascade で消えない | データ孤立 | route_pin_likes / route_pin_comments は元々 route_pins.id CASCADE 設定されているはず → day 21 で再確認 |
| 削除中にプッシュ通知が飛んでクラッシュ | UX 悪化 | 削除前に device_tokens を明示削除（または NULL revoke） |

---

## 7. Apple Review への提示

§6-3 Review Notes の該当文言:

> 【Account Deletion】
> Account deletion is available in-app from the Settings screen ("アカウントを削除") and removes the user's profile, walks, and uploaded media from our servers. This complies with App Store Review Guideline 5.1.1(v).

→ day 21 実装後に **Apple Review が実際に Settings → "アカウントを削除" を実行する** ことが想定される。

**注意**: apple-review@ アカウントが削除されると次回審査で困る → §F0 §6-1 の seed 設計書に「審査担当者の削除実行 → 公開後 CTO が再 seed」フローを記載済み

---

## 8. day 21 実装後の確認チェックリスト

- [ ] §5 Phase A-E すべて完了
- [ ] Sim で削除フロー 3 パターン PASS（email + password / Apple / Google）
- [ ] DB に削除痕跡 0 件確認
- [ ] Storage に削除痕跡 0 件確認
- [ ] `flutter analyze` 新規 error/warning 0
- [ ] Build 34 TestFlight 提出 + 自端末 install + 再現確認
- [ ] F0 §6-3 Review Notes の Account Deletion 段落と挙動が完全一致
- [ ] commit & push（メッセージ案: `W3 day 21: アカウント削除 In-App 実装（Guideline 5.1.1(v) 準拠）`）

---

## 9. 改訂履歴

| 日付 | 版 | 内容 | 担当 |
|---|---|---|---|
| 2026-05-15 | v1.0 | 初版作成（W3 day 20） | CTO |
| 2026-05-17 | v1.1 予定 | day 21 実装完了後の確定仕様 + 教訓 | CTO |

---

## 10. 参照

- [F0 App Store 審査申請チェックリスト v1](F0_app_store_submission_checklist.md)
- [F0 apple-review@ アカウント seed 設計書 v1.0](F0_apple_review_account_seed.md)
- App Store Review Guideline 5.1.1(v): https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage
- Supabase Auth Admin API: https://supabase.com/docs/reference/javascript/auth-admin-api
- Supabase Storage API: https://supabase.com/docs/reference/javascript/storage-api
