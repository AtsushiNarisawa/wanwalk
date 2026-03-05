#!/usr/bin/env python3
"""
横浜エリアに4本の公式ルートを追加するスクリプト
"""

import os
import sys
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv('/home/user/wanwalk/.env')

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ エラー: SUPABASE_URLまたはSUPABASE_SERVICE_ROLE_KEYが設定されていません")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 横浜エリアID
YOKOHAMA_AREA_ID = 'a2222222-2222-2222-2222-222222222222'

# 横浜エリアの4本のルート
routes = [
    {
        'name': 'みなとみらい海岸線コース',
        'description': 'みなとみらいの海岸線を散歩する約5kmのコース。横浜ランドマークタワーや赤レンガ倉庫、大観覧車などの観光スポットを巡りながら、愛犬と海風を感じられます。夜景も美しく、デートコースとしても人気。カフェやレストランも多く、休憩スポットに困りません。',
        'distance_meters': 5000.0,
        'estimated_minutes': 60,
        'elevation_gain_meters': 10.0,
        'difficulty_level': 'easy',
        'start_lat': 35.4537,
        'start_lon': 139.6380,
        'end_lat': 35.4537,
        'end_lon': 139.6380,
    },
    {
        'name': '山下公園〜中華街コース',
        'description': '山下公園から中華街を巡る約3kmのコース。海沿いの公園を散歩した後、中華街の賑やかな雰囲気を楽しめます。愛犬と一緒にテラス席で食事ができる店も多数。氷川丸やマリンタワーなど見どころも満載で、横浜の魅力を凝縮したコースです。',
        'distance_meters': 3000.0,
        'estimated_minutes': 40,
        'elevation_gain_meters': 5.0,
        'difficulty_level': 'easy',
        'start_lat': 35.4437,
        'start_lon': 139.6500,
        'end_lat': 35.4437,
        'end_lon': 139.6500,
    },
    {
        'name': '三溪園周遊コース',
        'description': '本格的な日本庭園を散策する約4kmのコース。広大な敷地に歴史的建造物が点在し、四季折々の花や紅葉が美しい。愛犬は抱っこまたはカートが必要なエリアもありますが、庭園周辺の散策路は自由に歩けます。静かで落ち着いた雰囲気が魅力です。',
        'distance_meters': 4000.0,
        'estimated_minutes': 50,
        'elevation_gain_meters': 30.0,
        'difficulty_level': 'moderate',
        'start_lat': 35.4200,
        'start_lon': 139.6450,
        'end_lat': 35.4200,
        'end_lon': 139.6450,
    },
    {
        'name': 'こどもの国コース',
        'description': '広大な自然公園を歩く約6kmのコース。芝生広場や池、雑木林など変化に富んだ景色を楽しめます。愛犬ものびのびと走り回れる開放的な空間。週末は家族連れで賑わい、他の犬と触れ合う機会も多数。アスレチックや牧場など見どころも豊富です。',
        'distance_meters': 6000.0,
        'estimated_minutes': 80,
        'elevation_gain_meters': 50.0,
        'difficulty_level': 'easy',
        'start_lat': 35.5350,
        'start_lon': 139.4850,
        'end_lat': 35.5350,
        'end_lon': 139.4850,
    },
]

def main():
    print("=" * 60)
    print("🌊 横浜エリア - 4本のルート追加開始")
    print("=" * 60)
    
    success_count = 0
    error_count = 0
    
    for idx, route in enumerate(routes, 1):
        try:
            route_data = {
                'area_id': YOKOHAMA_AREA_ID,
                'name': route['name'],
                'description': route['description'],
                'distance_meters': route['distance_meters'],
                'estimated_minutes': route['estimated_minutes'],
                'elevation_gain_meters': route['elevation_gain_meters'],
                'difficulty_level': route['difficulty_level'],
                'start_location': f"SRID=4326;POINT({route['start_lon']} {route['start_lat']})",
                'end_location': f"SRID=4326;POINT({route['end_lon']} {route['end_lat']})",
            }
            
            result = supabase.table('official_routes').insert(route_data).execute()
            
            print(f"✅ [{idx}/4] {route['name']} を追加しました")
            success_count += 1
            
        except Exception as e:
            print(f"❌ [{idx}/4] {route['name']} の追加に失敗: {str(e)}")
            error_count += 1
    
    print("\n" + "=" * 60)
    print(f"📊 結果: 成功 {success_count}件 / 失敗 {error_count}件")
    print("=" * 60)
    
    if error_count == 0:
        print("\n🎉 すべてのルートの追加が完了しました！")
    else:
        print(f"\n⚠️  {error_count}件のエラーがありました")

if __name__ == '__main__':
    main()
