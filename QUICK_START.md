# 🚀 WanMap クイックスタートガイド

## ✅ 今すぐ実行するコマンド（順番通りに）

### ステップ 1: 最新コードを取得

```bash
cd ~/Documents/wanmap_v2  # または実際のプロジェクトパス
git pull origin main
```

### ステップ 2: 依存関係をインストール

```bash
flutter pub get
```

**期待される結果**: "Got dependencies!" と表示される

### ステップ 3: Isar のコード生成

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**期待される結果**: "Succeeded after ..." と表示される

**もしエラーが出たら**:
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### ステップ 4: シミュレータを起動

```bash
open -a Simulator
```

Xcode のシミュレータアプリが起動します。

### ステップ 5: アプリを実行

```bash
flutter run
```

**期待される結果**: 
- アプリがシミュレータにインストールされる
- WanMap のスプラッシュ画面が表示される
- ログイン/サインアップ画面が表示される

## 🎯 成功の確認ポイント

✅ シミュレータで WanMap アプリが起動した
✅ ログイン画面が表示されている
✅ エラーメッセージが表示されていない

## ❌ よくあるエラーと解決方法

### Error 1: "No devices found"

**問題**: シミュレータが起動していない

**解決方法**:
```bash
open -a Simulator
# シミュレータが起動したら再度実行
flutter run
```

### Error 2: "build_runner not found"

**問題**: pubspec.yaml の更新が反映されていない

**解決方法**:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error 3: "Isar schema not found"

**問題**: Isar のコード生成がまだ実行されていない

**解決方法**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error 4: CocoaPods エラー

**問題**: iOS の依存関係の問題

**解決方法**:
```bash
cd ios
pod install
cd ..
flutter run
```

## 🧪 動作確認テスト（アプリ起動後）

1. **サインアップ画面の確認**
   - [ ] メールアドレス入力フィールドがある
   - [ ] パスワード入力フィールドがある
   - [ ] サインアップボタンがある

2. **テストアカウントでログイン**（後で実施）
   - [ ] メールアドレスを入力
   - [ ] パスワードを入力
   - [ ] ログインボタンをタップ
   - [ ] ホーム画面に遷移

## 📝 次のステップ

### ✅ アプリが起動したら

1. **TESTING_PLAN.md を開く**
   ```bash
   open TESTING_PLAN.md
   ```

2. **Phase 25-27 の手動統合を実施**
   - PHASE26_IMPLEMENTATION.md を確認
   - PHASE27_IMPLEMENTATION.md を確認

3. **実機でテスト**
   - iPhone を Mac に接続
   - `flutter run` を実行

### ❌ アプリが起動しない場合

1. **エラーメッセージを確認**
   - ターミナルの最後の10-20行をコピー

2. **診断情報を取得**
   ```bash
   flutter doctor -v
   ```

3. **完全クリーンを試す**
   ```bash
   flutter clean
   rm -rf ios/Pods
   rm ios/Podfile.lock
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

## 💡 開発環境の推奨設定

### VS Code（推奨）

1. 拡張機能をインストール:
   - Flutter
   - Dart

2. `F5` キーでデバッグ開始

### Android Studio

1. プラグインをインストール:
   - Flutter
   - Dart

2. Run ボタンでデバッグ開始

## 📞 サポートが必要な場合

以下の情報を提供してください:

```bash
# Flutter 環境情報
flutter doctor -v

# デバイス情報
flutter devices

# エラーメッセージ（全文）
```

---

## 🎊 準備完了！

上記のステップを完了したら、**TESTING_PLAN.md** に従って本格的なテストを開始してください！

アプリの起動に成功したら、次は実際に散歩を記録してみましょう！🐕
