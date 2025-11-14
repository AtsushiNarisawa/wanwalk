# WanMap ローカルセットアップコマンド集

## 🚀 すぐに実行するコマンド

### 1. 最新コードを取得（GitHub から）

```bash
cd ~/path/to/wanmap_v2
git pull origin main
```

### 2. 依存関係を再インストール

```bash
flutter pub get
```

### 3. Isar のコード生成（必須）

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**注意**: エラーが出た場合は以下を試してください：

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. iOS シミュレータの起動と確認

```bash
# シミュレータ一覧を表示
xcrun simctl list devices

# または Flutter で確認
flutter devices
```

**期待される出力例:**
```
iPhone 15 Pro (simulator) • xxxx-xxxx-xxxx • ios • iOS 17.0
```

### 5. アプリの実行

#### シミュレータで実行する場合:

```bash
# iPhone 15 Pro シミュレータを起動
open -a Simulator

# アプリを実行
flutter run
```

または特定のデバイスを指定:

```bash
flutter run -d <device-id>
```

#### 実機で実行する場合:

1. iPhone を Mac に USB 接続
2. iPhone で「このコンピュータを信頼」を選択
3. 以下を実行:

```bash
flutter devices
# 接続された iPhone の device-id を確認

flutter run -d <your-iphone-device-id>
```

## 🔧 トラブルシューティング

### Error: build_runner が見つからない

**原因**: `pubspec.yaml` の形式エラー

**解決方法**:
```bash
# 最新の pubspec.yaml を取得
git pull origin main

# 依存関係を再インストール
flutter clean
flutter pub get
```

### Error: Isar のコード生成でエラー

**解決方法**:
```bash
# キャッシュをクリア
flutter pub run build_runner clean

# 再生成
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: シミュレータが見つからない

**解決方法**:
```bash
# Xcode を起動
open -a Xcode

# Xcode → Window → Devices and Simulators
# から iPhone 15 Pro シミュレータを追加
```

または:

```bash
# シミュレータを手動で起動
open -a Simulator

# その後 flutter run を実行
flutter run
```

### Error: CocoaPods エラー（iOS）

**解決方法**:
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter run
```

### Error: パッケージの依存関係エラー

**解決方法**:
```bash
# 完全クリーン
flutter clean
rm -rf pubspec.lock
rm -rf .dart_tool

# 再インストール
flutter pub get
```

## 📱 実機デバイスのセットアップ

### 1. Apple Developer アカウントで署名

Xcode でプロジェクトを開く:
```bash
open ios/Runner.xcworkspace
```

Xcode で:
1. Runner プロジェクトを選択
2. Signing & Capabilities タブ
3. Team を選択（Apple Developer アカウント）
4. Bundle Identifier を確認（com.doghub.wanmap）

### 2. 実機で実行

```bash
# iPhone を接続
flutter devices

# 実機で実行
flutter run -d <your-iphone-device-id>
```

## 🧪 ビルドとテスト

### Debug ビルド（開発用）

```bash
flutter run --debug
```

### Profile ビルド（パフォーマンステスト用）

```bash
flutter run --profile
```

### Release ビルド（本番用）

```bash
flutter build ios --release
```

## 📦 便利なコマンド

### パッケージの更新確認

```bash
flutter pub outdated
```

### コードの静的解析

```bash
flutter analyze
```

### テストの実行

```bash
flutter test
```

### ホットリロード（実行中）

アプリ実行中にターミナルで:
- `r` キー: ホットリロード
- `R` キー: ホットリスタート
- `q` キー: 終了

## 🎯 次のステップ

1. ✅ `flutter pub get` を実行
2. ✅ `flutter pub run build_runner build --delete-conflicting-outputs` を実行
3. ✅ シミュレータまたは実機でアプリを起動
4. 📝 TESTING_PLAN.md に従ってテストを開始
5. 🍎 APPLE_DEVELOPER_PROGRAM_PREP.md に従って申請準備

## 💡 開発のヒント

### VS Code を使用している場合

1. Flutter 拡張機能をインストール
2. `F5` でデバッグ開始
3. ホットリロードが自動で有効

### Android Studio を使用している場合

1. Flutter プラグインをインストール
2. Run ボタンでデバッグ開始
3. ツールバーにホットリロードボタン

## 📞 困った時は

問題が解決しない場合は、以下の情報を含めてお問い合わせください：

```bash
# Flutter のバージョン情報
flutter doctor -v

# エラーメッセージの全文
# 実行したコマンド
# 期待される動作と実際の動作
```

---

**現在の状態**: Phase 25-27 完了、ローカルセットアップ準備完了
**次のステップ**: 上記コマンドを順番に実行してアプリを起動
