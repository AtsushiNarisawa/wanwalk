#!/usr/bin/env python3
"""
鎌倉エリアに4本の公式ルートを追加するスクリプト
"""

import os
import sys
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv('/home/user/wanmap_v2/.env')

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ エラー: SUPABASE_URLまたはSUPABASE_SERVICE_ROLE_KEYが設定されていません")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 鎌倉エリアID
KAMAKURA_AREA_ID = 'a3333333-3333-3333-3333-333333333333'

# 鎌倉エリアの4本のルート
routes = [
    {
        'name': '鎌倉大仏周辺コース',
        'description': '高徳院の大仏を中心とした約2kmの歴史散策コース。鎌倉のシンボルである大仏を間近で見られます。愛犬と一緒に境内を散策でき、周辺には江ノ電の長谷駅や土産物店も。静かな住宅街を歩く癒しのコースで、鎌倉らしい落ち着いた雰囲気を楽しめます。',
        'distance_meters': 2000.0,
        'estimated_minutes': 30,
        'elevation_gain_meters': 20.0,
        'difficulty_level': 'easy',
        'start_lat': 35.3167,
        'start_lon': 139.5365,
        'end_lat': 35.3167,
        'end_lon': 139.5365,
    },
    {
        'name': '材木座海岸コース',
        'description': '鎌倉の美しい海岸線を歩く約4kmのコース。砂浜を愛犬と一緒に走ったり、波打ち際で遊んだりできます。サーファーや海水浴客で賑わい、開放感抜群。夕暮れ時は特に美しく、富士山のシルエットも見られます。海沿いのカフェで休憩も最高です。',
        'distance_meters': 4000.0,
        'estimated_minutes': 50,
        'elevation_gain_meters': 5.0,
        'difficulty_level': 'easy',
        'start_lat': 35.3080,
        'start_lon': 139.5650,
        'end_lat': 35.3080,
        'end_lon': 139.5650,
    },
    {
        'name': '鶴岡八幡宮〜若宮大路コース',
        'description': '鎌倉のメインストリートを歩く約3kmのコース。鶴岡八幡宮への参道である若宮大路は、両側に桜並木が続き春は特に美しい。愛犬と一緒に参拝でき、小町通りでは食べ歩きやショッピングも楽しめます。鎌倉の歴史と文化を感じられる定番コースです。',
        'distance_meters': 3000.0,
        'estimated_minutes': 40,
        'elevation_gain_meters': 15.0,
        'difficulty_level': 'easy',
        'start_lat': 35.3260,
        'start_lon': 139.5550,
        'end_lat': 35.3260,
        'end_lon': 139.5550,
    },
    {
        'name': '北鎌倉寺社めぐりコース',
        'description': '北鎌倉の名刹を巡る約5kmのコース。円覚寺、建長寺、明月院など歴史ある寺院を訪れます。愛犬は抱っこが必要な場所もありますが、静かな山道を歩きながら鎌倉五山の雰囲気を堪能できます。紫陽花や紅葉の季節は特に美しく、写真撮影にも最適です。',
        'distance_meters': 5000.0,
        'estimated_minutes': 70,
        'elevation_gain_meters': 80.0,
        'difficulty_level': 'moderate',
        'start_lat': 35.3370,
        'start_lon': 139.5470,
        'end_lat': 35.3370,
        'end_lon': 139.5470,
    },
]

def main():
    print("=" * 60)
    print("⛩️  鎌倉エリア - 4本のルート追加開始")
    print("=" * 60)
    
    success_count = 0
    error_count = 0
    
    for idx, route in enumerate(routes, 1):
        try:
            route_data = {
                'area_id': KAMAKURA_AREA_ID,
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
