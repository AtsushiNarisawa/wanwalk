#!/usr/bin/env python3
"""
Supabase RPCデプロイヤー (REST API版)
Supabase Management APIを使用してSQLを実行
"""
import os
import sys
import requests
from pathlib import Path
import json

def load_env():
    """環境変数を.envファイルから読み込む"""
    env_path = Path(__file__).parent.parent / '.env'
    env_vars = {}
    
    if env_path.exists():
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    if '=' in line:
                        key, value = line.split('=', 1)
                        env_vars[key.strip()] = value.strip()
    
    return env_vars

def execute_sql_via_rest_api(sql_content):
    """Supabase REST APIを使ってSQLを実行"""
    env = load_env()
    supabase_url = env.get('SUPABASE_URL')
    service_role_key = env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if not supabase_url or not service_role_key:
        print("❌ エラー: Supabase接続情報が見つかりません")
        return False
    
    # Project Refを取得
    project_ref = supabase_url.replace('https://', '').split('.')[0]
    
    print(f"📡 Supabase Project: {project_ref}")
    print(f"🔗 URL: {supabase_url}")
    print()
    
    # Supabase PostgreREST APIを使用してRPCを作成
    # 注意: REST APIでは直接SQLを実行できないため、
    # PostgREST経由でアクセスする必要があります
    
    # 代替案: Supabase Edgeを使用してRPCを呼び出す方法
    api_url = f"{supabase_url}/rest/v1/rpc/exec_sql"
    
    headers = {
        'apikey': service_role_key,
        'Authorization': f'Bearer {service_role_key}',
        'Content-Type': 'application/json'
    }
    
    payload = {
        'query': sql_content
    }
    
    print("⚠️  Supabase REST APIでは直接SQLを実行できません")
    print("以下の手順で手動実行してください:")
    print()
    print("【推奨】Supabase SQL Editor で実行:")
    print(f"  1. https://supabase.com/dashboard/project/{project_ref}/editor/sql にアクセス")
    print(f"  2. 新しいクエリを作成")
    print(f"  3. 以下のSQLをコピー&ペースト:")
    print()
    print("=" * 70)
    print(sql_content)
    print("=" * 70)
    print()
    print("  4. 'Run' ボタンをクリック")
    print()
    
    return True

if __name__ == '__main__':
    # SQLファイルを読み込み
    sql_file = Path(__file__).parent.parent / 'supabase_migrations' / '008_add_get_recent_pins.sql'
    
    if not sql_file.exists():
        print(f"❌ SQLファイルが見つかりません: {sql_file}")
        sys.exit(1)
    
    with open(sql_file, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print(f"📂 SQLファイル: {sql_file.name}")
    print(f"📊 サイズ: {len(sql_content)} bytes")
    print()
    
    execute_sql_via_rest_api(sql_content)
