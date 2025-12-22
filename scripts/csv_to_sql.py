#!/usr/bin/env python3
"""
WanWalk ルート作成CSVからSQL変換スクリプト

使い方:
  python csv_to_sql.py routes.csv insert_routes.sql
"""

import csv
import uuid
import json
import sys
from datetime import datetime

# エリア名→area_id変換マップ
AREA_MAP = {
    '箱根': 'a1111111-1111-1111-1111-111111111111',
    '伊豆': 'a2222222-2222-2222-2222-222222222222',
    '那須': 'a3333333-3333-3333-3333-333333333333',
    '鎌倉': 'a4444444-4444-4444-4444-444444444444',
    '横浜': 'a5555555-5555-5555-5555-555555555555',
}

def escape_sql_string(s):
    """SQLのシングルクォートをエスケープ"""
    return s.replace("'", "''")

def csv_to_sql(csv_file_path, output_sql_path):
    """CSVファイルをSQLファイルに変換"""
    
    try:
        with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            
            sql_statements = []
            sql_statements.append("-- ========================================")
            sql_statements.append("-- WanWalk ルート一括投入SQL")
            sql_statements.append(f"-- 生成日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            sql_statements.append(f"-- ソースCSV: {csv_file_path}")
            sql_statements.append("-- ========================================\n")
            
            route_count = 0
            
            for idx, row in enumerate(reader, start=1):
                # エリアIDを取得
                area_name = row.get('エリア', '').strip()
                area_id = AREA_MAP.get(area_name)
                
                if not area_id:
                    print(f"⚠️  警告: 行{idx} - エリア '{area_name}' が見つかりません。新規UUIDを生成します。")
                    area_id = str(uuid.uuid4())
                
                # 必須フィールドのチェック
                required_fields = ['ルート名', 'ルート説明', '距離km', '所要時間分', '難易度', '標高差m']
                missing_fields = [f for f in required_fields if not row.get(f, '').strip()]
                
                if missing_fields:
                    print(f"❌ エラー: 行{idx} - 必須フィールドが空です: {', '.join(missing_fields)}")
                    continue
                
                # pet_infoをJSON形式で構築
                pet_info = {
                    "parking": row.get('駐車場情報', '').strip(),
                    "surface": row.get('路面状況', '').strip(),
                    "restroom": row.get('トイレ情報', '').strip(),
                    "water_station": row.get('水飲み場情報', '').strip(),
                    "pet_facilities": row.get('ペット関連施設', '').strip(),
                    "others": row.get('その他備考', '').strip()
                }
                
                # JSON文字列化（エスケープ処理）
                pet_info_json = json.dumps(pet_info, ensure_ascii=False)
                
                # SQL生成
                sql = f"""
-- ルート{idx}: {escape_sql_string(row['ルート名'])}
INSERT INTO official_routes (
  id,
  area_id,
  title,
  description,
  start_location,
  end_location,
  route_line,
  distance_km,
  estimated_duration_minutes,
  difficulty,
  elevation_gain_m,
  total_pins,
  total_walks,
  pet_info,
  created_at,
  updated_at
)
VALUES (
  gen_random_uuid(),
  '{area_id}'::uuid,
  '{escape_sql_string(row['ルート名'])}',
  '{escape_sql_string(row['ルート説明'])}',
  NULL,  -- 後で座標に変換: {escape_sql_string(row.get('開始地点住所', ''))}
  NULL,  -- 後で座標に変換: {escape_sql_string(row.get('終了地点住所', ''))}
  NULL,  -- 後で手動でroute_lineを追加
  {row['距離km']},
  {row['所要時間分']},
  '{row['難易度']}',
  {row['標高差m']},
  0,
  0,
  '{escape_sql_string(pet_info_json)}'::jsonb,
  now(),
  now()
);
"""
                sql_statements.append(sql)
                route_count += 1
            
            # SQLファイルに出力
            with open(output_sql_path, 'w', encoding='utf-8') as sqlfile:
                sqlfile.write('\n'.join(sql_statements))
                sqlfile.write("\n\n-- ============================================\n")
                sqlfile.write(f"-- 完了メッセージ\n")
                sqlfile.write("-- ============================================\n")
                sqlfile.write(f"SELECT '{route_count}件のルート投入が完了しました' AS status;\n")
            
            print(f"✅ {route_count}件のルートをSQLに変換しました: {output_sql_path}")
            print(f"\n次のステップ:")
            print(f"1. {output_sql_path} を開く")
            print(f"2. 開始地点・終了地点の座標（NULL部分）をGoogle Mapsで取得して置換")
            print(f"3. Supabase SQL Editorで実行")
            print(f"4. 後日、route_lineを手動で追加")
            
    except FileNotFoundError:
        print(f"❌ エラー: ファイルが見つかりません: {csv_file_path}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ エラー: {e}")
        sys.exit(1)

def main():
    if len(sys.argv) != 3:
        print("使い方: python csv_to_sql.py <入力CSV> <出力SQL>")
        print("例: python csv_to_sql.py routes.csv insert_routes.sql")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    sql_file = sys.argv[2]
    
    print(f"🔄 CSV→SQL変換を開始します...")
    print(f"   入力: {csv_file}")
    print(f"   出力: {sql_file}\n")
    
    csv_to_sql(csv_file, sql_file)

if __name__ == '__main__':
    main()
