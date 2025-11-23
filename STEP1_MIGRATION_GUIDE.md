# ステップ1: Supabaseマイグレーション実行ガイド

## 📋 事前確認

✅ Supabase Dashboard にアクセス可能  
✅ プロジェクトURL: `https://jkpenklhrlbctebkpvax.supabase.co`

---

## 🚀 実行手順

### 手順1-1: Phase 5マイグレーション（検索・ソーシャル）

1. **Supabase Dashboard を開く**
   - URL: https://supabase.com/dashboard/project/jkpenklhrlbctebkpvax
   - 左メニュー → 「SQL Editor」をクリック

2. **新しいクエリを作成**
   - 「+ New query」ボタンをクリック
   - クエリ名: `Phase 5-1: Search and Social`

3. **SQLファイルの内容をコピー**
   - ローカルファイル: `wanmap_v2/supabase_migrations/007_phase5_search_and_social.sql`
   - ファイルサイズ: 約17KB

4. **クエリエディタに貼り付け**
   - 全内容をコピーして貼り付け

5. **実行**
   - 右下の「Run」ボタンをクリック
   - ⏳ 実行完了を待つ（数秒〜数十秒）

6. **結果確認**
   - ✅ 成功メッセージ: `Success. No rows returned`
   - ❌ エラーの場合: エラーメッセージをコピーして報告

---

### 手順1-2: Phase 5マイグレーション（バッジシステム）

1. **新しいクエリを作成**
   - 「+ New query」ボタンをクリック
   - クエリ名: `Phase 5-2: Badges System`

2. **SQLファイルの内容をコピー**
   - ローカルファイル: `wanmap_v2/supabase_migrations/008_phase5_badges_system.sql`
   - ファイルサイズ: 約11KB

3. **クエリエディタに貼り付け**
   - 全内容をコピーして貼り付け

4. **実行**
   - 右下の「Run」ボタンをクリック
   - ⏳ 実行完了を待つ（数秒〜数十秒）

5. **結果確認**
   - ✅ 成功メッセージ: `Success. No rows returned`
   - ❌ エラーの場合: エラーメッセージをコピーして報告

---

## ✅ マイグレーション確認

### テーブルが作成されたか確認

**確認方法1: Table Editorで確認**
1. 左メニュー → 「Table Editor」をクリック
2. 以下のテーブルが表示されることを確認:
   - ✅ `route_favorites`
   - ✅ `pin_bookmarks`
   - ✅ `user_follows`
   - ✅ `notifications`
   - ✅ `badge_definitions`
   - ✅ `user_badges`

**確認方法2: SQLクエリで確認**
```sql
-- テーブル一覧を確認
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'route_favorites', 
    'pin_bookmarks', 
    'user_follows', 
    'notifications', 
    'badge_definitions', 
    'user_badges'
  )
ORDER BY table_name;
```

期待される結果: 6行（6テーブル）

### バッジデータが登録されたか確認

```sql
-- バッジ定義数を確認
SELECT COUNT(*) as badge_count FROM badge_definitions;
```

期待される結果: `17` （17種類のバッジ）

---

## 🐛 トラブルシューティング

### エラー: "relation already exists"
**原因**: すでにテーブルが存在している  
**対処**: マイグレーションはスキップして次へ進む（既に実行済み）

### エラー: "permission denied"
**原因**: 権限不足  
**対処**: プロジェクトのOwnerまたはAdminでログインしているか確認

### エラー: "syntax error"
**原因**: SQLファイルの内容が正しくコピーされていない  
**対処**: ファイル全体を再度コピー＆ペースト

---

## 📝 実行結果メモ

実行後、以下の情報を記録してください:

- [ ] `007_phase5_search_and_social.sql` 実行完了
  - 実行日時: _______________
  - 結果: ✅ 成功 / ❌ エラー
  - エラー内容（ある場合）: _______________

- [ ] `008_phase5_badges_system.sql` 実行完了
  - 実行日時: _______________
  - 結果: ✅ 成功 / ❌ エラー
  - エラー内容（ある場合）: _______________

- [ ] テーブル確認完了
  - 6テーブル全て存在: ✅ はい / ❌ いいえ

- [ ] バッジデータ確認完了
  - バッジ数: _____ 個（期待値: 17個）

---

**完了したら、ステップ2に進みます！**
