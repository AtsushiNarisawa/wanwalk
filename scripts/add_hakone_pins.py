#!/usr/bin/env python3
"""
箱根エリアの9本のルートに各3-5個のサンプルPinを追加
"""

import os
import json
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv('/home/user/wanmap_v2/.env')

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# ルートIDマッピングを読み込み
with open('/home/user/wanmap_v2/scripts/hakone_route_ids.json', 'r', encoding='utf-8') as f:
    route_ids = json.load(f)

# テストユーザーID（プロジェクトドキュメントに記載）
TEST_USER_ID = 'e09b6a6b-fb41-44ff-853e-7cc437836c77'

# 各ルートのサンプルPin
pins_data = {
    '芦ノ湖周遊コース': [
        {
            'pin_type': 'scenery',
            'title': '芦ノ湖と富士山の絶景',
            'comment': '天気が良ければ富士山が綺麗に見えます！愛犬も大喜びでした。',
            'lat': 35.2328,
            'lon': 139.0268,
        },
        {
            'pin_type': 'shop',
            'title': 'ペット同伴OKのカフェ',
            'comment': '湖畔のテラス席でワンちゃんと一緒にランチできます。',
            'lat': 35.2340,
            'lon': 139.0280,
        },
        {
            'pin_type': 'encounter',
            'title': '柴犬ちゃんと仲良くなりました',
            'comment': '散歩中に柴犬ちゃんと出会って、一緒に遊びました。',
            'lat': 35.2310,
            'lon': 139.0250,
        },
        {
            'pin_type': 'scenery',
            'title': '遊覧船と愛犬',
            'comment': '遊覧船をバックに愛犬の写真を撮影。最高の思い出です。',
            'lat': 35.2350,
            'lon': 139.0290,
        },
    ],
    '大涌谷散策コース': [
        {
            'pin_type': 'scenery',
            'title': '迫力の火山活動',
            'comment': '硫黄の香りがすごい！愛犬も興味津々でした。',
            'lat': 35.2438,
            'lon': 139.0268,
        },
        {
            'pin_type': 'shop',
            'title': '黒たまご売店',
            'comment': '名物の黒たまごを購入。ペットも一緒に休憩できます。',
            'lat': 35.2445,
            'lon': 139.0275,
        },
        {
            'pin_type': 'scenery',
            'title': '展望台からの富士山',
            'comment': '展望台から富士山が見えました。絶景です！',
            'lat': 35.2430,
            'lon': 139.0260,
        },
    ],
    '箱根神社参道コース': [
        {
            'pin_type': 'scenery',
            'title': '平和の鳥居',
            'comment': '湖に浮かぶ赤い鳥居が神秘的。愛犬と一緒に記念撮影しました。',
            'lat': 35.2050,
            'lon': 139.0240,
        },
        {
            'pin_type': 'encounter',
            'title': 'ゴールデンレトリバーと遭遇',
            'comment': '大型犬と仲良くなって、飼い主さんとも情報交換できました。',
            'lat': 35.2055,
            'lon': 139.0245,
        },
        {
            'pin_type': 'other',
            'title': '杉並木の癒し空間',
            'comment': '樹齢数百年の杉並木に癒されます。夏でも涼しいです。',
            'lat': 35.2045,
            'lon': 139.0235,
        },
    ],
    '仙石原すすき草原コース': [
        {
            'pin_type': 'scenery',
            'title': '黄金色のススキ草原',
            'comment': '秋には一面ススキが黄金色に輝いて幻想的です。',
            'lat': 35.2480,
            'lon': 139.0380,
        },
        {
            'pin_type': 'shop',
            'title': 'ペットOKのレストラン',
            'comment': 'テラス席でペットと一緒に食事ができます。',
            'lat': 35.2485,
            'lon': 139.0390,
        },
        {
            'pin_type': 'encounter',
            'title': 'トイプードルの群れ',
            'comment': '小型犬のお散歩会に遭遇。みんな可愛かったです。',
            'lat': 35.2475,
            'lon': 139.0375,
        },
        {
            'pin_type': 'other',
            'title': 'ススキの撮影スポット',
            'comment': 'インスタ映えする撮影ポイント。多くの人が写真を撮っていました。',
            'lat': 35.2490,
            'lon': 139.0385,
        },
    ],
    '箱根旧街道コース': [
        {
            'pin_type': 'scenery',
            'title': '石畳の歴史道',
            'comment': '江戸時代の石畳が残っています。歴史を感じます。',
            'lat': 35.2150,
            'lon': 139.0100,
        },
        {
            'pin_type': 'other',
            'title': '一里塚',
            'comment': '当時の旅人の目印だった一里塚。愛犬も興味津々。',
            'lat': 35.2155,
            'lon': 139.0105,
        },
        {
            'pin_type': 'encounter',
            'title': '柴犬と記念撮影',
            'comment': '日本犬同士の出会い。飼い主さんも喜んでくれました。',
            'lat': 35.2145,
            'lon': 139.0095,
        },
    ],
    '強羅公園周辺コース': [
        {
            'pin_type': 'scenery',
            'title': '四季の花々',
            'comment': '季節ごとに違う花が咲いています。散歩が楽しいです。',
            'lat': 35.2500,
            'lon': 139.0450,
        },
        {
            'pin_type': 'shop',
            'title': 'ペット同伴OKのカフェ',
            'comment': '公園近くのおしゃれなカフェ。テラス席が快適です。',
            'lat': 35.2505,
            'lon': 139.0455,
        },
        {
            'pin_type': 'other',
            'title': '温泉街の風情',
            'comment': 'レトロな温泉街を散策。愛犬も楽しそうでした。',
            'lat': 35.2495,
            'lon': 139.0445,
        },
    ],
    '元箱根港〜箱根町港コース': [
        {
            'pin_type': 'scenery',
            'title': '遊覧船の発着',
            'comment': '遊覧船を眺めながらのんびり散歩。癒されます。',
            'lat': 35.2030,
            'lon': 139.0250,
        },
        {
            'pin_type': 'shop',
            'title': '港のお土産店',
            'comment': 'ペット用のお土産もあります。記念品を購入しました。',
            'lat': 35.2050,
            'lon': 139.0270,
        },
        {
            'pin_type': 'encounter',
            'title': 'チワワちゃんと遭遇',
            'comment': '小さくて可愛いチワワちゃん。仲良くなれました。',
            'lat': 35.2040,
            'lon': 139.0260,
        },
        {
            'pin_type': 'scenery',
            'title': '富士山ビュー',
            'comment': '晴れた日は富士山が綺麗に見えます。最高です！',
            'lat': 35.2060,
            'lon': 139.0280,
        },
    ],
    '宮ノ下温泉街散策コース': [
        {
            'pin_type': 'scenery',
            'title': 'レトロな温泉街',
            'comment': '明治時代の雰囲気が残る温泉街。タイムスリップした気分です。',
            'lat': 35.2350,
            'lon': 139.0320,
        },
        {
            'pin_type': 'shop',
            'title': 'ペット同伴OKのベーカリー',
            'comment': '老舗のパン屋さん。テラス席で愛犬とパンを楽しめます。',
            'lat': 35.2355,
            'lon': 139.0325,
        },
        {
            'pin_type': 'other',
            'title': 'クラシックな建築',
            'comment': '歴史的建造物が素敵。散歩しながら建築鑑賞できます。',
            'lat': 35.2345,
            'lon': 139.0315,
        },
    ],
    '箱根湿生花園コース': [
        {
            'pin_type': 'scenery',
            'title': '珍しい湿地植物',
            'comment': '普段見られない植物がたくさん。自然観察が楽しいです。',
            'lat': 35.2460,
            'lon': 139.0400,
        },
        {
            'pin_type': 'other',
            'title': '木道散歩',
            'comment': '整備された木道が歩きやすい。愛犬も快適そうです。',
            'lat': 35.2465,
            'lon': 139.0405,
        },
        {
            'pin_type': 'encounter',
            'title': 'コーギーと遭遇',
            'comment': '元気いっぱいのコーギーちゃん。一緒に走りました。',
            'lat': 35.2455,
            'lon': 139.0395,
        },
    ],
}

def main():
    print("=" * 80)
    print("📍 箱根エリア - サンプルPin追加開始")
    print("=" * 80)
    
    total_success = 0
    total_error = 0
    
    for route_name, route_id in route_ids.items():
        if route_name not in pins_data:
            print(f"⚠️  {route_name} のPinデータが見つかりません")
            continue
        
        pins = pins_data[route_name]
        print(f"\n🗺️  {route_name} ({len(pins)}個のPin)")
        print("-" * 80)
        
        for idx, pin in enumerate(pins, 1):
            try:
                pin_data = {
                    'route_id': route_id,
                    'user_id': TEST_USER_ID,
                    'location': f"SRID=4326;POINT({pin['lon']} {pin['lat']})",
                    'pin_type': pin['pin_type'],
                    'title': pin['title'],
                    'comment': pin.get('comment', ''),
                }
                
                result = supabase.table('route_pins').insert(pin_data).execute()
                
                print(f"  ✅ [{idx}/{len(pins)}] {pin['title']}")
                total_success += 1
                
            except Exception as e:
                print(f"  ❌ [{idx}/{len(pins)}] {pin['title']} - {str(e)}")
                total_error += 1
    
    print("\n" + "=" * 80)
    print(f"📊 結果: 成功 {total_success}件 / 失敗 {total_error}件")
    print("=" * 80)
    
    if total_error == 0:
        print("\n🎉 すべてのPinの追加が完了しました！")
    else:
        print(f"\n⚠️  {total_error}件のエラーがありました")

if __name__ == '__main__':
    main()
