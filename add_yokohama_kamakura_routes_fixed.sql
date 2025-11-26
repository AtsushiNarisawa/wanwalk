-- 横浜エリアのルート追加

-- 1. 山下公園散歩コース
INSERT INTO official_routes (
  id, area_id, name, description,
  start_location, end_location, route_line,
  distance_meters, estimated_minutes, difficulty_level,
  thumbnail_url, gallery_images
) VALUES (
  '20000000-0000-0000-0000-000000000001',
  'a2222222-2222-2222-2222-222222222222',
  '山下公園散歩コース',
  '横浜の代表的な海沿い公園。海風を感じながら愛犬とゆったり散歩できます。芝生エリアもあり小型犬にもおすすめ。',
  ST_SetSRID(ST_MakePoint(139.6507, 35.4437), 4326),
  ST_SetSRID(ST_MakePoint(139.6507, 35.4437), 4326),
  ST_SetSRID(ST_GeomFromText('LINESTRING(139.6507 35.4437, 139.6520 35.4445, 139.6535 35.4440, 139.6520 35.4432, 139.6507 35.4437)'), 4326),
  1500,
  25,
  'easy',
  'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=400',
  ARRAY[
    'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=800',
    'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800',
    'https://images.unsplash.com/photo-1568515387631-8b650bbcdb90?w=800'
  ]
);

-- 2. みなとみらい臨港パークコース
INSERT INTO official_routes (
  id, area_id, name, description,
  start_location, end_location, route_line,
  distance_meters, estimated_minutes, difficulty_level,
  thumbnail_url, gallery_images
) VALUES (
  '20000000-0000-0000-0000-000000000002',
  'a2222222-2222-2222-2222-222222222222',
  'みなとみらい臨港パークコース',
  'みなとみらいの海沿いを歩く爽快コース。ランドマークタワーを眺めながらの散歩は最高です。',
  ST_SetSRID(ST_MakePoint(139.6350, 35.4540), 4326),
  ST_SetSRID(ST_MakePoint(139.6350, 35.4540), 4326),
  ST_SetSRID(ST_GeomFromText('LINESTRING(139.6350 35.4540, 139.6370 35.4550, 139.6390 35.4545, 139.6370 35.4535, 139.6350 35.4540)'), 4326),
  2000,
  35,
  'easy',
  'https://images.unsplash.com/photo-1554797589-7241bb691973?w=400',
  ARRAY[
    'https://images.unsplash.com/photo-1554797589-7241bb691973?w=800',
    'https://images.unsplash.com/photo-1590735213920-68192a487bc2?w=800',
    'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800'
  ]
);

-- 3. 元町・中華街散策コース
INSERT INTO official_routes (
  id, area_id, name, description,
  start_location, end_location, route_line,
  distance_meters, estimated_minutes, difficulty_level,
  thumbnail_url, gallery_images
) VALUES (
  '20000000-0000-0000-0000-000000000003',
  'a2222222-2222-2222-2222-222222222222',
  '元町・中華街散策コース',
  '異国情緒あふれる元町・中華街エリアを散策。週末は人が多いので平日がおすすめです。',
  ST_SetSRID(ST_MakePoint(139.6480, 35.4420), 4326),
  ST_SetSRID(ST_MakePoint(139.6480, 35.4420), 4326),
  ST_SetSRID(ST_GeomFromText('LINESTRING(139.6480 35.4420, 139.6495 35.4425, 139.6510 35.4420, 139.6495 35.4415, 139.6480 35.4420)'), 4326),
  1800,
  30,
  'moderate',
  'https://images.unsplash.com/photo-1535739568780-58a9c7b1d3e4?w=400',
  ARRAY[
    'https://images.unsplash.com/photo-1535739568780-58a9c7b1d3e4?w=800',
    'https://images.unsplash.com/photo-1584646098378-0874589d76b1?w=800',
    'https://images.unsplash.com/photo-1568515387631-8b650bbcdb90?w=800'
  ]
);

-- 鎌倉エリアのルート追加

-- 1. 鶴岡八幡宮参道コース
INSERT INTO official_routes (
  id, area_id, name, description,
  start_location, end_location, route_line,
  distance_meters, estimated_minutes, difficulty_level,
  thumbnail_url, gallery_images
) VALUES (
  '30000000-0000-0000-0000-000000000001',
  'a3333333-3333-3333-3333-333333333333',
  '鶴岡八幡宮参道コース',
  '鎌倉のシンボル、鶴岡八幡宮への参道を歩くコース。古都の風情を感じられます。',
  ST_SetSRID(ST_MakePoint(139.5503, 35.3192), 4326),
  ST_SetSRID(ST_MakePoint(139.5503, 35.3192), 4326),
  ST_SetSRID(ST_GeomFromText('LINESTRING(139.5503 35.3192, 139.5515 35.3200, 139.5530 35.3195, 139.5515 35.3187, 139.5503 35.3192)'), 4326),
  1600,
  28,
  'easy',
  'https://images.unsplash.com/photo-1590859808308-3d2d9c515b1a?w=400',
  ARRAY[
    'https://images.unsplash.com/photo-1590859808308-3d2d9c515b1a?w=800',
    'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800',
    'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800'
  ]
);

-- 2. 由比ガ浜海岸コース
INSERT INTO official_routes (
  id, area_id, name, description,
  start_location, end_location, route_line,
  distance_meters, estimated_minutes, difficulty_level,
  thumbnail_url, gallery_images
) VALUES (
  '30000000-0000-0000-0000-000000000002',
  'a3333333-3333-3333-3333-333333333333',
  '由比ガ浜海岸コース',
  '鎌倉の美しい海岸線を歩くコース。夕暮れ時の散歩が特におすすめです。',
  ST_SetSRID(ST_MakePoint(139.5350, 35.3100), 4326),
  ST_SetSRID(ST_MakePoint(139.5350, 35.3100), 4326),
  ST_SetSRID(ST_GeomFromText('LINESTRING(139.5350 35.3100, 139.5370 35.3105, 139.5390 35.3100, 139.5370 35.3095, 139.5350 35.3100)'), 4326),
  2200,
  40,
  'easy',
  'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400',
  ARRAY[
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
    'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800',
    'https://images.unsplash.com/photo-1568515387631-8b650bbcdb90?w=800'
  ]
);

-- 3. 北鎌倉円覚寺コース
INSERT INTO official_routes (
  id, area_id, name, description,
  start_location, end_location, route_line,
  distance_meters, estimated_minutes, difficulty_level,
  thumbnail_url, gallery_images
) VALUES (
  '30000000-0000-0000-0000-000000000003',
  'a3333333-3333-3333-3333-333333333333',
  '北鎌倉円覚寺コース',
  '北鎌倉の静かな寺院エリアを散策。緑豊かで落ち着いた雰囲気が魅力です。',
  ST_SetSRID(ST_MakePoint(139.5450, 35.3350), 4326),
  ST_SetSRID(ST_MakePoint(139.5450, 35.3350), 4326),
  ST_SetSRID(ST_GeomFromText('LINESTRING(139.5450 35.3350, 139.5465 35.3355, 139.5480 35.3350, 139.5465 35.3345, 139.5450 35.3350)'), 4326),
  1400,
  25,
  'moderate',
  'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400',
  ARRAY[
    'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=800',
    'https://images.unsplash.com/photo-1528164344705-47542687000d?w=800',
    'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800'
  ]
);
