-- ========================================
-- WanMap V2 公式ルート所要時間調整SQL
-- 愛犬連れの散歩速度を考慮した調整
-- 作成日: 2025-12-05
-- ========================================

-- 【調整の根拠】
-- 人間のみ: 約4-5 km/h
-- 愛犬連れ: 約2.5-3 km/h（ニオイ嗅ぎ、休憩、排泄、写真撮影などで約40%減速）
-- 
-- 【計算式】
-- 所要時間（分） = 距離（km） ÷ 2.8 km/h × 60 × 余裕率(1.0-1.2)

-- ============================================
-- 既存ルートの所要時間を調整
-- ============================================

-- ルート1: DogHub周遊コース
-- 距離: 1.2km → 所要時間: 20分 → 25分
UPDATE official_routes
SET 
  estimated_duration_minutes = 25,
  updated_at = NOW()
WHERE title = 'DogHub周遊コース'
  AND distance_km = 1.2;

-- ルート2: 箱根旧街道散歩道
-- 距離: 3.5km → 所要時間: 60分 → 75分（坂道あり、moderate難易度のため+15分）
UPDATE official_routes
SET 
  estimated_duration_minutes = 75,
  updated_at = NOW()
WHERE title = '箱根旧街道散歩道'
  AND distance_km = 3.5;

-- ルート3: 芦ノ湖畔ロングウォーク
-- 距離: 6.8km → 所要時間: 120分 → 150分（長距離、hard難易度のため+30分）
UPDATE official_routes
SET 
  estimated_duration_minutes = 150,
  updated_at = NOW()
WHERE title = '芦ノ湖畔ロングウォーク'
  AND distance_km = 6.8;

-- ============================================
-- 確認クエリ: 更新後のルート情報
-- ============================================

SELECT 
  title AS ルート名,
  distance_km AS 距離km,
  estimated_duration_minutes AS 所要時間分,
  ROUND((distance_km / (estimated_duration_minutes::numeric / 60)), 2) AS 平均速度kmh,
  difficulty AS 難易度,
  updated_at AS 更新日時
FROM official_routes
WHERE area_id IN (
  SELECT id FROM areas WHERE display_name = '箱根'
)
ORDER BY distance_km;

-- ============================================
-- 完了メッセージ
-- ============================================
SELECT '愛犬連れの散歩速度を考慮した所要時間調整が完了しました' AS status;
