#!/bin/bash

SUPABASE_URL="https://jkpenklhrlbctebkpvax.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8"

echo "🔍 エリア別にルートを取得して削減中..."
echo ""

# 箱根（3件保持）
echo "📍 箱根エリア..."
KEEP_IDS="10000000-0000-0000-0000-000000000001,894302aa-ddd2-454e-b0ff-26d253b44158,f8d24e4e-d02d-446e-9079-d97ab07338f9"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.a1111111-1111-1111-1111-111111111111&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 箱根: 3ルート保持"

# 横浜（2件保持）
echo "📍 横浜エリア..."
KEEP_IDS="20000000-0000-0000-0000-000000000001,779d1816-0c24-4d91-b5b2-2fbfc3292024"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.a2222222-2222-2222-2222-222222222222&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 横浜: 2ルート保持"

# 鎌倉（2件保持）
echo "📍 鎌倉エリア..."
KEEP_IDS="36ed0efb-087a-4401-a6d6-b4f35e1cadbd,8037d1b7-9451-482f-b0c8-4ddc8960cb54"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.a3333333-3333-3333-3333-333333333333&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 鎌倉: 2ルート保持"

# 伊豆（1件保持）
echo "📍 伊豆エリア..."
KEEP_IDS="5a04aacc-06ba-40c0-98be-97e89f76054b"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.a4444444-4444-4444-4444-444444444444&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 伊豆: 1ルート保持"

# 那須高原（1件保持）
echo "📍 那須高原エリア..."
KEEP_IDS="d484fbe2-7a5e-4324-a695-d98b9a350626"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.a5555555-5555-5555-5555-555555555555&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 那須高原: 1ルート保持"

# 軽井沢（1件保持）
echo "📍 軽井沢エリア..."
KEEP_IDS="2a9f2dfe-52da-4483-af6e-ae4164aca2ab"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.a6666666-6666-6666-6666-666666666666&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 軽井沢: 1ルート保持"

# 河口湖・山中湖（1件保持）
echo "📍 河口湖・山中湖エリア..."
KEEP_IDS="451d11d1-02a0-4709-891e-b829bb048f16"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.a7777777-7777-7777-7777-777777777777&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 河口湖・山中湖: 1ルート保持"

# 日光（1件保持）
echo "📍 日光エリア..."
KEEP_IDS="91c8afc0-6035-4e94-acd5-d28db8371d54"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.a8888888-8888-8888-8888-888888888888&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 日光: 1ルート保持"

# 草津温泉（1件保持）
echo "📍 草津温泉エリア..."
KEEP_IDS="64f9b8ac-a11f-4e97-9cab-b3527d67b47a"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.a9999999-9999-9999-9999-999999999999&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 草津温泉: 1ルート保持"

# 房総半島（1件保持）
echo "📍 房総半島エリア..."
KEEP_IDS="492d4101-1b07-4cd1-94c3-03068dad25db"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 房総半島: 1ルート保持"

# お台場・豊洲（1件保持）
echo "📍 お台場・豊洲エリア..."
KEEP_IDS="aa59e3d4-2a24-45d9-b0f4-409f5d6aa53b"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ お台場・豊洲: 1ルート保持"

# 葛西臨海公園（1件保持）
echo "📍 葛西臨海公園エリア..."
KEEP_IDS="1c821708-f0be-4163-9e1f-bfe20ef71ccc"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.cccccccc-cccc-cccc-cccc-cccccccccccc&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 葛西臨海公園: 1ルート保持"

# 代官山・中目黒（1件保持）
echo "📍 代官山・中目黒エリア..."
KEEP_IDS="e23fbf6e-ad6e-4e31-ab0c-260bd8e4318b"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.dddddddd-dddd-dddd-dddd-dddddddddddd&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 代官山・中目黒: 1ルート保持"

# 昭和記念公園（1件保持）
echo "📍 昭和記念公園エリア..."
KEEP_IDS="27950a12-b721-468d-a982-d2fbc2879704"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 昭和記念公園: 1ルート保持"

# 江ノ島（1件保持）
echo "📍 江ノ島エリア..."
KEEP_IDS="abd1ecd0-e99d-4f34-96a7-cf958dd148c4"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.ffffffff-ffff-ffff-ffff-ffffffffffff&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 江ノ島: 1ルート保持"

# 三浦半島（1件保持）
echo "📍 三浦半島エリア..."
KEEP_IDS="cefa5918-ba2c-4ed5-8238-14d05aa229ed"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.10101010-1010-1010-1010-101010101010&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 三浦半島: 1ルート保持"

# 多摩川河川敷（1件保持）
echo "📍 多摩川河川敷エリア..."
KEEP_IDS="b5587149-bb23-47d8-a5c6-34dadbf033f5"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.11111111-1111-1111-1111-111111111111&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 多摩川河川敷: 1ルート保持"

# 井の頭公園（1件保持）
echo "📍 井の頭公園エリア..."
KEEP_IDS="0728410d-a5b1-4576-8b07-cc03bc6a0ed9"
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/official_routes?area_id=eq.12121212-1212-1212-1212-121212121212&id=not.in.(${KEEP_IDS})" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}"
echo "  ✅ 井の頭公園: 1ルート保持"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ルート削減完了"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
