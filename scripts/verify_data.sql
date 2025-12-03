-- =============================================
-- Week 3 データ確認用SQLクエリ
-- =============================================

-- 1. 各エリアのルート数
SELECT 
    a.name AS エリア名,
    COUNT(r.id) AS ルート数
FROM areas a
LEFT JOIN official_routes r ON a.id = r.area_id
WHERE a.id IN (
    'a1111111-1111-1111-1111-111111111111',  -- 箱根
    'a2222222-2222-2222-2222-222222222222',  -- 横浜
    'a3333333-3333-3333-3333-333333333333'   -- 鎌倉
)
GROUP BY a.name
ORDER BY a.name;

-- 2. 各エリアのルート一覧
SELECT 
    a.name AS エリア名,
    r.name AS ルート名,
    r.distance_meters AS 距離メートル,
    r.estimated_minutes AS 所要分,
    r.difficulty_level AS 難易度,
    r.created_at AS 作成日時
FROM official_routes r
JOIN areas a ON r.area_id = a.id
WHERE a.id IN (
    'a1111111-1111-1111-1111-111111111111',
    'a2222222-2222-2222-2222-222222222222',
    'a3333333-3333-3333-3333-333333333333'
)
ORDER BY a.name, r.created_at DESC;

-- 3. 各ルートのPin数
SELECT 
    a.name AS エリア名,
    r.name AS ルート名,
    COUNT(p.id) AS Pin数
FROM official_routes r
JOIN areas a ON r.area_id = a.id
LEFT JOIN route_pins p ON r.id = p.route_id
WHERE a.id IN (
    'a1111111-1111-1111-1111-111111111111',
    'a2222222-2222-2222-2222-222222222222',
    'a3333333-3333-3333-3333-333333333333'
)
GROUP BY a.name, r.name
ORDER BY a.name, Pin数 DESC;

-- 4. 最近追加されたPin一覧（各エリア5件ずつ）
SELECT 
    a.name AS エリア名,
    r.name AS ルート名,
    p.pin_type AS タイプ,
    p.title AS タイトル,
    p.comment AS コメント,
    p.created_at AS 作成日時
FROM route_pins p
JOIN official_routes r ON p.route_id = r.id
JOIN areas a ON r.area_id = a.id
WHERE a.id IN (
    'a1111111-1111-1111-1111-111111111111',
    'a2222222-2222-2222-2222-222222222222',
    'a3333333-3333-3333-3333-333333333333'
)
ORDER BY a.name, p.created_at DESC
LIMIT 50;

-- 5. サマリー統計
SELECT 
    '箱根' AS エリア名,
    COUNT(DISTINCT r.id) AS ルート数,
    COUNT(p.id) AS Pin数
FROM official_routes r
LEFT JOIN route_pins p ON r.id = p.route_id
WHERE r.area_id = 'a1111111-1111-1111-1111-111111111111'

UNION ALL

SELECT 
    '横浜' AS エリア名,
    COUNT(DISTINCT r.id) AS ルート数,
    COUNT(p.id) AS Pin数
FROM official_routes r
LEFT JOIN route_pins p ON r.id = p.route_id
WHERE r.area_id = 'a2222222-2222-2222-2222-222222222222'

UNION ALL

SELECT 
    '鎌倉' AS エリア名,
    COUNT(DISTINCT r.id) AS ルート数,
    COUNT(p.id) AS Pin数
FROM official_routes r
LEFT JOIN route_pins p ON r.id = p.route_id
WHERE r.area_id = 'a3333333-3333-3333-3333-333333333333';
