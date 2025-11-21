# 📱 WanMap開発実装指示書 v3.0（完全版）
**Genspark AI Developer投入用**

**最終更新日**: 2025-11-21  
**対象**: Genspark AI Developer  
**目的**: 愛犬の散歩ルート共有アプリ「WanMap」Phase 1 MVP開発

---

## 🚨【最重要】技術スタック強制指定

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ このプロジェクトは必ずFlutterで実装してください ⚠️
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【必須事項】
✅ Flutter 3.35.7を使用
✅ モバイルアプリケーション（iOS/Android）
✅ Dart言語で実装

【禁止事項】
❌ Web技術（React, Vue, Next.js, Hono等）は使用しない
❌ Webアプリケーションとして実装しない
❌ Cloudflare Pagesは使用しない

【確認】
このプロジェクトはモバイルアプリです。
Flutterフレームワークでネイティブアプリを開発してください。
```

---

## 🎯 プロジェクト概要

### ビジネス目的
1. **主目的**: DogHub（箱根のドッグホテル・カフェ）の宣伝ツール
2. **副次目的**: 旅行先での散歩ルート共有プラットフォーム
3. **差別化**: 競合8アプリすべてが持たない「ルート共有」機能

### コアバリュー
> 「箱根に旅行に来た犬飼い主が、WanMapを開いて、**5分以内に良さそうな散歩ルートを見つけて歩き始められる**」

### Phase 1 MVP の範囲（8週間）

✅ **実装する機能**
- ゲストモード（ログインなしでルート閲覧可能）
- ユーザー認証（メール/パスワード）
- 犬情報登録（複数頭対応）
- GPS記録（フォアグラウンド）
- ルート保存・共有（公開/プライベート）
- ルート検索・閲覧・フィルタ
- わんスポット登録・閲覧
- わんスポット重複警告
- 写真撮影・GPS紐付け
- DogHub推薦バッジ

❌ **Phase 2以降に延期**
- バックグラウンドGPS記録
- わんスポット自動統合
- ヒートマップ
- わんマイル制度
- 旅行プラン機能
- 統計機能
- Instagram連携

---

## 🛠️ 技術スタック

### フロントエンド
- **Flutter**: 3.35.7
- **状態管理**: Provider
- **地図**: flutter_map + OpenStreetMap（Thunderforest タイル）
- **GPS**: geolocator + location
- **写真**: image_picker + image（圧縮用）

### バックエンド
- **Supabase**:
  - PostgreSQL（PostGIS有効化）
  - Auth（メール/パスワード認証）
  - **Storage**（画像保存 - 既に実装済み）
  - Realtime（リアルタイム更新）

### ストレージ
- **Supabase Storage**（既存実装を使用）
  - バケット1: `route-photos`（ルート写真）
  - バケット2: `profile-avatars`（プロフィール画像）
  - **※Cloudflare R2は使用しません**

### インフラ
- **地図タイル**: Thunderforest Outdoors（無料枠：月150,000リクエスト）

### コスト
- **年間ランニングコスト**: ¥1,200
- **開発費**: ほぼ0円

---

## 🔐 環境変数設定

### 現状の問題点
**⚠️ 現在、環境変数が`lib/config/env.dart`にハードコーディングされています。**  
これは**セキュリティリスク**があるため、以下の手順で外部化してください。

### ステップ1: `.env`ファイル作成

プロジェクトルートに`.env`ファイルを作成：

```env
# Supabase
SUPABASE_URL=https://jkpenklhrlbctebkpvax.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Thunderforest（地図タイル）
THUNDERFOREST_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### ステップ2: `.gitignore`に追加

```gitignore
# 環境変数（機密情報を含む）
.env
.env.local
.env.production
```

### ステップ3: `lib/config/env.dart`を修正

**❌ 現在のコード（ハードコーディング）**
```dart
class Environment {
  static const String supabaseUrl = 'https://jkpenklhrlbctebkpvax.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGci...';
}
```

**✅ 修正後（環境変数から読み込み）**
```dart
class Environment {
  // Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  
  // Thunderforest
  static const String thunderforestApiKey = String.fromEnvironment(
    'THUNDERFOREST_API_KEY',
    defaultValue: '',
  );
  
  // バリデーション
  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase環境変数が設定されていません');
    }
    if (thunderforestApiKey.isEmpty) {
      throw Exception('Thunderforest API Key環境変数が設定されていません');
    }
  }
}
```

### ステップ4: ビルド時に環境変数を渡す

```bash
# .envファイルから環境変数を読み込んでビルド
flutter run --dart-define-from-file=.env
```

---

## 📊 データベース設計

### Supabase初期設定

1. **Supabaseプロジェクト**: 既に作成済み
2. **SQL Editorでスキーマ実行**: 以下の全SQLスクリプトを実行

```sql
-- ============================================
-- WanMap Database Schema v3.0 (Phase 1 MVP)
-- ============================================

-- PostGIS拡張を有効化
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 2. user_profiles（ユーザープロフィール）
-- ============================================
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  is_admin BOOLEAN DEFAULT FALSE,
  business_name TEXT,
  business_location GEOMETRY(POINT, 4326),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles"
  ON user_profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================
-- 3. dogs（犬情報）
-- ============================================
CREATE TABLE dogs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  breed TEXT,
  size TEXT CHECK (size IN ('small', 'medium', 'large')),
  birth_date DATE,
  weight DECIMAL(5, 2),
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_dogs_user_id ON dogs(user_id);
ALTER TABLE dogs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all dogs"
  ON dogs FOR SELECT USING (true);

CREATE POLICY "Users can manage own dogs"
  ON dogs FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 4. routes（散歩ルート）
-- ============================================
CREATE TABLE routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  dog_id UUID REFERENCES dogs(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT TRUE,
  distance_meters DECIMAL(10, 2) NOT NULL,
  duration_seconds INTEGER NOT NULL,
  elevation_gain DECIMAL(8, 2),
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  start_location GEOMETRY(POINT, 4326) NOT NULL,
  end_location GEOMETRY(POINT, 4326) NOT NULL,
  area_name TEXT,
  tags TEXT[],
  is_featured BOOLEAN DEFAULT FALSE,
  featured_by UUID REFERENCES auth.users(id),
  featured_comment TEXT,
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_routes_user_id ON routes(user_id);
CREATE INDEX idx_routes_is_public ON routes(is_public);
CREATE INDEX idx_routes_area_name ON routes(area_name);
CREATE INDEX idx_routes_start_location ON routes USING GIST(start_location);
CREATE INDEX idx_routes_tags ON routes USING GIN(tags);

ALTER TABLE routes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public routes are viewable by everyone"
  ON routes FOR SELECT USING (is_public = true OR auth.uid() = user_id);

CREATE POLICY "Users can manage own routes"
  ON routes FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 5. route_points（ルート座標点）
-- ============================================
CREATE TABLE route_points (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  location GEOMETRY(POINT, 4326) NOT NULL,
  altitude DECIMAL(8, 2),
  accuracy DECIMAL(6, 2),
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  sequence_number INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_route_points_route_id ON route_points(route_id);
CREATE INDEX idx_route_points_sequence ON route_points(route_id, sequence_number);
CREATE INDEX idx_route_points_location ON route_points USING GIST(location);

ALTER TABLE route_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Route points inherit route visibility"
  ON route_points FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM routes
      WHERE routes.id = route_points.route_id
      AND (routes.is_public = true OR routes.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can manage own route points"
  ON route_points FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM routes
      WHERE routes.id = route_points.route_id
      AND routes.user_id = auth.uid()
    )
  );

-- ============================================
-- 6. route_photos（ルート写真）
-- ============================================
CREATE TABLE route_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  thumbnail_url TEXT,
  storage_path TEXT NOT NULL,
  location GEOMETRY(POINT, 4326),
  caption TEXT,
  taken_at TIMESTAMP WITH TIME ZONE,
  sequence_number INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_route_photos_route_id ON route_photos(route_id);
ALTER TABLE route_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Route photos inherit route visibility"
  ON route_photos FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM routes
      WHERE routes.id = route_photos.route_id
      AND (routes.is_public = true OR routes.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can manage own route photos"
  ON route_photos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM routes
      WHERE routes.id = route_photos.route_id
      AND routes.user_id = auth.uid()
    )
  );

-- ============================================
-- 7-12. その他のテーブル（route_likes, route_comments, spots, spot_photos, spot_comments, spot_upvotes）
-- ※ 同様のパターンで作成
-- ============================================

-- ============================================
-- PostgreSQL Functions（Supabase RPC用）
-- ============================================

CREATE OR REPLACE FUNCTION search_nearby_routes(
  user_lat FLOAT,
  user_lng FLOAT,
  search_radius_km FLOAT DEFAULT 10,
  min_distance_m FLOAT DEFAULT NULL,
  max_distance_m FLOAT DEFAULT NULL,
  difficulty_filter TEXT DEFAULT NULL,
  tags_filter TEXT[] DEFAULT NULL,
  featured_only BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  distance_meters DECIMAL,
  duration_seconds INTEGER,
  difficulty TEXT,
  area_name TEXT,
  tags TEXT[],
  is_featured BOOLEAN,
  featured_comment TEXT,
  like_count INTEGER,
  comment_count INTEGER,
  view_count INTEGER,
  distance_from_user_meters FLOAT,
  user_display_name TEXT,
  thumbnail_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id, r.title, r.description, r.distance_meters, r.duration_seconds,
    r.difficulty, r.area_name, r.tags, r.is_featured, r.featured_comment,
    r.like_count, r.comment_count, r.view_count,
    ST_Distance(
      r.start_location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) as distance_from_user_meters,
    up.display_name as user_display_name,
    (SELECT photo_url FROM route_photos WHERE route_id = r.id ORDER BY sequence_number LIMIT 1) as thumbnail_url,
    r.created_at
  FROM routes r
  JOIN user_profiles up ON r.user_id = up.id
  WHERE r.is_public = true
    AND ST_DWithin(
      r.start_location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      search_radius_km * 1000
    )
    AND (min_distance_m IS NULL OR r.distance_meters >= min_distance_m)
    AND (max_distance_m IS NULL OR r.distance_meters <= max_distance_m)
    AND (difficulty_filter IS NULL OR r.difficulty = difficulty_filter)
    AND (tags_filter IS NULL OR r.tags && tags_filter)
    AND (featured_only = false OR r.is_featured = true)
  ORDER BY 
    CASE WHEN r.is_featured THEN 0 ELSE 1 END,
    distance_from_user_meters ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- トリガー、その他のFunctionも同様に作成
```

**※完全なSQLスクリプトは前回提供した内容を参照**

3. **Supabase Storageバケット**: 既に作成済み
   - `route-photos`
   - `profile-avatars`

---

## 📦 pubspec.yaml

```yaml
name: wanmap
description: 愛犬の散歩ルート共有アプリ
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  supabase_flutter: ^2.5.0
  provider: ^6.1.0
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  geolocator: ^11.0.0
  location: ^5.0.3
  permission_handler: ^11.0.0
  image_picker: ^1.0.7
  image: ^4.1.7
  dio: ^5.4.0
  http: ^1.2.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  flutter_rating_bar: ^4.0.1
  photo_view: ^0.14.0
  intl: ^0.18.1
  uuid: ^4.3.0
  path_provider: ^2.1.0
  shared_preferences: ^2.2.0
  collection: ^1.18.0
  logger: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

---

## 📅 開発フェーズ（8週間）

### Week 1-2: 環境設定 + 認証機能
- Flutterプロジェクト作成
- 環境変数外部化
- 認証機能実装

### Week 3-4: GPS記録機能
- GPS記録実装
- ルート保存機能

### Week 5-6: ルート検索・表示機能
- マップ画面実装
- ルート検索・フィルタ

### Week 7: わんスポット機能
- わんスポット登録
- 重複警告機能

### Week 8: 写真機能 + テスト
- 写真アップロード（既存実装活用）
- 統合テスト

---

## 🔧 トラブルシューティング

### GPS権限エラー
iOS: `Info.plist`に位置情報使用説明を追加  
Android: `AndroidManifest.xml`に権限追加

### 地図タイル表示されない
Thunderforest APIキーを確認、環境変数を正しく渡す

### 画像アップロード失敗
Supabase Storageバケットの存在とPublic設定を確認

---

## ✅ チェックリスト

### 必須機能
- [ ] ゲストモードでルート閲覧
- [ ] GPS記録
- [ ] ルート保存・検索
- [ ] わんスポット登録
- [ ] 写真アップロード
- [ ] DogHub推薦バッジ

### 品質基準
- [ ] iOS/Android動作確認
- [ ] GPS精度テスト
- [ ] セキュリティ確認（RLS）

---

この指示書をGenspark AI Developerに投入してください。
