import os
from supabase import create_client

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_KEY")
supabase = create_client(url, key)

# 関数定義を取得
result = supabase.rpc("get_areas_simple").execute()

print("=== get_areas_simple() 結果サンプル (3件) ===")
for i, area in enumerate(result.data[:3], 1):
    print(f"\n{i}. {area.get('name')}")
    print(f"   ID: {area.get('id')}")
    print(f"   latitude: {area.get('latitude')} (type: {type(area.get('latitude'))})")
    print(f"   longitude: {area.get('longitude')} (type: {type(area.get('longitude'))})")
    print(f"   prefecture: {area.get('prefecture')}")
