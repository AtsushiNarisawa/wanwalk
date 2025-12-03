#!/usr/bin/env python3
"""
箱根エリアのルートIDを取得
"""

import os
import json
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv('/home/user/wanmap_v2/.env')

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

HAKONE_AREA_ID = 'a1111111-1111-1111-1111-111111111111'

# 箱根エリアの全ルートを取得
result = supabase.table('official_routes')\
    .select('id, name, distance_meters, difficulty_level, created_at')\
    .eq('area_id', HAKONE_AREA_ID)\
    .order('created_at', desc=True)\
    .execute()

print("=" * 80)
print("🗻 箱根エリアの全ルート")
print("=" * 80)

for idx, route in enumerate(result.data, 1):
    print(f"{idx}. {route['name']}")
    print(f"   ID: {route['id']}")
    print(f"   距離: {route['distance_meters']}m / 難易度: {route['difficulty_level']}")
    print(f"   作成日時: {route['created_at']}")
    print()

# 最新の9本（今日追加したルート）を抽出
latest_9_routes = result.data[:9]

print("=" * 80)
print("📋 今日追加した9本のルート（Pinを追加する対象）")
print("=" * 80)

route_mapping = {}
for idx, route in enumerate(latest_9_routes, 1):
    print(f"{idx}. {route['name']} → {route['id']}")
    route_mapping[route['name']] = route['id']

# JSON形式で保存
with open('/home/user/wanmap_v2/scripts/hakone_route_ids.json', 'w', encoding='utf-8') as f:
    json.dump(route_mapping, f, ensure_ascii=False, indent=2)

print("\n✅ ルートIDを hakone_route_ids.json に保存しました")
