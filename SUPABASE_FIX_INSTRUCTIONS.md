# Supabase データベース関数修正手順

## 🚨 重要: この手順を必ず実行してください

`PostgrestException: column official_routes.title does not exist` エラーを解決するため、Supabaseの`get_recent_pins`関数を更新する必要があります。

---

## ✅ 実行手順

### 1️⃣ Supabase SQL Editorにアクセス

1. ブラウザで以下のURLを開く:
   ```
   https://supabase.com/dashboard/project/jkpenklhrlbctebkpvax/editor
   ```
   
2. プロジェクト名: **jkpenklhrlbctebkpvax** であることを確認

---

### 2️⃣ 既存の関数を削除

SQL Editorに以下のコードを貼り付けて **RUN** をクリック:

```sql
-- 既存の関数を削除
DROP FUNCTION IF EXISTS get_recent_pins(INT, INT);
```

✅ 実行結果: `Success. No rows returned` と表示されればOK

---

### 3️⃣ 新しい関数を作成

次に以下のコードを貼り付けて **RUN** をクリック:

```sql
-- =====================================================
-- WanWalk: get_recent_pins修正（route_id=NULL対応）
-- =====================================================
CREATE OR REPLACE FUNCTION get_recent_pins(
  p_limit INT DEFAULT 10,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  pin_id UUID,
  route_id UUID,
  route_name TEXT,
  area_id UUID,
  area_name TEXT,
  prefecture TEXT,
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INT,
  comments_count INT,
  photo_url TEXT,
  user_id UUID,
  user_name TEXT,
  user_avatar_url TEXT,
  created_at TIMESTAMPTZ,
  pin_lat FLOAT,
  pin_lon FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rp.id AS pin_id,
    rp.route_id,
    official_routes.title AS route_name,
    official_routes.area_id,
    areas.name AS area_name,
    areas.prefecture,
    rp.pin_type,
    rp.title,
    rp.comment,
    rp.likes_count,
    0 AS comments_count,
    (
      SELECT rpp.photo_url
      FROM route_pin_photos rpp
      WHERE rpp.pin_id = rp.id
      ORDER BY rpp.display_order ASC
      LIMIT 1
    ) AS photo_url,
    rp.user_id,
    COALESCE(auth.users.raw_user_meta_data->>'display_name', 'Unknown User') AS user_name,
    COALESCE(auth.users.raw_user_meta_data->>'avatar_url', '') AS user_avatar_url,
    rp.created_at,
    ST_Y(rp.location::geometry) AS pin_lat,
    ST_X(rp.location::geometry) AS pin_lon
  FROM route_pins rp
  LEFT JOIN official_routes ON official_routes.id = rp.route_id
  LEFT JOIN areas ON areas.id = official_routes.area_id
  LEFT JOIN auth.users ON auth.users.id = rp.user_id
  WHERE EXISTS (
    SELECT 1 FROM route_pin_photos rpp WHERE rpp.pin_id = rp.id
  )
  ORDER BY rp.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_recent_pins IS 'ホーム画面用：最新の写真付きピン投稿を取得（route_id=NULLのピンも含む）';
```

✅ 実行結果: `Success. No rows returned` と表示されればOK

---

### 4️⃣ 関数が正しく作成されたか確認

以下のコードを実行して確認:

```sql
-- 関数の内容を確認
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'get_recent_pins';
```

✅ 実行結果: 1行のデータが返され、`prosrc`に上記のSQL内容が含まれていればOK

---

### 5️⃣ テスト実行

以下のコードで関数が正常に動作するか確認:

```sql
-- 最新のピン2件を取得
SELECT * FROM get_recent_pins(2, 0);
```

✅ 実行結果: エラーが出なければOK（データが0件でも問題なし）

---

## 📱 Flutterアプリで確認

### 1. Mac側で最新コードを取得

```bash
cd ~/projects/webapp/wanwalk
git pull origin main
```

### 2. アプリを完全再起動

```bash
# 実行中のアプリを完全停止
flutter clean
flutter pub get
flutter run
```

### 3. 確認ポイント

✅ **HOME画面の「最新のピン投稿」セクション**
- エラーが表示されない
- 投稿したピンが正しく表示される

✅ **新しいピンを投稿**
- ピン投稿が成功する
- すぐにHOME画面に反映される

---

## 🔍 エラーが続く場合

以下を確認してください:

### 1. Supabaseプロジェクトの確認
```
プロジェクトURL: https://jkpenklhrlbctebkpvax.supabase.co
```
このURLが`.env`ファイルの`SUPABASE_URL`と一致していることを確認

### 2. ログの確認
Flutterアプリのログで以下が出ていないか確認:
```
PostgrestException(message: column official_routes.title does not exist
```

このエラーが出る場合は、手順1〜5を再度実行してください。

---

## 📝 修正内容の説明

### 問題
- `get_recent_pins`関数内で`r.title`というエイリアスを使用していたが、テーブルエイリアスが正しく認識されていなかった

### 解決策
- `LEFT JOIN official_routes`を使用
- テーブル名を完全に指定: `official_routes.title`
- `route_id`がnullの場合でもピンが取得できるように対応

### 変更点
- JOINの順序を最適化
- テーブルエイリアスを削除し、完全なテーブル名を使用
- LEFT JOINにより、ルートに紐づかないピンも取得可能に

---

## 📊 データベース構造

```
route_pins (ピン投稿)
├── id (UUID)
├── route_id (UUID) ← NULL可能
├── user_id (UUID)
├── location (GEOGRAPHY)
├── pin_type (TEXT)
├── title (TEXT)
├── comment (TEXT)
└── created_at (TIMESTAMPTZ)

official_routes (公式ルート)
├── id (UUID)
├── area_id (UUID)
├── title (TEXT) ← これを取得
└── ...

areas (エリア)
├── id (UUID)
├── name (TEXT)
├── prefecture (TEXT)
└── ...
```

---

## ⚠️ 注意事項

1. **必ず正しいSupabaseプロジェクト**（jkpenklhrlbctebkpvax）で実行してください
2. SQL実行後は**必ずFlutterアプリを完全再起動**してください
3. エラーが続く場合は、手順を最初から実行し直してください

---

**このファイルの場所**: `/home/user/webapp/wanwalk/SUPABASE_FIX_INSTRUCTIONS.md`
