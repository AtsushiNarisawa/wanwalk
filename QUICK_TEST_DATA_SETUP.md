# 🚀 クイック テストデータセットアップ（5分で完了）

## 📋 必要な準備

1. Supabase Dashboard にアクセス: https://supabase.com/dashboard
2. WanMapプロジェクトを選択

---

## ステップ1: テストユーザーを作成（2分）

### Supabase Dashboard で以下を実行:

1. 左サイドバー → **Authentication** → **Users**
2. **Add user** ボタンをクリック
3. 以下の3ユーザーを作成:

#### ユーザー1
- Email: `test1@example.com`
- Password: `test1234`
- **Auto Confirm User**: ✅ チェック
- **Create user** をクリック

#### ユーザー2
- Email: `test2@example.com`
- Password: `test1234`
- **Auto Confirm User**: ✅ チェック
- **Create user** をクリック

#### ユーザー3
- Email: `test3@example.com`
- Password: `test1234`
- **Auto Confirm User**: ✅ チェック
- **Create user** をクリック

### ユーザーIDをメモ:

作成後、各ユーザーをクリックして **User UID** をコピーして以下にメモしてください:

```
test1@example.com のUID: _________________________________
test2@example.com のUID: _________________________________
test3@example.com のUID: _________________________________
```

---

## ステップ2: SQLスクリプトを編集（1分）

1. `test_data_setup.sql` ファイルを開く
2. VS Codeの検索・置換機能（Command + F）を使用
3. 以下を置き換え:

```
USER_ID_1 → test1@example.comのUID（全置換）
USER_ID_2 → test2@example.comのUID（全置換）
USER_ID_3 → test3@example.comのUID（全置換）
```

**例:**
```sql
# 置き換え前
'USER_ID_1'

# 置き換え後（例）
'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
```

---

## ステップ3: SQLスクリプトを実行（2分）

### Supabase Dashboard で以下を実行:

1. 左サイドバー → **SQL Editor**
2. **New query** をクリック
3. 編集した `test_data_setup.sql` の内容を**すべてコピー**
4. SQL Editorにペースト
5. **Run** ボタン（または Command + Enter）をクリック

### 実行結果の確認:

成功すると以下のメッセージが表示されます:
```
Success. No rows returned
```

---

## ✅ データ確認（1分）

### Table Editor で確認:

1. 左サイドバー → **Table Editor**
2. 各テーブルをクリックして確認:

- **routes**: 5件
- **photos**: 9件
- **route_points**: 15件
- **favorites**: 3件
- **comments**: 4件

すべてのテーブルにデータが入っていればOKです！

---

## 🎉 完了！アプリでテスト

### シミュレータでログイン:

1. アプリを起動
2. ログイン画面で入力:
   - Email: `test1@example.com`
   - Password: `test1234`
3. **ログイン** をタップ

### 確認事項:

- ✅ ホーム画面が表示される
- ✅ 「ルート一覧」をタップすると5件のルートが表示される
- ✅ 各ルートにサムネイル画像が表示される
- ✅ ルートをタップすると詳細画面が開く
- ✅ 写真をタップすると全画面で拡大表示される

---

## 🐛 トラブルシューティング

### エラー: "duplicate key value violates unique constraint"

既存データが残っています。以下のSQLを実行して削除:

```sql
DELETE FROM photos;
DELETE FROM comments;
DELETE FROM favorites;
DELETE FROM route_points;
DELETE FROM routes;
```

その後、`test_data_setup.sql` を再実行してください。

---

### 写真が表示されない

1. Storage → route-photos バケット → Policies
2. "Enable read access for all users" ポリシーを追加
3. アプリを再起動

---

### ルートが表示されない

1. `routes` テーブルを確認
2. `user_id` が正しいUser UIDになっているか確認
3. USER_ID_1 などのプレースホルダーが残っていないか確認

---

## 📝 次のステップ

テストデータが正しくセットアップできたら、以下をテストしてください:

### Phase 2 テスト項目:

1. **GPS記録の一時停止/再開**
   - マップ画面で「お散歩を開始」
   - 「一時停止」→「再開」が正しく動作するか確認

2. **写真の拡大表示**
   - ルート詳細画面で写真をタップ
   - ピンチイン/アウトで拡大縮小
   - スワイプで次の写真に移動

3. **ルート保存時の状態リセット**
   - GPS記録後に「お散歩を終了」
   - 次回の記録開始時に状態がリセットされているか確認

---

🎊 これでテストデータのセットアップは完了です！
