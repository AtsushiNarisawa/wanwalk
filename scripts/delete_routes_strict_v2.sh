#!/bin/bash

# Supabase configuration
SUPABASE_URL="https://jkpenklhrlbctebkpvax.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8"

# Routes to keep (strict: Hakone 3, Yokohama 2, Kamakura 2, Others 1 each)
KEEP_ROUTES=(
  # 箱根 (3 routes - top 3 by total_walks)
  "10000000-0000-0000-0000-000000000001"  # DogHub周遊コース (150)
  "894302aa-ddd2-454e-b0ff-26d253b44158"  # 芦ノ湖周遊コース (120)
  "f8d24e4e-d02d-446e-9079-d97ab07338f9"  # 強羅公園周辺コース (85) - first one
  
  # 横浜 (2 routes - selected from available)
  "20000000-0000-0000-0000-000000000001"  # 山下公園散歩コース
  "779d1816-0c24-4d91-b5b2-2fbfc3292024"  # 山下公園・港の見える丘公園コース
  
  # 鎌倉 (2 routes - top 2 by total_walks)
  "36ed0efb-087a-4401-a6d6-b4f35e1cadbd"  # 長谷寺・大仏コース (100)
  "8037d1b7-9451-482f-b0c8-4ddc8960cb54"  # 北鎌倉・円覚寺コース (90)
  
  # その他エリア (各1 route) - 最初の1つを保持
  "7013fa14-d8d5-454a-9f71-81e528cad318"  # お台場・豊洲: お台場海浜公園プロムナード
  "cefa5918-ba2c-4ed5-8238-14d05aa229ed"  # 三浦半島: 城ヶ島灯台コース
  "0728410d-a5b1-4576-8b07-cc03bc6a0ed9"  # 井の頭公園: 井の頭池周遊コース
  "5e40574f-48d2-4088-a7fd-a3bcb501d6a8"  # 代官山・中目黒: 目黒川桜並木コース
  "19b89d29-c13c-495d-95fe-1b9ebf54f130"  # 伊豆: 城ヶ崎海岸遊歩道
  "bbf11dc7-b244-4525-ab17-e66b8cc9a447"  # 多摩川河川敷: 多摩川サイクリングロード
  "86878fc9-61e8-4cc6-80ad-e12e363ef199"  # 房総半島: 養老渓谷遊歩道
  "068bf109-3e28-43e1-b073-a83d0f8e32a0"  # 日光: 中禅寺湖スカイライン展望
  "005e71c4-da0f-450d-a155-624f5aa11323"  # 昭和記念公園: 昭和記念公園一周コース
  "9395041d-8756-47cd-a1e3-5a5a8b72f0e4"  # 江ノ島: 江ノ島弁天橋から島内散策
  "d1fc6d73-95ed-4f1f-a976-f348e6d08cab"  # 河口湖・山中湖: 河口湖大橋遊歩道
  "7dd98896-d756-4b5b-9130-ee0009c4d749"  # 草津温泉: 草津温泉湯畑周辺散策
  "2c4d80a3-41bd-4909-903d-295b820709cb"  # 葛西臨海公園: 葛西臨海公園一周コース
  "d6728d18-87aa-4e8a-b15d-df3233e4f5bb"  # 軽井沢: 雲場池散策コース
  "03a8a723-cf63-48c8-9dd6-c7bffa193145"  # 那須高原: 那須高原ロングトレイル
)

echo "厳密ルート削減を開始します..."
echo "保持予定: 箱根3 + 横浜2 + 鎌倉2 + その他各1 = 合計21ルート"
echo ""

echo "全ルートを取得中..."
ALL_ROUTES=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/official_routes?select=id" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[].id')

KEPT_COUNT=0
DELETED_COUNT=0

echo "ルート処理中..."
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
    echo "✓ 保持: $route_id"
    ((KEPT_COUNT++))
  else
    echo "✗ 削除: $route_id"
    curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?id=eq.${route_id}" \
      -H "apikey: ${SUPABASE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_KEY}" > /dev/null
    ((DELETED_COUNT++))
  fi
done

echo ""
echo "=========================================="
echo "厳密ルート削減が完了しました！"
echo "=========================================="
echo "保持ルート数: ${KEPT_COUNT}"
echo "削除ルート数: ${DELETED_COUNT}"
echo "=========================================="
