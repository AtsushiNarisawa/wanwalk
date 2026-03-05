#!/usr/bin/env python3
"""
Supabase SQL Migration Deployer
指定されたSQLファイルをSupabase APIを通じて実行する
"""
import os
import sys
import requests
from pathlib import Path

# .env ファイルから接続情報を取得
def load_env():
    env_path = Path(__file__).parent.parent / '.env'
    env_vars = {}
    
    if env_path.exists():
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip()
    
    return env_vars

def execute_sql_migration(sql_file_path):
    """SQLマイグレーションファイルを実行"""
    
    # 環境変数読み込み
    env = load_env()
    supabase_url = env.get('SUPABASE_URL')
    service_role_key = env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if not supabase_url or not service_role_key:
        print("❌ エラー: .envファイルからSupabase接続情報を取得できません")
        sys.exit(1)
    
    # SQLファイル読み込み
    sql_path = Path(sql_file_path)
    if not sql_path.exists():
        print(f"❌ エラー: SQLファイルが見つかりません: {sql_file_path}")
        sys.exit(1)
    
    with open(sql_path, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print(f"📂 SQLファイル: {sql_path.name}")
    print(f"📊 SQLサイズ: {len(sql_content)} bytes")
    print(f"🔗 Supabase URL: {supabase_url}")
    print()
    
    # Supabase REST APIでSQL実行
    # Note: Supabaseは直接のSQL実行APIを持たないため、
    # PostgreSQL REST APIまたはpg_dumpを使う必要があります
    # ここではSupabase CLIの代替として、RPC経由での実行を試みます
    
    # Project Refを抽出
    project_ref = supabase_url.replace('https://', '').split('.')[0]
    
    # PostgreSQL直接接続URLを構築
    postgres_url = f"postgresql://postgres.{project_ref}:postgres@db.{project_ref}.supabase.co:5432/postgres"
    
    print("⚠️  注意: Python + requestsではPostgreSQL直接実行ができません")
    print("以下の方法でSQLを実行してください:")
    print()
    print("【方法1】Supabase Dashboard で実行:")
    print(f"  1. {supabase_url.replace('/rest/', '')}/project/{project_ref}/editor/sql にアクセス")
    print(f"  2. 以下のSQLファイルの内容をコピー&ペーストして実行:")
    print(f"     {sql_path.absolute()}")
    print()
    print("【方法2】ローカルでpsqlを使用:")
    print(f"  psql '{postgres_url}' -f {sql_path.absolute()}")
    print()
    print("【方法3】Supabase CLIを使用:")
    print(f"  supabase db push --db-url '{postgres_url}' --file {sql_path.absolute()}")
    print()
    
    # SQLファイルの内容を表示
    print("=" * 60)
    print("実行するSQL:")
    print("=" * 60)
    print(sql_content)
    print("=" * 60)
    
    return True

if __name__ == '__main__':
    sql_file = '/home/user/wanwalk/supabase_migrations/008_add_get_recent_pins.sql'
    execute_sql_migration(sql_file)
