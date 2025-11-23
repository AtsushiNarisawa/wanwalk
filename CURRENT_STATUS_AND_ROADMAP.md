# WanMap v2 - 現状とリリースまでのロードマップ

**作成日**: 2025-11-23  
**プロジェクト**: WanMap - 愛犬の散歩ルート共有モバイルアプリ  
**リポジトリ**: https://github.com/AtsushiNarisawa/wanmap_v2

---

## 📊 現在の実装状況サマリー

### ✅ 完全実装済み（動作確認済み）

#### 1. **コアアーキテクチャ**
- ✅ Flutter 3.38.2 + Dart 3.0+
- ✅ Riverpod 2.6.1 状態管理（完全移行完了）
- ✅ Supabase バックエンド接続
- ✅ 4タブUI（ホーム/マップ/記録/プロフィール）
- ✅ ダークモード対応
- ✅ Git/GitHub統合

#### 2. **認証システム**
- ✅ ログイン画面（email/password）
- ✅ サインアップ画面
- ✅ パスワードリセット画面
- ✅ Supabase Auth連携
- ✅ 3つのテストアカウント作成済み
  - test1@example.com / test123
  - test2@example.com / test123
  - test3@example.com / test123

#### 3. **UI コンポーネント（35画面）**
実装済みのスクリーンファイル:
```
認証 (3):
  - login_screen.dart
  - signup_screen.dart
  - password_reset_screen.dart

メイン (4):
  - main_screen.dart
  - tabs/home_tab.dart ✅ 動作確認済み
  - tabs/map_tab.dart ✅ 動作確認済み（地図タイル未表示のみ）
  - tabs/records_tab.dart ✅ 動作確認済み
  - tabs/profile_tab.dart ✅ 動作確認済み

散歩記録 (4):
  - daily/daily_walk_view.dart
  - daily/daily_walking_screen.dart
  - outing/outing_walk_view.dart
  - outing/outing_walk_view_v2.dart
  - outing/walking_screen.dart

ルート関連 (7):
  - outing/area_list_screen.dart
  - outing/route_list_screen.dart
  - outing/route_detail_screen.dart ✅ Riverpod完全対応
  - routes/favorites_screen.dart ✅ Riverpod完全対応
  - routes/public_routes_screen.dart
  - routes/route_edit_screen.dart
  - routes/routes_list_screen.dart

ピン関連 (1):
  - outing/pin_create_screen.dart

ソーシャル (7):
  - social/timeline_screen.dart
  - social/user_search_screen.dart
  - social/follow_list_screen.dart
  - social/followers_screen.dart
  - social/following_screen.dart
  - social/notification_center_screen.dart
  - social/popular_routes_screen.dart

プロフィール (2):
  - profile/user_profile_screen.dart
  - statistics/statistics_dashboard_screen.dart ✅ Riverpod完全対応

その他 (7):
  - map/map_screen.dart
  - history/walk_history_screen.dart
  - search/route_search_screen.dart
  - notifications/notifications_screen.dart
  - legal/privacy_policy_screen.dart
  - legal/terms_of_service_screen.dart
```

#### 4. **プロバイダー（22個 - 全てRiverpod StateNotifier）**
```
✅ auth_provider.dart - 認証状態管理
✅ theme_provider.dart - ダークモード管理
✅ dog_provider.dart - 犬情報管理
✅ route_provider.dart - ルート管理
✅ spot_provider.dart - スポット管理
✅ gps_provider_riverpod.dart - GPS位置追跡
✅ user_statistics_provider.dart - ユーザー統計
✅ badge_provider.dart - バッジシステム
✅ walk_history_provider.dart - 散歩履歴
✅ area_provider.dart - エリア管理
✅ social_provider.dart - ソーシャル機能（名前変更済み）
✅ follow_provider.dart - フォロー機能
✅ notification_provider.dart - 通知管理
✅ official_route_provider.dart - 公式ルート
✅ route_pin_provider.dart - ルートピン
✅ route_search_provider.dart - ルート検索
✅ favorites_provider.dart - お気に入り
✅ like_provider.dart - いいね機能
✅ connectivity_provider.dart - ネットワーク監視
✅ home_provider.dart - ホーム画面
✅ walk_detail_provider.dart - 散歩詳細
✅ walk_mode_provider.dart - 散歩モード
```

#### 5. **ウィジェット（34個）**
全てRiverpod対応済み、主要ウィジェット:
- badge_card.dart, favorite_route_card.dart, recommended_route_card.dart
- photo_route_card.dart, wanmap_route_card.dart
- daily_walk_history_card.dart, outing_walk_history_card.dart
- user_list_item.dart, follow_button.dart, like_button.dart
- paginated_list_view.dart, retryable_async_widget.dart
- 等34個のウィジェット

#### 6. **サービスレイヤー（28個）**
全て実装済み:
- auth_service.dart, badge_service.dart, dog_service.dart
- route_service.dart, spot_service.dart, gps_service.dart
- user_statistics_service.dart, walk_history_service.dart
- social_service.dart, follow_service.dart, like_service.dart
- notification_service.dart, favorite_service.dart
- photo_service.dart, storage_service.dart
- 等28個のサービス

#### 7. **モデル（24個）**
全てのデータモデル実装済み:
- user_statistics.dart, badge.dart, dog_model.dart
- route_model.dart, route_pin.dart, official_route.dart
- walk_history.dart, area.dart, spot_model.dart
- follow_model.dart, like_model.dart, notification_model.dart
- 等24個のモデル

#### 8. **Supabase データベース**

**✅ 実装済みテーブル（7個）:**
```sql
✅ users - ユーザー情報
✅ badge_definitions - バッジマスターデータ（17個登録済み）
✅ user_badges - ユーザー獲得バッジ
✅ route_favorites - お気に入りルート
✅ user_follows - フォロー関係
✅ areas - エリアマスター（3エリア登録済み）
✅ routes - 公式ルート（16ルート登録済み）
```

**✅ 実装済みRPC関数（2個）:**
```sql
✅ get_user_walk_statistics(p_user_id) - ユーザー統計取得
✅ check_and_unlock_badges(p_user_id) - バッジ解除チェック
```

**❌ 未実装テーブル:**
```sql
❌ walks - 散歩履歴（Daily/Outing両方）
❌ pins - ピン投稿データ
❌ route_pins - ルート上のピン関連
❌ walk_photos - 散歩写真
❌ comments - コメント機能
❌ notifications - 通知データ
❌ user_profiles - ユーザープロフィール拡張
❌ dogs - 犬情報
```

**❌ 未実装RPC関数:**
```sql
❌ get_notifications(p_user_id, p_limit, p_offset)
❌ search_routes(p_user_id, p_sort_by, p_limit, p_offset)
❌ get_outing_walk_history(p_user_id, p_limit, p_offset)
❌ get_daily_walk_history(p_user_id, p_limit, p_offset)
❌ get_timeline_pins(p_user_id, p_limit, p_offset)
❌ search_users(p_query, p_user_id, p_limit, p_offset)
```

#### 9. **外部サービス連携**
- ✅ Supabase: https://jkpenklhrlbctebkpvax.supabase.co
- ✅ Thunderforest Maps API: キー取得済み（8c3872c6b1d5471a0e8c88cc69ed4f）
  - ⚠️ .envファイルに未設定（"your-api-key-here"のまま）

---

## 🐛 現在の既知の問題

### 1. **統計データエラー**
**症状**: ProfileTabで `Error getting user statistics: type 'Null' is not a subtype of type 'int'`

**原因**: `get_user_walk_statistics` RPCは動作するが、全て0を返す
```json
{
  "total_walks": 0,
  "total_distance_km": 0,
  "total_duration_hours": 0,
  "average_distance_km": 0,
  "average_duration_minutes": 0,
  "daily_walks_count": 0,
  "route_walks_count": 0,
  "pins_posted_count": 0,
  "pins_liked_count": 0
}
```

**解決策**: 
- `walks`テーブル作成が必要
- テストデータを挿入
- または、データがない場合のnull安全処理を追加

### 2. **地図タイル未表示**
**症状**: MapTabで地図タイルが表示されない

**原因**: Thunderforest APIキーが.envファイルに未設定

**解決策**:
```bash
# .envファイルを修正
THUNDERFOREST_API_KEY=8c3872c6b1d5471a0e8c88cc69ed4f
```

### 3. **削除された画面へのナビゲーション**
**現状**: 以下の機能はスナックバーで「準備中」と表示:
- プロフィール編集画面
- 設定画面
- 愛犬管理画面
- お気に入り画面（記録タブから）
- バッジ一覧画面（記録タブから）
- フォロワー/フォロー機能（プロフィールタブから）
- 散歩詳細画面（履歴から）

**これらは実際には実装済みファイルが存在する:**
```
✅ routes/favorites_screen.dart - お気に入り画面（実装済み）
✅ social/followers_screen.dart - フォロワー画面（実装済み）
✅ social/following_screen.dart - フォロー中画面（実装済み）
```

**解決策**: ナビゲーション接続を復活させる

---

## 🎯 リリースまでのロードマップ

### **Phase 1: データベース完成（最優先）** ⏱️ 2-3日

#### 1-1. テーブル作成
必要なSQLマイグレーション作成:
```sql
-- 散歩履歴テーブル
CREATE TABLE walks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  walk_type TEXT NOT NULL CHECK (walk_type IN ('daily', 'outing')),
  route_id UUID REFERENCES routes(id), -- outingの場合のみ
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  distance_km DECIMAL(10,2),
  duration_minutes INTEGER,
  path_geojson JSONB, -- 経路データ
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ピン投稿テーブル
CREATE TABLE pins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  route_id UUID REFERENCES routes(id),
  walk_id UUID REFERENCES walks(id),
  pin_type TEXT CHECK (pin_type IN ('view', 'shop', 'meet', 'other')),
  title TEXT NOT NULL,
  description TEXT,
  location GEOGRAPHY(Point),
  photos TEXT[], -- 画像URL配列
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- その他テーブル（notifications, comments, user_profiles, dogs等）
```

#### 1-2. RPC関数作成
```sql
-- 散歩履歴取得
CREATE OR REPLACE FUNCTION get_daily_walk_history(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
) RETURNS TABLE(...) AS $$
  -- 実装
$$ LANGUAGE plpgsql;

-- ルート検索
CREATE OR REPLACE FUNCTION search_routes(
  p_user_id UUID,
  p_sort_by TEXT DEFAULT 'popular',
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
) RETURNS TABLE(...) AS $$
  -- 実装
$$ LANGUAGE plpgsql;

-- その他のRPC関数
```

#### 1-3. テストデータ投入
```sql
-- テストユーザーの散歩記録を作成
-- エリアデータの充実（箱根、横浜、鎌倉、東京、大阪等）
-- 公式ルートの追加（各エリア3-5本）
-- サンプルピン投稿
```

**成果物**:
- ✅ 完全なデータベーススキーマ
- ✅ 全てのRPC関数実装
- ✅ テストデータ完備
- ✅ 統計データエラー解消

---

### **Phase 2: UI/UX完成（高優先）** ⏱️ 3-4日

#### 2-1. 削除画面の再実装・接続
**優先度: 高**
1. **設定画面（SettingsScreen）**
   - テーマ切り替え（既に実装済みtheme_provider使用）
   - 通知設定
   - プライバシー設定
   - アカウント管理

2. **プロフィール編集画面（ProfileEditScreen）**
   - アバター画像変更（Supabase Storage使用）
   - 表示名、自己紹介編集
   - プロフィール写真アップロード

3. **愛犬管理画面（DogListScreen + DogRegistrationScreen）**
   - 犬の登録・編集・削除
   - 犬種、年齢、性別、写真
   - 複数頭対応

**優先度: 中**
4. **散歩詳細画面（WalkDetailScreen）**
   - 散歩ルート地図表示
   - 統計データ（距離、時間、速度）
   - 投稿したピン一覧
   - 写真ギャラリー

5. **バッジ一覧画面（BadgeListScreen）**
   - 実装済みbadge_provider.dartを使用
   - カテゴリ別タブ（距離/エリア/ピン/ソーシャル/特別）
   - ロック/アンロック状態表示
   - 進捗バー表示

#### 2-2. ナビゲーション修正
既存の実装済み画面への接続を復活:
```dart
// profile_tab.dart の修正例
// ❌ 現在: スナックバー「準備中」
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('フォロワー/フォロー機能は準備中です'))
);

// ✅ 修正後: 実装済み画面へナビゲート
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const FollowersScreen())
);
```

#### 2-3. 地図タイル修正
```dart
// .envファイル修正
THUNDERFOREST_API_KEY=8c3872c6b1d5471a0e8c88cc69ed4f

// アプリ再起動で地図表示確認
```

**成果物**:
- ✅ 全ての画面が正しく動作
- ✅ ナビゲーションフロー完成
- ✅ 地図タイル表示正常

---

### **Phase 3: コア機能実装（必須）** ⏱️ 5-7日

#### 3-1. 散歩記録機能（Daily/Outing両方）
**実装内容**:
- GPSリアルタイム追跡（gps_provider_riverpod.dart使用）
- 経路記録（GeoJSON形式）
- 一時停止/再開機能
- 散歩完了後の保存処理
- 統計計算（距離、時間、速度）
- バッジ自動チェック（散歩完了時）

**使用するファイル**:
- `daily_walking_screen.dart`
- `outing/walking_screen.dart`
- `gps_provider_riverpod.dart`
- `walk_history_provider.dart`

#### 3-2. ピン投稿機能
**実装内容**:
- 散歩中にピン作成（位置情報自動取得）
- 4種類のピンタイプ選択
- 写真アップロード（最大5枚）
- タイトル・説明入力
- Supabase Storageへ画像保存
- pins テーブルへ保存

**使用するファイル**:
- `pin_create_screen.dart`
- `route_pin_provider.dart`
- `photo_service.dart`
- `storage_service.dart`

#### 3-3. ソーシャル機能
**実装内容**:
- ユーザー検索（search_users RPC使用）
- フォロー/アンフォロー
- タイムライン表示（フォロー中のユーザーのピン）
- いいね機能
- リアルタイム通知（Supabase Realtime）
- 通知センター（スワイプ削除、一括既読）

**使用するファイル**:
- `social/user_search_screen.dart`
- `social/timeline_screen.dart`
- `social/notification_center_screen.dart`
- `social_provider.dart`
- `follow_provider.dart`
- `like_provider.dart`

#### 3-4. バッジシステム
**実装内容**:
- 自動バッジチェック（散歩完了時、ピン投稿時、フォロワー増加時）
- バッジ獲得通知表示
- バッジコレクション画面
- 進捗表示

**使用するファイル**:
- `badge_provider.dart`
- `badge_service.dart`
- `widgets/badges/badge_card.dart`
- `widgets/badges/badge_unlock_dialog.dart`

**成果物**:
- ✅ GPSで散歩を記録できる
- ✅ ピンを投稿できる
- ✅ ユーザーをフォローできる
- ✅ タイムラインを閲覧できる
- ✅ バッジを獲得できる

---

### **Phase 4: データ充実（重要）** ⏱️ 2-3日

#### 4-1. エリアデータ拡充
現在3エリア → 10エリアへ:
```
✅ 既存: 箱根、横浜、?
➕ 追加: 鎌倉、東京（代々木公園）、目黒区、世田谷区、
         大阪（大阪城公園）、京都（嵐山）、奈良公園
```

#### 4-2. 公式ルートデータ拡充
現在16ルート → 各エリア3-5本（合計30-50本）:
```
各エリアごとに:
- 初級ルート: 1-2本（2-3km、30-45分）
- 中級ルート: 1-2本（4-6km、60-90分）
- 上級ルート: 1本（7km以上、2時間以上）
```

#### 4-3. バッジデータ拡充
現在17個 → 22個へ（README記載の完全版）:
```
距離バッジ: 7個
エリアバッジ: 3個
ピンバッジ: 4個
ソーシャルバッジ: 4個
ルートバッジ: 3個
特別バッジ: 1個
```

#### 4-4. サンプルデータ作成
```
- テストユーザー3名の散歩履歴（各10件）
- サンプルピン投稿（各ルートに2-3個）
- フォロー関係の構築
- いいねデータ
```

**成果物**:
- ✅ 実際に使える公式ルートが豊富
- ✅ 各エリアに複数の選択肢
- ✅ デモ・テスト時に見栄えが良い

---

### **Phase 5: テスト・デバッグ（必須）** ⏱️ 3-5日

#### 5-1. 機能テスト
全ての画面・機能を手動テスト:
- [ ] ログイン/サインアップ
- [ ] Daily散歩記録
- [ ] Outing散歩記録
- [ ] ピン投稿
- [ ] ルート検索
- [ ] お気に入り登録
- [ ] ユーザー検索・フォロー
- [ ] タイムライン閲覧
- [ ] 通知受信
- [ ] バッジ獲得
- [ ] プロフィール編集
- [ ] 設定変更
- [ ] 愛犬登録・管理

#### 5-2. エラーハンドリング強化
- ネットワークエラー時の挙動
- GPS取得失敗時の対応
- 画像アップロード失敗時の処理
- データが空の場合のUI表示

#### 5-3. パフォーマンス最適化
- 画像の遅延読み込み（optimized_image.dart使用）
- 無限スクロールのパフォーマンス
- 地図表示の軽量化
- メモリ使用量の確認

#### 5-4. UI/UX改善
- ローディング表示の統一
- エラーメッセージの日本語化
- 操作フィードバックの改善
- アクセシビリティ確認

**成果物**:
- ✅ 全機能が安定動作
- ✅ エラーハンドリング完備
- ✅ 快適な操作感

---

### **Phase 6: リリース準備（必須）** ⏱️ 2-3日

#### 6-1. App Store準備
- [ ] アプリアイコン最終確認（既存: app_icon.png）
- [ ] スプラッシュスクリーン作成
- [ ] App Store スクリーンショット（5-8枚）
  - ホーム画面
  - マップ画面
  - 散歩記録画面
  - ルート詳細画面
  - タイムライン画面
- [ ] アプリ説明文作成（日本語・英語）
- [ ] プロモーションテキスト
- [ ] キーワード設定

#### 6-2. 法的文書
- [ ] プライバシーポリシー作成（privacy_policy_screen.dart に表示）
- [ ] 利用規約作成（terms_of_service_screen.dart に表示）
- [ ] 位置情報利用の説明文
- [ ] 写真アップロード利用規約

#### 6-3. ビルド設定
```yaml
# pubspec.yaml
version: 1.0.0+1

# iOS: ios/Runner/Info.plist
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>

# Android: android/app/build.gradle
versionCode 1
versionName "1.0.0"
```

#### 6-4. 最終チェック
- [ ] iOS実機テスト（iPhone 8以降）
- [ ] Android実機テスト（Android 10以降）
- [ ] ダークモード動作確認
- [ ] 位置情報権限の動作確認
- [ ] 写真アクセス権限の動作確認
- [ ] プッシュ通知の動作確認

**成果物**:
- ✅ App Store Connect アップロード準備完了
- ✅ Google Play Console アップロード準備完了
- ✅ 法的要件クリア

---

### **Phase 7: TestFlight配信** ⏱️ 1-2日

#### 7-1. iOS TestFlight
```bash
# ビルド作成
flutter build ipa --release

# Xcode でアーカイブ作成
# App Store Connect へアップロード
# TestFlight で配信設定
```

#### 7-2. Android内部テスト
```bash
# ビルド作成
flutter build appbundle --release

# Google Play Console へアップロード
# 内部テストトラックに配信
```

#### 7-3. ベータテスター招待
- 5-10名のテスターを募集
- フィードバック収集
- 不具合修正

**成果物**:
- ✅ TestFlight配信開始
- ✅ ベータテスター向けに配信
- ✅ 実ユーザーからのフィードバック取得

---

### **Phase 8: 正式リリース** ⏱️ 1週間

#### 8-1. App Store審査申請
- App Store Connect で審査申請
- 審査期間: 通常1-3日
- リジェクト時の対応準備

#### 8-2. Google Play審査申請
- Google Play Console で審査申請
- 審査期間: 通常数時間-1日

#### 8-3. リリース後の監視
- クラッシュレポート監視（Firebase Crashlytics推奨）
- ユーザーレビュー監視
- 緊急バグ修正体制

**成果物**:
- ✅ App Store 公開
- ✅ Google Play 公開
- ✅ 正式リリース完了 🎉

---

## 📅 タイムライン見積もり

| フェーズ | 所要日数 | 累計 |
|---------|---------|------|
| Phase 1: データベース完成 | 2-3日 | 3日 |
| Phase 2: UI/UX完成 | 3-4日 | 7日 |
| Phase 3: コア機能実装 | 5-7日 | 14日 |
| Phase 4: データ充実 | 2-3日 | 17日 |
| Phase 5: テスト・デバッグ | 3-5日 | 22日 |
| Phase 6: リリース準備 | 2-3日 | 25日 |
| Phase 7: TestFlight配信 | 1-2日 | 27日 |
| Phase 8: 正式リリース | 1週間 | 34日 |

**総見積もり: 約4-5週間（1ヶ月）**

---

## 🔧 技術的な注意事項

### 既存の強み
1. **完全なRiverpod移行**: 全てのプロバイダーがStateNotifier化済み
2. **豊富な画面実装**: 35画面が既に実装済み
3. **充実したサービスレイヤー**: 28個のサービスクラス
4. **包括的なモデル定義**: 24個のデータモデル
5. **Supabase接続済み**: 認証・データベース接続確立

### 現在の課題
1. **データベーススキーマ不完全**: walks, pinsテーブルが未作成
2. **RPC関数不足**: 散歩履歴・ルート検索などの関数が未実装
3. **ナビゲーション未接続**: 実装済み画面へのリンクが切れている
4. **テストデータ不足**: アプリの動作確認に必要なデータが少ない
5. **地図タイル未表示**: APIキー設定の問題

### 推奨する優先順位
1. **最優先**: Phase 1（データベース完成） - これがないと他が動かない
2. **高優先**: Phase 2（UI/UX完成） - ユーザー体験の基礎
3. **必須**: Phase 3（コア機能実装） - アプリの核となる機能
4. **重要**: Phase 4-6（データ充実・テスト・準備）
5. **最終**: Phase 7-8（配信・リリース）

---

## 🎯 次のアクションアイテム

### 今すぐできること

1. **Thunderforest APIキー設定**（5分）
```bash
cd /home/user/webapp/wanmap_v2
nano .env
# THUNDERFOREST_API_KEY=8c3872c6b1d5471a0e8c88cc69ed4f
```

2. **データベーススキーマ設計開始**（1-2時間）
- walks テーブルの設計
- pins テーブルの設計
- 必要なインデックスの検討
- RPC関数の設計

3. **既存画面へのナビゲーション復活**（30分）
```dart
// profile_tab.dart の3箇所
// records_tab.dart の2箇所
// walk_history_screen.dart の2箇所
// 合計7箇所の修正
```

### 明日以降の計画

**Week 1**: Phase 1 完全完了
- Day 1-2: テーブル作成・マイグレーション
- Day 3: RPC関数実装
- Day 4: テストデータ投入

**Week 2**: Phase 2-3 開始
- Day 1-2: UI/UX修正
- Day 3-5: 散歩記録機能実装
- Day 6-7: ピン投稿機能実装

**Week 3**: Phase 3-4 完了
- Day 1-3: ソーシャル機能実装
- Day 4-5: バッジシステム実装
- Day 6-7: データ充実

**Week 4**: Phase 5-6 完了
- Day 1-3: テスト・デバッグ
- Day 4-5: リリース準備

**Week 5**: Phase 7-8 リリース
- Day 1-2: TestFlight配信
- Day 3-7: 審査・正式リリース

---

## 📝 メモ

### 実装済みだが未接続の機能
以下は**既にコードが存在**するが、ナビゲーションが切れているだけ:
- お気に入りルート一覧（favorites_screen.dart）
- フォロワー一覧（followers_screen.dart）
- フォロー中一覧（following_screen.dart）
- ユーザー検索（user_search_screen.dart）
- ルート検索（route_search_screen.dart）
- ルート詳細（route_detail_screen.dart）
- 統計ダッシュボード（statistics_dashboard_screen.dart）

→ これらは**Phase 2**で簡単に復活可能

### Supabaseマイグレーション自動化
`/home/user/supabase_automation/` に以下のスクリプトが存在:
- `run_migration.js` - SQLマイグレーション実行
- `create_test_accounts.js` - テストアカウント作成（完了済み）
- `execute_sql.js` - SQL実行ツール
- `test_connection.js` - 接続テスト（動作確認済み）

### 重要なGitコミット履歴
```
4d61d97 - Fix: ProfileTab NoSuchMethod error
b595c88 - Fix: Complete Riverpod migration
01fb150 - Complete 4-tab UI redesign
6f50800 - WanMapリニューアル Phase 2実装完了
7955650 - WanMapリニューアル Phase 1実装完了
```

---

**最終更新**: 2025-11-23  
**次回レビュー**: Phase 1完了時
