#!/usr/bin/env python3
"""
WanWalk テストデータ自動セットアップスクリプト

このスクリプトは以下を自動で実行します:
1. Supabaseにテストユーザーを作成
2. テストデータ（ルート、写真、コメントなど）をデータベースに投入
"""

import requests
import json
from datetime import datetime, timedelta

# Supabase設定
SUPABASE_URL = "https://jkpenklhrlbctebkpvax.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8"

# 注意: Service Role Keyが必要です（ユーザー作成のため）
# Supabase Dashboard → Settings → API → service_role key
SUPABASE_SERVICE_KEY = input("Supabase Service Role Key を入力してください: ").strip()

# APIエンドポイント
AUTH_URL = f"{SUPABASE_URL}/auth/v1"
REST_URL = f"{SUPABASE_URL}/rest/v1"

# ヘッダー設定
headers_service = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json"
}

headers_anon = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# テストユーザー情報
TEST_USERS = [
    {"email": "test1@example.com", "password": "test1234"},
    {"email": "test2@example.com", "password": "test1234"},
    {"email": "test3@example.com", "password": "test1234"},
]

def create_test_users():
    """テストユーザーを作成"""
    print("\n" + "="*60)
    print("ステップ1: テストユーザーの作成")
    print("="*60)
    
    user_ids = []
    
    for user in TEST_USERS:
        print(f"\n📧 {user['email']} を作成中...")
        
        # ユーザー作成
        response = requests.post(
            f"{AUTH_URL}/admin/users",
            headers=headers_service,
            json={
                "email": user["email"],
                "password": user["password"],
                "email_confirm": True
            }
        )
        
        if response.status_code in [200, 201]:
            user_data = response.json()
            user_id = user_data["id"]
            user_ids.append(user_id)
            print(f"   ✅ 作成成功: User ID = {user_id}")
        else:
            print(f"   ⚠️  エラー: {response.status_code}")
            print(f"   {response.text}")
            # 既存ユーザーの場合、IDを取得
            if "already been registered" in response.text or response.status_code == 422:
                print("   既存ユーザーです。IDを取得します...")
                # ログインしてIDを取得
                login_response = requests.post(
                    f"{AUTH_URL}/token?grant_type=password",
                    headers=headers_anon,
                    json={
                        "email": user["email"],
                        "password": user["password"]
                    }
                )
                if login_response.status_code == 200:
                    user_id = login_response.json()["user"]["id"]
                    user_ids.append(user_id)
                    print(f"   ✅ ID取得成功: User ID = {user_id}")
                else:
                    print(f"   ❌ ID取得失敗: {login_response.text}")
                    return None
    
    print(f"\n✅ すべてのユーザーが準備できました")
    return user_ids

def delete_existing_data():
    """既存のテストデータを削除"""
    print("\n" + "="*60)
    print("ステップ2: 既存データの削除")
    print("="*60)
    
    tables = ["photos", "comments", "favorites", "route_points", "routes"]
    
    for table in tables:
        print(f"\n🗑️  {table} テーブルをクリア中...")
        
        # すべてのレコードを取得
        response = requests.get(
            f"{REST_URL}/{table}?select=*",
            headers=headers_anon
        )
        
        if response.status_code == 200:
            records = response.json()
            print(f"   削除対象: {len(records)}件")
            
            # 各レコードを削除
            for record in records:
                if "id" in record:
                    del_response = requests.delete(
                        f"{REST_URL}/{table}?id=eq.{record['id']}",
                        headers=headers_anon
                    )
                    if del_response.status_code not in [200, 204]:
                        print(f"   ⚠️  削除エラー: {del_response.text}")
            
            print(f"   ✅ クリア完了")
        else:
            print(f"   ⚠️  取得エラー: {response.status_code}")

def insert_test_data(user_ids):
    """テストデータを投入"""
    print("\n" + "="*60)
    print("ステップ3: テストデータの投入")
    print("="*60)
    
    user_id_1, user_id_2, user_id_3 = user_ids
    
    # 現在時刻
    now = datetime.utcnow()
    
    # ルートデータ
    routes = [
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "user_id": user_id_1,
            "title": "芦ノ湖畔の朝散歩",
            "description": "芦ノ湖の美しい湖畔を愛犬と一緒にのんびり散歩しました。早朝の静けさと富士山の眺めが最高でした。",
            "distance": 2500.0,
            "duration": 1800,
            "start_time": (now - timedelta(days=5)).isoformat(),
            "end_time": (now - timedelta(days=5) + timedelta(minutes=30)).isoformat(),
            "is_public": True,
            "prefecture": "神奈川県",
            "area": "hakone",
            "thumbnail_url": "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
            "like_count": 15,
            "created_at": (now - timedelta(days=5)).isoformat()
        },
        {
            "id": "00000000-0000-0000-0000-000000000002",
            "user_id": user_id_1,
            "title": "大涌谷から早雲山のハイキング",
            "description": "大涌谷の絶景を楽しみながら早雲山まで登りました。愛犬も元気いっぱい！硫黄の香りが印象的でした。",
            "distance": 5200.0,
            "duration": 4500,
            "start_time": (now - timedelta(days=3)).isoformat(),
            "end_time": (now - timedelta(days=3) + timedelta(minutes=75)).isoformat(),
            "is_public": True,
            "prefecture": "神奈川県",
            "area": "hakone",
            "thumbnail_url": "https://images.unsplash.com/photo-1551632811-561732d1e306?w=800",
            "like_count": 23,
            "created_at": (now - timedelta(days=3)).isoformat()
        },
        {
            "id": "00000000-0000-0000-0000-000000000003",
            "user_id": user_id_1,
            "title": "箱根湯本温泉街さんぽ",
            "description": "箱根湯本の温泉街を散策。お土産屋さんを見ながらのんびり歩きました。愛犬も温泉街の雰囲気を楽しんでいました。",
            "distance": 1800.0,
            "duration": 1200,
            "start_time": (now - timedelta(days=2)).isoformat(),
            "end_time": (now - timedelta(days=2) + timedelta(minutes=20)).isoformat(),
            "is_public": True,
            "prefecture": "神奈川県",
            "area": "hakone",
            "thumbnail_url": "https://images.unsplash.com/photo-1528164344705-47542687000d?w=800",
            "like_count": 8,
            "created_at": (now - timedelta(days=2)).isoformat()
        },
        {
            "id": "00000000-0000-0000-0000-000000000004",
            "user_id": user_id_2,
            "title": "仙石原の森林浴トレイル",
            "description": "仙石原の美しい森の中をトレッキング。マイナスイオンたっぷりで愛犬も大喜び。",
            "distance": 3500.0,
            "duration": 2700,
            "start_time": (now - timedelta(days=1)).isoformat(),
            "end_time": (now - timedelta(days=1) + timedelta(minutes=45)).isoformat(),
            "is_public": True,
            "prefecture": "神奈川県",
            "area": "hakone",
            "thumbnail_url": "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800",
            "like_count": 12,
            "created_at": (now - timedelta(days=1)).isoformat()
        },
        {
            "id": "00000000-0000-0000-0000-000000000005",
            "user_id": user_id_1,
            "title": "自宅周辺の散歩",
            "description": "いつもの散歩コース。愛犬のお気に入りルートです。",
            "distance": 1200.0,
            "duration": 900,
            "start_time": (now - timedelta(hours=6)).isoformat(),
            "end_time": (now - timedelta(hours=6) + timedelta(minutes=15)).isoformat(),
            "is_public": False,
            "prefecture": "神奈川県",
            "area": "hakone",
            "like_count": 5,
            "created_at": (now - timedelta(hours=6)).isoformat()
        }
    ]
    
    print("\n📍 ルートデータを投入中...")
    response = requests.post(
        f"{REST_URL}/routes",
        headers=headers_anon,
        json=routes
    )
    
    if response.status_code in [200, 201]:
        print(f"   ✅ {len(routes)}件のルートを作成しました")
    else:
        print(f"   ❌ エラー: {response.status_code}")
        print(f"   {response.text}")
        return False
    
    # ルートポイントデータ
    route_points = []
    
    # ルート1のポイント（芦ノ湖畔）
    for i in range(7):
        route_points.append({
            "route_id": "00000000-0000-0000-0000-000000000001",
            "latitude": 35.2043 + (i * 0.0005),
            "longitude": 139.0248 + (i * 0.0006),
            "altitude": 723.0 + i,
            "sequence_number": i + 1,
            "recorded_at": (now - timedelta(days=5) + timedelta(minutes=i*5)).isoformat()
        })
    
    # ルート2のポイント（大涌谷〜早雲山）
    for i in range(8):
        route_points.append({
            "route_id": "00000000-0000-0000-0000-000000000002",
            "latitude": 35.2443 + (i * 0.0007),
            "longitude": 139.0206 + (i * 0.0010),
            "altitude": 1044.0 + (i * 20),
            "sequence_number": i + 1,
            "recorded_at": (now - timedelta(days=3) + timedelta(minutes=i*10)).isoformat()
        })
    
    print("\n📍 GPSポイントを投入中...")
    response = requests.post(
        f"{REST_URL}/route_points",
        headers=headers_anon,
        json=route_points
    )
    
    if response.status_code in [200, 201]:
        print(f"   ✅ {len(route_points)}件のGPSポイントを作成しました")
    else:
        print(f"   ❌ エラー: {response.status_code}")
        print(f"   {response.text}")
    
    # 写真データ
    photos = [
        # ルート1の写真
        {"route_id": "00000000-0000-0000-0000-000000000001", "url": "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200", "caption": "芦ノ湖と富士山の絶景", "latitude": 35.2043, "longitude": 139.0248, "created_at": (now - timedelta(days=5)).isoformat()},
        {"route_id": "00000000-0000-0000-0000-000000000001", "url": "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=1200", "caption": "湖畔の散歩道", "latitude": 35.2053, "longitude": 139.0258, "created_at": (now - timedelta(days=5) + timedelta(minutes=10)).isoformat()},
        {"route_id": "00000000-0000-0000-0000-000000000001", "url": "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1200", "caption": "朝の静けさ", "latitude": 35.2068, "longitude": 139.0275, "created_at": (now - timedelta(days=5) + timedelta(minutes=25)).isoformat()},
        
        # ルート2の写真
        {"route_id": "00000000-0000-0000-0000-000000000002", "url": "https://images.unsplash.com/photo-1551632811-561732d1e306?w=1200", "caption": "大涌谷の噴煙", "latitude": 35.2443, "longitude": 139.0206, "created_at": (now - timedelta(days=3)).isoformat()},
        {"route_id": "00000000-0000-0000-0000-000000000002", "url": "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200", "caption": "山頂からの眺め", "latitude": 35.2465, "longitude": 139.0235, "created_at": (now - timedelta(days=3) + timedelta(minutes=30)).isoformat()},
        {"route_id": "00000000-0000-0000-0000-000000000002", "url": "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1200", "caption": "森の中の小道", "latitude": 35.2480, "longitude": 139.0255, "created_at": (now - timedelta(days=3) + timedelta(minutes=50)).isoformat()},
        {"route_id": "00000000-0000-0000-0000-000000000002", "url": "https://images.unsplash.com/photo-1511884642898-4c92249e20b6?w=1200", "caption": "愛犬と一緒に", "latitude": 35.2495, "longitude": 139.0275, "created_at": (now - timedelta(days=3) + timedelta(minutes=70)).isoformat()},
        
        # ルート3の写真
        {"route_id": "00000000-0000-0000-0000-000000000003", "url": "https://images.unsplash.com/photo-1528164344705-47542687000d?w=1200", "caption": "箱根湯本の温泉街", "latitude": 35.2325, "longitude": 139.1068, "created_at": (now - timedelta(days=2)).isoformat()},
        {"route_id": "00000000-0000-0000-0000-000000000003", "url": "https://images.unsplash.com/photo-1513002749550-c59d786b8e6c?w=1200", "caption": "かわいいお土産屋さん", "latitude": 35.2328, "longitude": 139.1072, "created_at": (now - timedelta(days=2) + timedelta(minutes=10)).isoformat()},
    ]
    
    print("\n📷 写真データを投入中...")
    response = requests.post(
        f"{REST_URL}/photos",
        headers=headers_anon,
        json=photos
    )
    
    if response.status_code in [200, 201]:
        print(f"   ✅ {len(photos)}件の写真を作成しました")
    else:
        print(f"   ❌ エラー: {response.status_code}")
        print(f"   {response.text}")
    
    # お気に入りデータ
    favorites = [
        {"user_id": user_id_2, "route_id": "00000000-0000-0000-0000-000000000001", "created_at": (now - timedelta(days=4)).isoformat()},
        {"user_id": user_id_2, "route_id": "00000000-0000-0000-0000-000000000002", "created_at": (now - timedelta(days=2)).isoformat()},
        {"user_id": user_id_3, "route_id": "00000000-0000-0000-0000-000000000001", "created_at": (now - timedelta(days=3)).isoformat()},
    ]
    
    print("\n❤️  お気に入りデータを投入中...")
    response = requests.post(
        f"{REST_URL}/favorites",
        headers=headers_anon,
        json=favorites
    )
    
    if response.status_code in [200, 201]:
        print(f"   ✅ {len(favorites)}件のお気に入りを作成しました")
    else:
        print(f"   ❌ エラー: {response.status_code}")
        print(f"   {response.text}")
    
    # コメントデータ
    comments = [
        {"route_id": "00000000-0000-0000-0000-000000000001", "user_id": user_id_2, "content": "芦ノ湖の朝は最高ですね！私も行ってみたいです。", "created_at": (now - timedelta(days=4)).isoformat()},
        {"route_id": "00000000-0000-0000-0000-000000000001", "user_id": user_id_3, "content": "富士山の眺めが素晴らしい！ワンちゃんも楽しそう。", "created_at": (now - timedelta(days=3)).isoformat()},
        {"route_id": "00000000-0000-0000-0000-000000000002", "user_id": user_id_2, "content": "大涌谷はワンちゃんも入れるんですね！知りませんでした。", "created_at": (now - timedelta(days=2)).isoformat()},
        {"route_id": "00000000-0000-0000-0000-000000000002", "user_id": user_id_3, "content": "長距離お疲れさまでした。私も今度チャレンジしてみます！", "created_at": (now - timedelta(days=1)).isoformat()},
    ]
    
    print("\n💬 コメントデータを投入中...")
    response = requests.post(
        f"{REST_URL}/comments",
        headers=headers_anon,
        json=comments
    )
    
    if response.status_code in [200, 201]:
        print(f"   ✅ {len(comments)}件のコメントを作成しました")
    else:
        print(f"   ❌ エラー: {response.status_code}")
        print(f"   {response.text}")
    
    return True

def main():
    """メイン処理"""
    print("\n" + "="*60)
    print("🐕 WanWalk テストデータ自動セットアップ")
    print("="*60)
    
    try:
        # ステップ1: テストユーザー作成
        user_ids = create_test_users()
        if not user_ids or len(user_ids) != 3:
            print("\n❌ ユーザー作成に失敗しました")
            return
        
        # ステップ2: 既存データ削除
        delete_existing_data()
        
        # ステップ3: テストデータ投入
        success = insert_test_data(user_ids)
        
        if success:
            print("\n" + "="*60)
            print("✅ テストデータのセットアップが完了しました！")
            print("="*60)
            print("\n📱 次のステップ:")
            print("   1. アプリで test1@example.com / test1234 でログイン")
            print("   2. ルート一覧で5件のルートを確認")
            print("   3. 写真の拡大表示をテスト")
            print("   4. GPS記録の一時停止/再開をテスト")
            print("\n🎉 テストを開始してください！")
        else:
            print("\n❌ データ投入に失敗しました")
    
    except Exception as e:
        print(f"\n❌ エラーが発生しました: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
