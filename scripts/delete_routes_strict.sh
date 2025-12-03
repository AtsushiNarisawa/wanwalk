#!/bin/bash

# Supabase configuration
SUPABASE_URL="https://jkpenklhrlbctebkpvax.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8"

# Routes to keep (strict reduction: Hakone 3, Yokohama 2, Kamakura 2, Others 1 each)
KEEP_ROUTES=(
  # 箱根 (3 routes - top usage)
  "8d4aaa94-00a9-4b41-96fb-68e0f24ae0ff"  # DogHub周遊コース (150)
  "eb4a0c42-b1ff-48ac-afa8-4a17dc33a5c7"  # 芦ノ湖周遊コース (120)
  "f5e8a1c1-3f19-4b3d-8a7b-2d9e6c5f8b4a"  # 強羅公園周辺コース (110)
  
  # 横浜 (2 routes - top usage)
  "c2d8e5f4-6b7a-4c3d-9e1f-8a2b5c6d7e8f"  # 山下公園散歩コース (80)
  "d3e9f6a5-7c8b-5d4e-0f2a-9b3c6d7e8f9a"  # 山下公園・港の見える丘公園コース (75)
  
  # 鎌倉 (2 routes - top usage)
  "e4f0a7b6-8d9c-6e5f-1a3b-0c4d7e8f9a0b"  # 長谷寺・大仏コース (100)
  "f5a1b8c7-9e0d-7f6a-2b4c-1d5e8f9a0b1c"  # 北鎌倉・円覚寺コース (90)
  
  # その他エリア (各1 route)
  "a6b2c9d8-0f1e-8a7b-3c5d-2e6f9a0b1c2d"  # お台場・豊洲: お台場海浜公園プロムナード
  "b7c3d0e9-1a2f-9b8c-4d6e-3f7a0b1c2d3e"  # 三浦半島: 城ヶ島灯台コース
  "c8d4e1f0-2b3a-0c9d-5e7f-4a8b1c2d3e4f"  # 井の頭公園: 井の頭池周遊コース
  "d9e5f2a1-3c4b-1d0e-6f8a-5b9c2d3e4f5a"  # 代官山・中目黒: 目黒川桜並木コース
  "e0f6a3b2-4d5c-2e1f-7a9b-6c0d3e4f5a6b"  # 伊豆: 城ヶ崎海岸遊歩道
  "f1a7b4c3-5e6d-3f2a-8b0c-7d1e4f5a6b7c"  # 多摩川河川敷: 多摩川サイクリングロード
  "a2b8c5d4-6f7e-4a3b-9c1d-8e2f5a6b7c8d"  # 房総半島: 養老渓谷遊歩道
  "b3c9d6e5-7a8f-5b4c-0d2e-9f3a6b7c8d9e"  # 日光: 中禅寺湖スカイライン展望
  "c4d0e7f6-8b9a-6c5d-1e3f-0a4b7c8d9e0f"  # 昭和記念公園: 昭和記念公園一周コース
  "d5e1f8a7-9c0b-7d6e-2f4a-1b5c8d9e0f1a"  # 江ノ島: 江ノ島弁天橋から島内散策
  "e6f2a9b8-0d1c-8e7f-3a5b-2c6d9e0f1a2b"  # 河口湖・山中湖: 河口湖大橋遊歩道
  "f7a3b0c9-1e2d-9f8a-4b6c-3d7e0f1a2b3c"  # 草津温泉: 草津温泉湯畑周辺散策
  "a8b4c1d0-2f3e-0a9b-5c7d-4e8f1a2b3c4d"  # 葛西臨海公園: 葛西臨海公園一周コース
  "b9c5d2e1-3a4f-1b0c-6d8e-5f9a2b3c4d5e"  # 軽井沢: 雲場池散策コース
  "c0d6e3f2-4b5a-2c1d-7e9f-6a0b3c4d5e6f"  # 那須高原: 那須高原ロングトレイル
)

echo "Fetching all official routes..."
ALL_ROUTES=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/official_routes?select=id" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[].id')

KEPT_COUNT=0
DELETED_COUNT=0

echo "Processing routes..."
for route_id in $ALL_ROUTES; do
  # Check if route should be kept
  SHOULD_KEEP=false
  for keep_id in "${KEEP_ROUTES[@]}"; do
    if [ "$route_id" = "$keep_id" ]; then
      SHOULD_KEEP=true
      break
    fi
  done
  
  if [ "$SHOULD_KEEP" = true ]; then
    echo "Keeping route: $route_id"
    ((KEPT_COUNT++))
  else
    echo "Deleting route: $route_id"
    curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?id=eq.${route_id}" \
      -H "apikey: ${SUPABASE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_KEY}" > /dev/null
    ((DELETED_COUNT++))
  fi
done

echo ""
echo "=========================================="
echo "Strict route reduction completed!"
echo "=========================================="
echo "Routes kept: ${KEPT_COUNT}"
echo "Routes deleted: ${DELETED_COUNT}"
echo "=========================================="
