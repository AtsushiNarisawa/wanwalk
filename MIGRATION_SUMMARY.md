# WanMap v2 - walks テーブル統合移行完了レポート

**作成日**: 2025-11-23  
**担当**: Claude Code Assistant  
**対象**: Phase 1 - データベース統合作業

---

## 📋 作業概要

### 目的
古い散歩データテーブル（daily_walks, daily_walk_points, route_walks）を新しい統合テーブル（walks）に移行し、データベース構造をシンプルかつ保守しやすくする。

### 方針
- **walks テーブル**: daily/outing 両方の散歩を統合管理
- **walk_type カラム**: 'daily'（日常散歩）と 'outing'（お出かけ散歩）で区別
- **path_geojson カラム**: GPS経路を GeoJSON LineString 形式で保存
- **PostGIS geography**: 地理空間データを効率的に管理

---

## ✅ 完了した作業

### 1. データベーステーブル作成（完了）

#### walks テーブル
```sql
CREATE TABLE walks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  walk_type TEXT NOT NULL CHECK (walk_type IN ('daily', 'outing')),
  route_id UUID REFERENCES routes(id) ON DELETE SET NULL,
  start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_time TIMESTAMPTZ,
  distance_km DECIMAL(10,2),
  duration_minutes INTEGER,
  average_speed_kmh DECIMAL(5,2),
  path_geojson JSONB,
  path_geography GEOGRAPHY(LINESTRING, 4326),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**主な特徴**:
- ✅ daily/outing を walk_type で区別
- ✅ path_geojson で GPS経路を保存
- ✅ path_geography で地理空間クエリに対応
- ✅ average_speed_kmh 自動計算トリガー
- ✅ RLS（Row Level Security）設定済み

#### route_pins, route_pin_photos, pin_likes テーブル
- ✅ ピン投稿機能のデータ構造
- ✅ いいね機能の実装
- ✅ 写真添付（最大5枚）

### 2. RPC関数の更新（完了）

#### get_user_walk_statistics
```sql
-- walks テーブルから統計を取得
SELECT
  COALESCE(COUNT(DISTINCT w.id), 0) AS total_walks,
  COALESCE(SUM(w.distance_km), 0) AS total_distance_km,
  COALESCE(SUM(w.duration_minutes) / 60.0, 0) AS total_duration_hours,
  COALESCE(COUNT(DISTINCT w.id) FILTER (WHERE w.walk_type = 'daily'), 0) AS daily_walks_count,
  COALESCE(COUNT(DISTINCT w.id) FILTER (WHERE w.walk_type = 'outing'), 0) AS route_walks_count
FROM walks w
WHERE w.user_id = p_user_id;
```

### 3. Flutterコードの移行（完了）

#### 修正したファイル（4ファイル）

**1. lib/services/walk_history_service.dart**
```dart
// ❌ 修正前
final outingCount = await _supabase.from('route_walks')...
final dailyCount = await _supabase.from('daily_walks')...

// ✅ 修正後
final walkCount = await _supabase.from('walks')
    .select('id')
    .eq('user_id', userId)
    .count();
```

**2. lib/services/walk_save_service.dart**
```dart
// ❌ 修正前
await _supabase.from('daily_walks').insert({...});
await _supabase.from('daily_walk_points').insert(pointsData);

// ✅ 修正後
final pathGeoJson = {
  'type': 'LineString',
  'coordinates': route.points.map((p) => [
    p.latLng.longitude,
    p.latLng.latitude,
    p.altitude ?? 0.0,
  ]).toList(),
};

await _supabase.from('walks').insert({
  'walk_type': 'daily',
  'path_geojson': pathGeoJson,
  ...
});
```

**3. lib/services/walk_detail_service.dart**
```dart
// ❌ 修正前
final walkResponse = await _supabase.from('route_walks')
    .select('..., official_routes!inner(...)')
    .eq('id', walkId)
    .single();

// ✅ 修正後
final walkResponse = await _supabase.from('walks')
    .select('..., routes!inner(...)')
    .eq('id', walkId)
    .eq('walk_type', 'outing')
    .single();
```

**4. lib/screens/main/tabs/profile_tab.dart**
```dart
// ❌ 修正前
Widget _buildSocialStats(BuildContext context, bool isDark) {
  // userId が定義されていない
  FollowersScreen(userId: userId) // ❌ エラー
}

// ✅ 修正後
Widget _buildSocialStats(BuildContext context, bool isDark, String userId) {
  // userId をパラメータとして受け取る
  FollowersScreen(userId: userId) // ✅ 正常
}
```

### 4. テストデータ投入（完了）

#### walks テーブル
```sql
-- 5件のテストデータ投入済み
-- walk_type='daily': 3件
-- walk_type='outing': 2件
```

#### route_pins テーブル
```sql
-- 5件のテストデータ投入済み
-- 各ピンに写真1-3枚添付
```

#### 動作確認
- ✅ average_speed_kmh 自動計算: 正常
- ✅ path_geography 自動生成: 正常
- ✅ toggle_pin_like: いいね/解除トグル正常
- ✅ get_user_walk_statistics: walks + pins 統計取得成功

---

## 🗑️ 削除対象テーブル（実行待ち）

### データベースからの削除
以下のテーブルは walks テーブルに統合済みのため削除可能：

```sql
-- 実行SQLファイル: database_migrations/003_drop_old_tables.sql

DROP TABLE IF EXISTS route_walks CASCADE;
DROP TABLE IF EXISTS daily_walk_points CASCADE;
DROP TABLE IF EXISTS daily_walks CASCADE;
```

### 実行方法（手動）

**Supabase Dashboard で実行:**
1. https://supabase.com/dashboard を開く
2. wanmap_v2 プロジェクトを選択
3. SQL Editor を開く
4. `database_migrations/003_drop_old_tables.sql` の内容をコピー&ペースト
5. "Run" をクリック

**⚠️ 注意事項:**
- 実行前に walks テーブルにデータが正しく移行されていることを確認
- バックアップを取得していることを確認
- 本番環境では必ずテスト環境で先に実行

---

## 🎯 次のステップ

### Phase 1 完了後
1. ✅ データベース統合完了
2. ✅ Flutterコード移行完了
3. ⏳ **古いテーブル削除（Supabase Dashboard で手動実行）**
4. ⏳ **ローカルマシンでシミュレータテスト**

### Phase 2 以降
- UI/UX 完成（削除画面の再実装・接続）
- コア機能実装（散歩記録、ピン投稿、ソーシャル機能）
- データ充実（エリア・ルートデータの拡充）
- テスト・デバッグ
- リリース準備

---

## 📊 変更の影響範囲

### 変更されたファイル
```
database_migrations/
  ├── 001_walks_table_v4.sql           ✅ 新規作成
  ├── 002_pins_table_v2.sql            ✅ 新規作成
  └── 003_drop_old_tables.sql          ✅ 新規作成

lib/services/
  ├── walk_history_service.dart        ✅ 修正完了
  ├── walk_save_service.dart           ✅ 修正完了
  └── walk_detail_service.dart         ✅ 修正完了

lib/screens/main/tabs/
  └── profile_tab.dart                 ✅ 修正完了

lib/providers/
  └── route_pin_provider.dart          ✅ 修正完了（カラム名）
```

### 変更されていないファイル
- `lib/models/user_walking_profile.dart` - モデル定義のみ、DB参照なし

---

## 🔧 技術的な改善点

### Before（旧構造）
```
daily_walks (日常散歩)
  ├── daily_walk_points (GPSポイント)

route_walks (お出かけ散歩)
  └── (GPS経路なし)
```

**問題点:**
- ❌ テーブルが分散して複雑
- ❌ 統計取得に複数クエリが必要
- ❌ コード重複（daily/outing で別処理）
- ❌ GPS経路がdailyのみ

### After（新構造）
```
walks (統合テーブル)
  ├── walk_type: 'daily' | 'outing'
  ├── path_geojson (GPS経路)
  └── path_geography (PostGIS)
```

**改善点:**
- ✅ シンプルな構造
- ✅ 統計取得が1クエリで完結
- ✅ コードの重複なし
- ✅ daily/outing 両方でGPS経路保存可能
- ✅ PostGIS による高速地理空間クエリ

---

## 📝 メモ

### 実行済みSQL
- `001_walks_table_v4.sql` - ✅ 実行済み
- `002_pins_table_v2.sql` - ✅ 実行済み

### 実行待ちSQL
- `003_drop_old_tables.sql` - ⏳ Supabase Dashboard で手動実行待ち

### Git コミット
```bash
[main f9d84d3] Migrate old tables to walks table
 17 files changed, 1597 insertions(+), 298 deletions(-)
```

---

**最終更新**: 2025-11-23  
**ステータス**: ✅ Phase 1 - 古いテーブル削除以外完了
