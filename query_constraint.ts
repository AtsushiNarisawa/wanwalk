import { createClient } from 'npm:@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const supabase = createClient(supabaseUrl, supabaseKey)

const { data, error } = await supabase.rpc('execute_sql', {
  query: `
    SELECT 
      conname AS constraint_name,
      pg_get_constraintdef(oid) AS constraint_definition
    FROM pg_constraint
    WHERE conrelid = 'route_pins'::regclass
      AND contype = 'c'
      AND conname LIKE '%pin_type%';
  `
})

if (error) {
  console.error('Error:', error)
} else {
  console.log('Constraint definition:', JSON.stringify(data, null, 2))
}
