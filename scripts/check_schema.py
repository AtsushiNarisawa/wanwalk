#!/usr/bin/env python3
"""
official_routesテーブルのスキーマを確認
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv('/home/user/wanwalk/.env')

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY')

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 既存のルートを1件取得してカラム構造を確認
try:
    result = supabase.table('official_routes').select('*').limit(1).execute()
    
    if result.data and len(result.data) > 0:
        print("✅ official_routes テーブルのカラム:")
        print("-" * 60)
        for key in result.data[0].keys():
            print(f"  - {key}")
        print("-" * 60)
        print("\n📄 サンプルデータ:")
        import json
        print(json.dumps(result.data[0], indent=2, ensure_ascii=False))
    else:
        print("⚠️  テーブルにデータがありません")
        
except Exception as e:
    print(f"❌ エラー: {str(e)}")
