# WanWalk v2 📚 ドキュメント索引

このドキュメントは、WanWalk v2プロジェクトのすべての重要なドキュメントへのクイックアクセスを提供します。

---

## 🎯 プロジェクト概要と目的

### メインドキュメント
- **[📘 README.md](./README.md)** - プロジェクトの全体概要、セットアップ手順、基本情報
- **[📋 COMPLETE_PROJECT_DOCUMENTATION.md](./COMPLETE_PROJECT_DOCUMENTATION.md)** - 包括的なプロジェクトドキュメント（22,826文字）
  - プロジェクト概要
  - 画面遷移図
  - 実装状況マトリックス
  - 外部サービス情報
  - 開発ルールと原則
  - 既知の問題と解決策

### 現状把握
- **[📊 CURRENT_STATUS_AND_ROADMAP.md](./CURRENT_STATUS_AND_ROADMAP.md)** - 現在の実装状況とロードマップ
- **[✅ ACTUAL_IMPLEMENTATION_STATUS.md](./ACTUAL_IMPLEMENTATION_STATUS.md)** - 実際の実装状況詳細

---

## 🛠️ 技術スタック詳細

### 開発環境・セットアップ
- **[⚙️ LOCAL_SETUP_COMMANDS.md](./LOCAL_SETUP_COMMANDS.md)** - ローカル開発環境のセットアップコマンド集
- **[🚀 QUICKSTART.md](./QUICKSTART.md)** - クイックスタートガイド
- **[📝 SETUP_GUIDE_STEP_BY_STEP.md](./SETUP_GUIDE_STEP_BY_STEP.md)** - ステップバイステップのセットアップガイド

### ビルド・テスト
- **[🔨 BUILD_TEST_GUIDE.md](./BUILD_TEST_GUIDE.md)** - ビルドとテストのガイド
- **[✅ PRE_BUILD_CHECKLIST.md](./PRE_BUILD_CHECKLIST.md)** - ビルド前チェックリスト
- **[📱 SIMULATOR_TESTING_GUIDE.md](./SIMULATOR_TESTING_GUIDE.md)** - iOS Simulatorテストガイド
- **[🍎 XCODE_BUILD_READY.md](./XCODE_BUILD_READY.md)** - Xcodeビルド準備完了ドキュメント

### Provider移行（Riverpod）
- **[🔄 PROVIDER_MIGRATION_ANALYSIS.md](./PROVIDER_MIGRATION_ANALYSIS.md)** - Provider → Riverpod移行分析
- **[✅ PROVIDER_MIGRATION_COMPLETE.md](./PROVIDER_MIGRATION_COMPLETE.md)** - 移行完了レポート
- **[📋 MIGRATION_SUMMARY.md](./MIGRATION_SUMMARY.md)** - 移行サマリー

---

## 🗺️ 画面遷移図（ASCII形式）

### ナビゲーション構造
- **[🧭 APP_NAVIGATION_MAP.md](./APP_NAVIGATION_MAP.md)** - アプリのナビゲーションマップ
- **[📊 NAVIGATION_ANALYSIS_COMPLETE.md](./NAVIGATION_ANALYSIS_COMPLETE.md)** - ナビゲーション分析完了レポート
- **[🔧 NAVIGATION_ISSUES_AND_FIXES.md](./NAVIGATION_ISSUES_AND_FIXES.md)** - ナビゲーション問題と修正

### メイン画面構成
**[COMPLETE_PROJECT_DOCUMENTATION.md](./COMPLETE_PROJECT_DOCUMENTATION.md)** 内の「画面遷移図」セクションに詳細なASCII図があります：
- メインタブ構成（Home, Map, Records, Profile）
- 日常散歩フロー
- おでかけ散歩フロー
- ソーシャル機能フロー

---

## ✅ 実装状況マトリックス（Phase別・機能別）

### Phase別実装レポート
- **[📊 PHASE1_MVP_COMPLETION_REPORT.md](./PHASE1_MVP_COMPLETION_REPORT.md)** - Phase 1 MVP完了レポート
- **[📊 PHASE2_IMPLEMENTATION_REPORT.md](./PHASE2_IMPLEMENTATION_REPORT.md)** - Phase 2実装レポート
- **[✅ PHASE3_VERIFICATION_REPORT.md](./PHASE3_VERIFICATION_REPORT.md)** - Phase 3検証レポート
- **[📊 PHASE5_COMPLETE_REPORT.md](./PHASE5_COMPLETE_REPORT.md)** - Phase 5完了レポート
- **[📋 PHASE26_IMPLEMENTATION.md](./PHASE26_IMPLEMENTATION.md)** - Phase 2.6実装詳細
- **[📋 PHASE27_IMPLEMENTATION.md](./PHASE27_IMPLEMENTATION.md)** - Phase 2.7実装詳細

### 機能別実装状況
- **[📊 COMPREHENSIVE_IMPLEMENTATION_STATUS.md](./COMPREHENSIVE_IMPLEMENTATION_STATUS.md)** - 包括的実装状況
- **[📝 IMPLEMENTATION_PROGRESS.md](./IMPLEMENTATION_PROGRESS.md)** - 実装進捗レポート
- **[📋 FEATURE_VERIFICATION_REPORT.md](./FEATURE_VERIFICATION_REPORT.md)** - 機能検証レポート

### UI/UX実装
- **[🎨 UI_REDESIGN_COMPLETION_REPORT.md](./UI_REDESIGN_COMPLETION_REPORT.md)** - UI再設計完了レポート
- **[📱 APP_ICON_IMPLEMENTATION.md](./APP_ICON_IMPLEMENTATION.md)** - アプリアイコン実装
- **[💡 UI_UX_IMPROVEMENT_PROPOSAL.md](./UI_UX_IMPROVEMENT_PROPOSAL.md)** - UI/UX改善提案

---

## 🔗 外部サービス・API情報

### Supabase
**認証情報は [COMPLETE_PROJECT_DOCUMENTATION.md](./COMPLETE_PROJECT_DOCUMENTATION.md) の「外部サービス・API情報」セクションに記載**

関連ドキュメント：
- **[🗄️ DATABASE_MIGRATION_GUIDE.md](./DATABASE_MIGRATION_GUIDE.md)** - データベースマイグレーションガイド
- **[📦 CURRENT_STORAGE_IMPLEMENTATION.md](./CURRENT_STORAGE_IMPLEMENTATION.md)** - Supabase Storage実装状況
- **[🔍 check_supabase_schema.md](./check_supabase_schema.md)** - Supabaseスキーマチェック
- **[📂 supabase_migrations/README.md](./supabase_migrations/README.md)** - マイグレーションファイルREADME

### Thunderforest Maps API
**APIキーは [COMPLETE_PROJECT_DOCUMENTATION.md](./COMPLETE_PROJECT_DOCUMENTATION.md) に記載**
- 地図タイルプロバイダー
- Outdoors タイルセット使用

### GitHub
**リポジトリ情報は [COMPLETE_PROJECT_DOCUMENTATION.md](./COMPLETE_PROJECT_DOCUMENTATION.md) に記載**
- プライベートリポジトリ: `wanwalk`

---

## 📖 開発ルールと原則

### サンドボックスvsローカル運用
**[COMPLETE_PROJECT_DOCUMENTATION.md](./COMPLETE_PROJECT_DOCUMENTATION.md)** の「開発ルールと原則」セクションに詳細記載：
- サンドボックス: `/home/user/webapp/wanwalk` （コード編集）
- ローカルMac: `/Users/atsushinarisawa/projects/webapp/wanwalk` （実行・テスト）
- **重要**: サンドボックスで編集 → git push → Mac で git pull → 完全再起動

### Riverpod規約
- `StateNotifierProvider` の使用
- `ref.watch()` によるリアクティブなUI更新
- `autoDispose` によるメモリ管理

### Git運用
- ブランチ戦略: `main` （本番）
- コミットメッセージ規約
- プッシュ前の動作確認

### 地図関連注意点
- PostGIS座標順序: `(longitude, latitude)`
- Flutter座標順序: `(latitude, longitude)`
- GEOGRAPHY型のハンドリング

### テスト手順
- **[📋 TESTING_INDEX.md](./TESTING_INDEX.md)** - テスト関連ドキュメント索引
- **[🧪 QUICK_START_TESTING_GUIDE.md](./QUICK_START_TESTING_GUIDE.md)** - クイックスタートテストガイド
- **[📝 TESTING_PLAN.md](./TESTING_PLAN.md)** - テスト計画

---

## 🐛 既知の問題と詳細な試行履歴

### デバッグレポート
- **[🔍 DEBUG_REPORT.md](./DEBUG_REPORT.md)** - デバッグレポート
- **[✅ DEBUG_VERIFICATION_REPORT.md](./DEBUG_VERIFICATION_REPORT.md)** - デバッグ検証レポート
- **[📊 FINAL_DEBUG_REPORT.md](./FINAL_DEBUG_REPORT.md)** - 最終デバッグレポート
- **[📋 COMPREHENSIVE_DEBUG_CHECKLIST.md](./COMPREHENSIVE_DEBUG_CHECKLIST.md)** - 包括的デバッグチェックリスト

### 既知の問題（保留中）
**[COMPLETE_PROJECT_DOCUMENTATION.md](./COMPLETE_PROJECT_DOCUMENTATION.md)** の「既知の問題と解決策」セクションに詳細記載：

1. **エリア一覧読み込みエラー** ⚠️ 最大の問題
   - 症状: `type 'Null' is not a subtype of type 'num'`
   - 試行した解決策7つすべて失敗
   - 現在の状態: **保留**

2. **ホーム画面スクロール不可**
   - 症状: クイックアクション下のコンテンツがスクロールできない
   - 現在の状態: **保留**

3. **写真アップロードバケット名不一致**
   - 症状: `route-photos` バケットが存在しない
   - 対策: `walk-photos` バケット作成が必要
   - 現在の状態: **Phase 3実装中**

### クイック修正ガイド
- **[🚑 QUICK_FIXES_GUIDE.md](./QUICK_FIXES_GUIDE.md)** - クイック修正ガイド
- **[⚡ IMMEDIATE_ACTION_PLAN.md](./IMMEDIATE_ACTION_PLAN.md)** - 緊急アクションプラン

---

## 📅 今後のタスク

### Phase 3完了手順
**[COMPLETE_PROJECT_DOCUMENTATION.md](./COMPLETE_PROJECT_DOCUMENTATION.md)** の「今後のタスク」セクションに詳細記載：

1. **写真アップロード機能の完成**
   - [ ] `walk-photos` Storageバケット作成
   - [ ] `PhotoService`のバケット名修正
   - [ ] カメラボタンへの統合
   - [ ] テスト実施

2. **Phase 3動作確認**
   - [ ] 日常散歩フルフロー
   - [ ] プロフィール自動更新
   - [ ] Records Tab履歴表示

### Phase 6以降の計画
- **[📋 NEXT_STEPS.md](./NEXT_STEPS.md)** - 次のステップ
- **[🗺️ CURRENT_STATUS_AND_ROADMAP.md](./CURRENT_STATUS_AND_ROADMAP.md)** - ロードマップ

---

## 📦 テストデータとセットアップ

### テストデータ作成
- **[🐕 FINAL_TEST_DATA_ROMEO.md](./FINAL_TEST_DATA_ROMEO.md)** - Romeoテストデータ（最終版）
- **[📝 TEST_DATA_SETUP_GUIDE.md](./TEST_DATA_SETUP_GUIDE.md)** - テストデータセットアップガイド
- **[🗃️ QUICK_TEST_DATA_SETUP.md](./QUICK_TEST_DATA_SETUP.md)** - クイックテストデータセットアップ
- **[🇯🇵 Supabaseデータ投入手順.md](./Supabaseデータ投入手順.md)** - 日本語データ投入手順

### ステップバイステップガイド
- **[1️⃣ STEP1_MIGRATION_GUIDE.md](./STEP1_MIGRATION_GUIDE.md)** - Step 1: マイグレーション
- **[2️⃣ STEP2_CREATE_TEST_ACCOUNTS.md](./STEP2_CREATE_TEST_ACCOUNTS.md)** - Step 2: テストアカウント作成
- **[3️⃣ STEP3_INSERT_TEST_DATA.md](./STEP3_INSERT_TEST_DATA.md)** - Step 3: テストデータ挿入
- **[4️⃣ STEP4_TESTING_GUIDE.md](./STEP4_TESTING_GUIDE.md)** - Step 4: テストガイド

---

## 📊 進捗レポート・サマリー

### セッションサマリー
- **[📅 SESSION_SUMMARY_2025-11-23.md](./SESSION_SUMMARY_2025-11-23.md)** - 2025-11-23セッションサマリー
- **[📅 WORK_SUMMARY_2025-11-18.md](./WORK_SUMMARY_2025-11-18.md)** - 2025-11-18作業サマリー
- **[📅 WORK_SUMMARY_2025-11-17.md](./WORK_SUMMARY_2025-11-17.md)** - 2025-11-17作業サマリー

### 完了タスクレポート
- **[✅ COMPLETED_TASKS_2025-11-15.md](./COMPLETED_TASKS_2025-11-15.md)** - 2025-11-15完了タスク
- **[📊 FINAL_PROGRESS_2025-11-18.md](./FINAL_PROGRESS_2025-11-18.md)** - 2025-11-18最終進捗
- **[📋 AUTO_IMPLEMENTATION_SUMMARY_2025-11-22.md](./AUTO_IMPLEMENTATION_SUMMARY_2025-11-22.md)** - 2025-11-22自動実装サマリー

---

## 🚀 リリース準備

### Apple Developer Program
- **[🍎 APPLE_DEVELOPER_PROGRAM_PREP.md](./APPLE_DEVELOPER_PROGRAM_PREP.md)** - Apple Developer Program準備
- **[📋 RELEASE_PREPARATION.md](./RELEASE_PREPARATION.md)** - リリース準備ドキュメント
- **[✅ RELEASE_READINESS_REPORT.md](./RELEASE_READINESS_REPORT.md)** - リリース準備状況レポート

---

## 🔧 トラブルシューティング

### プラットフォーム固有の問題
- **[🖥️ MACOS_VS_IOS_FEATURE_CHECK.md](./MACOS_VS_IOS_FEATURE_CHECK.md)** - macOS vs iOS機能チェック
- **[🔨 XCODE_BUILD_FIX.md](./XCODE_BUILD_FIX.md)** - Xcodeビルド修正
- **[🇯🇵 ビルド手順_古いTOP問題解決.md](./ビルド手順_古いTOP問題解決.md)** - ビルド手順（日本語）

### Phase別バグ修正
- **[🐛 PHASE2_BUG_FIXES.md](./PHASE2_BUG_FIXES.md)** - Phase 2バグ修正

---

## 📚 その他の重要ドキュメント

### 実装ガイド
- **[📖 wanwalk_implementation_guide_v3.md](./wanwalk_implementation_guide_v3.md)** - WanWalk実装ガイド v3

### 提案書
- **[💡 PUBLIC_ROUTES_ENHANCEMENT_PROPOSAL.md](./PUBLIC_ROUTES_ENHANCEMENT_PROPOSAL.md)** - 公開ルート機能拡張提案

---

## 🎯 最重要ドキュメント（優先度順）

1. **[📘 COMPLETE_PROJECT_DOCUMENTATION.md](./COMPLETE_PROJECT_DOCUMENTATION.md)** - 最も包括的なドキュメント（必読）
2. **[📋 README.md](./README.md)** - プロジェクト概要
3. **[📊 CURRENT_STATUS_AND_ROADMAP.md](./CURRENT_STATUS_AND_ROADMAP.md)** - 現在の状況
4. **[🚀 QUICKSTART.md](./QUICKSTART.md)** - クイックスタート
5. **[🔨 BUILD_TEST_GUIDE.md](./BUILD_TEST_GUIDE.md)** - ビルド・テストガイド

---

**最終更新日**: 2025-11-24  
**プロジェクトバージョン**: v2 (Phase 3実装中)  
**作成者**: WanWalk v2 Development Team
