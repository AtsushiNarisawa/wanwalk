import os
from supabase import create_client

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_KEY")
supabase = create_client(url, key)

# SQLファイルを読み込み
with open('supabase_migrations/013_favorite_routes.sql', 'r') as f:
    sql_content = f.read()

# SQL文を分割して実行
sql_statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip() and not stmt.strip().startswith('--')]

print("=== お気に入りルート機能のデプロイ開始 ===\n")

success_count = 0
error_count = 0

for i, stmt in enumerate(sql_statements, 1):
    if not stmt or stmt.startswith('COMMENT'):
        continue
        
    try:
        # テーブル作成、インデックス、RLS、関数などを実行
        result = supabase.rpc('exec_sql', {'query': stmt}).execute()
        print(f"✅ Statement {i}: Success")
        success_count += 1
    except Exception as e:
        # postgrest経由では実行できないので、直接postgresqlで実行が必要
        print(f"⚠️ Statement {i}: {str(e)[:100]}")
        error_count += 1

print(f"\n=== 完了 ===")
print(f"成功: {success_count}件")
print(f"エラー: {error_count}件")
print("\n注意: Supabase RPC経由ではDDL文を実行できません。")
print("Supabase SQL Editorで直接実行してください。")
