# WanWalk Supabase データベースセットアップ手順

このディレクトリには、WanWalkアプリで使用するSupabaseデータベースのスキーマファイルが含まれています。

## 📋 ファイル一覧

1. **complete_schema_with_social.sql** - 全機能を含む完全版スキーマ（推奨）
   - Phase 1-15: 基本テーブル (profiles, dogs, routes, route_points, favorites, route_photos)
   - Phase 17: コメント機能 (comments)
   - Phase 24: ソーシャル機能 (follows, likes)

2. **phase24_social_schema.sql** - Phase 24のみ（既にPhase 1-17が実行済みの場合）
   - follows テーブル
   - likes テーブル

## 🚀 セットアップ手順

### 方法1: 完全版スキーマを実行（推奨）

**初めてセットアップする場合、または既存テーブルを更新したい場合**

1. Supabaseダッシュボードにアクセス
   - https://supabase.com/dashboard にログイン
   - WanWalkプロジェクトを選択

2. SQL Editorを開く
   - 左サイドバーから「SQL Editor」をクリック
   - 「+ New Query」をクリック

3. スキーマファイルの内容をコピー
   ```bash
   # Macのターミナルで実行
   cat supabase_migrations/complete_schema_with_social.sql | pbcopy
   ```
   
4. SQL Editorに貼り付けて実行
   - コピーしたSQLを貼り付け
   - 「Run」ボタンをクリック（または Cmd+Enter）
   
5. 実行結果を確認
   - エラーがないことを確認
   - 「Success. No rows returned」と表示されればOK
   - NOTICEメッセージが表示されます：
     ```
     WanWalk データベーススキーマ適用完了
     テーブル作成: profiles, dogs, routes, route_points, favorites, route_photos, comments, follows, likes
     RLSポリシー: すべて設定済み
     インデックス: すべて作成済み
     ビュー: follow_stats, route_like_counts
     関数: is_following(), has_liked_route()
     ```

### 方法2: Phase 24のみ実行

**既にPhase 1-17のテーブルが存在する場合**

1. 上記と同様にSupabaseダッシュボードにアクセス

2. SQL Editorで `phase24_social_schema.sql` を実行
   ```bash
   # Macのターミナルで実行
   cat supabase_migrations/phase24_social_schema.sql | pbcopy
   ```

3. SQL Editorに貼り付けて実行

## ✅ 実行後の確認

### テーブルの確認

SQL Editorで以下を実行：

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

**期待される結果:**
- comments
- dogs
- favorites
- follows ← Phase 24で追加
- likes ← Phase 24で追加
- profiles
- route_photos
- route_points
- routes

### RLSポリシーの確認

```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
ORDER BY tablename, policyname;
```

### ビューと関数の確認

```sql
-- ビューの確認
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public';

-- 結果: follow_stats, route_like_counts

-- 関数の確認
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION';

-- 結果: is_following, has_liked_route, update_updated_at_column
```

## 🔧 トラブルシューティング

### エラー: "already exists"

既存のテーブルやポリシーが存在する場合、このエラーが表示されることがあります。
スキーマファイルは `IF NOT EXISTS` と `DROP POLICY IF EXISTS` を使用しているため、
既存のリソースを保護しながら新しいテーブルを追加します。

**解決方法:**
1. エラーメッセージを無視（影響なし）
2. または、特定のテーブルのみ削除して再実行
   ```sql
   DROP TABLE IF EXISTS public.follows CASCADE;
   DROP TABLE IF EXISTS public.likes CASCADE;
   -- 再度スキーマを実行
   ```

### エラー: "permission denied"

RLSポリシーの権限エラーが発生する場合：

```sql
-- RLSを一時的に無効化（開発環境のみ）
ALTER TABLE public.follows DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes DISABLE ROW LEVEL SECURITY;

-- 再度有効化
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
```

## 📊 データベース構造

### 基本テーブル (Phase 1-15)
- **profiles**: ユーザープロフィール
- **dogs**: 犬の情報
- **routes**: 散歩ルート
- **route_points**: GPS座標
- **favorites**: お気に入りルート
- **route_photos**: ルート写真

### コメント機能 (Phase 17)
- **comments**: ルートへのコメント

### ソーシャル機能 (Phase 24)
- **follows**: フォロー/フォロワー関係
- **likes**: ルートへのいいね

### ビュー
- **follow_stats**: ユーザーごとのフォロワー/フォロー中数
- **route_like_counts**: ルートごとのいいね数

### 関数
- **is_following(follower_id, following_id)**: フォロー状態チェック
- **has_liked_route(user_id, route_id)**: いいね状態チェック
- **update_updated_at_column()**: updated_at自動更新

## 🔐 セキュリティ (RLS)

すべてのテーブルでRow Level Security (RLS) が有効化されています：

- **profiles**: 全員閲覧可、自分のみ更新可
- **dogs**: 自分のみ閲覧・管理可
- **routes**: 自分と公開ルートのみ閲覧可
- **route_points**: ルートのRLSに従う
- **favorites**: 自分のみ閲覧・管理可
- **route_photos**: 公開ルートは全員閲覧可、自分のみ管理可
- **comments**: 公開ルートのコメントは全員閲覧可、自分のみ削除可
- **follows**: 全員閲覧可、自分のフォローのみ作成・削除可
- **likes**: 全員閲覧可、自分のいいねのみ作成・削除可

## 📝 次のステップ

データベースセットアップが完了したら：

1. Flutterアプリをビルド
   ```bash
   cd wanwalk
   flutter pub get
   flutter run
   ```

2. 機能をテスト
   - ユーザー登録/ログイン
   - プロフィール作成
   - ルート記録
   - ユーザー検索とフォロー
   - ルートにいいね

3. 本番環境へのデプロイ準備
   - Storage buckets設定 (avatars, route_photos)
   - 環境変数設定
   - 認証設定の確認

## 🆘 サポート

問題が発生した場合：

1. Supabaseのログを確認
   - Dashboard → Logs → Postgres Logs

2. RLSポリシーのテスト
   ```sql
   -- 現在のユーザーIDを確認
   SELECT auth.uid();
   
   -- テーブルのポリシーを確認
   SELECT * FROM pg_policies WHERE tablename = 'follows';
   ```

3. データの確認
   ```sql
   -- フォロー数を確認
   SELECT * FROM public.follow_stats LIMIT 10;
   
   -- いいね数を確認
   SELECT * FROM public.route_like_counts LIMIT 10;
   ```
