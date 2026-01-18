-- 既存のピンデータを確認
SELECT 
  id,
  user_id,
  pin_type,
  title,
  comment,
  location,
  created_at
FROM route_pins
ORDER BY created_at DESC
LIMIT 10;

-- pin_type の種類を確認
SELECT 
  pin_type,
  COUNT(*) as count
FROM route_pins
GROUP BY pin_type;

-- pin_type の制約を確認
SELECT
  conname AS constraint_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.route_pins'::regclass
  AND conname LIKE '%pin_type%';
