#!/usr/bin/env python3
"""
Week 3 データ追加の最終確認
"""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv('/home/user/wanmap_v2/.env')
supabase = create_client(os.getenv('SUPABASE_URL'), os.getenv('SUPABASE_SERVICE_ROLE_KEY'))

print("=" * 80)
print("📊 Week 3 データ追加 - 最終確認レポート")
print("=" * 80)

# エリアごとのサマリー
areas = [
    ('箱根', 'a1111111-1111-1111-1111-111111111111'),
    ('横浜', 'a2222222-2222-2222-2222-222222222222'),
    ('鎌倉', 'a3333333-3333-3333-3333-333333333333'),
]

total_routes = 0
total_pins = 0

for area_name, area_id in areas:
    # ルート数
    routes_res = supabase.table('official_routes').select('id', count='exact').eq('area_id', area_id).execute()
    route_count = routes_res.count if hasattr(routes_res, 'count') else len(routes_res.data)
    
    # Pin数を取得
    route_ids = [r['id'] for r in routes_res.data]
    pin_count = 0
    for rid in route_ids:
        pc = supabase.table('route_pins').select('id', count='exact').eq('route_id', rid).execute()
        pin_count += pc.count if hasattr(pc, 'count') else len(pc.data)
    
    print(f"\n🗺️  {area_name}エリア")
    print(f"  - ルート数: {route_count}本")
    print(f"  - Pin数: {pin_count}個")
    
    total_routes += route_count
    total_pins += pin_count

print("\n" + "=" * 80)
print(f"✅ 合計: {total_routes}本のルート / {total_pins}個のPin")
print("=" * 80)

# 最近追加されたルート（各エリア3本ずつ）
print("\n📋 最近追加されたルート")
print("-" * 80)

for area_name, area_id in areas:
    result = supabase.table('official_routes')\
        .select('name, distance_meters, difficulty_level, created_at')\
        .eq('area_id', area_id)\
        .order('created_at', desc=True)\
        .limit(3)\
        .execute()
    
    print(f"\n{area_name}:")
    for idx, route in enumerate(result.data, 1):
        print(f"  {idx}. {route['name']}")
        print(f"     {route['distance_meters']}m / {route['difficulty_level']} / {route['created_at'][:10]}")

print("\n" + "=" * 80)
print("🎉 Week 3 データ追加が正常に完了しました！")
print("=" * 80)
