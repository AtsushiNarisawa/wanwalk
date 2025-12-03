import requests
import time

SUPABASE_URL = "https://jkpenklhrlbctebkpvax.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8"

# Routes to keep (21 routes)
KEEP_ROUTES = {
    # Hakone (3)
    "10000000-0000-0000-0000-000000000001",  # DogHub周遊コース
    "894302aa-ddd2-454e-b0ff-26d253b44158",  # 芦ノ湖周遊コース
    "f8d24e4e-d02d-446e-9079-d97ab07338f9",  # 強羅公園周辺コース
    # Yokohama (2)
    "20000000-0000-0000-0000-000000000001",  # 山下公園散歩コース
    "779d1816-0c24-4d91-b5b2-2fbfc3292024",  # 山下公園・港の見える丘公園コース
    # Kamakura (2)
    "36ed0efb-087a-4401-a6d6-b4f35e1cadbd",  # 長谷寺・大仏コース
    "8037d1b7-9451-482f-b0c8-4ddc8960cb54",  # 北鎌倉・円覚寺コース
    # Others (1 each)
    "7013fa14-d8d5-454a-9f71-81e528cad318",  # お台場・豊洲
    "cefa5918-ba2c-4ed5-8238-14d05aa229ed",  # 三浦半島
    "0728410d-a5b1-4576-8b07-cc03bc6a0ed9",  # 井の頭公園
    "5e40574f-48d2-4088-a7fd-a3bcb501d6a8",  # 代官山・中目黒
    "19b89d29-c13c-495d-95fe-1b9ebf54f130",  # 伊豆
    "bbf11dc7-b244-4525-ab17-e66b8cc9a447",  # 多摩川河川敷
    "86878fc9-61e8-4cc6-80ad-e12e363ef199",  # 房総半島
    "068bf109-3e28-43e1-b073-a83d0f8e32a0",  # 日光
    "005e71c4-da0f-450d-a155-624f5aa11323",  # 昭和記念公園
    "9395041d-8756-47cd-a1e3-5a5a8b72f0e4",  # 江ノ島
    "d1fc6d73-95ed-4f1f-a976-f348e6d08cab",  # 河口湖・山中湖
    "7dd98896-d756-4b5b-9130-ee0009c4d749",  # 草津温泉
    "2c4d80a3-41bd-4909-903d-295b820709cb",  # 葛西臨海公園
    "d6728d18-87aa-4e8a-b15d-df3233e4f5bb",  # 軽井沢
    "03a8a723-cf63-48c8-9dd6-c7bffa193145",  # 那須高原
}

headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}"
}

# Get all routes
response = requests.get(f"{SUPABASE_URL}/rest/v1/official_routes?select=id", headers=headers)
all_routes = response.json()

deleted = 0
kept = 0

for route in all_routes:
    route_id = route['id']
    
    if route_id in KEEP_ROUTES:
        print(f"✓ 保持: {route_id}")
        kept += 1
    else:
        print(f"✗ 削除: {route_id}")
        delete_response = requests.delete(
            f"{SUPABASE_URL}/rest/v1/official_routes?id=eq.{route_id}",
            headers=headers
        )
        deleted += 1
        time.sleep(0.1)  # Rate limiting

print(f"\n完了！")
print(f"保持: {kept}ルート")
print(f"削除: {deleted}ルート")
