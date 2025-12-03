#!/bin/bash

# Supabase設定
SUPABASE_URL="https://jkpenklhrlbctebkpvax.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8"

# 残すルートID（箱根3件、横浜2件、鎌倉2件、その他各エリア1件）
KEEP_ROUTES=(
    # 箱根（3件）
    "10000000-0000-0000-0000-000000000001"  # DogHub周遊コース (150回)
    "894302aa-ddd2-454e-b0ff-26d253b44158"  # 芦ノ湖周遊コース (120回)
    "f8d24e4e-d02d-446e-9079-d97ab07338f9"  # 強羅公園周辺コース (85回)
    
    # 横浜（2件）
    "20000000-0000-0000-0000-000000000001"  # 山下公園散歩コース
    "779d1816-0c24-4d91-b5b2-2fbfc3292024"  # 山下公園・港の見える丘公園コース
    
    # 鎌倉（2件）
    "36ed0efb-087a-4401-a6d6-b4f35e1cadbd"  # 長谷寺・大仏コース (100回)
    "8037d1b7-9451-482f-b0c8-4ddc8960cb54"  # 北鎌倉・円覚寺コース (90回)
    
    # 三浦半島（1件）
    "cefa5918-ba2c-4ed5-8238-14d05aa229ed"  # 城ヶ島灯台コース
    
    # 多摩川河川敷（1件）
    "b5587149-bb23-47d8-a5c6-34dadbf033f5"  # 二子玉川河川敷コース
    
    # 井の頭公園（1件）
    "0728410d-a5b1-4576-8b07-cc03bc6a0ed9"  # 井の頭池周遊コース
    
    # 伊豆（1件）
    "5a04aacc-06ba-40c0-98be-97e89f76054b"  # 熱川海岸プロムナード (80回)
    
    # 那須高原（1件）
    "d484fbe2-7a5e-4324-a695-d98b9a350626"  # 殺生石遊歩道
    
    # 軽井沢（1件）
    "2a9f2dfe-52da-4483-af6e-ae4164aca2ab"  # 離山ハイキングコース
    
    # 河口湖・山中湖（1件）
    "451d11d1-02a0-4709-891e-b829bb048f16"  # 山中湖花の都公園周辺
    
    # 日光（1件）
    "91c8afc0-6035-4e94-acd5-d28db8371d54"  # 戦場ヶ原ハイキングコース
    
    # 草津温泉（1件）
    "64f9b8ac-a11f-4e97-9cab-b3527d67b47a"  # 草津高原ロングトレイル
    
    # 房総半島（1件）
    "492d4101-1b07-4cd1-94c3-03068dad25db"  # 鴨川シーワールド周辺海岸
    
    # お台場・豊洲（1件）
    "aa59e3d4-2a24-45d9-b0f4-409f5d6aa53b"  # 豊洲ぐるり公園一周
    
    # 葛西臨海公園（1件）
    "1c821708-f0be-4163-9e1f-bfe20ef71ccc"  # クリスタルビュー展望台コース
    
    # 代官山・中目黒（1件）
    "e23fbf6e-ad6e-4e31-ab0c-260bd8e4318b"  # 西郷山公園コース
    
    # 昭和記念公園（1件）
    "27950a12-b721-468d-a982-d2fbc2879704"  # 水鳥の池周遊コース
    
    # 江ノ島（1件）
    "abd1ecd0-e99d-4f34-96a7-cf958dd148c4"  # 片瀬海岸プロムナード
)

echo "🔍 全ルートを取得中..."

# 全ルートIDを取得
ALL_ROUTES=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/official_routes?select=id" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[].id')

DELETED_COUNT=0
KEPT_COUNT=0

echo "🗑️  ルート削除を開始..."
echo ""

for route_id in $ALL_ROUTES; do
    # 残すリストに含まれているか確認
    SHOULD_KEEP=0
    for keep_id in "${KEEP_ROUTES[@]}"; do
        if [ "$route_id" == "$keep_id" ]; then
            SHOULD_KEEP=1
            break
        fi
    done
    
    if [ $SHOULD_KEEP -eq 0 ]; then
        # 削除実行
        curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?id=eq.${route_id}" \
          -H "apikey: ${SUPABASE_KEY}" \
          -H "Authorization: Bearer ${SUPABASE_KEY}" > /dev/null
        
        echo "  ❌ 削除: ${route_id}"
        DELETED_COUNT=$((DELETED_COUNT + 1))
    else
        echo "  ✅ 保持: ${route_id}"
        KEPT_COUNT=$((KEPT_COUNT + 1))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ルート削減完了"
echo "  保持: ${KEPT_COUNT}ルート"
echo "  削除: ${DELETED_COUNT}ルート"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
