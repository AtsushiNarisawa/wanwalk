# サムネイル自動更新トリガーの実装手順

## 目的
写真追加時に自動的に `routes.thumbnail_url` を更新するPostgreSQLトリガーを実装します。

## 効果
- ✅ 写真追加時に**自動的に**サムネイルが設定される
- ✅ 手動でSQLを実行する必要がなくなる
- ✅ 最初の写真（display_order=0）が常にサムネイルになる

## 実行手順

### ステップ1: Supabaseダッシュボードを開く
1. https://supabase.com にアクセス
2. ログイン
3. `wanmap_v2` プロジェクトを選択

### ステップ2: SQL Editorを開く
左側メニューから **「SQL Editor」** をクリック

### ステップ3: SQLを実行
1. **「New query」** ボタンをクリック
2. `supabase_migrations/auto_update_thumbnail.sql` の内容をコピー
3. SQL Editorに貼り付け
4. **「Run」** ボタンをクリック

### ステップ4: 実行結果を確認
以下のメッセージが表示されれば成功：
```
Success. No rows returned
```

### ステップ5: 動作確認（オプション）
新しい写真を追加して、`routes.thumbnail_url` が自動的に更新されるか確認：

1. アプリで任意のルートに写真を追加
2. Supabase Table Editor → `routes` テーブル
3. 該当ルートの `thumbnail_url` に写真のパスが設定されているか確認

## トラブルシューティング

### エラー: "permission denied for table routes"
→ RLSポリシーの問題。以下を実行：
```sql
GRANT UPDATE ON public.routes TO postgres;
```

### エラー: "function already exists"
→ すでにトリガーが存在。問題ありません。再実行してもOK。

### 動作しない場合
1. トリガーが正しく作成されているか確認：
```sql
SELECT * FROM pg_trigger WHERE tgname = 'trg_auto_update_thumbnail';
```

2. 関数が存在するか確認：
```sql
SELECT proname FROM pg_proc WHERE proname = 'fn_auto_update_thumbnail';
```

## ロールバック（元に戻す）

トリガーを削除したい場合：
```sql
DROP TRIGGER IF EXISTS trg_auto_update_thumbnail ON public.route_photos;
DROP FUNCTION IF EXISTS fn_auto_update_thumbnail();
```

## 補足情報

### トリガーの動作
- **いつ**: `route_photos` テーブルにINSERT時
- **何を**: `routes.thumbnail_url` を更新
- **条件**: 
  - サムネイルが未設定の場合
  - または、最初の写真（display_order=0）の場合

### パフォーマンス
- 影響: 最小限（1回のUPDATE文のみ）
- 写真追加時のみ実行されるため、通常の操作には影響なし
