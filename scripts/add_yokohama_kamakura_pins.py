#!/usr/bin/env python3
"""
横浜・鎌倉エリアの各ルートにサンプルPinを追加
"""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv('/home/user/wanwalk/.env')
supabase = create_client(os.getenv('SUPABASE_URL'), os.getenv('SUPABASE_SERVICE_ROLE_KEY'))
TEST_USER = 'e09b6a6b-fb41-44ff-853e-7cc437836c77'

# エリアごとのPin
pins = {
    'a2222222-2222-2222-2222-222222222222': [  # 横浜
        {'route': 'みなとみらい海岸線コース', 'pins': [
            {'type': 'scenery', 'title': 'ランドマークタワーと愛犬', 'comment': '横浜のシンボルをバックに撮影。絶景です！', 'lat': 35.4537, 'lon': 139.6380},
            {'type': 'shop', 'title': 'ペット同伴OKのカフェ', 'comment': '海が見えるテラス席で休憩。最高でした。', 'lat': 35.4545, 'lon': 139.6390},
            {'type': 'encounter', 'title': 'ダックスフンドと遭遇', 'comment': '可愛いダックスちゃんと仲良くなりました。', 'lat': 35.4530, 'lon': 139.6370},
        ]},
        {'route': '山下公園〜中華街コース', 'pins': [
            {'type': 'scenery', 'title': '氷川丸と愛犬', 'comment': '歴史的な船をバックに記念撮影できます。', 'lat': 35.4437, 'lon': 139.6500},
            {'type': 'shop', 'title': '中華街のテラス席', 'comment': 'ペット同伴で中華料理を楽しめました。', 'lat': 35.4445, 'lon': 139.6510},
            {'type': 'encounter', 'title': 'ポメラニアンと遭遇', 'comment': '元気いっぱいのポメちゃん。可愛かったです。', 'lat': 35.4430, 'lon': 139.6490},
        ]},
        {'route': '三溪園周遊コース', 'pins': [
            {'type': 'scenery', 'title': '日本庭園の美', 'comment': '四季折々の花が美しい。癒されます。', 'lat': 35.4200, 'lon': 139.6450},
            {'type': 'other', 'title': '歴史的建造物', 'comment': '古い建物を見ながら散歩。風情があります。', 'lat': 35.4205, 'lon': 139.6455},
        ]},
        {'route': 'こどもの国コース', 'pins': [
            {'type': 'scenery', 'title': '広大な芝生広場', 'comment': '愛犬が思い切り走れる開放的な空間です。', 'lat': 35.5350, 'lon': 139.4850},
            {'type': 'encounter', 'title': 'ラブラドールと遊ぶ', 'comment': '大型犬同士で楽しく遊びました。', 'lat': 35.5355, 'lon': 139.4855},
            {'type': 'other', 'title': 'ピクニックエリア', 'comment': 'お弁当を食べながら愛犬とのんびり。', 'lat': 35.5345, 'lon': 139.4845},
        ]},
    ],
    'a3333333-3333-3333-3333-333333333333': [  # 鎌倉
        {'route': '鎌倉大仏周辺コース', 'pins': [
            {'type': 'scenery', 'title': '大仏と愛犬', 'comment': '鎌倉のシンボルと記念撮影。最高の思い出です。', 'lat': 35.3167, 'lon': 139.5365},
            {'type': 'shop', 'title': 'ペット同伴OKの茶屋', 'comment': '抹茶を飲みながら休憩。和の雰囲気が素敵。', 'lat': 35.3170, 'lon': 139.5370},
            {'type': 'encounter', 'title': '秋田犬と遭遇', 'comment': '大きくて優しい秋田犬。触らせてもらいました。', 'lat': 35.3165, 'lon': 139.5360},
        ]},
        {'route': '材木座海岸コース', 'pins': [
            {'type': 'scenery', 'title': '海岸線の夕焼け', 'comment': '夕暮れ時の海が美しい。富士山も見えました。', 'lat': 35.3080, 'lon': 139.5650},
            {'type': 'encounter', 'title': 'ビーグルと遊ぶ', 'comment': '砂浜で愛犬同士が楽しく遊びました。', 'lat': 35.3085, 'lon': 139.5655},
            {'type': 'shop', 'title': '海沿いのカフェ', 'comment': 'テラス席で海を見ながらランチ。最高でした。', 'lat': 35.3075, 'lon': 139.5645},
        ]},
        {'route': '鶴岡八幡宮〜若宮大路コース', 'pins': [
            {'type': 'scenery', 'title': '桜並木の参道', 'comment': '春は桜が綺麗。愛犬と散歩するのが楽しいです。', 'lat': 35.3260, 'lon': 139.5550},
            {'type': 'shop', 'title': '小町通りのお店', 'comment': 'ペット同伴OKのお店が多くて便利。', 'lat': 35.3265, 'lon': 139.5555},
            {'type': 'other', 'title': '鶴岡八幡宮', 'comment': '愛犬と一緒に参拝できます。縁起が良い。', 'lat': 35.3255, 'lon': 139.5545},
        ]},
        {'route': '北鎌倉寺社めぐりコース', 'pins': [
            {'type': 'scenery', 'title': '紅葉の寺院', 'comment': '秋の紅葉が美しい。写真映えします。', 'lat': 35.3370, 'lon': 139.5470},
            {'type': 'other', 'title': '静かな山道', 'comment': '自然豊かで癒されます。愛犬も喜んでいました。', 'lat': 35.3375, 'lon': 139.5475},
            {'type': 'encounter', 'title': 'シェルティと遭遇', 'comment': '賢くて可愛いシェルティちゃん。仲良くなりました。', 'lat': 35.3365, 'lon': 139.5465},
        ]},
    ],
}

total = 0
for area_id, routes in pins.items():
    area_name = '横浜' if '2222' in area_id else '鎌倉'
    print(f"\n{'='*60}\n{area_name}エリアのPin追加\n{'='*60}")
    
    for route_data in routes:
        res = supabase.table('official_routes').select('id').eq('area_id', area_id).eq('name', route_data['route']).single().execute()
        route_id = res.data['id']
        
        print(f"\n🗺️  {route_data['route']} ({len(route_data['pins'])}個)")
        for idx, p in enumerate(route_data['pins'], 1):
            supabase.table('route_pins').insert({
                'route_id': route_id,
                'user_id': TEST_USER,
                'location': f"SRID=4326;POINT({p['lon']} {p['lat']})",
                'pin_type': p['type'],
                'title': p['title'],
                'comment': p['comment'],
            }).execute()
            print(f"  ✅ [{idx}/{len(route_data['pins'])}] {p['title']}")
            total += 1

print(f"\n{'='*60}\n📊 合計: {total}個のPinを追加しました\n{'='*60}\n🎉 完了！")
