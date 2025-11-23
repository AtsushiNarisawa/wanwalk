-- Query to check the CHECK constraint on route_pins.pin_type
SELECT 
  conname AS constraint_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'route_pins'::regclass
  AND contype = 'c'
  AND conname LIKE '%pin_type%';
