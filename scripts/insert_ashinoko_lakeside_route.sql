-- ========================================
-- WanMap V2 公式ルート投入SQL
-- エリア: 箱根
-- ルート: 芦ノ湖湖畔散歩コース（元箱根港〜箱根公園）
-- 作成日: 2025-12-05
-- 修正日: 2025-12-05（所要時間を愛犬連れに調整: 35分→50分）
-- ========================================

-- 【所要時間調整の根拠】
-- 距離: 2.5km
-- 修正前: 35分（速度4.29 km/h） ← 人間だけの速度
-- 修正後: 50分（速度3.0 km/h） ← 愛犬連れの速度（ニオイ嗅ぎ、休憩、写真撮影含む）

INSERT INTO official_routes (
  id,
  area_id,
  title,
  description,
  start_location,
  end_location,
  route_line,
  distance_km,
  estimated_duration_minutes,
  difficulty,
  elevation_gain_m,
  total_pins,
  total_walks,
  pet_info,
  created_at,
  updated_at
)
VALUES (
  gen_random_uuid(),
  'a1111111-1111-1111-1111-111111111111'::uuid,
  '芦ノ湖湖畔散歩コース（元箱根港〜箱根公園）',
  '元箱根港を起点に、箱根恩賜公園を経由して湖畔を散歩するコース。舗装された歩きやすい道が続き、愛犬との散歩に最適。湖の景観を楽しみながら、箱根神社の赤い鳥居や箱根関所跡などの観光スポットにも立ち寄れます。往復コースのため、体力に合わせて距離調整も可能。',
  ST_SetSRID(ST_MakePoint(139.024526, 35.189992), 4326)::geography,
  ST_SetSRID(ST_MakePoint(139.024526, 35.189992), 4326)::geography,
  NULL,
  2.5,
  50,
  'easy',
  30,
  0,
  0,
  '{
    "parking": "あり（元箱根港駐車場・有料500円/日）",
    "surface": "コンクリート 80% / 土・砂利 20%",
    "restroom": "あり（元箱根港、箱根公園内）",
    "water_station": "あり（箱根公園入口、湖畔複数箇所）",
    "pet_facilities": "周辺にペット同伴可カフェあり、箱根神社は境内ペット同伴可（リード着用必須）",
    "others": "リード着用必須。観光シーズン（GW・紅葉期）は混雑するため早朝散歩推奨。小型犬でも歩きやすい平坦なコース。"
  }'::jsonb,
  now(),
  now()
);

-- ============================================
-- 確認クエリ: 投入されたルートを確認
-- ============================================

SELECT 
  id,
  title AS ルート名,
  distance_km AS 距離km,
  estimated_duration_minutes AS 所要時間分,
  ROUND((distance_km / (estimated_duration_minutes::numeric / 60)), 2) AS 平均速度kmh,
  difficulty AS 難易度,
  pet_info->>'parking' AS 駐車場情報,
  created_at AS 作成日時
FROM official_routes
WHERE title = '芦ノ湖湖畔散歩コース（元箱根港〜箱根公園）'
ORDER BY created_at DESC
LIMIT 1;

-- ============================================
-- 完了メッセージ
-- ============================================
SELECT '芦ノ湖湖畔散歩コースの投入が完了しました（所要時間: 50分）' AS status;
