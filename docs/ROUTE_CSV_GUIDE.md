# WanWalk ルート作成CSVガイド

## 📊 CSV管理によるルート作成フロー

CSVファイルで複数のルートを一括管理し、効率的にデータベースに投入できます。

---

## 📁 1. CSVテンプレート

### ダウンロード

`route_template.csv` をダウンロードして、Excelやスプレッドシートで編集してください。

### CSV列定義

| 列名 | 必須 | データ型 | 説明 | 入力例 |
|------|------|---------|------|--------|
| **ルート名** | ✅ | TEXT | ルートの名前 | 芦ノ湖湖畔散歩コース（元箱根港〜箱根公園） |
| **エリア** | ✅ | TEXT | エリア名 | 箱根・仙石原大涌谷 / 箱根・芦ノ湖元箱根 / 横浜 / 鎌倉 など（詳細は下記エリアIDマップ参照） |
| **ルート説明** | ✅ | TEXT | ルートの詳細説明 | 元箱根港を起点に、箱根恩賜公園を経由して湖畔を散歩するコース... |
| **距離km** | ✅ | NUMERIC | 距離（キロメートル） | 2.5 |
| **所要時間分** | ✅ | INTEGER | 所要時間（分）※愛犬連れ速度3.0km/h | 50 |
| **難易度** | ✅ | TEXT | easy / moderate / hard | easy |
| **標高差m** | ✅ | INTEGER | 標高差（メートル） | 30 |
| **駐車場情報** | ✅ | TEXT | 駐車場の有無・料金など | あり（元箱根港駐車場・有料500円/日） |
| **路面状況** | ✅ | TEXT | 路面の種類と割合 | コンクリート 80% / 土・砂利 20% |
| **トイレ情報** | ✅ | TEXT | トイレの有無・場所 | あり（元箱根港、箱根公園内） |
| **水飲み場情報** | ✅ | TEXT | 水飲み場の有無・場所 | あり（箱根公園入口、湖畔複数箇所） |
| **ペット関連施設** | ⚪ | TEXT | ペット同伴可施設など | 周辺にペット同伴可カフェあり |
| **その他備考** | ⚪ | TEXT | その他の注意事項 | リード着用必須。GW・紅葉期は混雑 |
| **開始地点住所** | ✅ | TEXT | 開始地点の住所または目印 | 神奈川県足柄下郡箱根町元箱根 元箱根港駐車場 |
| **終了地点住所** | ✅ | TEXT | 終了地点の住所または目印 | 神奈川県足柄下郡箱根町元箱根 元箱根港駐車場（往復） |
| **写真URL1** | ⚪ | TEXT | 写真のURL（1枚目） | https://example.com/photo1.jpg |
| **写真URL2** | ⚪ | TEXT | 写真のURL（2枚目） | https://example.com/photo2.jpg |
| **写真URL3** | ⚪ | TEXT | 写真のURL（3枚目） | https://example.com/photo3.jpg |
| **写真URL4** | ⚪ | TEXT | 写真のURL（4枚目） | https://example.com/photo4.jpg |
| **写真URL5** | ⚪ | TEXT | 写真のURL（5枚目） | https://example.com/photo5.jpg |

---

## 📝 2. CSV編集のポイント

### ✅ 難易度の選択肢

| 値 | 説明 |
|----|------|
| `easy` | 初心者・小型犬向け / 平坦で舗装路 |
| `moderate` | 中級者向け / 一部坂道あり |
| `hard` | 上級者向け / 急坂・未舗装路あり |

### ✅ エリア名とエリアIDの対応

#### 箱根エリア（親エリア + 5サブエリア）

| エリア名 | area_id | 説明 |
|---------|---------|------|
| **箱根（親エリア）** | a1111111-1111-1111-1111-111111111111 | 箱根全体を表す親エリア |
| 箱根・湯本塔ノ沢 | b1111111-1111-1111-1111-111111111111 | 箱根湯本・塔ノ沢エリア（温泉街） |
| 箱根・宮ノ下小涌谷 | b2222222-2222-2222-2222-222222222222 | 宮ノ下・小涌谷エリア（彫刻の森） |
| 箱根・強羅早雲山 | b3333333-3333-3333-3333-333333333333 | 強羅・早雲山エリア（強羅公園） |
| 箱根・仙石原大涌谷 | b4444444-4444-4444-4444-444444444444 | 仙石原・大涌谷エリア（**DogHub所在地**） |
| 箱根・芦ノ湖元箱根 | b5555555-5555-5555-5555-555555555555 | 芦ノ湖・元箱根エリア（湖畔散策） |

#### その他のエリア

| エリア名 | area_id | 説明 |
|---------|---------|------|
| 横浜 | a2222222-2222-2222-2222-222222222222 | 横浜市全体 |
| 鎌倉 | a3333333-3333-3333-3333-333333333333 | 鎌倉市全体 |
| 伊豆 | ※要確認 | 伊豆半島エリア |
| 那須 | ※要確認 | 那須高原エリア |
| 軽井沢 | ※要確認 | 軽井沢エリア |
| 富士山周辺 | ※要確認 | 富士五湖エリア |

**注意**: 実際のデータベースに登録されているエリアIDは、Supabaseで以下のSQLを実行して確認してください：

```sql
SELECT id, name, prefecture FROM areas ORDER BY name;
```

### ✅ 所要時間の目安

**愛犬連れの速度：3.0 km/h**

| 距離 | 所要時間（分） |
|------|--------------|
| 1.0 km | 20分 |
| 2.0 km | 40分 |
| 2.5 km | 50分 |
| 3.0 km | 60分 |
| 5.0 km | 100分 |

計算式: `所要時間（分） = 距離（km） ÷ 3.0 × 60`

### ✅ CSV編集時の注意点

1. **カンマ区切りで保存**（UTF-8エンコーディング推奨）
2. **改行を含むテキストは引用符で囲む**
   - 例: `"元箱根港を起点に、
   箱根恩賜公園を経由..."`
3. **カンマを含むテキストも引用符で囲む**
   - 例: `"あり（元箱根港、箱根公園内）"`
4. **数値は引用符なし**
   - 例: `2.5` ✅ / `"2.5"` ⚠️

---

## 🔧 3. CSVからSQLへの変換

### 自動変換スクリプト（Python）

以下のPythonスクリプトでCSVを一括SQL変換できます：

```python
import csv
import uuid
from datetime import datetime

# エリア名→area_id変換マップ
AREA_MAP = {
    '箱根': 'a1111111-1111-1111-1111-111111111111',
    '伊豆': 'a2222222-2222-2222-2222-222222222222',
    '那須': 'a3333333-3333-3333-3333-333333333333',
    '鎌倉': 'a4444444-4444-4444-4444-444444444444',
    '横浜': 'a5555555-5555-5555-5555-555555555555',
}

def csv_to_sql(csv_file_path, output_sql_path):
    with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        
        sql_statements = []
        
        for row in reader:
            # エリアIDを取得
            area_id = AREA_MAP.get(row['エリア'], str(uuid.uuid4()))
            
            # pet_infoをJSON形式で構築
            pet_info = {
                "parking": row['駐車場情報'],
                "surface": row['路面状況'],
                "restroom": row['トイレ情報'],
                "water_station": row['水飲み場情報'],
                "pet_facilities": row.get('ペット関連施設', ''),
                "others": row.get('その他備考', '')
            }
            
            # JSON文字列化（エスケープ処理）
            import json
            pet_info_json = json.dumps(pet_info, ensure_ascii=False)
            
            # SQL生成
            sql = f"""
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
  '{row['ルート名'].replace("'", "''")}',
  '{row['ルート説明'].replace("'", "''")}',
  NULL,  -- 後で座標に変換: {row['開始地点住所']}
  NULL,  -- 後で座標に変換: {row['終了地点住所']}
  NULL,  -- 後で手動でroute_lineを追加
  {row['距離km']},
  {row['所要時間分']},
  '{row['難易度']}',
  {row['標高差m']},
  0,
  0,
  '{pet_info_json}'::jsonb,
  now(),
  now()
);
"""
            sql_statements.append(sql)
        
        # SQLファイルに出力
        with open(output_sql_path, 'w', encoding='utf-8') as sqlfile:
            sqlfile.write('\n'.join(sql_statements))
        
        print(f"✅ {len(sql_statements)}件のルートをSQLに変換しました: {output_sql_path}")

# 実行例
csv_to_sql('routes.csv', 'insert_routes.sql')
```

---

## 🚀 4. データ投入フロー

### ステップ1: CSVファイル作成
1. `route_template.csv` をダウンロード
2. Excelまたはスプレッドシートで編集
3. UTF-8形式でCSV保存

### ステップ2: CSVをSQLに変換
```bash
python csv_to_sql.py routes.csv insert_routes.sql
```

### ステップ3: 座標の手動追加
生成されたSQLファイルの `NULL` 部分を、Google Mapsで取得した座標に置換：

```sql
-- 変換前
start_location: NULL,  -- 後で座標に変換: 神奈川県足柄下郡箱根町元箱根 元箱根港駐車場

-- 変換後
start_location: ST_SetSRID(ST_MakePoint(139.024526, 35.189992), 4326)::geography,
```

### ステップ4: データベースに投入
```bash
# Supabase SQL Editorで実行
psql -h your-supabase-host -U postgres -d postgres -f insert_routes.sql
```

### ステップ5: route_lineの追加（後日手動）
- Google My Maps や geojson.io でルート軌跡を描画
- GeoJSON形式でエクスポート
- UPDATE文で `route_line` カラムに追加

---

## 📋 5. サンプルCSV

```csv
ルート名,エリア,ルート説明,距離km,所要時間分,難易度,標高差m,駐車場情報,路面状況,トイレ情報,水飲み場情報,ペット関連施設,その他備考,開始地点住所,終了地点住所
芦ノ湖湖畔散歩コース,箱根,元箱根港を起点に湖畔を散歩するコース,2.5,50,easy,30,あり（有料500円/日）,コンクリート80%,あり（元箱根港）,あり（複数箇所）,ペットカフェあり,リード着用必須,神奈川県足柄下郡箱根町元箱根,神奈川県足柄下郡箱根町元箱根
鎌倉大仏ルート,鎌倉,鎌倉大仏を経由する歴史散歩コース,3.0,60,easy,20,あり（有料800円/日）,アスファルト90%,あり（高徳院前）,あり（境内）,境内ペット同伴可,土日は混雑,神奈川県鎌倉市長谷 高徳院前,神奈川県鎌倉市長谷 高徳院前
```

---

## 🎯 まとめ

### CSV管理のメリット
✅ 複数ルートを一括編集  
✅ Excelやスプレッドシートで共同編集  
✅ バックアップ・バージョン管理が簡単  
✅ Pythonスクリプトで自動SQL生成  

### 手動作業が必要な項目
⚠️ 開始地点・終了地点の座標変換  
⚠️ ルート軌跡（route_line）の描画  
⚠️ サムネイル画像の準備  

---

以上です。CSVファイルでルート情報を管理し、効率的にデータベースに投入してください！
