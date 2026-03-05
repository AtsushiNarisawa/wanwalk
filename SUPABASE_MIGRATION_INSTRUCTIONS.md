# Supabase マイグレーション手順

## 🚨 実行順序（重要）

以下の順序でSupabase SQL Editorで実行してください：

### 1. テーブルにカラムを追加

```sql
-- ファイル: supabase_migrations/010_add_route_images.sql
-- thumbnail_url と gallery_images カラムを official_routes テーブルに追加

ALTER TABLE official_routes
ADD COLUMN IF NOT EXISTS thumbnail_url TEXT,
ADD COLUMN IF NOT EXISTS gallery_images TEXT[];

COMMENT ON COLUMN official_routes.thumbnail_url IS 'ルート検索で表示するサムネイル画像URL';
COMMENT ON COLUMN official_routes.gallery_images IS 'ルート詳細で表示するギャラリー画像URL配列';
```

### 2. search_routes 関数を更新

```sql
-- ファイル: supabase_migrations/011_update_search_routes_function.sql
-- search_routes 関数で official_routes.thumbnail_url を使用し、現在地からの距離を計算

CREATE OR REPLACE FUNCTION search_routes(
  p_user_id UUID,
  p_query TEXT DEFAULT NULL,
  p_area_ids UUID[] DEFAULT NULL,
  p_difficulties TEXT[] DEFAULT NULL,
  p_min_distance_km DECIMAL DEFAULT NULL,
  p_max_distance_km DECIMAL DEFAULT NULL,
  p_min_duration_min INT DEFAULT NULL,
  p_max_duration_min INT DEFAULT NULL,
  p_features TEXT[] DEFAULT NULL,
  p_best_seasons TEXT[] DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'popularity',
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0,
  p_user_lat FLOAT DEFAULT NULL,
  p_user_lon FLOAT DEFAULT NULL
)
RETURNS TABLE (
  route_id UUID,
  area_id UUID,
  area_name TEXT,
  route_name TEXT,
  description TEXT,
  difficulty TEXT,
  distance_km DECIMAL,
  estimated_duration_minutes INT,
  elevation_gain_m INT,
  features TEXT[],
  best_seasons TEXT[],
  total_walks INT,
  total_pins INT,
  average_rating DECIMAL,
  is_favorited BOOLEAN,
  thumbnail_url TEXT,
  start_location JSONB,
  distance_from_user_km DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id AS route_id,
    r.area_id,
    a.display_name AS area_name,
    r.title AS route_name,
    r.description,
    r.difficulty,
    r.distance_km,
    r.estimated_duration_minutes,
    r.elevation_gain_m,
    r.features,
    r.best_seasons,
    r.total_walks,
    r.total_pins,
    r.average_rating,
    EXISTS(
      SELECT 1 FROM route_favorites rf 
      WHERE rf.route_id = r.id AND rf.user_id = p_user_id
    ) AS is_favorited,
    r.thumbnail_url,
    jsonb_build_object(
      'type', 'Point',
      'coordinates', ARRAY[ST_X(r.start_location::geometry), ST_Y(r.start_location::geometry)]
    ) AS start_location,
    CASE 
      WHEN p_user_lat IS NOT NULL AND p_user_lon IS NOT NULL THEN
        ST_Distance(
          r.start_location::geography,
          ST_MakePoint(p_user_lon, p_user_lat)::geography
        ) / 1000.0
      ELSE NULL
    END AS distance_from_user_km
  FROM official_routes r
  JOIN areas a ON a.id = r.area_id
  WHERE r.is_active = TRUE
    AND (
      p_query IS NULL OR
      r.title ILIKE '%' || p_query || '%' OR
      r.description ILIKE '%' || p_query || '%'
    )
    AND (p_area_ids IS NULL OR r.area_id = ANY(p_area_ids))
    AND (p_difficulties IS NULL OR r.difficulty = ANY(p_difficulties))
    AND (p_min_distance_km IS NULL OR r.distance_km >= p_min_distance_km)
    AND (p_max_distance_km IS NULL OR r.distance_km <= p_max_distance_km)
    AND (p_min_duration_min IS NULL OR r.estimated_duration_minutes >= p_min_duration_min)
    AND (p_max_duration_min IS NULL OR r.estimated_duration_minutes <= p_max_duration_min)
    AND (p_features IS NULL OR r.features && p_features)
    AND (p_best_seasons IS NULL OR r.best_seasons && p_best_seasons)
  ORDER BY 
    CASE 
      WHEN p_sort_by = 'nearby_first' AND p_user_lat IS NOT NULL AND p_user_lon IS NOT NULL THEN
        ST_Distance(
          r.start_location::geography,
          ST_MakePoint(p_user_lon, p_user_lat)::geography
        )
      ELSE NULL
    END ASC NULLS LAST,
    CASE 
      WHEN p_sort_by = 'popularity' THEN r.total_walks
      WHEN p_sort_by = 'rating' THEN COALESCE(r.average_rating, 0)::INT
      WHEN p_sort_by = 'newest' THEN EXTRACT(EPOCH FROM r.created_at)::INT
      ELSE 0
    END DESC,
    CASE 
      WHEN p_sort_by = 'distance_asc' THEN r.distance_km
      ELSE NULL
    END ASC,
    CASE 
      WHEN p_sort_by = 'distance_desc' THEN r.distance_km
      ELSE NULL
    END DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION search_routes IS '高度なルート検索（現在地からの距離、thumbnail_url対応）';
```

### 3. 箱根ルートに画像を追加

```sql
-- ファイル: update_hakone_route_images.sql
-- 箱根の公式ルートにサムネイルとギャラリー画像を追加

-- 芦ノ湖湖畔コース
UPDATE official_routes
SET 
  thumbnail_url = 'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=800',
  gallery_images = ARRAY[
    'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=800',
    'https://images.unsplash.com/photo-1528127269322-539801943592?w=800',
    'https://images.unsplash.com/photo-1493780474015-ba834fd0ce2f?w=800'
  ]
WHERE title = '芦ノ湖湖畔コース';

-- 箱根神社参道コース
UPDATE official_routes
SET 
  thumbnail_url = 'https://images.unsplash.com/photo-1528127269322-539801943592?w=800',
  gallery_images = ARRAY[
    'https://images.unsplash.com/photo-1528127269322-539801943592?w=800',
    'https://images.unsplash.com/photo-1493780474015-ba834fd0ce2f?w=800',
    'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=800'
  ]
WHERE title = '箱根神社参道コース';

-- 仙石原すすき草原コース
UPDATE official_routes
SET 
  thumbnail_url = 'https://images.unsplash.com/photo-1493780474015-ba834fd0ce2f?w=800',
  gallery_images = ARRAY[
    'https://images.unsplash.com/photo-1493780474015-ba834fd0ce2f?w=800',
    'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=800',
    'https://images.unsplash.com/photo-1528127269322-539801943592?w=800'
  ]
WHERE title = '仙石原すすき草原コース';
```

## ✅ 確認方法

SQLを実行後、以下で確認してください：

```sql
-- ルートに画像が追加されたか確認
SELECT title, thumbnail_url, gallery_images
FROM official_routes
WHERE area_id = (SELECT id FROM areas WHERE name = 'hakone')
ORDER BY title;
```

## 📱 Mac側の作業

SQLを実行した後：

```bash
cd ~/projects/webapp/wanwalk
git pull origin main
flutter run
```

## 🎯 期待される結果

- ✅ ルート検索画面でサムネイル画像が表示される
- ✅ 「近い順」ソートが機能する
- ✅ 現在地からの距離が表示される（例：📍1.2km）
- ✅ カードのレイアウトが正常に表示される
