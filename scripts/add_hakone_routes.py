#!/usr/bin/env python3
"""
箱根エリアに9本の公式ルートを追加するスクリプト
"""

import os
import sys
from supabase import create_client, Client
from dotenv import load_dotenv

# .envファイルを読み込み
load_dotenv('/home/user/wanmap_v2/.env')

# Supabase接続（Service Role Keyを使用してRLSをバイパス）
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ エラー: SUPABASE_URLまたはSUPABASE_SERVICE_ROLE_KEYが設定されていません")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 箱根エリアID
HAKONE_AREA_ID = 'a1111111-1111-1111-1111-111111111111'

# 箱根エリアの9本のルート
routes = [
    {
        'name': '芦ノ湖周遊コース',
        'description': '芦ノ湖を一周する約10kmのコース。湖畔の美しい景色を楽しみながら、愛犬とゆったり散歩できます。春は桜、秋は紅葉が美しく、四季折々の表情を見せてくれます。遊覧船や箱根神社の鳥居など見どころも豊富で、休憩スポットも多数あります。',
        'distance_meters': 10000.0,
        'estimated_minutes': 120,
        'elevation_gain_meters': 50.0,
        'difficulty_level': 'moderate',
        'start_lat': 35.2328,
        'start_lon': 139.0268,
        'end_lat': 35.2328,
        'end_lon': 139.0268,
    },
    {
        'name': '大涌谷散策コース',
        'description': '大涌谷の火山活動を間近で見られる約3kmのコース。硫黄の香りと迫力ある景色が魅力。愛犬と一緒に箱根の自然を体感できます。展望台からは富士山も望め、名物の黒たまごを食べながら休憩できます。舗装された道で歩きやすいのも特徴です。',
        'distance_meters': 3000.0,
        'estimated_minutes': 45,
        'elevation_gain_meters': 100.0,
        'difficulty_level': 'easy',
        'start_lat': 35.2438,
        'start_lon': 139.0268,
        'end_lat': 35.2438,
        'end_lon': 139.0268,
    },
    {
        'name': '箱根神社参道コース',
        'description': '箱根神社への参道を歩く約2kmのコース。樹齢数百年の杉並木が続く神秘的な雰囲気の中、愛犬と一緒に心を清められます。湖畔に立つ平和の鳥居は絶好の撮影スポット。境内は犬も同伴可能で、運気アップを願えます。',
        'distance_meters': 2000.0,
        'estimated_minutes': 30,
        'elevation_gain_meters': 30.0,
        'difficulty_level': 'easy',
        'start_lat': 35.2050,
        'start_lon': 139.0240,
        'end_lat': 35.2050,
        'end_lon': 139.0240,
    },
    {
        'name': '仙石原すすき草原コース',
        'description': '仙石原の広大なすすき草原を歩く約5kmのコース。秋には一面金色に輝くススキが風になびく幻想的な景色を楽しめます。平坦な道が続くので愛犬も歩きやすく、開放感あふれる散歩を満喫できます。周辺には美術館やカフェも充実。',
        'distance_meters': 5000.0,
        'estimated_minutes': 60,
        'elevation_gain_meters': 20.0,
        'difficulty_level': 'easy',
        'start_lat': 35.2480,
        'start_lon': 139.0380,
        'end_lat': 35.2480,
        'end_lon': 139.0380,
    },
    {
        'name': '箱根旧街道コース',
        'description': '江戸時代の東海道を辿る約8kmの歴史コース。石畳の道を愛犬と歩きながら、当時の旅人の気分を味わえます。杉並木や一里塚など歴史的な見どころが点在。やや起伏がありますが、達成感のある本格的なハイキングを楽しめます。',
        'distance_meters': 8000.0,
        'estimated_minutes': 100,
        'elevation_gain_meters': 200.0,
        'difficulty_level': 'hard',
        'start_lat': 35.2150,
        'start_lon': 139.0100,
        'end_lat': 35.2150,
        'end_lon': 139.0100,
    },
    {
        'name': '強羅公園周辺コース',
        'description': '強羅公園を中心とした約3kmの散策コース。四季折々の花が咲き誇る公園内を愛犬と散歩できます（一部エリアは抱っこが必要）。温泉街の風情を感じながら、カフェやお土産店巡りも楽しめます。坂道が多いですが距離は短め。',
        'distance_meters': 3000.0,
        'estimated_minutes': 40,
        'elevation_gain_meters': 80.0,
        'difficulty_level': 'easy',
        'start_lat': 35.2500,
        'start_lon': 139.0450,
        'end_lat': 35.2500,
        'end_lon': 139.0450,
    },
    {
        'name': '元箱根港〜箱根町港コース',
        'description': '芦ノ湖の湖畔を歩く約4kmの爽快コース。遊覧船を眺めながら愛犬とのんびり散歩できます。晴れた日には富士山の絶景を望め、写真撮影にも最適。港周辺には飲食店や休憩所が充実しており、一日中楽しめます。',
        'distance_meters': 4000.0,
        'estimated_minutes': 50,
        'elevation_gain_meters': 10.0,
        'difficulty_level': 'easy',
        'start_lat': 35.2030,
        'start_lon': 139.0250,
        'end_lat': 35.2080,
        'end_lon': 139.0300,
    },
    {
        'name': '宮ノ下温泉街散策コース',
        'description': '明治創業の老舗ホテルや温泉施設が並ぶレトロな温泉街を歩く約2kmのコース。愛犬と一緒にタイムスリップしたような雰囲気を楽しめます。クラシックな建築物や坂道の風景が魅力的。ペット同伴OKのカフェも点在しています。',
        'distance_meters': 2000.0,
        'estimated_minutes': 30,
        'elevation_gain_meters': 50.0,
        'difficulty_level': 'easy',
        'start_lat': 35.2350,
        'start_lon': 139.0320,
        'end_lat': 35.2350,
        'end_lon': 139.0320,
    },
    {
        'name': '箱根湿生花園コース',
        'description': '箱根湿生花園周辺を散策する約3kmの自然観察コース。湿地帯に咲く珍しい植物を愛犬と一緒に観察できます（園内は抱っこが必要）。木道が整備されており歩きやすく、自然の音に癒されます。春から夏にかけては特に花が美しい時期です。',
        'distance_meters': 3000.0,
        'estimated_minutes': 45,
        'elevation_gain_meters': 15.0,
        'difficulty_level': 'easy',
        'start_lat': 35.2460,
        'start_lon': 139.0400,
        'end_lat': 35.2460,
        'end_lon': 139.0400,
    },
]

def main():
    print("=" * 60)
    print("🗻 箱根エリア - 9本のルート追加開始")
    print("=" * 60)
    
    success_count = 0
    error_count = 0
    
    for idx, route in enumerate(routes, 1):
        try:
            # PostGIS形式でGEOGRAPHYデータを作成
            route_data = {
                'area_id': HAKONE_AREA_ID,
                'name': route['name'],
                'description': route['description'],
                'distance_meters': route['distance_meters'],
                'estimated_minutes': route['estimated_minutes'],
                'elevation_gain_meters': route['elevation_gain_meters'],
                'difficulty_level': route['difficulty_level'],
                'start_location': f"SRID=4326;POINT({route['start_lon']} {route['start_lat']})",
                'end_location': f"SRID=4326;POINT({route['end_lon']} {route['end_lat']})",
            }
            
            # データベースに挿入
            result = supabase.table('official_routes').insert(route_data).execute()
            
            print(f"✅ [{idx}/9] {route['name']} を追加しました")
            success_count += 1
            
        except Exception as e:
            print(f"❌ [{idx}/9] {route['name']} の追加に失敗: {str(e)}")
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
