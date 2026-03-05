-- ============================================
-- WanWalk v2: 全エリアテストデータ投入スクリプト
-- ============================================
-- 各エリアに公式ルート、ピン、エリア情報を追加
-- 実行前に現在のデータを確認してください

-- ============================================
-- 1. エリアマスタデータの確認・追加
-- ============================================

-- 既存のエリアを確認
SELECT id, name, description, latitude, longitude FROM areas ORDER BY name;

-- エリアが存在しない場合は追加（通常は既に存在するはず）
INSERT INTO areas (id, name, description, latitude, longitude, created_at)
VALUES 
  ('hakone', '箱根', '箱根・小田原エリアの散歩コース', 35.25, 139.05, NOW()),
  ('yokohama', '横浜', '横浜市内の散歩コース', 35.4437, 139.6380, NOW()),
  ('kamakura', '鎌倉', '古都鎌倉の歴史散歩コース', 35.3192, 139.5503, NOW())
ON CONFLICT (id) DO UPDATE SET
  description = EXCLUDED.description,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude;

-- ============================================
-- 2. 箱根エリアの公式ルート
-- ============================================

-- 箱根：芦ノ湖畔散歩コース
INSERT INTO official_routes (
  id, area_id, title, description, distance_meters, estimated_minutes,
  difficulty_level, start_point_name, end_point_name, prefecture, city,
  features, thumbnail_url, is_public, created_at
) VALUES (
  gen_random_uuid(),
  'hakone',
  '芦ノ湖畔散歩コース',
  '美しい芦ノ湖を眺めながら歩く癒しのコース。湖畔の遊歩道は平坦で歩きやすく、犬との散歩に最適です。',
  3200,
  40,
  'easy',
  '箱根神社前',
  '箱根園',
  '神奈川県',
  '箱根町',
  ARRAY['湖畔', '景観', '平坦', '写真映え'],
  NULL,
  true,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 箱根：旧街道杉並木コース
INSERT INTO official_routes (
  id, area_id, title, description, distance_meters, estimated_minutes,
  difficulty_level, start_point_name, end_point_name, prefecture, city,
  features, thumbnail_url, is_public, created_at
) VALUES (
  gen_random_uuid(),
  'hakone',
  '旧街道杉並木コース',
  '江戸時代の面影を残す旧東海道の杉並木。歴史を感じながら森林浴も楽しめる人気コース。',
  2800,
  35,
  'moderate',
  '箱根湯本駅',
  '畑宿',
  '神奈川県',
  '箱根町',
  ARRAY['歴史', '森林', '杉並木', '涼しい'],
  NULL,
  true,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 箱根：強羅公園周辺コース
INSERT INTO official_routes (
  id, area_id, title, description, distance_meters, estimated_minutes,
  difficulty_level, start_point_name, end_point_name, prefecture, city,
  features, thumbnail_url, is_public, created_at
) VALUES (
  gen_random_uuid(),
  'hakone',
  '強羅公園周辺コース',
  '四季折々の花が楽しめる強羅公園を起点とした散策コース。カフェも多く休憩しやすい。',
  2500,
  30,
  'easy',
  '強羅駅',
  '強羅公園',
  '神奈川県',
  '箱根町',
  ARRAY['公園', '花', 'カフェ', '休憩'],
  NULL,
  true,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 3. 横浜エリアの公式ルート
-- ============================================

-- 横浜：山下公園・港の見える丘公園コース
INSERT INTO official_routes (
  id, area_id, title, description, distance_meters, estimated_minutes,
  difficulty_level, start_point_name, end_point_name, prefecture, city,
  features, thumbnail_url, is_public, created_at
) VALUES (
  gen_random_uuid(),
  'yokohama',
  '山下公園・港の見える丘公園コース',
  '横浜を代表する海沿いの公園を巡るコース。氷川丸や港の景色を楽しみながら歩けます。',
  4500,
  55,
  'easy',
  '山下公園',
  '港の見える丘公園',
  '神奈川県',
  '横浜市',
  ARRAY['海', '公園', '景観', '観光'],
  NULL,
  true,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 横浜：赤レンガ倉庫・みなとみらいコース
INSERT INTO official_routes (
  id, area_id, title, description, distance_meters, estimated_minutes,
  difficulty_level, start_point_name, end_point_name, prefecture, city,
  features, thumbnail_url, is_public, created_at
) VALUES (
  gen_random_uuid(),
  'yokohama',
  '赤レンガ倉庫・みなとみらいコース',
  '横浜の代表的観光スポットを巡る都会的なコース。ショッピングやカフェも楽しめます。',
  3800,
  45,
  'easy',
  '桜木町駅',
  '赤レンガ倉庫',
  '神奈川県',
  '横浜市',
  ARRAY['都会', 'ショッピング', 'カフェ', '観光'],
  NULL,
  true,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 横浜：三溪園コース
INSERT INTO official_routes (
  id, area_id, title, description, distance_meters, estimated_minutes,
  difficulty_level, start_point_name, end_point_name, prefecture, city,
  features, thumbnail_url, is_public, created_at
) VALUES (
  gen_random_uuid(),
  'yokohama',
  '三溪園コース',
  '日本庭園の美しさを堪能できるコース。歴史的建造物も多く、和の雰囲気を満喫。',
  2200,
  30,
  'easy',
  '根岸駅',
  '三溪園',
  '神奈川県',
  '横浜市',
  ARRAY['庭園', '歴史', '和風', '静か'],
  NULL,
  true,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 4. 鎌倉エリアの公式ルート
-- ============================================

-- 鎌倉：鶴岡八幡宮・小町通りコース
INSERT INTO official_routes (
  id, area_id, title, description, distance_meters, estimated_minutes,
  difficulty_level, start_point_name, end_point_name, prefecture, city,
  features, thumbnail_url, is_public, created_at
) VALUES (
  gen_random_uuid(),
  'kamakura',
  '鶴岡八幡宮・小町通りコース',
  '鎌倉のシンボル鶴岡八幡宮と賑やかな小町通りを巡るコース。食べ歩きも楽しめます。',
  3000,
  40,
  'easy',
  '鎌倉駅',
  '鶴岡八幡宮',
  '神奈川県',
  '鎌倉市',
  ARRAY['神社', 'ショッピング', '食べ歩き', '観光'],
  NULL,
  true,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 鎌倉：長谷寺・大仏コース
INSERT INTO official_routes (
  id, area_id, title, description, distance_meters, estimated_minutes,
  difficulty_level, start_point_name, end_point_name, prefecture, city,
  features, thumbnail_url, is_public, created_at
) VALUES (
  gen_random_uuid(),
  'kamakura',
  '長谷寺・大仏コース',
  '鎌倉大仏と美しい長谷寺を巡る定番コース。由比ヶ浜も近く海を眺めることもできます。',
  2600,
  35,
  'moderate',
  '長谷駅',
  '長谷寺',
  '神奈川県',
  '鎌倉市',
  ARRAY['寺', '大仏', '歴史', '海'],
  NULL,
  true,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 鎌倉：北鎌倉・円覚寺コース
INSERT INTO official_routes (
  id, area_id, title, description, distance_meters, estimated_minutes,
  difficulty_level, start_point_name, end_point_name, prefecture, city,
  features, thumbnail_url, is_public, created_at
) VALUES (
  gen_random_uuid(),
  'kamakura',
  '北鎌倉・円覚寺コース',
  '静かな北鎌倉エリアの古刹を巡るコース。落ち着いた雰囲気で心が癒されます。',
  1800,
  25,
  'easy',
  '北鎌倉駅',
  '円覚寺',
  '神奈川県',
  '鎌倉市',
  ARRAY['寺', '静か', '禅', '自然'],
  NULL,
  true,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 5. 確認クエリ
-- ============================================

-- 各エリアのルート数を確認
SELECT 
  a.name as エリア名,
  COUNT(r.id) as ルート数
FROM areas a
LEFT JOIN official_routes r ON r.area_id = a.id
GROUP BY a.id, a.name
ORDER BY a.name;

-- 投入されたルート一覧を確認
SELECT 
  a.name as エリア,
  r.title as ルート名,
  r.distance_meters as 距離,
  r.estimated_minutes as 所要時間,
  r.difficulty_level as 難易度
FROM official_routes r
JOIN areas a ON r.area_id = a.id
ORDER BY a.name, r.title;
