# Walks Table Migration v4 - 実行ガイド

## 🚨 修正内容

**v3 の問題**:
- `routes.area_id` カラムを参照していたが、実際には `routes.area` (TEXT型)
- `areas` テーブルとの不要な結合

**v4 の修正**:
- `r.area_id` → `r.area` に修正
- `areas` テーブルとの結合を削除（粒度が異なるため）
- `routes.area` を直接使用（公園名など具体的な場所名）

## 📋 実行手順

### Step 1: 壊れたRPC関数を削除

Supabase Dashboard の SQL Editor で以下のファイルを実行してください：

```
database_migrations/001_walks_table_DROP_v3_functions.sql
```

これにより以下の関数が削除されます：
- `get_daily_walk_history`
- `get_outing_walk_history`
- `calculate_walk_statistics`
- `get_user_walk_statistics`

**確認クエリ**:
```sql
SELECT routine_name FROM information_schema.routines 
WHERE routine_name IN ('get_daily_walk_history', 'get_outing_walk_history', 
                       'calculate_walk_statistics', 'get_user_walk_statistics');
```
→ 0行が返されればOK

---

### Step 2: 修正版RPC関数を作成

Supabase Dashboard の SQL Editor で以下のファイルを実行してください：

```
database_migrations/001_walks_table_v4.sql
```

**注意**: `walks` テーブル自体は既に存在するため、以下のエラーは無視してOKです：
```
ERROR: relation "walks" already exists
```

重要なのはRPC関数が正しく作成されることです。

---

### Step 3: 動作確認

以下のクエリで確認してください：

#### 3-1. テーブルの確認
```sql
SELECT * FROM walks LIMIT 1;
```

#### 3-2. RPC関数の確認（テストユーザーIDを使用）
```sql
-- テストユーザーIDを取得
SELECT id FROM auth.users LIMIT 1;
-- ↑ 返された UUID を以下で使用

-- 統計情報を取得
SELECT * FROM get_user_walk_statistics('your-user-id-here');
```

期待される結果:
```json
{
  "total_walks": 0,
  "total_outing_walks": 0,
  "total_distance_km": 0,
  "total_duration_hours": 0,
  "areas_visited": 0,
  "routes_completed": 0,
  "pins_created": 0,
  "pins_liked_count": 0,
  "followers_count": 0,
  "following_count": 0
}
```

---

## ✅ 成功の確認

以下がすべて成功すれば完了です：

1. ✅ DROP文が正常に実行された
2. ✅ v4 SQLが正常に実行された（walks テーブル存在エラーは無視）
3. ✅ `get_user_walk_statistics` が正常に実行できる
4. ✅ エラー `column r.area_id does not exist` が発生しない

---

## 🔍 トラブルシューティング

### エラー: `column r.area_id does not exist`
→ DROP文を実行していない可能性があります。Step 1に戻ってください。

### エラー: `function ... already exists`
→ DROP文が不完全な可能性があります。以下を手動で実行：
```sql
DROP FUNCTION IF EXISTS get_daily_walk_history(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_outing_walk_history(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS calculate_walk_statistics(UUID);
DROP FUNCTION IF EXISTS get_user_walk_statistics(UUID);
```

---

## 📊 修正詳細

### calculate_walk_statistics (Line 280)

**変更前**:
```sql
COUNT(DISTINCT r.area_id) FILTER (WHERE walk_type = 'outing')::INTEGER AS areas_visited,
```

**変更後**:
```sql
COUNT(DISTINCT r.area) FILTER (WHERE walk_type = 'outing' AND r.area IS NOT NULL)::INTEGER AS areas_visited,
```

### get_outing_walk_history (Line 253-254)

**変更前**:
```sql
LEFT JOIN areas a ON r.area_id = a.id
SELECT a.name_ja AS area_name
```

**変更後**:
```sql
-- areas テーブルとの結合を削除
SELECT 
  r.area AS route_area,          -- TEXT型の場所名
  r.prefecture AS route_prefecture
```

---

## 📝 実際のデータ構造

**routes.area の値**:
- `"駒沢オリンピック公園"`
- `"代々木公園"`
- `"自宅周辺"`
- など（具体的な場所名）

**areas.name の値**:
- `"箱根"`
- `"横浜"`
- `"鎌倉"`
- など（市区町村レベル）

→ 粒度が異なるため直接結合は不適切
