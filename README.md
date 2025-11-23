# WanMap - 愛犬の散歩ルート共有モバイルアプリ

<div align="center">
  <img src="assets/icon/app_icon.png" width="120" alt="WanMap Icon">
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.38.2-blue.svg)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
  [![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green.svg)](https://supabase.com)
  [![Riverpod](https://img.shields.io/badge/Riverpod-2.6.1-purple.svg)](https://riverpod.dev)
</div>

## 📱 プロジェクト概要

WanMapは、愛犬との散歩を記録・共有できるモバイルアプリケーションです。2025年1月にリニューアルを実施し、2モード制（Daily/Outing）と公式ルート・コミュニティ機能を導入しました。

### 🎯 主な機能

#### 1. **2モード制散歩記録**
- **Daily（日常の散歩）**: プライベート記録として保存
- **Outing（おでかけ散歩）**: 公式ルートを歩いてコミュニティに参加

#### 2. **公式ルートシステム**
- 管理者が登録した推奨ルート
- エリア別にルートを探索（箱根、横浜、鎌倉等）
- 難易度別（初級・中級・上級）
- 距離・所要時間表示

#### 3. **ピン投稿機能**
- 公式ルート上に体験・発見を投稿
- 4種類のピンタイプ（景色/店舗/出会い/その他）
- 写真添付（最大5枚）
- いいね機能

#### 4. **リアルタイムGPS追跡**
- 散歩中のリアルタイム位置追跡
- 経路記録と統計表示
- 一時停止/再開機能

#### 5. **ルート検索・フィルター（Phase 5-1）**
- テキスト検索による公式ルート検索
- 8種類のフィルター（難易度、距離、所要時間、エリア、特徴、ベストシーズン、評価、カテゴリ）
- 5つのソート順（人気順、距離昇順/降順、評価順、新着順）
- 無限スクロール（20件/ページ）
- お気に入り登録/解除

#### 6. **お気に入り・ブックマーク（Phase 5-2）**
- お気に入りルート一覧
- ブックマークピン一覧
- タブ切り替え（ルート/ピン）
- Pull-to-refresh

#### 7. **ユーザー統計（Phase 5-3）**
- ユーザーレベル表示（総距離ベース: 10kmで1レベル）
- 総距離、総散歩回数、訪問エリア数、作成ピン数
- レベル進捗バー
- 統計ダッシュボード
- バッジ統計サマリー

#### 8. **ソーシャル機能（Phase 5-4）**
- ユーザー検索
- フォロー/アンフォロー
- フォロワー/フォロー中一覧
- タイムライン（フォロー中のピン）
- リアルタイム通知（Supabase Realtime）
- 通知センター（スワイプ削除、一括既読）

#### 9. **バッジシステム（Phase 5-5）**
- 17種類の初期バッジ
- 5つのカテゴリ（距離、エリア、ピン、ソーシャル、特別）
- 4つのティア（ブロンズ、シルバー、ゴールド、プラチナ）
- バッジコレクション画面（カテゴリ別タブ）
- ロック/アンロック状態の視覚化
- 自動バッジ解除チェック（散歩完了時）
- バッジ獲得通知

## 🏗️ アーキテクチャ

### 技術スタック

| カテゴリ | 技術 | バージョン |
|---------|------|-----------|
| フレームワーク | Flutter | 3.38.2 |
| 言語 | Dart | 3.0+ |
| 状態管理 | Riverpod | 2.6.1 |
| バックエンド | Supabase | - |
| データベース | PostgreSQL + PostGIS | - |
| 地図 | Flutter Map | 6.1.0 |
| GPS | Geolocator | 11.0.0 |

### データベース構造

#### エリアとルート
```
areas (エリアマスタ)
  ├── id: UUID
  ├── name: TEXT (箱根、横浜等)
  ├── description: TEXT
  └── center_location: GEOGRAPHY(Point)

official_routes (公式ルート)
  ├── id: UUID
  ├── area_id: UUID → areas
  ├── name: TEXT
  ├── start_location: GEOGRAPHY(Point)
  ├── end_location: GEOGRAPHY(Point)
  ├── route_line: GEOGRAPHY(LineString)
  ├── distance_meters: FLOAT
  ├── estimated_minutes: INT
  ├── difficulty_level: TEXT (easy/moderate/hard)
  └── total_pins: INT
```

#### ユーザー投稿
```
route_pins (ルートピン)
  ├── id: UUID
  ├── route_id: UUID → official_routes
  ├── user_id: UUID → auth.users
  ├── location: GEOGRAPHY(Point)
  ├── pin_type: TEXT (scenery/shop/encounter/other)
  ├── title: TEXT
  ├── comment: TEXT
  └── likes_count: INT

route_pin_photos (ピン写真)
  ├── id: UUID
  ├── pin_id: UUID → route_pins
  ├── photo_url: TEXT
  └── sequence_number: INT

pin_likes (いいね)
  ├── id: UUID
  ├── pin_id: UUID → route_pins
  ├── user_id: UUID → auth.users
  └── created_at: TIMESTAMPTZ
```

#### プライベート記録
```
daily_walks (日常の散歩)
  ├── id: UUID
  ├── user_id: UUID → auth.users
  ├── walked_at: TIMESTAMPTZ
  ├── distance_meters: FLOAT
  ├── duration_seconds: INT
  └── title: TEXT

daily_walk_points (経路ポイント)
  ├── id: UUID
  ├── route_id: UUID → daily_walks
  ├── latitude: FLOAT
  ├── longitude: FLOAT
  ├── timestamp: TIMESTAMPTZ
  └── sequence_number: INT
```

#### Phase 5: ソーシャル・バッジ機能
```
route_favorites (ルートお気に入り)
  ├── id: UUID
  ├── user_id: UUID → auth.users
  ├── route_id: UUID → official_routes
  └── created_at: TIMESTAMPTZ

pin_bookmarks (ピンブックマーク)
  ├── id: UUID
  ├── user_id: UUID → auth.users
  ├── pin_id: UUID → route_pins
  └── created_at: TIMESTAMPTZ

user_follows (ユーザーフォロー)
  ├── id: UUID
  ├── follower_id: UUID → auth.users
  ├── following_id: UUID → auth.users
  └── created_at: TIMESTAMPTZ

notifications (通知)
  ├── id: UUID
  ├── user_id: UUID → auth.users
  ├── type: TEXT (new_follower/pin_liked/new_pin/badge_unlocked等)
  ├── title: TEXT
  ├── body: TEXT
  ├── related_user_id: UUID → auth.users (optional)
  ├── related_pin_id: UUID → route_pins (optional)
  ├── is_read: BOOLEAN
  └── created_at: TIMESTAMPTZ

badge_definitions (バッジ定義)
  ├── id: UUID
  ├── badge_code: TEXT (distance_10km等)
  ├── name_ja: TEXT
  ├── name_en: TEXT
  ├── description: TEXT
  ├── icon_name: TEXT
  ├── category: TEXT (distance/area/pins/social/special)
  ├── tier: TEXT (bronze/silver/gold/platinum)
  └── sort_order: INT

user_badges (ユーザーバッジ)
  ├── id: UUID
  ├── user_id: UUID → auth.users
  ├── badge_id: UUID → badge_definitions
  ├── unlocked_at: TIMESTAMPTZ
  └── is_new: BOOLEAN
```

## 📂 プロジェクト構造

```
lib/
├── config/                  # 設定ファイル
│   ├── supabase_config.dart
│   ├── wanmap_colors.dart
│   ├── wanmap_typography.dart
│   └── wanmap_spacing.dart
│
├── models/                  # データモデル
│   ├── walk_mode.dart       # Daily/Outing enum
│   ├── area.dart
│   ├── official_route.dart  # PostGIS対応
│   ├── route_pin.dart
│   ├── route_walk.dart
│   ├── user_walking_profile.dart
│   ├── route_search_params.dart  # Phase 5: 検索パラメータ
│   ├── user_profile.dart         # Phase 5: ユーザープロフィール
│   ├── user_statistics.dart      # Phase 5: ユーザー統計
│   ├── notification_model.dart   # Phase 5: 通知
│   ├── social_model.dart         # Phase 5: ソーシャル関連
│   └── badge.dart                # Phase 5: バッジ
│
├── providers/               # Riverpod状態管理
│   ├── walk_mode_provider.dart
│   ├── area_provider.dart
│   ├── official_route_provider.dart
│   ├── route_pin_provider.dart
│   ├── gps_provider_riverpod.dart
│   ├── route_search_provider.dart     # Phase 5: ルート検索
│   ├── favorites_provider.dart        # Phase 5: お気に入り
│   ├── social_provider.dart           # Phase 5: ソーシャル
│   ├── notification_provider.dart     # Phase 5: 通知
│   ├── badge_provider.dart            # Phase 5: バッジ
│   └── user_provider.dart             # Phase 5: ユーザー統計
│
├── screens/                 # 画面
│   ├── home/
│   │   └── home_screen.dart         # ホーム画面（モード切り替え）
│   ├── daily/
│   │   └── daily_walk_view.dart     # 日常の散歩画面
│   ├── outing/
│   │   ├── outing_walk_view.dart    # おでかけ散歩画面
│   │   ├── area_list_screen.dart    # エリア一覧
│   │   ├── route_list_screen.dart   # ルート一覧
│   │   ├── route_detail_screen.dart # ルート詳細
│   │   ├── walking_screen.dart      # 散歩中画面
│   │   └── pin_create_screen.dart   # ピン投稿画面
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── search/                           # Phase 5: 検索機能
│   │   └── route_search_screen.dart
│   ├── favorites/                        # Phase 5: お気に入り
│   │   └── saved_screen.dart
│   ├── profile/                          # Phase 5: プロフィール
│   │   ├── profile_screen.dart
│   │   ├── profile_edit_screen.dart
│   │   ├── user_profile_screen.dart
│   │   └── statistics_dashboard_screen.dart
│   ├── social/                           # Phase 5: ソーシャル
│   │   ├── user_search_screen.dart
│   │   └── notification_center_screen.dart
│   ├── notifications/                    # Phase 5: 通知
│   │   └── notifications_screen.dart
│   └── badges/                           # Phase 5: バッジ
│       └── badge_list_screen.dart
│
├── widgets/                 # 共通Widget
│   ├── walk_mode_switcher.dart
│   ├── search/                           # Phase 5: 検索関連
│   │   ├── route_filter_bottom_sheet.dart
│   │   └── search_route_card.dart
│   ├── favorites/                        # Phase 5: お気に入り関連
│   │   └── favorite_route_card.dart
│   ├── notifications/                    # Phase 5: 通知関連
│   │   └── notification_item.dart
│   └── badges/                           # Phase 5: バッジ関連
│       └── badge_card.dart
│
├── services/                # サービスクラス
│   ├── gps_service.dart
│   ├── notification_service.dart
│   ├── route_search_service.dart        # Phase 5: ルート検索
│   ├── favorites_service.dart           # Phase 5: お気に入り
│   ├── social_service.dart              # Phase 5: ソーシャル
│   ├── badge_service.dart               # Phase 5: バッジ
│   └── local_notification_service.dart  # Phase 5: ローカル通知
│
├── utils/                   # ユーティリティ
│   └── badge_unlock_helper.dart         # Phase 5: バッジ解除ヘルパー
│
└── main.dart               # エントリーポイント（Riverpod対応）
```

## 🚀 セットアップ

### 前提条件

- Flutter 3.38.2以上
- Xcode 26.1.1（iOS開発の場合）
- Supabaseプロジェクト
- PostGIS有効化済みのPostgreSQLデータベース

### 1. リポジトリクローン

```bash
git clone https://github.com/AtsushiNarisawa/wanmap_v2.git
cd wanmap_v2
```

### 2. 依存関係インストール

```bash
flutter pub get
```

### 3. 環境変数設定

`.env`ファイルを作成:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
THUNDERFOREST_API_KEY=your_thunderforest_api_key
```

### 4. Supabaseマイグレーション実行

Supabase管理画面のSQLエディタで以下のファイルを順次実行:

```bash
supabase_migrations/001_rename_existing_tables.sql
supabase_migrations/002_create_new_tables.sql
supabase_migrations/003_create_rls_policies.sql
supabase_migrations/004_create_rpc_functions.sql
supabase_migrations/005_insert_initial_data.sql
supabase_migrations/007_phase5_search_and_social.sql  # Phase 5
supabase_migrations/008_phase5_badges_system.sql      # Phase 5
```

**Phase 5テストデータ（オプション）:**
```bash
supabase_migrations/test_data_phase5.sql
```
⚠️ **注意**: テストデータスクリプトを実行する前に、実際のユーザーIDに置き換えてください（詳細は `PHASE5_TEST_GUIDE.md` を参照）

### 5. ビルドと実行

#### シミュレータ
```bash
flutter run
```

#### 実機（iOS）
```bash
# CocoaPods依存関係インストール
cd ios
pod install
cd ..

# ビルドと実行
flutter run --release
```

## 📊 実装状況

### ✅ Phase 1: 基本機能（完了）
- [x] データベース設計（PostGIS対応）
- [x] RLSポリシー設定
- [x] モデルクラス作成
- [x] Riverpod Provider作成
- [x] 2モード制UI実装
- [x] エリア・ルート画面実装
- [x] main.dart Riverpod対応

### ✅ Phase 2: ピン投稿機能（完了）
- [x] ピン作成画面
- [x] 写真選択機能（最大5枚）
- [x] 散歩中画面（GPS追跡）
- [x] マップ表示（公式ルート重畳）
- [x] 統計情報表示
- [x] 一時停止/再開機能
- [x] ルート詳細画面連携

### ⏳ Phase 3: 完成（TODO）
- [ ] 写真のStorageアップロード実装
- [ ] GPS統計計算実装（距離・時間）
- [ ] プロファイル自動更新
- [ ] 動作確認とテスト

### ✅ Phase 4: 散歩履歴・ホーム画面（完了）
- [x] 散歩履歴一覧画面
- [x] 散歩履歴詳細画面
- [x] ホーム画面統計カード
- [x] RLS ポリシー設定
- [x] データモデル整備

### ✅ Phase 5: ソーシャル・検索・バッジ（完了）
#### Phase 5-1: ルート検索・フィルター
- [x] テキスト検索実装
- [x] 8種類のフィルター（難易度、距離、時間、エリア、特徴、シーズン、評価、カテゴリ）
- [x] 5つのソート順（人気、距離↑↓、評価、新着）
- [x] 無限スクロール（20件/ページ、80%トリガー）
- [x] お気に入り登録/解除
- [x] Pull-to-refresh
- [x] RPC関数 `search_routes`

#### Phase 5-2: お気に入り・ブックマーク
- [x] お気に入りルート一覧
- [x] ブックマークピン一覧
- [x] タブ切り替え（ルート/ピン）
- [x] 無限スクロール
- [x] Pull-to-refresh
- [x] ログインプロンプト
- [x] RPC関数 `get_favorite_routes`, `get_bookmarked_pins`

#### Phase 5-3: ユーザー統計
- [x] ユーザー統計モデル（総距離、総散歩、エリア数、ピン数）
- [x] レベル計算（10kmごとに1レベル）
- [x] 経験値バー表示
- [x] 統計ダッシュボード画面
- [x] バッジ統計サマリー
- [x] RPC関数 `get_user_statistics`

#### Phase 5-4: ソーシャル機能
- [x] ユーザー検索
- [x] フォロー/アンフォロー
- [x] フォロワー/フォロー中一覧
- [x] ユーザープロフィール画面
- [x] タイムライン（フォロー中のピン）
- [x] リアルタイム通知（Supabase Realtime）
- [x] 通知センター（スワイプ削除、一括既読）
- [x] 通知タイプ別アイコン・アクション
- [x] RPC関数 `get_followers`, `get_following`, `get_following_timeline`

#### Phase 5-5: バッジシステム
- [x] バッジ定義マスタ（17種類の初期バッジ）
- [x] 5カテゴリ（距離、エリア、ピン、ソーシャル、特別）
- [x] 4ティア（ブロンズ、シルバー、ゴールド、プラチナ）
- [x] バッジコレクション画面（カテゴリ別タブ）
- [x] ロック/アンロック状態の視覚化
- [x] バッジカード（アイコン、ティアカラー、説明、獲得日時）
- [x] バッジ統計（獲得数、達成率、進捗バー）
- [x] 自動バッジ解除チェック（RPC関数）
- [x] 最近獲得したバッジ表示
- [x] RPC関数 `check_and_unlock_badges`, `get_user_badges`

### 📝 Phase 5ドキュメント
- `PHASE5_TEST_GUIDE.md`: Phase 5全機能のテストガイド
- `supabase_migrations/test_data_phase5.sql`: テストデータ生成スクリプト

## 🔐 セキュリティ

### Row Level Security (RLS)

すべてのテーブルにRLSポリシーが設定されています:

- **プライベート記録**: ユーザー本人のみアクセス可能
- **公式ルート・エリア**: 全ユーザー閲覧可能
- **ピン投稿**: 全ユーザー閲覧可能、編集は投稿者のみ
- **いいね**: 全ユーザー実行可能、削除は本人のみ

## 📱 対応プラットフォーム

- ✅ iOS 12.0以上
- ⏳ Android（実装予定）

## 🤝 貢献

プルリクエストを歓迎します！以下の手順でご協力ください:

1. フォーク
2. フィーチャーブランチ作成 (`git checkout -b feature/amazing-feature`)
3. コミット (`git commit -m 'Add amazing feature'`)
4. プッシュ (`git push origin feature/amazing-feature`)
5. プルリクエスト作成

## 📄 ライセンス

このプロジェクトは個人開発用です。

## 👨‍💻 開発者

**成沢敦史** (Atsushi Narisawa)
- マーケティングスペシャリスト兼ペット事業起業家
- DogHub（神奈川県足柄下郡箱根町）運営

## 📞 連絡先

問い合わせは GitHub Issues でお願いします。

---

**Last Updated**: 2025-11-22 (Phase 5完了)
**Version**: 1.5.0 (Phase 5: ソーシャル・検索・バッジ)  
**Git Commits**: 
- Phase 1: 7955650
- Phase 2: 6f50800
- Phase 4: 散歩履歴・ホーム画面
- Phase 5: ソーシャル・検索・バッジ機能

## 📚 関連ドキュメント

- [Phase 5 テストガイド](PHASE5_TEST_GUIDE.md) - Phase 5全機能のテスト手順書
- [マイグレーションガイド](supabase_migrations/) - データベースマイグレーションSQL
