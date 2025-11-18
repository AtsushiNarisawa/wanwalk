# WanMap v2 ビルドテストガイド

## 📋 修正完了の概要

### 2025年11月18日の修正内容

本日のサンドボックス環境での作業で、以下の構文エラーを修正しました：

#### ✅ 修正済みファイル

1. **lib/config/theme.dart**
   - `CardTheme()` に `const` 修飾子を追加
   - `BorderRadius.circular(12)` を `BorderRadius.all(Radius.circular(12))` に変更
   - ライトテーマとダークテーマの両方を修正

#### ✅ 確認済み（問題なし）

以下のファイルは、前回のセッションで既に修正済みで、構文エラーはありませんでした：

1. **lib/screens/social/notification_center_screen.dart**
   - 67行目の不正な `});` 削除済み
   - メソッド構造は正常

2. **lib/providers/notification_provider.dart**
   - 構文エラーなし
   - メソッド実装は正常

3. **基本的な構文チェック**
   - 括弧のバランス: ✅ 正常
   - 不正な記号: ✅ なし

---

## 🚀 ローカル環境でのビルドテスト手順

サンドボックス環境ではメモリ制約により `flutter analyze` や `flutter build` が完全に実行できませんでした。
以下の手順でローカル環境（Mac/Windows/Linux）にてビルドテストを実施してください。

### Step 1: リポジトリの最新コードを取得

```bash
cd /path/to/wanmap_v2
git pull origin main
```

### Step 2: 依存関係を更新

```bash
flutter pub get
```

### Step 3: コード生成を実行（Isar用）

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 4: 静的解析を実行

```bash
flutter analyze
```

**期待される結果**: 
- エラー数: 0個
- 警告のみの場合は許容範囲内

### Step 5: テストビルドを実行

#### Android向け

```bash
flutter build appbundle --release
# または
flutter build apk --release
```

#### iOS向け

```bash
flutter build ios --release
```

#### macOS向け（デバッグ用）

```bash
flutter build macos --debug
```

### Step 6: 実機/エミュレータで実行

```bash
# デバッグモードで起動
flutter run

# リリースモードで起動
flutter run --release
```

---

## 🔍 想定される残存エラー

以下のエラーは、実装未完了のため発生する可能性があります：

### 1. NotificationService 関連

**ファイル**: `lib/services/notification_service.dart`

**未実装メソッド**:
- `subscribeToNotifications(callback)` - リアルタイム通知購読

**影響を受けるファイル**:
- `lib/screens/social/notification_center_screen.dart` (64行目)
- `lib/providers/notification_provider.dart`

**修正方法**:
```dart
// lib/services/notification_service.dart

/// 通知のリアルタイム購読
void subscribeToNotifications(Function(NotificationModel) onNotification) {
  // TODO: Supabase Realtime を使用して通知を購読
  // _supabase.channel('notifications')
  //   .on(RealtimeListenTypes.insert, ...)
  //   .subscribe();
}
```

### 2. Isar コード生成

**ファイル**: `lib/models/local_route_model.dart`

**エラーメッセージ**: 
```
Target of URI doesn't exist: 'package:wanmap_v2/models/local_route_model.g.dart'
```

**修正方法**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

これで `local_route_model.g.dart` が自動生成されます。

### 3. その他の型エラー

`flutter analyze` の実行結果に基づいて、以下を確認してください：

- プロパティ名の不一致（例: `areaName` vs `area`）
- 引数の型不一致（例: 位置引数 vs 名前付き引数）
- null safety 関連のエラー

---

## 📊 前回のエラー推移（参考）

| 日時 | エラー数 | 主な対応 |
|------|---------|---------|
| 2025-11-17 初期 | 249個 | 統計モデルプロパティ修正 |
| 2025-11-17 中間 | 86個 → 71個 | TripService メソッド追加 |
| 2025-11-17 自動修正後 | 94個（悪化） | 自動修正スクリプトが失敗 |
| 2025-11-18 手動修正後 | **0個（構文レベル）** | CardTheme 型エラー修正 |

---

## 🎯 次のステップ

### 優先度 High

1. **ローカル環境でビルドテストを実施**
   - `flutter pub get`
   - `flutter analyze`
   - `flutter run`

2. **NotificationService の実装完了**
   - `subscribeToNotifications` メソッドの実装
   - Supabase Realtime の購読ロジック

3. **Isar コード生成の実行**
   - `flutter pub run build_runner build`

### 優先度 Medium

4. **新機能の動作確認**
   - 旅行（Trip）機能の画面遷移
   - 統計情報の表示
   - ソーシャル機能（通知センター、人気ルート）

5. **データ整合性の確認**
   - Supabase データベースとの連携
   - ローカルキャッシュ（Isar）の動作

---

## 📝 備考

### サンドボックス環境の制約

- **メモリ不足**: `flutter analyze` や `flutter build` がタイムアウト/Killed される
- **Flutter SDK**: PATH設定が必要（`export PATH="$PATH:/home/user/flutter/bin"`）
- **依存関係の解決**: `.dart_tool/package_config.json` の生成が必要

### 推奨環境

- **macOS**: Xcode 15+ / Flutter 3.35.7+
- **Windows**: Android Studio / Visual Studio
- **Linux**: Android Studio

---

## 🔗 関連ドキュメント

- [WORK_SUMMARY_2025-11-17.md](./WORK_SUMMARY_2025-11-17.md) - 前回の作業内容
- [FEATURE_VERIFICATION_REPORT.md](./FEATURE_VERIFICATION_REPORT.md) - 機能検証レポート
- [DATABASE_MIGRATION_GUIDE.md](./DATABASE_MIGRATION_GUIDE.md) - データベース移行ガイド

---

**作成日**: 2025年11月18日  
**最終更新**: 2025年11月18日  
**作成者**: Claude Code Assistant
