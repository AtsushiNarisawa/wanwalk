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
│   └── user_walking_profile.dart
│
├── providers/               # Riverpod状態管理
│   ├── walk_mode_provider.dart
│   ├── area_provider.dart
│   ├── official_route_provider.dart
│   ├── route_pin_provider.dart
│   └── gps_provider_riverpod.dart
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
│   └── auth/
│       ├── login_screen.dart
│       └── signup_screen.dart
│
├── widgets/                 # 共通Widget
│   └── walk_mode_switcher.dart
│
├── services/                # サービスクラス
│   ├── gps_service.dart
│   └── notification_service.dart
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
```

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

**Last Updated**: 2025-01-22  
**Version**: 1.0.0 (リニューアル版)  
**Git Commits**: 
- Phase 1: 7955650
- Phase 2: 6f50800
