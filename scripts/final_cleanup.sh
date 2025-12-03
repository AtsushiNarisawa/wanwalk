#!/bin/bash

SUPABASE_URL="https://jkpenklhrlbctebkpvax.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8"

# Get all routes and delete extras from specific areas
echo "箱根の余分なルートを削除中..."
HAKONE_ROUTES=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/official_routes?select=id,name,total_walks&areas.name=eq.箱根&order=total_walks.desc.nullslast" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}")

# Keep top 3 from Hakone
KEEP_HAKONE=(
  "10000000-0000-0000-0000-000000000001"
  "894302aa-ddd2-454e-b0ff-26d253b44158"
  "f8d24e4e-d02d-446e-9079-d97ab07338f9"
)

echo "$HAKONE_ROUTES" | jq -r '.[].id' | while read route_id; do
  SHOULD_KEEP=false
  for keep_id in "${KEEP_HAKONE[@]}"; do
    if [ "$route_id" = "$keep_id" ]; then
      SHOULD_KEEP=true
      break
    fi
  done
  
  if [ "$SHOULD_KEEP" = false ]; then
    echo "削除: 箱根 - $route_id"
    curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?id=eq.${route_id}" \
      -H "apikey: ${SUPABASE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_KEY}" > /dev/null
  fi
done

echo "横浜の余分なルートを削除中..."
YOKOHAMA_ROUTES=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/official_routes?select=id,name&areas.name=eq.横浜" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}")

# Keep top 2 from Yokohama
KEEP_YOKOHAMA=(
  "20000000-0000-0000-0000-000000000001"
  "779d1816-0c24-4d91-b5b2-2fbfc3292024"
)

echo "$YOKOHAMA_ROUTES" | jq -r '.[].id' | while read route_id; do
  SHOULD_KEEP=false
  for keep_id in "${KEEP_YOKOHAMA[@]}"; do
    if [ "$route_id" = "$keep_id" ]; then
      SHOULD_KEEP=true
      break
    fi
  done
  
  if [ "$SHOULD_KEEP" = false ]; then
    echo "削除: 横浜 - $route_id"
    curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?id=eq.${route_id}" \
      -H "apikey: ${SUPABASE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_KEY}" > /dev/null
  fi
done

echo "鎌倉の余分なルートを削除中..."
KAMAKURA_ROUTES=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/official_routes?select=id,name,total_walks&areas.name=eq.鎌倉&order=total_walks.desc.nullslast" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}")

# Keep top 2 from Kamakura
KEEP_KAMAKURA=(
  "36ed0efb-087a-4401-a6d6-b4f35e1cadbd"
  "8037d1b7-9451-482f-b0c8-4ddc8960cb54"
)

echo "$KAMAKURA_ROUTES" | jq -r '.[].id' | while read route_id; do
  SHOULD_KEEP=false
  for keep_id in "${KEEP_KAMAKURA[@]}"; do
    if [ "$route_id" = "$keep_id" ]; then
      SHOULD_KEEP=true
      break
    fi
  done
  
  if [ "$SHOULD_KEEP" = false ]; then
    echo "削除: 鎌倉 - $route_id"
    curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?id=eq.${route_id}" \
      -H "apikey: ${SUPABASE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_KEY}" > /dev/null
  fi
done

echo "その他エリアの余分なルートを削除中..."

# Delete extras from other areas (keep only 1 each)
AREAS=("お台場・豊洲" "三浦半島" "井の頭公園" "代官山・中目黒" "伊豆" "多摩川河川敷" "房総半島" "日光" "昭和記念公園" "江ノ島" "河口湖・山中湖" "草津温泉" "葛西臨海公園" "軽井沢" "那須高原")

for area in "${AREAS[@]}"; do
  AREA_ROUTES=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/official_routes?select=id&areas.name=eq.${area}&limit=100" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[].id')
  
  FIRST=true
  for route_id in $AREA_ROUTES; do
    if [ "$FIRST" = true ]; then
      FIRST=false
      echo "保持: $area - $route_id"
    else
      echo "削除: $area - $route_id"
      curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?id=eq.${route_id}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" > /dev/null
    fi
  done
done

echo "完了！"
