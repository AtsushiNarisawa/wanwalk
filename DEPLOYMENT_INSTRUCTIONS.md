# WanMap v2 - Phase 1 & 2 デプロイ手順

## 実装完了内容

### Phase 1: ホーム画面のビジュアル化（コミット: `d59f199`）
✅ **1. MAP表示**
   - 200px高さのマップを追加
   - 最新のピン投稿を中心に表示
   - FlutterMapを使用してインタラクティブなマップを実装

✅ **2. 最新の写真付きピン投稿**
   - 横並びで2枚のカードを表示
   - 写真、タイトル、投稿者名、エリア名、いいね数、投稿時刻を表示
   - `RecentPinPost`モデルと`recentPinsProvider`を作成

✅ **3. 人気の公式ルート**
   - 既存機能を維持（以前のコミットで実装済み）

✅ **4. おすすめエリア**
   - カルーセル表示から縦3枚カード + 「一覧を見る」ボタンに変更
   - 全18エリアの中から最初の3件を表示

### Phase 2: フッターの再構成（コミット: `e960ad7`）
✅ **1. フッターを4タブに再構成**
   - タブ1: **ホーム** (変更なし)
   - タブ2: **ルート** (旧「マップ」、お出かけ散歩)
   - タブ3: **クイック記録** (旧「散歩記録」、日常の散歩)
   - タブ4: **プロフィール** (変更なし)

✅ **2. 日常の散歩ランディング画面**
   - 「散歩を始める」ボタン → `DailyWalkingScreen`へ遷移
   - 「散歩履歴を見る」ボタン → `WalkHistoryScreen`へ遷移
   - 誤タップによる散歩開始を防止

---

## 【重要】Supabase SQL実行（必須）

**新しいRPC関数 `get_recent_pins` をSupabaseに投入する必要があります。**

### 手順:
1. **Supabase Dashboardにアクセス**
   ```
   https://supabase.com/dashboard/project/jkpenklhrlbctebkpvax/editor/sql
   ```

2. **新しいクエリを作成**
   - 左メニューの「SQL Editor」をクリック
   - 「New query」ボタンをクリック

3. **以下のSQLをコピー&ペースト**
   ```sql
   -- =====================================================
   -- WanMap: ホーム画面用・最新の写真付きピン投稿取得
   -- =====================================================
   -- 実行日: 2025-11-29
   -- 目的: ホームタブに最新の写真付きピン投稿を表示するRPC追加

   -- =====================================================
   -- RPC: 最新の写真付きピン投稿取得
   -- =====================================================
   CREATE OR REPLACE FUNCTION get_recent_pins(
     p_limit INT DEFAULT 10,
     p_offset INT DEFAULT 0
   )
   RETURNS TABLE (
     pin_id UUID,
     route_id UUID,
     route_name TEXT,
     area_id UUID,
     area_name TEXT,
     prefecture TEXT,
     pin_type TEXT,
     title TEXT,
     comment TEXT,
     likes_count INT,
     photo_url TEXT,
     user_id UUID,
     user_name TEXT,
     user_avatar_url TEXT,
     created_at TIMESTAMPTZ,
     pin_lat FLOAT,
     pin_lon FLOAT
   )
   LANGUAGE plpgsql
   AS $$
   BEGIN
     RETURN QUERY
     SELECT 
       rp.id AS pin_id,
       rp.route_id,
       r.title AS route_name,
       r.area_id,
       a.display_name AS area_name,
       a.prefecture,
       rp.pin_type,
       rp.title,
       rp.description AS comment,
       rp.likes_count,
       (
         SELECT rpp.photo_url
         FROM route_pin_photos rpp
         WHERE rpp.pin_id = rp.id
         ORDER BY rpp.photo_order ASC
         LIMIT 1
       ) AS photo_url,
       rp.user_id,
       COALESCE(u.raw_user_meta_data->>'display_name', 'Unknown User') AS user_name,
       COALESCE(u.raw_user_meta_data->>'avatar_url', '') AS user_avatar_url,
       rp.created_at,
       ST_Y(rp.location::geometry) AS pin_lat,
       ST_X(rp.location::geometry) AS pin_lon
     FROM route_pins rp
     JOIN official_routes r ON r.id = rp.route_id
     JOIN areas a ON a.id = r.area_id
     LEFT JOIN auth.users u ON u.id = rp.user_id
     WHERE rp.is_active = TRUE
       AND EXISTS (
         SELECT 1 FROM route_pin_photos rpp WHERE rpp.pin_id = rp.id
       )
     ORDER BY rp.created_at DESC
     LIMIT p_limit
     OFFSET p_offset;
   END;
   $$;

   COMMENT ON FUNCTION get_recent_pins IS 'ホーム画面用：最新の写真付きピン投稿を取得（写真があるピンのみ）';
   ```

4. **「Run」ボタンをクリック**
   - 実行が成功すると、「Success」と表示されます
   - エラーが出た場合は、メッセージを確認してください

5. **実行結果の確認**
   - 同じSQL Editorで以下を実行:
   ```sql
   SELECT * FROM get_recent_pins(2, 0);
   ```
   - 最新の写真付きピン投稿が2件返ってくることを確認

---

## Macでの動作確認手順

### 1. GitHubから最新コードを取得
```bash
cd /Users/atsushinarisawa/projects/webapp/wanmap_v2

git pull origin main

git log --oneline -3
# 期待される出力:
# e960ad7 Phase 2: Reconfigure footer to 4 tabs (Home, Route, Quick Record, Profile)
# d59f199 Phase 1: Add visual home tab with map preview and recent pin posts
# 1b007ff ✨ Add popular official routes to home tab
```

### 2. 依存関係の更新
```bash
flutter pub get
```

### 3. アプリを起動
```bash
flutter run
```

---

## 期待される動作

### ホーム画面
1. **MAP表示** (画面上部)
   - 200pxの高さのマップが表示される
   - 最新のピン投稿がマーカーで表示される（Week 3データのピンがあれば）

2. **最新の写真付きピン投稿** (MAPの直下)
   - タイトル: 「最新の写真付きピン投稿」
   - 横に2枚のカードが並ぶ
   - 各カードには写真、タイトル、投稿者名、エリア名、いいね数、投稿時刻が表示
   - **⚠️ 注意**: Week 3データにピン投稿がない場合は「まだピン投稿がありません」と表示

3. **人気の公式ルート**
   - Week 3データの箱根、横浜、鎌倉のルートが表示（既存機能）

4. **おすすめエリア**
   - 最初の3エリアが縦に表示
   - 「一覧を見る（18エリア）」ボタンが表示

### フッター
- タブ1: **ホーム** (従来通り)
- タブ2: **ルート** (旧「マップ」、アイコン: route)
- タブ3: **クイック記録** (新設、アイコン: 赤い丸)
- タブ4: **プロフィール** (従来通り)

### クイック記録タブ
- タップすると「日常の散歩」ランディング画面が表示
- 「散歩を始める」ボタン → 散歩記録開始画面へ
- 「散歩履歴を見る」ボタン → 散歩履歴画面へ

---

## トラブルシューティング

### 1. ホーム画面で「最新の写真付きピン投稿」が表示されない
**原因**: Supabase RPC `get_recent_pins` が実行されていない

**解決策**:
- 上記「Supabase SQL実行」手順を実行してください
- Supabase Dashboardで以下のSQLで確認:
  ```sql
  SELECT * FROM get_recent_pins(2, 0);
  ```

### 2. 「まだピン投稿がありません」と表示される
**原因**: Week 3データにピン投稿データが含まれていない

**解決策**:
- Week 3データインポートスクリプトを実行:
  ```bash
  cd /Users/atsushinarisawa/projects/webapp/wanmap_v2/scripts
  python3 add_hakone_pins.py
  python3 add_yokohama_kamakura_pins.py
  ```

### 3. ビルドエラーが発生する
**原因**: 依存関係が更新されていない

**解決策**:
```bash
flutter clean
flutter pub get
flutter run
```

### 4. MAP表示で「マップを読み込めませんでした」エラー
**原因**: flutter_mapパッケージが正しくインストールされていない

**解決策**:
```bash
flutter pub get
# pubspec.yamlにflutter_map: ^6.0.0が含まれているか確認
cat pubspec.yaml | grep flutter_map
```

---

## 変更ファイル一覧

### Phase 1 (コミット: `d59f199`)
- `supabase_migrations/008_add_get_recent_pins.sql` (新規) - Supabase RPC関数
- `lib/models/recent_pin_post.dart` (新規) - 最新ピン投稿モデル
- `lib/providers/recent_pins_provider.dart` (新規) - 最新ピン取得Provider
- `lib/screens/main/tabs/home_tab.dart` (変更) - ホーム画面UI大幅変更
- `scripts/deploy_get_recent_pins_rpc.py` (新規) - SQL投入支援スクリプト

### Phase 2 (コミット: `e960ad7`)
- `lib/screens/daily/daily_walk_landing_screen.dart` (新規) - 日常の散歩ランディング画面
- `lib/screens/main/main_screen.dart` (変更) - フッター4タブ再構成

---

## 次のステップ

### 実装済み
- ✅ Phase 1: ホーム画面のビジュアル化
- ✅ Phase 2: フッターの再構成

### 今後の課題
- ⏳ 最新ピン投稿カードタップ時の詳細画面実装
- ⏳ Week 3データにピン投稿データの追加（必要に応じて）
- ⏳ 散歩記録タブの完全削除（Phase 2で非表示化済み）

---

## サポート

問題が発生した場合は、以下の情報を共有してください:
1. エラーメッセージ（スクリーンショットまたはテキスト）
2. 実行したコマンド
3. 期待される動作と実際の動作の違い

以上でデプロイ手順は完了です。お疲れさまでした！
