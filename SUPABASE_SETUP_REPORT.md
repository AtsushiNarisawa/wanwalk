# WanWalk Supabase 整備レポート

**作成日:** 2026-03-03  
**対象:** Phase 1+2 コード修正に伴うSupabase環境整備  

---

## 実施が必要な作業（4項目）

### 1. profiles テーブルの作成

**背景:** BUG-C02 修正で `users` テーブルと `profiles` テーブルの不整合を解消。Supabase Auth が `auth.users` を自動管理するため、公開プロフィール情報は `profiles` テーブルに統一しました。

**必要なカラム:**

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | UUID (PK) | auth.usersのIDと同じ |
| email | TEXT | メールアドレス |
| display_name | TEXT | 表示名 |
| bio | TEXT | 自己紹介 |
| avatar_url | TEXT | アバター画像URL |
| created_at | TIMESTAMPTZ | 作成日時 |
| updated_at | TIMESTAMPTZ | 更新日時 |

**RLSポリシー:**
- 全ユーザーがプロフィールを**閲覧可能**（公開情報のため）
- 自分のプロフィールのみ**作成・更新可能**

**自動処理:**
- 新規ユーザー登録時に profiles レコードを自動作成するトリガー付き

---

### 2. user-avatars バケットの確認・作成

**背景:** BUG-C03 修正でバケット名を `user-avatars` に統一。

**設定:**
- バケット名: `user-avatars`
- 公開: はい（アバター画像は公開）
- ファイルサイズ上限: 5MB
- 許可形式: JPEG, PNG, GIF, WebP

**RLSポリシー:**
- 誰でも画像を**閲覧可能**
- 認証済みユーザーは自分のフォルダにのみ**アップロード可能**
- 認証済みユーザーは自分のフォルダのファイルのみ**削除可能**

**アプリが使用する全バケット（5つ）:**

| バケット名 | 用途 | 公開 |
|-----------|------|------|
| `user-avatars` | ユーザーアバター画像 | はい |
| `dog-photos` | 愛犬写真 | はい |
| `route-photos` | ルート写真 | はい |
| `walk-photos` | 散歩中の写真 | はい |
| `pin_photos` | ピン投稿の写真 | はい |

---

### 3. 既存データのマイグレーション

**操作手順:**
1. `users` テーブルにデータがある場合 → `profiles` テーブルにコピー
2. `auth.users` に存在するが `profiles` にないユーザー → プロフィールを自動作成
3. テストユーザーのデータも移行対象

**SQLスクリプトに含まれています。** セクション4を実行するだけでOKです。

---

### 4. RPC関数の確認・作成

**重要な変更:** QAレポートでは14個のRPC関数と報告していましたが、コードを詳細に調査した結果、**39個のRPC関数**がFlutterアプリから呼び出されていることが判明しました。

**39個のRPC関数一覧:**

| # | 関数名 | 用途 | カテゴリ |
|---|--------|------|---------|
| 1 | `like_pin` | ピンにいいね | いいね |
| 2 | `unlike_pin` | いいね取り消し | いいね |
| 3 | `check_user_liked_pin` | いいね状態確認 | いいね |
| 4 | `get_user_liked_pins` | いいねしたピン一覧 | いいね |
| 5 | `toggle_pin_like` | いいねトグル | いいね |
| 6 | `bookmark_pin` | ブックマーク追加 | ブックマーク |
| 7 | `unbookmark_pin` | ブックマーク解除 | ブックマーク |
| 8 | `check_user_bookmarked_pin` | ブックマーク状態確認 | ブックマーク |
| 9 | `get_user_bookmarked_pins` | ブックマーク一覧 | ブックマーク |
| 10 | `add_pin_comment` | コメント追加 | コメント |
| 11 | `delete_pin_comment` | コメント削除 | コメント |
| 12 | `get_pin_comments` | コメント一覧 | コメント |
| 13 | `get_pin_comments_count` | コメント数 | コメント |
| 14 | `get_pin_location` | ピン位置情報取得 | ピン |
| 15 | `get_recent_pins` | 最新ピン取得 | ピン |
| 16 | `get_all_routes_geojson` | 全ルートGeoJSON | マップ |
| 17 | `get_areas_simple` | エリア一覧 | マップ |
| 18 | `get_route_by_id_geojson` | 個別ルートGeoJSON | マップ |
| 19 | `get_routes_by_area_geojson` | エリア別ルートGeoJSON | マップ |
| 20 | `get_monthly_popular_official_routes` | 月間人気ルート | マップ |
| 21 | `find_nearby_routes` | 近くのルート検索 | 検索 |
| 22 | `get_daily_walk_history` | 日常散歩履歴 | 履歴 |
| 23 | `get_outing_walk_history` | お出かけ散歩履歴 | 履歴 |
| 24 | `get_recommended_routes` | おすすめルート | ホーム |
| 25 | `get_trending_routes` | 急上昇ルート | ホーム |
| 26 | `get_recent_memories` | 最近の思い出写真 | ホーム |
| 27 | `get_routes_by_area_enhanced` | エリア別ルート拡張版 | ホーム |
| 28 | `get_favorite_routes` | お気に入りルート一覧 | お気に入り |
| 29 | `get_bookmarked_pins` | ブックマーク済みピン一覧 | お気に入り |
| 30 | `get_user_statistics` | ユーザー統計 | 統計 |
| 31 | `get_monthly_statistics` | 月別統計 | 統計 |
| 32 | `get_weekly_statistics` | 週別統計 | 統計 |
| 33 | `get_hourly_statistics` | 時間帯別統計 | 統計 |
| 34 | `get_lifetime_statistics` | 累計統計 | 統計 |
| 35 | `get_area_statistics` | エリア別統計 | 統計 |
| 36 | `get_dog_statistics` | 愛犬別統計 | 統計 |
| 37 | `get_user_walk_statistics` | プロフィール用散歩統計 | 統計 |
| 38 | `get_notifications` | 通知一覧 | 通知 |
| 39 | `update_user_walking_profile` | プロフィール自動更新 | プロフィール |

---

## 実行手順

### ステップ1: SQLスクリプトの実行

1. Supabase管理画面にログイン
2. **SQL Editor** を開く
3. ファイル `supabase_migrations/PHASE1_2_SUPABASE_SETUP.sql` の内容をコピー
4. **セクションごとに順番に実行** してください

> **注意:** 一括実行ではなく、セクション（`-- ============` で区切られた部分）ごとに実行することを推奨します。エラーが発生した場合に特定しやすくなります。

### ステップ2: 確認

セクション18の確認クエリを実行して、以下を確認してください：

1. `profiles` テーブルが存在し、データが入っているか
2. RPC関数が39個すべて存在するか
3. ストレージバケットが5つすべて存在するか
4. 既存のテストユーザーのデータが `profiles` テーブルに移行されているか

### ステップ3: 報告

上記4項目すべて確認できたら報告をお願いします。その後、TestFlightビルドを作成します。

---

## アプリが参照するテーブル一覧

Flutterアプリのコードから `.from()` で参照されているテーブル：

| テーブル名 | 参照数 | 用途 |
|-----------|--------|------|
| `profiles` (= SupabaseTables.users) | 6 | ユーザープロフィール |
| `dogs` | 5 | 愛犬情報 |
| `walks` | 7 | 散歩記録 |
| `official_routes` | 4 | 公式ルート |
| `route_pins` | 7 | ピン投稿 |
| `route_pin_photos` | 5 | ピン写真 |
| `areas` | 4 | エリアマスタ |
| `route_points` | 4 | ルート経路ポイント |
| `notifications` | 5 | 通知 |
| `spot_reviews` | 10 | スポットレビュー |
| `pin_bookmarks` | 3 | ピンブックマーク |
| `pin_likes` | 1 | ピンいいね |
| `likes` | 5 | いいね（旧テーブル） |
| `route_spots` | 1 | ルートスポット |
| `contact_messages` | 1 | お問い合わせ |
| `routes` | 8 | ルート（旧テーブル名） |
| `walk_photos` / `walk-photos` | 7 | 散歩写真 |
| `route_photos` / `route-photos` | 7 | ルート写真 |

---

## 追加発見事項

### 新たに発見された問題

1. **RPC関数数の訂正:** 当初14個と報告していたが、実際には **39個** が必要。すべてのRPC関数のSQLをスクリプトに含めました。

2. **ストレージバケット:** 当初3個と認識していたが、実際には **5個** が必要（`pin_photos` バケットが追加で必要）。

3. **テーブル名の混在:** コード内で一部 `routes` と `official_routes` の両方が参照されている箇所がありますが、Phase 1+2 の修正で `official_routes` に統一済みです。ただし、`walks` テーブルの `route_id` カラムが文字列型の場合、UUID変換が必要な箇所があります。

### 補足: テーブル構造の注意点

`official_routes` テーブルのカラム名が以下のように混在している可能性があります：
- `name` / `title` → アプリはどちらも許容（COALESCE で対応）
- `distance_meters` / `distance_km` → RPC関数で自動変換
- `estimated_minutes` / `estimated_duration_minutes` → RPC関数で自動変換
- `difficulty_level` / `difficulty` → RPC関数で自動変換

RPC関数内で `COALESCE` を使用して両方のカラム名に対応しています。

---

## 次のアクション

1. **Supabase管理者:** 上記SQLスクリプトを実行
2. **Supabase管理者:** 確認クエリの結果を報告
3. **開発者:** 報告を受けてTestFlightビルドを作成
4. **CEO:** TestFlightで実機テスト
