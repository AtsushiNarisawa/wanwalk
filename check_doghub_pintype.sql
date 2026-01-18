-- DogHub箱根仙石原のpinTypeを確認
SELECT 
  id,
  title,
  pin_type,
  is_official,
  facility_info
FROM route_pins
WHERE title LIKE '%DogHub%'
ORDER BY created_at DESC
LIMIT 5;
