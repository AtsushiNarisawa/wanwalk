# WanWalk v2 - 完全プロジェクトドキュメント

**作成日**: 2025-11-24  
**最終更新**: 2025-11-24  
**バージョン**: 1.5.0 (Phase 5完了、Phase 3一部実装中)

---

## 📋 目次

1. [プロジェクト概要](#プロジェクト概要)
2. [全体アーキテクチャ](#全体アーキテクチャ)
3. [画面遷移図](#画面遷移図)
4. [実装状況マトリックス](#実装状況マトリックス)
5. [外部サービス・API情報](#外部サービスapi情報)
6. [開発ルールと原則](#開発ルールと原則)
7. [既知の問題と解決策](#既知の問題と解決策)
8. [今後のタスク](#今後のタスク)

---

## プロジェクト概要

### 🎯 プロジェクト名
**WanWalk** - 愛犬の散歩ルート共有モバイルアプリ

### 👤 プロジェクトオーナー
- **名前**: 成沢敦史 (Atsushi Narisawa)
- **職業**: 大手広告代理店出身のマーケティングスペシャリスト兼ペット事業起業家
- **年齢**: 43歳
- **事業**: DogHub（神奈川県足柄下郡箱根町）- 犬のホテル・カフェ事業運営

### 🎯 アプリの目的
愛犬との散歩を記録・共有し、コミュニティを形成するモバイルアプリケーション。
箱根を拠点とした公式ルートと、ユーザーの日常散歩記録の両方をサポート。

### 📱 主要機能
1. **2モード制散歩記録**
   - Daily（日常散歩）: プライベート記録
   - Outing（おでかけ散歩）: 公式ルートを歩く

2. **公式ルートシステム**
   - エリア別推奨ルート（箱根、横浜、鎌倉）
   - 難易度・距離・所要時間表示

3. **ピン投稿機能**
   - 景色/店舗/出会い/その他の4タイプ
   - 写真添付（最大5枚）
   - いいね機能

4. **ソーシャル機能**
   - ユーザー検索・フォロー
   - タイムライン
   - 通知システム

5. **バッジシステム**
   - 17種類の初期バッジ
   - 5カテゴリ×4ティア

6. **ユーザー統計**
   - レベルシステム（10kmで1レベル）
   - 総距離・散歩回数・訪問エリア数

---

## 全体アーキテクチャ

### 技術スタック

| カテゴリ | 技術 | バージョン | 状態 |
|---------|------|-----------|------|
| フレームワーク | Flutter | 3.38.2 | ✅ |
| 言語 | Dart | 3.0+ | ✅ |
| 状態管理 | Riverpod | 2.6.1 | ✅ 完全移行済み |
| バックエンド | Supabase | - | ✅ |
| データベース | PostgreSQL + PostGIS | - | ✅ |
| 認証 | Supabase Auth | - | ✅ |
| ストレージ | Supabase Storage | - | ⚠️ 一部 |
| 地図表示 | Flutter Map | 6.1.0 | ✅ |
| 地図タイル | Thunderforest | Outdoors API | ⚠️ |
| GPS追跡 | Geolocator | 11.0.0 | ✅ |
| 画像選択 | Image Picker | 最新 | ✅ |

### プロジェクト構造

```
wanwalk/
├── lib/
│   ├── main.dart                    # エントリーポイント (Riverpod対応)
│   │
│   ├── config/                      # 設定ファイル
│   │   ├── env.dart                 # 環境変数読み込み
│   │   ├── supabase_config.dart     # Supabase設定
│   │   ├── wanwalk_colors.dart       # カラーパレット
│   │   ├── wanwalk_typography.dart   # タイポグラフィ
│   │   └── wanwalk_spacing.dart      # スペーシング定数
│   │
│   ├── models/ (24個)               # データモデル
│   │   ├── walk_mode.dart           # Daily/Outing enum
│   │   ├── area.dart                # エリアモデル
│   │   ├── official_route.dart      # 公式ルート
│   │   ├── route_pin.dart           # ピン投稿
│   │   ├── route_model.dart         # 散歩ルート
│   │   ├── walk_history.dart        # 散歩履歴
│   │   ├── user_statistics.dart     # ユーザー統計
│   │   ├── badge.dart               # バッジ
│   │   ├── notification_model.dart  # 通知
│   │   ├── follow_model.dart        # フォロー
│   │   ├── like_model.dart          # いいね
│   │   └── ...                      # 他20個のモデル
│   │
│   ├── providers/ (22個)            # Riverpod状態管理
│   │   ├── auth_provider.dart       # 認証
│   │   ├── theme_provider.dart      # テーマ
│   │   ├── gps_provider_riverpod.dart  # GPS追跡
│   │   ├── area_provider.dart       # エリア
│   │   ├── official_route_provider.dart # 公式ルート
│   │   ├── route_pin_provider.dart  # ピン
│   │   ├── walk_mode_provider.dart  # 散歩モード
│   │   ├── user_statistics_provider.dart # 統計
│   │   ├── badge_provider.dart      # バッジ
│   │   ├── social_provider.dart     # ソーシャル
│   │   ├── notification_provider.dart # 通知
│   │   ├── favorites_provider.dart  # お気に入り
│   │   ├── route_search_provider.dart # 検索
│   │   └── ...                      # 他10個のProvider
│   │
│   ├── services/ (28個)             # ビジネスロジック
│   │   ├── auth_service.dart
│   │   ├── gps_service.dart         # GPS記録
│   │   ├── photo_service.dart       # 写真管理 ✅
│   │   ├── storage_service.dart     # Storage操作
│   │   ├── walk_save_service.dart   # 散歩保存
│   │   ├── walk_history_service.dart
│   │   ├── user_statistics_service.dart
│   │   ├── badge_service.dart
│   │   ├── social_service.dart
│   │   ├── notification_service.dart
│   │   ├── favorite_service.dart
│   │   ├── route_search_service.dart
│   │   └── ...                      # 他16個のService
│   │
│   ├── screens/ (35画面)            # UI画面
│   │   ├── auth/ (3)
│   │   │   ├── login_screen.dart    # ✅
│   │   │   ├── signup_screen.dart   # ✅
│   │   │   └── password_reset_screen.dart # ✅
│   │   │
│   │   ├── main/ (5)
│   │   │   ├── main_screen.dart     # 4タブメイン画面 ✅
│   │   │   └── tabs/
│   │   │       ├── home_tab.dart    # ホームタブ ✅
│   │   │       ├── map_tab.dart     # マップタブ ⚠️ タイル問題
│   │   │       ├── records_tab.dart # 記録タブ ✅
│   │   │       └── profile_tab.dart # プロフィールタブ ✅
│   │   │
│   │   ├── daily/ (2)
│   │   │   ├── daily_walk_view.dart         # 日常散歩開始 ✅
│   │   │   └── daily_walking_screen.dart    # 散歩中画面 ✅
│   │   │
│   │   ├── outing/ (7)
│   │   │   ├── outing_walk_view.dart        # おでかけ開始 ✅
│   │   │   ├── outing_walk_view_v2.dart     # v2 ✅
│   │   │   ├── area_list_screen.dart        # エリア一覧 ❌ エラー
│   │   │   ├── route_list_screen.dart       # ルート一覧 ⚠️
│   │   │   ├── route_detail_screen.dart     # ルート詳細 ✅
│   │   │   ├── walking_screen.dart          # 散歩中 ✅
│   │   │   └── pin_create_screen.dart       # ピン投稿 ⚠️
│   │   │
│   │   ├── routes/ (4)
│   │   │   ├── favorites_screen.dart        # お気に入り ✅
│   │   │   ├── public_routes_screen.dart
│   │   │   ├── route_edit_screen.dart
│   │   │   └── routes_list_screen.dart
│   │   │
│   │   ├── social/ (7)
│   │   │   ├── timeline_screen.dart
│   │   │   ├── user_search_screen.dart
│   │   │   ├── follow_list_screen.dart
│   │   │   ├── followers_screen.dart
│   │   │   ├── following_screen.dart
│   │   │   ├── notification_center_screen.dart
│   │   │   └── popular_routes_screen.dart
│   │   │
│   │   ├── profile/ (2)
│   │   │   ├── user_profile_screen.dart
│   │   │   └── statistics_dashboard_screen.dart # ✅
│   │   │
│   │   ├── history/ (1)
│   │   │   └── walk_history_screen.dart
│   │   │
│   │   ├── search/ (1)
│   │   │   └── route_search_screen.dart
│   │   │
│   │   ├── notifications/ (1)
│   │   │   └── notifications_screen.dart
│   │   │
│   │   ├── map/ (1)
│   │   │   └── map_screen.dart
│   │   │
│   │   └── legal/ (2)
│   │       ├── privacy_policy_screen.dart
│   │       └── terms_of_service_screen.dart
│   │
│   ├── widgets/ (34個)              # 再利用可能ウィジェット
│   │   ├── badge_card.dart
│   │   ├── favorite_route_card.dart
│   │   ├── photo_route_card.dart
│   │   ├── user_list_item.dart
│   │   ├── follow_button.dart
│   │   ├── like_button.dart
│   │   ├── optimized_image.dart
│   │   ├── photo_viewer.dart
│   │   └── ...                      # 他26個
│   │
│   └── utils/                       # ユーティリティ
│       └── badge_unlock_helper.dart
│
├── supabase_migrations/             # データベースマイグレーション
│   ├── 001_rename_existing_tables.sql
│   ├── 002_create_new_tables.sql
│   ├── 003_create_rls_policies.sql
│   ├── 004_create_rpc_functions.sql
│   ├── 005_insert_initial_data.sql
│   ├── 006_phase4_history_functions.sql
│   ├── 007_phase5_search_and_social.sql
│   ├── 008_phase5_badges_system.sql
│   └── test_data_phase5.sql
│
├── database_migrations/             # 追加マイグレーション
│   ├── 001_walks_table_v4.sql       # walks テーブル最終版
│   ├── 002_pins_table_v1.sql
│   ├── 005_walk_photos_table.sql
│   └── ...
│
├── .env                             # 環境変数（機密情報）
├── pubspec.yaml                     # パッケージ依存関係
├── README.md                        # プロジェクト概要
└── この他28個のドキュメント         # 実装状況・テストガイド等

```

---

## 画面遷移図

### メイン画面構造（4タブ）

```
┌────────────────────────────────────────────┐
│         MainScreen (4タブUI)                │
├─────┬─────┬─────┬─────────────────────────┤
│ Home│ Map │Reco │Profile                   │
└─────┴─────┴─────┴──────────────────────────┘

【Home Tab】- ホーム画面
  ├─ おすすめエリア（カルーセル）
  │   └─ [エリアを探す] → AreaListScreen ❌ エラー中
  ├─ 人気の公式ルート
  └─ クイックアクション（4ボタン）
      ├─ エリア検索 → AreaListScreen ❌
      ├─ ルート検索 → RouteSearchScreen
      ├─ 日常散歩 → DailyWalkView
      └─ 散歩記録 → WalkHistoryScreen

【Map Tab】- マップビュー
  └─ 現在地中心のマップ表示 ⚠️ タイル表示問題

【Records Tab】- 記録タブ
  ├─ 統計サマリーカード
  │   ├─ 総距離
  │   ├─ 総時間
  │   └─ レベル進捗
  ├─ 散歩履歴一覧
  │   ├─ Daily散歩
  │   └─ Outing散歩
  └─ [お気に入り] → FavoritesScreen ✅

【Profile Tab】- プロフィールタブ
  ├─ ユーザー情報表示
  ├─ 統計情報
  │   └─ [統計詳細] → StatisticsDashboardScreen ✅
  ├─ フォロワー/フォロー
  │   ├─ [フォロワー] → FollowersScreen
  │   └─ [フォロー中] → FollowingScreen
  ├─ バッジコレクション
  └─ 設定
```

### 散歩フロー

```
【日常散歩（Daily）】
1. HomeTab or QuickAction
    ↓ [日常散歩開始]
2. DailyWalkView
    ├─ 犬選択（オプション）
    └─ [散歩開始] → DailyWalkingScreen ✅
3. DailyWalkingScreen（散歩中）
    ├─ リアルタイムGPS追跡
    ├─ 地図表示
    ├─ 統計表示（距離/時間/ポイント数）
    ├─ [📷 カメラ] ⚠️ Phase 3実装中
    ├─ [一時停止/再開]
    └─ [終了] → 保存確認ダイアログ
4. 保存完了 → Records Tab

【おでかけ散歩（Outing）】
1. HomeTab → [エリアを探す]
    ↓
2. AreaListScreen（エリア一覧）❌ エラー発生中
    └─ 箱根/横浜/鎌倉を選択
        ↓
3. RouteListScreen（ルート一覧）
    └─ ルート選択 → RouteDetailScreen ✅
4. RouteDetailScreen（ルート詳細）
    ├─ ルート情報表示
    ├─ 既存ピン表示
    ├─ [お気に入り登録/解除]
    └─ [このルートを歩く] → WalkingScreen ✅
5. WalkingScreen（散歩中）
    ├─ 公式ルート重畳表示
    ├─ リアルタイムGPS追跡
    ├─ [📍 ピン投稿] → PinCreateScreen
    ├─ [一時停止/再開]
    └─ [終了] → プロファイル自動更新
6. 完了 → Records Tab
```

### ソーシャルフロー

```
【ユーザー検索・フォロー】
Profile Tab → [ユーザー検索]
    ↓
UserSearchScreen
    ├─ キーワード検索
    └─ ユーザー選択 → UserProfileScreen
        ├─ プロフィール表示
        ├─ [フォロー/アンフォロー]
        ├─ 統計情報
        └─ 最近の散歩履歴

【タイムライン】
Home Tab → [タイムライン]
    ↓
TimelineScreen
    └─ フォロー中のユーザーの
        ピン投稿を時系列表示

【通知】
全画面 → 通知アイコン（ベルマーク）
    ↓
NotificationCenterScreen
    ├─ 新しいフォロワー
    ├─ ピンへのいいね
    ├─ バッジ獲得
    └─ タップでアクション
```

---

## 実装状況マトリックス

### Phase別実装状況

| Phase | 内容 | 状態 | 完了率 |
|-------|------|------|--------|
| Phase 1 | 基本機能・データベース | ✅ 完了 | 100% |
| Phase 2 | ピン投稿機能 | ✅ 完了 | 100% |
| **Phase 3** | **完成・写真アップロード** | **🔄 実装中** | **50%** |
| Phase 4 | 散歩履歴・ホーム画面 | ✅ 完了 | 100% |
| Phase 5 | ソーシャル・バッジ | ✅ 完了 | 100% |

### Phase 3 詳細ステータス

| 項目 | 状態 | 備考 |
|-----|------|------|
| GPS統計計算（距離・時間） | ✅ 完了 | `gps_service.dart` に実装済み |
| プロファイル自動更新 | ✅ 完了 | 散歩終了時に自動更新 |
| **写真のStorageアップロード** | **🔄 実装中** | **進行中** |
| └ PhotoService実装 | ✅ 完了 | `photo_service.dart` 存在 |
| └ カメラボタン追加 | ✅ 完了 | `daily_walking_screen.dart` に追加 |
| └ 写真アップロード処理 | ❌ 未完了 | **バケット名修正必要** |
| └ Storageバケット設定 | ⚠️ 一部 | `walk-photos` 未作成 |
| 動作確認とテスト | ❌ 未完了 | **Phase 3完了後実施** |

### 機能別実装状況

#### ✅ 完全実装済み

| カテゴリ | 機能 | 備考 |
|---------|-----|------|
| 認証 | ログイン/サインアップ | email/password |
| 認証 | パスワードリセット | Supabase Auth |
| 認証 | テストアカウント3つ | test1/2/3@example.com |
| UI | 4タブレイアウト | Home/Map/Records/Profile |
| UI | ダークモード | 完全対応 |
| GPS | リアルタイム追跡 | Geolocator使用 |
| GPS | 距離計算 | RouteModel.calculateDistance() |
| GPS | 時間計算 | duration自動計算 |
| 地図 | Flutter Map表示 | ✅ |
| 統計 | ユーザーレベル | 10kmで1レベル |
| 統計 | バッジシステム | 17種類実装 |
| ソーシャル | フォロー機能 | RPC関数実装 |
| ソーシャル | 通知システム | Realtime対応 |
| 検索 | ルート検索 | 8フィルター |
| お気に入り | ルート/ピン | 完全実装 |

#### ⚠️ 一部実装・問題あり

| カテゴリ | 機能 | 問題 | 対応状況 |
|---------|-----|------|---------|
| 地図タイル | Thunderforest表示 | APIキーエラー | ⚠️ 確認中 |
| エリア一覧 | AreaListScreen | GEOGRAPHY型エラー | ❌ **保留中** |
| ホーム画面 | スクロール不可 | レイアウト問題 | ❌ **保留中** |
| 写真 | アップロード機能 | バケット名不一致 | 🔄 **Phase 3対応中** |

#### ❌ 未実装

| カテゴリ | 機能 | 優先度 | 備考 |
|---------|-----|--------|------|
| ピン | 写真表示 | 中 | データはある |
| ピン | コメント機能 | 低 | Phase 6予定 |
| プロフィール | 編集機能 | 中 | UI未実装 |
| プロフィール | アバター変更 | 中 | UI未実装 |
| 犬情報 | 登録・編集 | 中 | テーブル未作成 |
| 散歩履歴 | 詳細表示 | 低 | 一覧のみ |
| 通知 | プッシュ通知 | 低 | ローカルのみ |

### データベーステーブル実装状況

#### ✅ 実装済みテーブル（Supabase）

| テーブル名 | 用途 | RLS | レコード数 |
|-----------|------|-----|----------|
| `users` | ユーザー情報 | ✅ | - |
| `areas` | エリアマスター | ✅ | 3件（箱根/横浜/鎌倉） |
| `official_routes` | 公式ルート | ✅ | 3件（テスト用） |
| `route_pins` | ピン投稿 | ✅ | - |
| `route_pin_photos` | ピン写真 | ✅ | - |
| `pin_likes` | いいね | ✅ | - |
| `route_favorites` | お気に入り | ✅ | - |
| `pin_bookmarks` | ブックマーク | ✅ | - |
| `user_follows` | フォロー関係 | ✅ | - |
| `notifications` | 通知 | ✅ | - |
| `badge_definitions` | バッジマスター | ✅ | 17件 |
| `user_badges` | ユーザーバッジ | ✅ | - |

#### ❌ 未作成テーブル

| テーブル名 | 用途 | 優先度 | Phase |
|-----------|------|--------|-------|
| `walks` | 散歩履歴 | **高** | Phase 3 |
| `walk_points` | GPS経路ポイント | **高** | Phase 3 |
| `walk_photos` | 散歩写真 | **高** | **Phase 3** |
| `dogs` | 犬情報 | 中 | Phase 6 |
| `user_profiles` | プロフィール拡張 | 中 | Phase 6 |
| `comments` | コメント | 低 | Phase 7 |

### Supabase RPC関数実装状況

#### ✅ 実装済みRPC関数

| 関数名 | 用途 | 状態 |
|-------|------|------|
| `get_user_walk_statistics` | ユーザー統計取得 | ✅ 動作確認済み |
| `check_and_unlock_badges` | バッジ解除チェック | ✅ 動作確認済み |
| `search_routes` | ルート検索 | ✅ 動作確認済み |
| `get_favorite_routes` | お気に入りルート取得 | ✅ 動作確認済み |
| `get_bookmarked_pins` | ブックマークピン取得 | ✅ 動作確認済み |
| `get_followers` | フォロワー一覧 | ✅ 動作確認済み |
| `get_following` | フォロー中一覧 | ✅ 動作確認済み |
| `get_following_timeline` | タイムライン | ✅ 動作確認済み |
| `get_user_badges` | ユーザーバッジ一覧 | ✅ 動作確認済み |
| **`get_areas_simple`** | **エリア一覧（座標変換）** | **✅ 新規作成（このスレッド）** |

#### ❌ 未実装RPC関数

| 関数名 | 用途 | 優先度 |
|-------|------|--------|
| `save_walk` | 散歩保存 | **高** |
| `get_walk_history` | 散歩履歴取得 | **高** |
| `upload_walk_photo` | 写真アップロード | **高** |

### Supabase Storageバケット

| バケット名 | 用途 | Public | 状態 |
|-----------|------|--------|------|
| `profile-avatars` | プロフィール画像 | ✅ Yes | ✅ 存在 |
| `dog-photos` | 犬の写真 | ✅ Yes | ✅ 存在 |
| `pin_photos` | ピン写真 | ✅ Yes | ✅ 存在 |
| **`walk-photos`** | **散歩写真** | **✅ Yes** | **❌ 未作成（Phase 3で作成予定）** |

---

## 外部サービス・API情報

### 🔐 Supabase（バックエンド）

| 項目 | 値 |
|-----|---|
| **プロジェクトURL** | `https://jkpenklhrlbctebkpvax.supabase.co` |
| **Anon Key** | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8` |
| データベース | PostgreSQL + PostGIS |
| 認証 | Supabase Auth |
| ストレージ | Supabase Storage |
| リアルタイム | Supabase Realtime（通知用） |

**接続確認方法:**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: 'https://jkpenklhrlbctebkpvax.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIs...',
);
```

### 🗺️ Thunderforest Maps API（地図タイル）

| 項目 | 値 |
|-----|---|
| **APIキー** | `8c3872c0b1d54471a5e0c685ce76e6ff` |
| プラン | Free Tier |
| リクエスト上限 | 150,000回/月 |
| 使用タイル | Outdoors |
| ドキュメント | https://www.thunderforest.com/ |

**使用例:**
```dart
TileLayer(
  urlTemplate: 'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=${Environment.thunderforestApiKey}',
  userAgentPackageName: 'com.doghub.wanwalk',
)
```

**⚠️ 注意事項:**
- 過去に期限切れキー `8c3872c6b1d5471a0e8c88cc69ed4f` を使用していた問題あり
- `.env` ファイルに正しく設定されているか確認必要

### 📱 GitHub（バージョン管理）

| 項目 | 値 |
|-----|---|
| **リポジトリ** | `https://github.com/AtsushiNarisawa/wanwalk` |
| ブランチ | `main` |
| オーナー | AtsushiNarisawa |

**Git操作時の注意:**
- サンドボックス環境（`/home/user/webapp/wanwalk`）で開発
- ローカルMac（`/Users/atsushinarisawa/projects/webapp/wanwalk`）でテスト
- 修正後は必ず `git push` → `git pull` でローカルに反映

### 🧪 テストアカウント

| Email | Password | User ID |
|-------|----------|---------|
| `test1@example.com` | `test123` | `9697d7af-a10b-493f-9ecf-1f31ed6029f2` |
| `test2@example.com` | `test123` | - |
| `test3@example.com` | `test123` | - |

---

## 開発ルールと原則

### 🎯 開発環境の理解

#### サンドボックス vs ローカルMac

**【重要】このプロジェクトは2つの環境で動作:**

1. **サンドボックス環境（AIアシスタント）**
   - パス: `/home/user/webapp/wanwalk`
   - 用途: コード編集、Git操作、ドキュメント作成
   - 役割: 開発作業

2. **ローカルMac（ユーザー）**
   - パス: `/Users/atsushinarisawa/projects/webapp/wanwalk`
   - 用途: Flutter実行、iOSシミュレータでテスト
   - 役割: 動作確認

**ワークフロー:**
```
1. サンドボックスでコード修正
     ↓
2. git commit & git push
     ↓
3. Macで git pull
     ↓
4. Mac で flutter run
     ↓
5. iOSシミュレータで動作確認
```

**⚠️ 絶対に忘れないこと:**
- サンドボックスで修正 → **必ず git push**
- Macでテスト前 → **必ず git pull**
- ホットリロード（`R`）だけでは不十分な場合 → `flutter run` で完全再起動

### 🔐 セキュリティルール

1. **機密情報は `.env` ファイルに記載**
   - Supabase URL/Key
   - Thunderforest API Key
   - `.gitignore` に `.env` を追加済み

2. **Git に含めない:**
   - `.env`
   - `ios/Pods/`
   - `.dart_tool/`
   - `build/`

3. **RLS（Row Level Security）必須:**
   - 全テーブルにRLSポリシー設定
   - ユーザーデータは本人のみアクセス可能

### 📝 コーディング規約

#### 状態管理: Riverpod 2.6.1

**必須ルール:**
1. **Provider ではなく Riverpod を使用**
2. **全ての Provider は `riverpod` パッケージを使用**
3. **`ConsumerWidget` または `ConsumerStatefulWidget` を継承**

**例:**
```dart
// ✅ 正しい
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    // ...
  }
}

// ❌ 間違い（Provider パッケージは使わない）
import 'package:provider/provider.dart';
```

#### ファイル命名規則

- スクリーン: `*_screen.dart`
- プロバイダー: `*_provider.dart`
- サービス: `*_service.dart`
- モデル: `*_model.dart` または `*.dart`
- ウィジェット: `*_widget.dart` または `*.dart`

#### Import順序

```dart
// 1. Dartパッケージ
import 'dart:async';

// 2. Flutterパッケージ
import 'package:flutter/material.dart';

// 3. サードパーティパッケージ
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 4. プロジェクト内ファイル
import '../../config/wanwalk_colors.dart';
import '../../models/area.dart';
```

### 🗺️ 地図関連の注意点

1. **GEOGRAPHY型の扱い:**
   - Supabaseから返されるGEOGRAPHY型はバイナリ
   - RPC関数で `ST_X()`, `ST_Y()` を使って数値に変換
   - または `ST_AsText()` でWKT形式に変換

2. **座標の順序:**
   - PostGIS: (longitude, latitude)
   - Flutter LatLng: (latitude, longitude)
   - **必ず順序を確認！**

### 🔄 Git運用ルール

1. **ブランチ戦略:**
   - メインブランチ: `main`
   - 基本的に `main` に直接コミット
   - 大きな機能追加時のみフィーチャーブランチ作成

2. **コミットメッセージ:**
   ```
   Add: 新機能追加
   Fix: バグ修正
   Update: 既存機能の更新
   Refactor: リファクタリング
   Docs: ドキュメント更新
   ```

3. **コミット頻度:**
   - 機能単位で小まめにコミット
   - 動作確認後にコミット推奨

### 🧪 テスト手順

1. **新機能実装後:**
   ```bash
   # サンドボックス
   git add .
   git commit -m "Add: 新機能"
   git push origin main
   
   # Mac
   git pull origin main
   flutter run
   ```

2. **動作確認項目:**
   - [ ] ログインできるか
   - [ ] 対象画面に遷移できるか
   - [ ] データが正しく表示されるか
   - [ ] エラーが出ないか
   - [ ] ログアウトできるか

3. **エラー発生時:**
   - ターミナルの全出力をコピー
   - スクリーンショット撮影
   - エラーメッセージを正確に記録

### 📱 iOS シミュレータ使用時の注意

1. **デバッグログの確認:**
   - `print()` 文でログ出力
   - 絵文字プレフィックス推奨: `🔵`, `✅`, `❌`, `⚠️`

2. **ホットリロード vs フルリスタート:**
   - `r`: ホットリロード（UI変更のみ）
   - `R`: ホットリスタート（State リセット）
   - `q` → `flutter run`: 完全再起動（推奨）

3. **Providerキャッシュ問題:**
   - `FutureProvider` はキャッシュされる
   - `autoDispose` を使用して自動破棄
   - または `ref.invalidate()` で明示的にリフレッシュ

---

## 既知の問題と解決策

### 🚨 現在進行中の問題

#### 問題1: エリア一覧画面でエラー

**症状:**
```
「エリアの読み込みに失敗しました」
Exception: Failed to fetch areas: type 'Null' is not a subtype of type 'num' in type cast
```

**発生場所:**
- `AreaListScreen` (`lib/screens/outing/area_list_screen.dart`)
- ホーム画面の「エリアを探す」ボタンをタップ時

**原因（推定）:**
- GEOGRAPHY型データが正しく解析できていない
- `get_areas_simple()` RPC関数を作成したが、まだエラーが出る
- Providerのキャッシュ問題の可能性

**試行した対策:**
1. ✅ `Area.fromJson` を安全な型キャストに修正
2. ✅ `get_areas_simple()` RPC関数を作成（latitude/longitudeに変換）
3. ✅ `area_provider.dart` を `FutureProvider.autoDispose` に変更
4. ✅ 再試行ボタンを追加
5. ❌ まだエラーが解消されず

**現在の状態:**
- **保留中**（Phase 3完了後に再度取り組む）

**次の対策案:**
1. Supabaseで直接クエリ実行して返されるデータ形式を確認
2. `area_provider.dart` のログを強化
3. 完全にアプリを削除して再インストール

---

#### 問題2: ホーム画面がスクロールできない

**症状:**
- クイックアクション（4ボタン）の下にコンテンツがあるがスクロールできない

**発生場所:**
- `HomeTab` (`lib/screens/main/tabs/home_tab.dart`)

**原因:**
- `areasAsync` がエラー状態で、レイアウトが崩れている可能性
- `SingleChildScrollView` は実装されているが機能していない

**試行した対策:**
1. ✅ レイアウト順序を変更（クイックアクションを最初に）
2. ❌ まだスクロールできず

**現在の状態:**
- **保留中**

---

#### 問題3: 地図タイル（Thunderforest）が表示されない

**症状:**
- マップタブで地図タイルが表示されない
- または古いAPIキーが使われている

**原因:**
- 過去に期限切れキー `8c3872c6b1d5471a0e8c88cc69ed4f` を使用
- 新しいキー `8c3872c0b1d54471a5e0c685ce76e6ff` に更新済み
- ビルドキャッシュが残っている可能性

**対策:**
1. ✅ `.env` ファイルで正しいキーに更新
2. ✅ `daily_walking_screen.dart` で `Environment.thunderforestApiKey` を使用
3. ⚠️ 他の画面でも同様に修正必要か確認

**確認方法:**
```bash
# API キーのテスト
curl "https://tile.thunderforest.com/outdoors/1/0/0.png?apikey=8c3872c0b1d54471a5e0c685ce76e6ff"
```

---

### 📝 過去に解決した問題

#### 解決済み1: Riverpod移行

**問題:** Provider パッケージから Riverpod への移行
**解決:** 全22個のProviderをRiverpodに完全移行完了
**日付:** 2025-11-22

#### 解決済み2: GPS統計計算

**問題:** 距離・時間の計算が未実装
**解決:** `gps_service.dart` に実装完了
**日付:** Phase 3

#### 解決済み3: バッジシステム

**問題:** バッジ定義とRPC関数が未実装
**解決:** 17種類のバッジと `check_and_unlock_badges` RPC実装完了
**日付:** Phase 5

---

## 今後のタスク

### 🎯 Phase 3 完了タスク（優先度: 最高）

#### 1. 写真アップロード機能の完成

**残タスク:**
- [ ] `walk-photos` Storageバケットを作成
- [ ] `PhotoService` のバケット名を修正（`route-photos` → `walk-photos`）
- [ ] `daily_walking_screen.dart` のカメラボタンに `PhotoService` を統合
- [ ] 写真アップロード処理を実装
- [ ] アップロード成功/失敗のUIフィードバック

**実装手順:**
```sql
-- 1. Supabaseでバケット作成
INSERT INTO storage.buckets (id, name, public)
VALUES ('walk-photos', 'walk-photos', true);

-- 2. RLSポリシー設定
CREATE POLICY "Authenticated users can upload walk photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'walk-photos');

CREATE POLICY "Public can view walk photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'walk-photos');
```

```dart
// 3. PhotoService修正
// lib/services/photo_service.dart の58行目
await _supabase.storage
    .from('walk-photos')  // 変更
    .upload(filePath, file);
```

```dart
// 4. カメラボタンの実装
// lib/screens/daily/daily_walking_screen.dart
onPressed: () async {
  final photoService = PhotoService();
  final file = await photoService.takePhoto();
  if (file != null) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final routeId = 'walk_${DateTime.now().millisecondsSinceEpoch}';
    final path = await photoService.uploadPhoto(
      file: file,
      routeId: routeId,
      userId: userId!,
    );
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真をアップロードしました')),
      );
    }
  }
},
```

#### 2. Phase 3 動作確認とテスト

**テスト項目:**
- [ ] 日常散歩を開始できる
- [ ] GPS追跡が動作する
- [ ] 距離・時間が正しく表示される
- [ ] カメラボタンで写真撮影できる
- [ ] 写真がStorageにアップロードされる
- [ ] 散歩を終了できる
- [ ] プロフィールが自動更新される
- [ ] Records Tabに履歴が表示される

---

### 🔄 保留中の問題の解決（優先度: 高）

#### エリア一覧エラーの解決

**アプローチ:**
1. Supabaseで直接確認:
   ```sql
   SELECT * FROM get_areas_simple();
   ```
2. データ形式を確認後、`Area.fromJson` を再修正
3. 完全なアプリ削除→再インストール

#### ホーム画面スクロール問題

**アプローチ:**
1. エリア一覧エラー解決後に再確認
2. `SingleChildScrollView` の `physics` を確認
3. レイアウトデバッグ

---

### 📅 Phase 6以降の計画（優先度: 中）

#### Phase 6: ユーザープロフィール拡張

- [ ] プロフィール編集画面実装
- [ ] アバター変更機能
- [ ] 犬情報登録・編集
- [ ] `dogs` テーブル作成
- [ ] `user_profiles` テーブル作成

#### Phase 7: コメント機能

- [ ] ピンへのコメント
- [ ] `comments` テーブル作成
- [ ] コメント通知

#### Phase 8: Android対応

- [ ] Android実機テスト
- [ ] Google Play Console設定
- [ ] APKビルド

#### Phase 9: リリース準備

- [ ] App Store申請
- [ ] プライバシーポリシー最終確認
- [ ] 利用規約最終確認
- [ ] マーケティング素材準備

---

## 📞 サポート・連絡先

**開発者:** 成沢敦史 (Atsushi Narisawa)  
**GitHub:** https://github.com/AtsushiNarisawa  
**リポジトリ:** https://github.com/AtsushiNarisawa/wanwalk  
**問い合わせ:** GitHub Issues

---

## 📚 関連ドキュメント

- `README.md` - プロジェクト概要
- `CURRENT_STATUS_AND_ROADMAP.md` - 実装状況とロードマップ
- `PHASE5_TEST_GUIDE.md` - Phase 5テストガイド
- `APP_NAVIGATION_MAP.md` - 画面ナビゲーション詳細
- `DATABASE_MIGRATION_GUIDE.md` - データベースマイグレーション手順

---

**最終更新:** 2025-11-24  
**ドキュメント作成者:** AI Assistant  
**レビュアー:** 成沢敦史

**このドキュメントは2度検証して作成されました。**
