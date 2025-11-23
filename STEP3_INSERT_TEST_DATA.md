# ステップ3: テストデータ投入ガイド

## 📋 前提条件

- ✅ ステップ1完了: マイグレーション実行済み
- ✅ ステップ2完了: 3つのテストアカウント作成済み
- ✅ 3つのユーザーUUIDを取得済み

---

## 🚀 実行手順

### 手順3-1: テストデータスクリプトを編集

1. **テストデータファイルを開く**
   - ファイル: `wanmap_v2/supabase_migrations/test_data_phase5.sql`
   - テキストエディタで開く

2. **ユーザーIDを置き換え**
   
   **置き換え箇所（60行目付近）:**
   ```sql
   DO $$
   DECLARE
     user1_id UUID := '00000000-0000-0000-0000-000000000001'; -- 仮のID
     user2_id UUID := '00000000-0000-0000-0000-000000000002'; -- 仮のID
     user3_id UUID := '00000000-0000-0000-0000-000000000003'; -- 仮のID
   ```

   **↓ 以下のように実際のUUIDに変更:**
   ```sql
   DO $$
   DECLARE
     user1_id UUID := 'ステップ2で取得したUser1のUUID'; -- test1@example.com
     user2_id UUID := 'ステップ2で取得したUser2のUUID'; -- test2@example.com
     user3_id UUID := 'ステップ2で取得したUser3のUUID'; -- test3@example.com
   ```

   **例:**
   ```sql
   DO $$
   DECLARE
     user1_id UUID := 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
     user2_id UUID := 'b2c3d4e5-f6g7-8901-bcde-f01234567891';
     user3_id UUID := 'c3d4e5f6-g7h8-9012-cdef-012345678902';
   ```

3. **ファイルを保存**

---

### 手順3-2: テストデータを投入

1. **Supabase Dashboard を開く**
   - URL: https://supabase.com/dashboard/project/jkpenklhrlbctebkpvax
   - 左メニュー → 「SQL Editor」をクリック

2. **新しいクエリを作成**
   - 「+ New query」ボタンをクリック
   - クエリ名: `Phase 5 Test Data`

3. **編集したSQLファイルの内容をコピー**
   - `test_data_phase5.sql` の全内容をコピー

4. **クエリエディタに貼り付け**
   - 全内容を貼り付け

5. **実行**
   - 右下の「Run」ボタンをクリック
   - ⏳ 実行完了を待つ（数秒〜数十秒）

6. **結果確認**
   - ✅ 成功メッセージ: `Success. No rows returned` または `NOTICE: Test data created successfully!`
   - ❌ エラーの場合: エラーメッセージをコピーして報告

---

## ✅ データ投入確認

### 確認クエリ1: 散歩履歴が作成されたか

```sql
-- 各ユーザーの散歩回数を確認
SELECT 
  user_id,
  COUNT(*) as total_walks,
  ROUND(SUM(distance_meters) / 1000.0, 2) as total_distance_km
FROM walks
GROUP BY user_id
ORDER BY total_distance_km DESC;
```

**期待される結果:**
- User 1: 10件の散歩、約40~50km
- User 2: 7件の散歩、約20~30km
- User 3: 5件の散歩、約10~20km

---

### 確認クエリ2: ピンが作成されたか

```sql
-- 各ユーザーのピン数を確認
SELECT 
  user_id,
  COUNT(*) as total_pins
FROM pins
GROUP BY user_id
ORDER BY total_pins DESC;
```

**期待される結果:**
- User 1: 5個のピン
- User 2: 3個のピン
- User 3: 4個のピン

---

### 確認クエリ3: フォロー関係が作成されたか

```sql
-- フォロー関係を確認
SELECT 
  f.follower_id,
  f.following_id,
  f.created_at
FROM user_follows f
ORDER BY f.created_at DESC;
```

**期待される結果:**
- 5件のフォロー関係
- User 1 → User 2, User 3
- User 2 → User 1
- User 3 → User 1, User 2

---

### 確認クエリ4: 通知が作成されたか

```sql
-- 通知を確認
SELECT 
  user_id,
  type,
  title,
  is_read,
  created_at
FROM notifications
ORDER BY created_at DESC;
```

**期待される結果:**
- 6件の通知
- タイプ: `new_follower`, `pin_liked`

---

### 確認クエリ5: バッジが解除されたか

```sql
-- 各ユーザーのバッジ解除数を確認
SELECT 
  ub.user_id,
  COUNT(*) as unlocked_badges,
  STRING_AGG(bd.badge_code, ', ') as badge_codes
FROM user_badges ub
JOIN badge_definitions bd ON ub.badge_id = bd.id
GROUP BY ub.user_id
ORDER BY unlocked_badges DESC;
```

**期待される結果:**
- User 1: 5個のバッジ（distance_10km, area_3, pins_5, first_walk, first_pin）
- User 2: 2個のバッジ（distance_10km, first_walk）
- User 3: 2個のバッジ（first_walk, first_pin）

---

## 📝 実行結果メモ

- [ ] テストデータスクリプト編集完了
  - User 1 UUID: ________________________________
  - User 2 UUID: ________________________________
  - User 3 UUID: ________________________________

- [ ] テストデータ投入完了
  - 実行日時: _______________
  - 結果: ✅ 成功 / ❌ エラー
  - エラー内容（ある場合）: _______________

- [ ] 散歩履歴確認完了
  - User 1: ____ 件、____ km
  - User 2: ____ 件、____ km
  - User 3: ____ 件、____ km

- [ ] ピン確認完了
  - User 1: ____ 個
  - User 2: ____ 個
  - User 3: ____ 個

- [ ] フォロー関係確認完了
  - フォロー数: ____ 件（期待値: 5件）

- [ ] 通知確認完了
  - 通知数: ____ 件（期待値: 6件）

- [ ] バッジ解除確認完了
  - User 1: ____ 個（期待値: 5個）
  - User 2: ____ 個（期待値: 2個）
  - User 3: ____ 個（期待値: 2個）

---

## 🐛 トラブルシューティング

### エラー: "invalid input syntax for type uuid"
**原因**: UUIDの形式が正しくない  
**対処**: 
- ステップ2で取得したUUIDをもう一度確認
- UUIDは `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` の形式

### エラー: "insert or update on table ... violates foreign key constraint"
**原因**: 参照先のテーブルにデータがない  
**対処**: 
- エリアとルートのデータが存在するか確認:
  ```sql
  SELECT COUNT(*) FROM areas;
  SELECT COUNT(*) FROM routes WHERE is_official = true;
  ```
- データがない場合は、基本マイグレーションを実行

### エラー: "duplicate key value violates unique constraint"
**原因**: すでにテストデータが投入されている  
**対処**: 
- テストデータを削除してから再実行:
  ```sql
  DELETE FROM user_badges WHERE user_id IN ('user1_id', 'user2_id', 'user3_id');
  DELETE FROM notifications WHERE user_id IN ('user1_id', 'user2_id', 'user3_id');
  DELETE FROM user_follows WHERE follower_id IN ('user1_id', 'user2_id', 'user3_id');
  DELETE FROM pin_bookmarks WHERE user_id IN ('user1_id', 'user2_id', 'user3_id');
  DELETE FROM route_favorites WHERE user_id IN ('user1_id', 'user2_id', 'user3_id');
  DELETE FROM pins WHERE user_id IN ('user1_id', 'user2_id', 'user3_id');
  DELETE FROM walks WHERE user_id IN ('user1_id', 'user2_id', 'user3_id');
  ```

---

**データ投入が完了したら、ステップ4に進みます！**
