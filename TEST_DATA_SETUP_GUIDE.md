# WanMap テストデータセットアップガイド

## 📋 概要

このガイドでは、WanMapアプリのテストに必要なデータをSupabaseに追加する手順を説明します。

## 🎯 作成されるテストデータ

### テストユーザー（3名）
- **test1@example.com** - メインテストユーザー（ルート作成者）
- **test2@example.com** - いいね・コメント用ユーザー
- **test3@example.com** - 追加テストユーザー

### ルート（5件）
1. **芦ノ湖畔の朝散歩** - 短距離、写真3枚、いいね15件
2. **大涌谷から早雲山のハイキング** - 長距離、写真4枚、いいね23件
3. **箱根湯本温泉街さんぽ** - 中距離、写真2枚、いいね8件
4. **仙石原の森林浴トレイル** - 中距離、別ユーザー、いいね12件
5. **自宅周辺の散歩** - プライベート（非公開）

### その他のデータ
- **GPSポイント**: 15件（実際のルートトラック）
- **写真**: 9件（Unsplashの美しい風景写真）
- **お気に入り**: 3件
- **コメント**: 4件

---

## 🚀 セットアップ手順

### ステップ1: Supabaseダッシュボードにアクセス

1. [Supabase Dashboard](https://supabase.com/dashboard) にアクセス
2. WanMapプロジェクトを選択

---

### ステップ2: テストユーザーの作成

#### 方法A: Supabase UI から作成（推奨）

1. 左サイドバーの **Authentication** をクリック
2. **Users** タブを選択
3. **Add user** ボタンをクリック
4. 以下の3ユーザーを作成：

**ユーザー1:**
- Email: `test1@example.com`
- Password: `test1234`
- Auto Confirm User: ✅ チェック

**ユーザー2:**
- Email: `test2@example.com`
- Password: `test1234`
- Auto Confirm User: ✅ チェック

**ユーザー3:**
- Email: `test3@example.com`
- Password: `test1234`
- Auto Confirm User: ✅ チェック

5. 各ユーザーの **User UID** をコピーして保存しておく

---

### ステップ3: SQLスクリプトの編集

1. `test_data_setup.sql` ファイルを開く
2. 以下の3箇所の **USER_ID_1**, **USER_ID_2**, **USER_ID_3** を実際のUser UIDに置き換える：

```sql
-- 例: これを...
'USER_ID_1'

-- こうする（実際のUIDを使用）
'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
```

**置き換える箇所:**
- routes テーブルの INSERT 文（5箇所）
- favorites テーブルの INSERT 文（3箇所）
- comments テーブルの INSERT 文（4箇所）

**検索・置換を使うと便利:**
- `USER_ID_1` → test1@example.com のUID
- `USER_ID_2` → test2@example.com のUID
- `USER_ID_3` → test3@example.com のUID

---

### ステップ4: SQLスクリプトの実行

1. Supabaseダッシュボードの左サイドバーから **SQL Editor** をクリック
2. **New query** をクリック
3. 編集した `test_data_setup.sql` の内容をコピー＆ペースト
4. **Run** ボタンをクリックして実行

**実行結果の確認:**
```
Success. No rows returned
```

このメッセージが表示されればOKです。

---

### ステップ5: データの確認

#### Table Editor で確認

1. 左サイドバーの **Table Editor** をクリック
2. 各テーブルを確認：

**routes テーブル:**
- 5件のルートが作成されているか確認
- `is_public` が true のものが4件、false のものが1件

**photos テーブル:**
- 9件の写真が作成されているか確認
- `url` にUnsplashの画像URLが入っているか確認

**route_points テーブル:**
- 15件のGPSポイントが作成されているか確認

**favorites テーブル:**
- 3件のお気に入りが作成されているか確認

**comments テーブル:**
- 4件のコメントが作成されているか確認

---

### ステップ6: アプリでテスト

#### 1. ログインテスト

**シミュレータでアプリを起動:**
```bash
flutter run
```

**ログイン:**
- Email: `test1@example.com`
- Password: `test1234`

#### 2. データ表示の確認

**ホーム画面:**
- 統計情報が表示されているか確認
- 「ルート一覧」をタップ

**ルート一覧画面:**
- 5件のルートが表示されているか確認
- サムネイル画像が正しく表示されているか確認
- 距離、時間、いいね数が表示されているか確認

**ルート詳細画面:**
- ルートをタップして詳細画面を開く
- 地図上にルートが表示されているか確認
- 写真ギャラリーが表示されているか確認
- 統計情報が正しく表示されているか確認

#### 3. 写真拡大機能のテスト

**写真をタップ:**
- 全画面で写真が表示される
- ピンチイン/アウトで拡大縮小できる
- スワイプで次/前の写真に移動できる
- 左上の戻るボタンで元の画面に戻れる

#### 4. GPS記録機能のテスト

**マップ画面に移動:**
- 「お散歩を開始」ボタンをタップ
- GPS記録が開始される
- 「一時停止」ボタンをタップ → 「再開」に変わる
- 「再開」ボタンをタップ → 記録が再開される
- 「写真」ボタンをタップ → カメラが起動（シミュレータでは動作しない可能性あり）
- 「お散歩を終了」ボタンをタップ
- ルート名を入力して保存

---

## 🔧 トラブルシューティング

### エラー: "duplicate key value violates unique constraint"

**原因:** すでに同じIDのデータが存在している

**解決方法:**
1. SQL Editorで既存データを削除:
```sql
DELETE FROM photos;
DELETE FROM comments;
DELETE FROM favorites;
DELETE FROM route_points;
DELETE FROM routes;
```
2. スクリプトを再実行

---

### 写真が表示されない

**原因1:** Storage Buckets のパーミッション設定

**解決方法:**
1. Supabaseダッシュボード → Storage
2. `route-photos` バケットを選択
3. Policies タブ
4. "Enable read access for all users" ポリシーを追加

**原因2:** 外部画像URLのCORS問題

**解決方法:**
- Unsplashの画像は通常問題なく表示されます
- 別の画像URLを使用する場合はCORS設定を確認

---

### いいね数が表示されない

**原因:** `like_count` カラムが NULL

**解決方法:**
```sql
UPDATE routes SET like_count = 0 WHERE like_count IS NULL;
```

---

## 📝 データのクリーンアップ

テストデータを削除する場合:

```sql
-- すべてのテストデータを削除
DELETE FROM photos;
DELETE FROM comments;
DELETE FROM favorites;
DELETE FROM route_points;
DELETE FROM routes WHERE user_id IN ('USER_ID_1', 'USER_ID_2', 'USER_ID_3');
```

**注意:** 'USER_ID_1', 'USER_ID_2', 'USER_ID_3' を実際のUser UIDに置き換えてください。

---

## ✅ チェックリスト

セットアップが完了したら、以下を確認してください:

- [ ] テストユーザー3名が作成されている
- [ ] ルートが5件作成されている
- [ ] 写真が9件作成されている
- [ ] GPSポイントが15件作成されている
- [ ] お気に入りが3件作成されている
- [ ] コメントが4件作成されている
- [ ] アプリでログインできる
- [ ] ルート一覧が表示される
- [ ] 写真が正しく表示される
- [ ] 写真の拡大表示が動作する
- [ ] GPS記録の一時停止/再開が動作する

---

## 🎉 完了！

テストデータのセットアップが完了しました。Phase 2のテストを開始してください！
