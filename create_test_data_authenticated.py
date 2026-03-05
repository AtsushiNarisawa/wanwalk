#!/usr/bin/env python3
"""
WanWalk テストデータ作成スクリプト（認証付き）
既存ユーザーでログインしてからテストデータを作成します。
"""

import requests
import json
from datetime import datetime, timedelta
import random
import sys

# Supabase設定
SUPABASE_URL = "https://jkpenklhrlbctebkpvax.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8"

def get_user_credentials():
    """既存のユーザー情報を取得"""
    print("📝 Supabaseに登録済みのユーザー情報を入力してください")
    print()
    
    # テスト用デフォルト値
    default_email = "test@example.com"
    default_password = "test123456"
    
    email = input(f"メールアドレス (Enter = {default_email}): ").strip()
    if not email:
        email = default_email
    
    import getpass
    password = getpass.getpass(f"パスワード (Enter = {default_password}): ") or default_password
    
    return email, password

def login_user(email, password):
    """ユーザーとしてログイン"""
    print(f"\n🔐 ログイン中: {email}")
    
    response = requests.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Content-Type": "application/json"
        },
        json={
            "email": email,
            "password": password
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        access_token = data.get('access_token')
        user_id = data.get('user', {}).get('id')
        print(f"✅ ログイン成功: User ID = {user_id}")
        return access_token, user_id
    else:
        print(f"❌ ログイン失敗: {response.status_code} - {response.text}")
        return None, None

def generate_route_points(start_lat, start_lng, num_points=50):
    """ランダムな散歩ルートのGPSポイントを生成"""
    points = []
    current_lat = start_lat
    current_lng = start_lng
    
    for i in range(num_points):
        # ランダムに少しずつ移動（約5-10メートル）
        delta_lat = random.uniform(-0.0001, 0.0001)
        delta_lng = random.uniform(-0.0001, 0.0001)
        
        current_lat += delta_lat
        current_lng += delta_lng
        
        points.append({
            "latitude": current_lat,
            "longitude": current_lng,
            "altitude": random.uniform(100, 150),
            "timestamp": (datetime.now() - timedelta(minutes=num_points - i)).isoformat(),
            "sequence_number": i
        })
    
    return points

def create_route(access_token, user_id, title, description, distance, duration, start_lat, start_lng):
    """ルートを作成（認証付き）"""
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Prefer": "return=representation"
    }
    
    # 時刻を計算
    days_ago = random.randint(1, 30)
    started_at = datetime.now() - timedelta(days=days_ago, seconds=duration)
    ended_at = datetime.now() - timedelta(days=days_ago)
    
    route_data = {
        "user_id": user_id,
        "title": title,
        "description": description,
        "distance": distance,
        "duration": duration,
        "started_at": started_at.isoformat(),
        "ended_at": ended_at.isoformat(),
        "is_public": True,
        "created_at": ended_at.isoformat()
    }
    
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/routes",
        headers=headers,
        json=route_data
    )
    
    if response.status_code in [200, 201]:
        route = response.json()[0]
        route_id = route['id']
        print(f"✅ ルート作成成功: {title}")
        print(f"   ID: {route_id}")
        print(f"   距離: {distance}m, 時間: {duration}秒")
        
        # GPSポイントを作成
        num_points = int(duration / 10)  # 10秒ごとに1ポイント
        points = generate_route_points(start_lat, start_lng, num_points)
        
        # route_idを追加
        for point in points:
            point['route_id'] = route_id
        
        # ポイントをバッチ挿入
        point_response = requests.post(
            f"{SUPABASE_URL}/rest/v1/route_points",
            headers=headers,
            json=points
        )
        
        if point_response.status_code in [200, 201]:
            print(f"   ✅ GPSポイント {len(points)}件 追加完了")
        else:
            print(f"   ❌ GPSポイント追加失敗: {point_response.status_code}")
            print(f"      {point_response.text[:200]}")
        
        return route_id
    else:
        print(f"❌ ルート作成失敗: {response.status_code}")
        print(f"   {response.text[:200]}")
        return None

def add_photos_to_route(access_token, route_id, user_id, num_photos=3):
    """ルートに写真を追加（認証付き）"""
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Prefer": "return=representation"
    }
    
    photo_urls = [
        "https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800",
        "https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800",
        "https://images.unsplash.com/photo-1552053831-71594a27632d?w=800",
        "https://images.unsplash.com/photo-1517849845537-4d257902454a?w=800",
        "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=800",
        "https://images.unsplash.com/photo-1530281700549-e82e7bf110d6?w=800",
    ]
    
    success_count = 0
    for i in range(num_photos):
        photo_url = random.choice(photo_urls)
        
        photo_data = {
            "route_id": route_id,
            "user_id": user_id,
            "storage_path": f"test/{route_id}/{i}.jpg",
            "public_url": photo_url,
            "caption": f"散歩中の素敵な一枚 #{i+1}",
            "created_at": datetime.now().isoformat()
        }
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/route_photos",
            headers=headers,
            json=photo_data
        )
        
        if response.status_code in [200, 201]:
            success_count += 1
        else:
            print(f"   ❌ 写真 {i+1} 追加失敗: {response.status_code}")
    
    if success_count > 0:
        print(f"   ✅ 写真 {success_count}/{num_photos}件 追加完了")

def main():
    print("=" * 70)
    print("🐕 WanWalk テストデータ作成スクリプト（認証付き）")
    print("=" * 70)
    print()
    
    # ユーザーログイン
    email, password = get_user_credentials()
    access_token, user_id = login_user(email, password)
    
    if not access_token:
        print("\n❌ ログインに失敗しました。")
        print("   正しいメールアドレスとパスワードを入力してください。")
        sys.exit(1)
    
    print()
    print("-" * 70)
    print("📍 テストルート作成中...")
    print("-" * 70)
    print()
    
    # ルート1: 芦ノ湖畔散歩コース
    print("📍 ルート1: 芦ノ湖畔の朝散歩コース")
    route_id_1 = create_route(
        access_token=access_token,
        user_id=user_id,
        title="芦ノ湖畔の朝散歩コース",
        description="芦ノ湖の美しい景色を眺めながらの爽やかな朝の散歩。愛犬も大喜びでした！",
        distance=2500,
        duration=1800,
        start_lat=35.2050,
        start_lng=139.0250
    )
    
    if route_id_1:
        add_photos_to_route(access_token, route_id_1, user_id, 3)
    
    print()
    
    # ルート2: 箱根旧街道コース
    print("📍 ルート2: 箱根旧街道 歴史散歩")
    route_id_2 = create_route(
        access_token=access_token,
        user_id=user_id,
        title="箱根旧街道 歴史散歩",
        description="石畳の旧街道を歩く歴史ロマン溢れる散歩コース。杉並木が素晴らしかったです。",
        distance=3200,
        duration=2400,
        start_lat=35.2150,
        start_lng=139.0320
    )
    
    if route_id_2:
        add_photos_to_route(access_token, route_id_2, user_id, 2)
    
    print()
    
    # ルート3: 仙石原すすき草原コース
    print("📍 ルート3: 仙石原すすき草原 夕焼けコース")
    route_id_3 = create_route(
        access_token=access_token,
        user_id=user_id,
        title="仙石原すすき草原 夕焼けコース",
        description="黄金色に輝くすすき草原での夕方散歩。愛犬も走り回って楽しそうでした！",
        distance=1800,
        duration=1500,
        start_lat=35.2400,
        start_lng=139.0150
    )
    
    if route_id_3:
        add_photos_to_route(access_token, route_id_3, user_id, 3)
    
    print()
    print("=" * 70)
    print("✅ テストデータ作成完了！")
    print("=" * 70)
    print()
    print("📱 iPhoneアプリで以下を確認してください：")
    print("  1. アプリを再起動")
    print("  2. ホーム画面でルート一覧を表示")
    print("  3. 各ルートをタップして詳細表示")
    print("  4. 地図上にルートが描画されることを確認")
    print("  5. 写真ギャラリーが表示されることを確認")
    print("  6. 「写真を追加」ボタンをタップして動作確認")
    print()

if __name__ == "__main__":
    main()
