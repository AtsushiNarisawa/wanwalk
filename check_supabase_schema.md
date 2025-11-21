# 📋 Supabaseスキーマ確認ガイド

このガイドでは、Supabaseデータベーススキーマが正しく適用されているか確認する方法を説明します。

---

## ✅ 確認方法

### 方法1: Supabase Studioで確認（推奨）

1. https://supabase.com/dashboard にアクセス
2. WanMapプロジェクトを選択
3. 左サイドバーの「Table Editor」をクリック
4. 以下のテーブルが表示されていることを確認：

#### 必須テーブル（11個）

- [ ] **user_profiles** - ユーザープロフィール
- [ ] **dogs** - 犬情報
- [ ] **routes** - 散歩ルート
- [ ] **route_points** - GPS座標点
- [ ] **route_photos** - ルート写真
- [ ] **route_likes** - ルートいいね
- [ ] **route_comments** - ルートコメント
- [ ] **spots** - わんスポット
- [ ] **spot_photos** - スポット写真
- [ ] **spot_comments** - スポットコメント
- [ ] **spot_upvotes** - スポットupvote

### 方法2: SQL Editorで確認

1. 左サイドバーの「SQL Editor」をクリック
2. 以下のSQLを実行：

```sql
-- テーブル一覧を取得
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

**期待される結果**: 上記11個のテーブル名が表示される

---

## 🔧 PostGIS拡張機能の確認

### SQL Editorで実行

```sql
-- PostGIS拡張機能が有効か確認
SELECT * FROM pg_extension WHERE extname = 'postgis';
```

**期待される結果**: 1行のデータが返される

**もし何も返らない場合**:

1. 左サイドバーの「Database」をクリック
2. 「Extensions」タブをクリック
3. 「postgis」を検索
4. 「Enable」ボタンをクリック

---

## 🔍 RPC関数の確認

### SQL Editorで実行

```sql
-- RPC関数が作成されているか確認
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_type = 'FUNCTION'
  AND routine_name IN (
    'search_nearby_routes',
    'search_nearby_spots',
    'check_spot_duplicate'
  )
ORDER BY routine_name;
```

**期待される結果**: 以下の3つの関数名が表示される
- check_spot_duplicate
- search_nearby_routes
- search_nearby_spots

---

## 📊 テーブル構造の詳細確認

### dogsテーブルの例

```sql
-- dogsテーブルの構造を確認
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'dogs'
ORDER BY ordinal_position;
```

**期待される結果**:

| column_name | data_type | is_nullable |
|-------------|-----------|-------------|
| id | uuid | NO |
| user_id | uuid | NO |
| name | text | NO |
| breed | text | YES |
| size | text | YES |
| birth_date | date | YES |
| weight | numeric | YES |
| photo_url | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

---

## 🔐 Row Level Security (RLS) の確認

### SQL Editorで実行

```sql
-- RLSが有効なテーブルを確認
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = true
ORDER BY tablename;
```

**期待される結果**: 全11テーブルでRLSが有効（rowsecurity = true）

### ポリシーの確認

```sql
-- dogsテーブルのポリシーを確認
SELECT policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'dogs';
```

**期待される結果**:
- `Users can view all dogs` (SELECT)
- `Users can manage own dogs` (ALL)

---

## ❌ よくあるエラーと解決方法

### エラー1: テーブルが作成されていない

**症状**: Table Editorに何も表示されない

**原因**: スキーマが実行されていない

**解決方法**:
1. SQL Editorを開く
2. `supabase_schema.sql`の内容を全てコピー＆ペースト
3. 「Run」をクリック
4. エラーがないか確認

### エラー2: PostGIS関数エラー

**症状**: `function st_dwithin does not exist`

**原因**: PostGIS拡張機能が有効になっていない

**解決方法**:
1. Database > Extensions
2. postgisを検索して「Enable」

### エラー3: RPC関数が見つからない

**症状**: `function search_nearby_routes does not exist`

**原因**: RPC関数が作成されていない

**解決方法**:
1. SQL Editorで`supabase_schema.sql`の後半部分（RPC関数定義）を再実行
2. 関数定義は`CREATE OR REPLACE FUNCTION`で始まる

---

## 🧪 テストクエリ

### テーブルが正常に動作するかテスト

```sql
-- user_profilesテーブルのテスト
INSERT INTO user_profiles (id, display_name)
VALUES (auth.uid(), 'Test User')
ON CONFLICT (id) DO NOTHING;

-- dogsテーブルのテスト
INSERT INTO dogs (user_id, name, breed, size)
VALUES (auth.uid(), 'Test Dog', 'Test Breed', 'medium')
RETURNING *;

-- データの削除（テスト後）
DELETE FROM dogs WHERE name = 'Test Dog';
```

**注意**: テストデータは必ず削除してください

---

## ✅ チェックリスト

セットアップが完了しているか、以下を確認してください：

- [ ] 11個の全テーブルが作成されている
- [ ] PostGIS拡張機能が有効
- [ ] 3個のRPC関数が作成されている
- [ ] 全テーブルでRLSが有効
- [ ] 各テーブルに適切なポリシーが設定されている

**全てチェックできたら、データベースのセットアップは完了です！** ✨

---

## 📞 サポート

問題が解決しない場合は、以下の情報を添えてお問い合わせください：

1. エラーメッセージの全文
2. 実行したSQLクエリ
3. Supabaseプロジェクトのバージョン
4. PostGIS拡張機能の状態
