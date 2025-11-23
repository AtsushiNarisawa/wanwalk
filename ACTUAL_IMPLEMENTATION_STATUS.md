# WanMap v2 実際の実装状況（正確版）

**確認日時**: 2025-01-16  
**方法**: ファイルシステムの実際のファイル存在を確認

---

## 🎯 重要な発見

過去の履歴を確認した結果、**ほとんどの機能が既に実装済み**でした！

以前のチェックスクリプトは、特定のファイル名のみを探していたため、実際には存在する機能を「不足」と誤認識していました。

---

## ✅ 実装済み画面の完全リスト（45画面）

### 認証系（3画面）
- ✅ `lib/screens/auth/login_screen.dart`
- ✅ `lib/screens/auth/signup_screen.dart`
- ✅ `lib/screens/auth/password_reset_screen.dart`

### Phase 1: 基本機能（10画面）
- ✅ `lib/screens/home/home_screen.dart`
- ✅ `lib/screens/daily/daily_walk_view.dart`
- ✅ `lib/screens/daily/daily_walking_screen.dart`
- ✅ `lib/screens/map/map_screen.dart`
- ✅ `lib/screens/map/record_screen.dart`
- ✅ `lib/screens/profile/profile_screen.dart`
- ✅ `lib/screens/profile/profile_edit_screen.dart`
- ✅ `lib/screens/spots/spot_registration_screen.dart` ⚠️ (ピン作成画面)
- ✅ `lib/screens/spots/spot_detail_screen.dart`
- ✅ `lib/screens/settings/settings_screen.dart`

### Phase 2: エリア・公式ルート（6画面）
- ✅ `lib/screens/outing/area_list_screen.dart`
- ✅ `lib/screens/outing/route_list_screen.dart`
- ✅ `lib/screens/outing/route_detail_screen.dart`
- ✅ `lib/screens/outing/outing_walk_view.dart`
- ✅ `lib/screens/outing/outing_walk_view_v2.dart`
- ✅ `lib/screens/routes/public_routes_screen.dart`

### Phase 3: 検索機能（2画面）
- ✅ `lib/screens/search/route_search_screen.dart` ⚠️ (検索画面)
- ✅ `lib/screens/routes/route_search_screen.dart` ⚠️ (重複？)

### Phase 4: 履歴機能（2画面）
- ✅ `lib/screens/history/walk_history_screen.dart` ⚠️ (履歴画面)
- ✅ `lib/screens/history/walk_detail_screen.dart` ⚠️ (詳細画面)

### Phase 5: ソーシャル機能（10画面）
- ✅ `lib/screens/social/timeline_screen.dart`
- ✅ `lib/screens/social/follow_list_screen.dart`
- ✅ `lib/screens/social/followers_screen.dart`
- ✅ `lib/screens/social/following_screen.dart`
- ✅ `lib/screens/social/user_search_screen.dart`
- ✅ `lib/screens/social/popular_routes_screen.dart`
- ✅ `lib/screens/social/notification_center_screen.dart`
- ✅ `lib/screens/notifications/notifications_screen.dart` ⚠️ (重複?)
- ✅ `lib/screens/profile/user_profile_screen.dart`
- ✅ `lib/screens/routes/favorites_screen.dart`

### Phase 5: バッジ・統計（3画面）
- ✅ `lib/screens/badges/badge_list_screen.dart`
- ✅ `lib/screens/profile/statistics_dashboard_screen.dart`
- ✅ `lib/screens/statistics/statistics_dashboard_screen.dart` ⚠️ (重複？)

### Phase 5: お気に入り・保存（1画面）
- ✅ `lib/screens/favorites/saved_screen.dart`

### ルート管理（3画面）
- ✅ `lib/screens/routes/routes_list_screen.dart`
- ✅ `lib/screens/routes/route_detail_screen.dart`
- ✅ `lib/screens/routes/route_edit_screen.dart`

### お出かけ（2画面）
- ✅ `lib/screens/outing/pin_create_screen.dart`
- ✅ `lib/screens/outing/walking_screen.dart`

### 犬の管理（2画面）
- ✅ `lib/screens/dogs/dog_list_screen.dart`
- ✅ `lib/screens/dogs/dog_registration_screen.dart`

### 法的情報（2画面）
- ✅ `lib/screens/legal/privacy_policy_screen.dart`
- ✅ `lib/screens/legal/terms_of_service_screen.dart`

---

## ⚠️ 発見された問題点

### 1. ファイルの重複
以下の機能で複数の類似画面が存在（どちらが最新版か不明）：

#### 統計ダッシュボード
- `lib/screens/profile/statistics_dashboard_screen.dart`
- `lib/screens/statistics/statistics_dashboard_screen.dart`

#### 通知画面
- `lib/screens/notifications/notifications_screen.dart`
- `lib/screens/social/notification_center_screen.dart`

#### ルート検索
- `lib/screens/search/route_search_screen.dart`
- `lib/screens/routes/route_search_screen.dart`

### 2. お出かけ散歩画面のバージョン
- `outing_walk_view.dart`
- `outing_walk_view_v2.dart`
両方存在 - v2が最新版？

---

## 🔍 確認が必要な項目

### データベーステーブルとの整合性

#### Phase 4: 履歴機能
- **画面**: `walk_history_screen.dart`, `walk_detail_screen.dart` ✅ 存在
- **データベース**: `trips`, `trip_routes` テーブル ✅ 存在
- **問題**: 画面名が `walk_*` だが、テーブル名は `trip_*`
  - これは **daily_walks** (日々の散歩) と **trips** (旅行計画) の2つの概念が混在している可能性

#### Phase 1: ピン機能
- **画面**: `spot_registration_screen.dart`, `spot_detail_screen.dart` ✅ 存在
- **データベース**: `pins` または `route_pins` テーブル ❓
- **確認**: テーブル名の統一が必要

---

## 🎯 実際に不足している機能（再評価）

### 1. badge_detail_screen.dart（バッジ詳細画面）
- 現状: badge_list_screen のみ
- 必要性: 低（一覧画面で十分な可能性）

### 2. trip関連の画面（Phase 4の旅行計画機能）
現在は `walk_history` (日々の散歩履歴) のみで、`trips` (旅行計画) の専用画面がない可能性：
- `trip_list_screen.dart` - 旅行計画一覧
- `trip_create_screen.dart` - 旅行計画作成
- `trip_detail_screen.dart` - 旅行計画詳細
- `trip_edit_screen.dart` - 旅行計画編集

### 3. area_detail_screen.dart（エリア詳細画面）
- 現状: area_list_screen のみ
- 必要性: 中（エリアごとの統計・公式ルートを表示）

### 4. official_route_detail_screen.dart（公式ルート詳細）
- 現状: route_detail_screen で代用可能？
- 必要性: 低

---

## 📋 優先的に確認すべきこと

### 最優先: バッジシステムの動作確認
1. **badgesテーブル/ビューの作成**
   - `/home/user/webapp/wanmap_v2/FIX_BADGES_TABLE_ALIAS.sql` を実行
   - badge_definitions → badges ビューのマッピング
   - 17個のバッジデータ投入

2. **badge_list_screen.dart の動作確認**
   - 既に実装済み
   - データベース修正後に動作するはず

3. **statistics_dashboard_screen.dart の動作確認**
   - 2つのファイルが存在 - どちらが使用されているか確認

### 高優先: 履歴機能の確認
1. **walk_history_screen vs trips機能の関係**
   - `walk_history_screen.dart` が daily_walks を表示しているか確認
   - `trips` テーブルを使用する画面が不足していないか確認

2. **trip関連画面の必要性**
   - ユーザーが旅行計画機能を使えるようにする画面が必要か判断

### 中優先: 重複ファイルの整理
1. どちらのファイルが実際に使用されているか確認
2. 古いファイルを削除またはリネーム

---

## 🚀 次のアクション

### ステップ1: バッジテーブルの修正（即実行）
```bash
Supabase SQL Editor で以下を実行:
/home/user/webapp/wanmap_v2/FIX_BADGES_TABLE_ALIAS.sql
```

### ステップ2: 実装状況の詳細確認
以下のファイルを読んで、実際の実装内容を確認：
1. `lib/screens/history/walk_history_screen.dart` - daily_walks を使用？
2. `lib/screens/badges/badge_list_screen.dart` - 動作確認
3. `lib/screens/profile/statistics_dashboard_screen.dart` vs `lib/screens/statistics/statistics_dashboard_screen.dart`
4. 重複ファイルの内容比較

### ステップ3: 不足機能の実装（必要に応じて）
1. trip関連画面（旅行計画機能）
2. area_detail_screen（必要性を確認後）
3. badge_detail_screen（必要性を確認後）

---

## 📊 結論

**以前の診断は誤りでした。実際には：**

- ❌ Phase 3 検索機能が未実装 → ✅ **実装済み** (`route_search_screen.dart` × 2)
- ❌ Phase 4 履歴機能が未実装 → ✅ **部分実装済み** (`walk_history_screen.dart`)
- ❌ Phase 2 エリア詳細が未実装 → ⚠️ **area_detail は不足だが、リスト・ルート詳細は実装済み**

**真の問題点：**
1. 🚨 **badgesテーブルの不足** （データベース側の問題）
2. ⚠️ **重複ファイルの存在** （どれが最新版か不明）
3. ⚠️ **trips機能の専用画面が不足** （旅行計画 vs 日々の散歩）

**推奨アクション：**
1. バッジテーブルを修正（SQL実行）
2. 既存画面の動作確認
3. 重複ファイルの整理
4. 本当に不足している機能のみを実装
