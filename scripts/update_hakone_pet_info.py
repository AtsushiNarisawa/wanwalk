#!/usr/bin/env python3
"""
箱根エリアのルートに愛犬家向け情報（pet_info）を追加するスクリプト
"""

import os
import sys
import json
from supabase import create_client, Client
from dotenv import load_dotenv

# .envファイルを読み込み
load_dotenv('/home/user/wanmap_v2/.env')

# Supabase接続（Service Role Keyを使用してRLSをバイパス）
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ エラー: SUPABASE_URLまたはSUPABASE_SERVICE_ROLE_KEYが設定されていません")
    print("💡 .envファイルに以下を設定してください:")
    print("   SUPABASE_URL=your_supabase_url")
    print("   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 箱根エリアID
HAKONE_AREA_ID = 'a1111111-1111-1111-1111-111111111111'

# 各ルートのpet_info設定
pet_info_data = {
    '芦ノ湖周遊コース': {
        'parking': 'あり（箱根町港駐車場・無料/桃源台駐車場・有料）',
        'surface': 'コンクリート 80% / 土・砂利 20%',
        'water_station': 'あり（箱根町港、桃源台、箱根園など複数箇所）',
        'restroom': 'あり（各主要スポットに設置）',
        'pet_facilities': 'ペット同伴可カフェ・レストラン多数、遊覧船ペット乗船可（ケージまたはキャリー必須）',
        'others': 'リード着用必須。湖畔は風が強い日があるため防寒対策推奨。全長10kmのため休憩を挟みながらの散歩を推奨。'
    },
    '大涌谷散策コース': {
        'parking': 'あり（大涌谷駐車場・有料）',
        'surface': 'コンクリート 100%（舗装路）',
        'water_station': 'あり（大涌谷駐車場エリア）',
        'restroom': 'あり（大涌谷駐車場）',
        'pet_facilities': 'ペット同伴可のお土産ショップあり',
        'others': 'リード着用必須。火山性ガスが発生しているため、体調の優れないペットは避けてください。標高が高く気温が低いため防寒対策必須。'
    },
    '仙石原すすき草原コース': {
        'parking': 'あり（仙石原すすき草原駐車場・無料）',
        'surface': '土・草地 60% / コンクリート 40%',
        'water_station': 'なし（事前に水を持参推奨）',
        'restroom': 'あり（駐車場近く）',
        'pet_facilities': '周辺にペット同伴可カフェあり',
        'others': 'リード着用必須。秋（9月下旬〜11月上旬）が見頃。草地を歩くため、散歩後の足拭き推奨。ダニ対策も忘れずに。'
    },
    '箱根湯本温泉街散策': {
        'parking': 'あり（箱根湯本駅周辺の有料駐車場複数）',
        'surface': 'コンクリート 100%',
        'water_station': 'なし（商店街の店舗で購入可能）',
        'restroom': 'あり（箱根湯本駅、商店街各所）',
        'pet_facilities': 'DogHub（ドッグカフェ・ホテル）、ペット同伴可の飲食店・お土産屋多数',
        'others': 'リード着用必須。温泉街のため人通りが多い。マナーを守った散歩を心がけてください。DogHubで休憩・ドリンク補給可能。'
    },
    '強羅公園周辺コース': {
        'parking': 'あり（強羅公園駐車場・有料）',
        'surface': 'コンクリート 70% / 土・砂利 30%',
        'water_station': 'あり（強羅公園入口）',
        'restroom': 'あり（強羅公園内）',
        'pet_facilities': '強羅公園はペット入園可（リード着用必須）、周辺にペット同伴可カフェあり',
        'others': 'リード着用必須。公園内は季節の花が美しく写真撮影スポット多数。坂道が多いため中型犬以上推奨。'
    },
    '箱根旧街道石畳コース': {
        'parking': 'あり（箱根旧街道入口駐車場・無料）',
        'surface': '石畳 60% / 土 40%',
        'water_station': 'なし（甘酒茶屋で購入可能）',
        'restroom': 'あり（甘酒茶屋）',
        'pet_facilities': '甘酒茶屋（ペット同伴可の休憩所）',
        'others': 'リード着用必須。歴史を感じる石畳の道。滑りやすい箇所があるため注意。小型犬でも歩けますが、足腰の強い犬向き。'
    },
    '早雲山〜大涌谷ハイキング': {
        'parking': 'あり（早雲山駅駐車場・有料）',
        'surface': '土・砂利 70% / コンクリート 30%',
        'water_station': 'なし（事前に水を持参必須）',
        'water_station': 'なし（事前に水を持参必須）',
        'restroom': 'あり（早雲山駅、大涌谷）',
        'pet_facilities': 'なし',
        'others': 'リード着用必須。本格的なハイキングコース。標高差が大きく体力が必要。大型犬・中型犬推奨。火山性ガスに注意。'
    },
    '元箱根・箱根神社参拝コース': {
        'parking': 'あり（箱根神社駐車場・無料）',
        'surface': 'コンクリート 60% / 土・砂利 40%',
        'water_station': 'あり（箱根神社境内）',
        'restroom': 'あり（箱根神社境内）',
        'pet_facilities': '周辺にペット同伴可カフェ・レストランあり',
        'others': 'リード着用必須。箱根神社境内はペット入場可（参拝は抱っこまたはキャリー推奨）。平和の鳥居は写真スポット。'
    },
    '小涌谷・蓬莱園散策': {
        'parking': 'あり（小涌谷駅周辺・有料）',
        'surface': 'コンクリート 50% / 土・草地 50%',
        'water_station': 'あり（蓬莱園内）',
        'restroom': 'あり（蓬莱園入口）',
        'pet_facilities': '岡田美術館足湯（ペット同伴可エリアあり）、周辺にペット同伴可カフェあり',
        'others': 'リード着用必須。つつじの季節（5月中旬〜6月上旬）が特に美しい。緑豊かで静かな散歩が楽しめます。'
    },
    # 追加のルート（汎用的な情報）
    'DogHub周遊コース': {
        'parking': 'あり（DogHub専用駐車場・無料）',
        'surface': 'コンクリート 60% / 土・砂利 40%',
        'water_station': 'あり（DogHub店内）',
        'restroom': 'あり（DogHub店内）',
        'pet_facilities': 'DogHub（ドッグカフェ・ホテル）、ドッグラン、シャワー設備あり',
        'others': 'リード着用必須。DogHubを拠点とした散歩コース。休憩・水分補給はDogHubで。'
    },
    '芦ノ湖畔散歩コース': {
        'parking': 'あり（箱根町港周辺・有料）',
        'surface': 'コンクリート 80% / 土・砂利 20%',
        'water_station': 'あり（箱根町港）',
        'restroom': 'あり（箱根町港）',
        'pet_facilities': '周辺にペット同伴可カフェあり',
        'others': 'リード着用必須。芦ノ湖の美しい景色を楽しめる散歩コース。'
    },
    '旧街道杉並木コース': {
        'parking': 'あり（箱根旧街道入口・無料）',
        'surface': '石畳・土 70% / コンクリート 30%',
        'water_station': 'なし（事前に水を持参推奨）',
        'restroom': 'あり（甘酒茶屋）',
        'pet_facilities': '甘酒茶屋（ペット同伴可の休憩所）',
        'others': 'リード着用必須。歴史ある杉並木と石畳の道。足腰の強い犬向き。'
    },
    '箱根旧街道散歩道': {
        'parking': 'あり（箱根旧街道入口・無料）',
        'surface': '石畳・土 60% / コンクリート 40%',
        'water_station': 'なし（甘酒茶屋で購入可能）',
        'restroom': 'あり（甘酒茶屋）',
        'pet_facilities': '甘酒茶屋（ペット同伴可）',
        'others': 'リード着用必須。江戸時代の石畳が残る歴史的な散歩道。'
    },
    '芦ノ湖畔ロングウォーク': {
        'parking': 'あり（桃源台・箱根町港など複数箇所）',
        'surface': 'コンクリート 75% / 土・砂利 25%',
        'water_station': 'あり（各主要スポット）',
        'restroom': 'あり（各主要スポット）',
        'pet_facilities': 'ペット同伴可カフェ・レストラン多数',
        'others': 'リード着用必須。長距離コースのため体力のある犬向き。休憩を挟みながらの散歩を推奨。'
    },
    '箱根神社参道コース': {
        'parking': 'あり（箱根神社駐車場・無料）',
        'surface': 'コンクリート 50% / 石畳・砂利 50%',
        'water_station': 'あり（箱根神社境内）',
        'restroom': 'あり（箱根神社境内）',
        'pet_facilities': '周辺にペット同伴可カフェあり',
        'others': 'リード着用必須。箱根神社境内はペット入場可（参拝は抱っこまたはキャリー推奨）。'
    },
    '箱根旧街道コース': {
        'parking': 'あり（箱根旧街道入口・無料）',
        'surface': '石畳 60% / 土 40%',
        'water_station': 'なし（事前に水を持参必須）',
        'restroom': 'あり（甘酒茶屋）',
        'pet_facilities': '甘酒茶屋（ペット同伴可）',
        'others': 'リード着用必須。本格的な石畳の道。滑りやすい箇所があるため注意。'
    },
    '元箱根港〜箱根町港コース': {
        'parking': 'あり（元箱根港・箱根町港周辺）',
        'surface': 'コンクリート 90% / 土 10%',
        'water_station': 'あり（各港周辺）',
        'restroom': 'あり（各港）',
        'pet_facilities': 'ペット同伴可カフェあり',
        'others': 'リード着用必須。芦ノ湖畔の平坦なコース。初心者・小型犬でも安心。'
    },
    '宮ノ下温泉街散策コース': {
        'parking': 'あり（宮ノ下駅周辺・有料）',
        'surface': 'コンクリート 100%',
        'water_station': 'なし（商店街で購入可能）',
        'restroom': 'あり（宮ノ下駅、商店街各所）',
        'pet_facilities': 'ペット同伴可の飲食店・カフェあり',
        'others': 'リード着用必須。温泉街のため人通りが多い時間帯あり。マナーを守った散歩を。'
    },
    '箱根湿生花園コース': {
        'parking': 'あり（箱根湿生花園駐車場・無料）',
        'surface': '土・草地 60% / コンクリート 40%',
        'water_station': 'あり（箱根湿生花園入口）',
        'restroom': 'あり（箱根湿生花園）',
        'pet_facilities': '箱根湿生花園はペット入園可（リード着用必須）',
        'others': 'リード着用必須。季節の花を楽しめる散歩コース。草地が多いため、散歩後の足拭き推奨。'
    },
}

def main():
    print("🐕 箱根エリアのルートにpet_infoを追加します\n")
    
    # 箱根エリアのルートを取得
    try:
        response = supabase.table('official_routes')\
            .select('id, name, area_id')\
            .eq('area_id', HAKONE_AREA_ID)\
            .execute()
        
        routes = response.data
        
        if not routes:
            print("❌ 箱根エリアのルートが見つかりません")
            sys.exit(1)
        
        print(f"✅ {len(routes)}本のルートを取得しました\n")
        
        # 各ルートにpet_infoを追加
        updated_count = 0
        skipped_count = 0
        
        for route in routes:
            route_name = route['name']
            route_id = route['id']
            
            if route_name in pet_info_data:
                pet_info = pet_info_data[route_name]
                
                # pet_infoを更新
                update_response = supabase.table('official_routes')\
                    .update({'pet_info': pet_info})\
                    .eq('id', route_id)\
                    .execute()
                
                print(f"✅ {route_name}: pet_infoを追加しました")
                updated_count += 1
            else:
                print(f"⚠️  {route_name}: pet_infoデータが定義されていません（スキップ）")
                skipped_count += 1
        
        print(f"\n📊 完了: {updated_count}件更新 / {skipped_count}件スキップ")
        
    except Exception as e:
        print(f"❌ エラーが発生しました: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
