-- pin_type の種類と数を確認
SELECT 
  pin_type,
  COUNT(*) as count
FROM route_pins
GROUP BY pin_type
ORDER BY count DESC;
