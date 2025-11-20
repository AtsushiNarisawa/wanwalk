# WanMap シミュレーターテストガイド

**作成日**: 2025-11-20  
**対象**: iOS Simulator / Android Emulator

---

## 🖥️ 開発環境の準備

### macOS（iOS + Android）

#### 1. Flutter SDKのインストール確認
```bash
# Flutterのバージョン確認
flutter --version

# Flutter Doctorで環境チェック
flutter doctor -v
```

**必要な出力:**
```
✓ Flutter (Channel stable, 3.x.x)
✓ Xcode - develop for iOS and macOS
✓ Android Studio - develop for Android
```

---

### iOS Simulator セットアップ（macOS専用）

#### 2. Xcodeのインストール
```bash
# Xcodeがインストールされているか確認
xcode-select -p

# 出力例: /Applications/Xcode.app/Contents/Developer
```

**インストールされていない場合:**
1. App Storeから「Xcode」をインストール（約12GB）
2. 初回起動後、追加コンポーネントのインストールを許可

#### 3. iOS Simulatorの起動
```bash
# 利用可能なシミュレーターを確認
xcrun simctl list devices

# シミュレーターを起動（例: iPhone 15 Pro）
open -a Simulator
```

**または、Xcodeから起動:**
```
Xcode → Window → Devices and Simulators → Simulators
→ 任意のデバイスを右クリック → Boot
```

**推奨シミュレーター:**
- iPhone 15 Pro (iOS 17.x)
- iPhone 14 Pro (iOS 16.x)
- iPhone SE (第3世代) - 小画面テスト用

---

### Android Emulator セットアップ（macOS/Windows/Linux）

#### 4. Android Studioのインストール
```bash
# Android Studioがインストールされているか確認
ls -la ~/Library/Android/sdk  # macOS
ls -la %LOCALAPPDATA%\Android\Sdk  # Windows
```

**インストールされていない場合:**
1. [Android Studio](https://developer.android.com/studio)をダウンロード
2. インストール時に「Android Virtual Device (AVD)」を選択

#### 5. Android Emulatorの作成
```bash
# Android Studioを起動
open -a "Android Studio"  # macOS
```

**AVD Managerで作成:**
```
Android Studio → Tools → AVD Manager → Create Virtual Device
↓
1. デバイスを選択: Pixel 7 Pro
2. システムイメージを選択: Android 13 (API 33) または Android 14 (API 34)
3. AVD名を設定: Pixel_7_Pro_API_33
4. Finish
```

**推奨エミュレーター:**
- Pixel 7 Pro (API 33/34)
- Pixel 5 (API 30) - 旧バージョンテスト用

---

## 🚀 WanMapアプリの起動

### ステップ1: プロジェクトディレクトリに移動

```bash
# ローカルマシンのプロジェクトパスに移動
cd /path/to/wanmap_v2

# 例（macOS）:
cd ~/Projects/wanmap_v2

# 例（Windows）:
cd C:\Users\YourName\Projects\wanmap_v2
```

---

### ステップ2: 依存関係のインストール

```bash
# Flutterパッケージを取得
flutter pub get

# 出力例:
# Resolving dependencies...
# Got dependencies!
```

**エラーが出た場合:**
```bash
# キャッシュをクリア
flutter clean
flutter pub get
```

---

### ステップ3: デバイス/シミュレーターの確認

```bash
# 接続されているデバイスを確認
flutter devices

# 出力例:
# iPhone 15 Pro (mobile) • 2D4F8F9A-... • ios • iOS 17.0 (simulator)
# Pixel 7 Pro (mobile)   • emulator-5554 • android • Android 13 (API 33) (emulator)
```

**デバイスが表示されない場合:**

**iOS:**
```bash
# Simulatorを起動
open -a Simulator
```

**Android:**
```bash
# エミュレーターを起動
~/Library/Android/sdk/emulator/emulator -avd Pixel_7_Pro_API_33  # macOS
%LOCALAPPDATA%\Android\Sdk\emulator\emulator -avd Pixel_7_Pro_API_33  # Windows
```

---

### ステップ4: アプリの起動

#### iOS Simulatorで起動
```bash
# デバイスIDを指定して起動
flutter run -d "iPhone 15 Pro"

# または、デバイスIDで指定
flutter run -d 2D4F8F9A-1234-5678-90AB-CDEF12345678
```

#### Android Emulatorで起動
```bash
# エミュレーターで起動
flutter run -d emulator-5554

# または、デバイス名で指定
flutter run -d "Pixel 7 Pro"
```

#### 複数デバイスがある場合
```bash
# 対話的に選択
flutter run

# 表示例:
# Multiple devices found:
# [1]: iPhone 15 Pro (mobile)
# [2]: Pixel 7 Pro (mobile)
# Please choose one (or "q" to quit): 1
```

---

### ステップ5: ホットリロード（開発中）

アプリが起動したら、コードを編集して即座に反映できます。

```bash
# ホットリロード（状態を保持）
r

# ホットリスタート（状態をリセット）
R

# アプリ終了
q
```

**ホットリロードの例:**
```dart
// lib/screens/map/map_screen.dartを編集
const SnackBar(
  content: Text('記録を一時停止しました'),  // ← テキスト変更
  backgroundColor: Colors.orange,
)

// ターミナルで「r」キーを押す
→ 即座にUIが更新される
```

---

## 🧪 Phase 2機能のテスト手順

### テスト1: GPS記録の一時停止/再開

**準備:**
- シミュレーターでは実際のGPSデータが取れないため、**モックデータ**を使用します

**iOS Simulatorの位置情報設定:**
```
Simulator → Features → Location → Custom Location...
→ Latitude: 35.6762, Longitude: 139.6503 (東京)
→ OK
```

または、GPXファイルで移動をシミュレート:
```
Simulator → Features → Location → Apple (定義済みの移動ルート)
```

**Android Emulatorの位置情報設定:**
```
Emulator → Extended Controls (...ボタン) → Location
→ Latitude: 35.6762, Longitude: 139.6503
→ Send
```

**テスト手順:**
```
1. アプリ起動 → ログイン
2. マップ画面で「お散歩を開始」ボタンをタップ
3. ✅ 記録開始のSnackBarが表示される
4. 「一時停止」ボタンをタップ
5. ✅ ボタンが「再開」に変わる
6. ✅ オレンジのSnackBarが表示される
7. 10秒待機
8. 「再開」ボタンをタップ
9. ✅ ボタンが「一時停止」に戻る
10. ✅ 緑のSnackBarが表示される
11. 「お散歩を終了」ボタンをタップ
12. タイトル入力して「保存」
13. ✅ ルートが保存される
```

**確認ポイント:**
- [ ] 一時停止中はGPSポイントが記録されない
- [ ] ボタンが正しく切り替わる
- [ ] 再開後にGPS記録が再開する
- [ ] 2回目の記録開始時に状態がリセットされる

---

### テスト2: 写真フルスクリーン表示

**注意:** シミュレーターではカメラが使えないため、**既存の写真付きルート**でテストします。

**テスト準備:**
1. 事前にSupabaseに写真付きルートを登録しておく
2. または、実機で写真を撮影したルートをSupabaseに保存

**テスト手順:**
```
1. ホーム画面 → 「公開ルート」タブ
2. 写真付きルートをタップ
3. ルート詳細画面で写真セクションまでスクロール
4. 写真サムネイルをタップ
5. ✅ フルスクリーン表示が開く
6. ✅ 写真カウンター「1 / 3」が表示される
7. ピンチズーム操作
8. ✅ 拡大・縮小が動作する（0.5x〜4.0x）
9. 左右スワイプ
10. ✅ 次の写真に切り替わる
11. ✅ カウンターが「2 / 3」に更新される
12. 戻るボタン（<）をタップ
13. ✅ ルート詳細画面に戻る
```

**確認ポイント:**
- [ ] 写真が正しく表示される
- [ ] ピンチズームが動作する
- [ ] スワイプでページ切り替えできる
- [ ] カウンターが正しく更新される

---

### テスト3: いいね数表示

**テスト手順:**
```
1. ホーム画面 → 「公開ルート」タブ
2. ルートカードを確認
3. ✅ ハートアイコン♥と数字が表示される
4. ルート詳細を開く
5. いいねボタンをタップ
6. ✅ いいね数が増える
7. 戻るボタンで一覧に戻る
8. ✅ カードのいいね数が更新されている
```

**確認ポイント:**
- [ ] カードにいいね数が表示される
- [ ] いいね後にカウントが増える
- [ ] 一覧に戻ってもカウントが保持される

---

## 🔧 トラブルシューティング

### 問題1: シミュレーターが起動しない

**iOS Simulator:**
```bash
# Simulatorプロセスを強制終了
killall Simulator

# Xcodeのデバイスキャッシュをリセット
xcrun simctl erase all

# Xcodeを再起動
```

**Android Emulator:**
```bash
# エミュレーターを終了
adb emu kill

# AVDをコールドブートで起動
~/Library/Android/sdk/emulator/emulator -avd Pixel_7_Pro_API_33 -no-snapshot-load
```

---

### 問題2: `flutter run`が失敗する

**エラー例: "No devices found"**
```bash
# デバイスリストを確認
flutter devices

# 何も表示されない場合はシミュレーターを起動
open -a Simulator  # iOS
```

**エラー例: "Xcode not found"**
```bash
# Xcodeのパスを設定
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# ライセンスに同意
sudo xcodebuild -license accept
```

**エラー例: "Android SDK not found"**
```bash
# Android SDKのパスを設定（.zshrcまたは.bashrcに追加）
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# 設定を反映
source ~/.zshrc  # または source ~/.bashrc
```

---

### 問題3: GPS位置情報が取得できない

**iOS Simulator:**
```bash
# シミュレーターの位置情報をリセット
Settings app → Privacy & Security → Location Services → Reset Location & Privacy
```

または、GPXファイルを使用:
```xml
<!-- tokyo_walk.gpx -->
<?xml version="1.0"?>
<gpx version="1.1">
  <trk>
    <trkseg>
      <trkpt lat="35.6762" lon="139.6503"><time>2024-01-01T00:00:00Z</time></trkpt>
      <trkpt lat="35.6765" lon="139.6510"><time>2024-01-01T00:01:00Z</time></trkpt>
      <trkpt lat="35.6770" lon="139.6520"><time>2024-01-01T00:02:00Z</time></trkpt>
    </trkseg>
  </trk>
</gpx>
```

```
Simulator → Features → Location → GPX File... → tokyo_walk.gpx
```

**Android Emulator:**
```
Extended Controls → Location → Routes → Load GPX/KML → 再生
```

---

### 問題4: 写真撮影ができない（シミュレーター）

シミュレーターではカメラハードウェアがないため、以下の方法で回避:

**方法1: 実機でテスト**
```bash
# iPhoneを接続してテスト
flutter run -d "Your iPhone Name"
```

**方法2: テスト用写真を事前アップロード**
```dart
// Supabaseコンソールでテスト用写真を手動アップロード
// または、Webブラウザから写真を追加
```

**方法3: モック実装（開発用）**
```dart
// lib/services/photo_service.dart
Future<File?> takePhoto() async {
  if (Platform.isIOS && !kIsWeb) {
    // Simulatorの場合はデフォルト画像を返す
    return File('assets/images/test_photo.jpg');
  }
  // ... 通常の実装
}
```

---

## 📊 シミュレーターの制限事項

### iOS Simulator
- ❌ カメラ（写真撮影不可）
- ❌ 加速度センサー
- ❌ ジャイロスコープ
- ⚠️ GPS（手動設定またはGPXファイル）
- ✅ ネットワーク通信
- ✅ タッチ操作
- ✅ ダークモード

### Android Emulator
- ❌ カメラ（一部エミュレートされるが品質低い）
- ⚠️ GPS（手動設定またはGPXファイル）
- ⚠️ Bluetooth（一部のみ）
- ✅ ネットワーク通信
- ✅ タッチ操作
- ✅ ダークモード

**推奨:** GPS記録と写真撮影のフルテストは**実機**で行ってください。

---

## ⚡ 効率的なテストワークフロー

### デバッグモードでの起動
```bash
# デバッグモードで起動（ホットリロード有効）
flutter run --debug

# プロファイルモード（パフォーマンステスト用）
flutter run --profile

# リリースモード（最終確認用）
flutter run --release
```

### ログの確認
```bash
# Flutter DevToolsを起動
flutter pub global activate devtools
flutter pub global run devtools

# ブラウザで http://localhost:9100 が開く
```

### 複数デバイスで同時テスト
```bash
# ターミナル1: iOS
flutter run -d "iPhone 15 Pro"

# ターミナル2: Android
flutter run -d emulator-5554
```

---

## 📝 テストチェックリスト

実機テスト前にシミュレーターで確認すべき項目:

### Phase 2機能
- [ ] GPS記録の開始/停止が動作する
- [ ] 一時停止ボタンが「一時停止」⇔「再開」切り替わる
- [ ] 一時停止中はポイントが記録されない
- [ ] 2回目の記録開始時に状態がリセットされる
- [ ] 写真フルスクリーン表示が開く
- [ ] ピンチズームが動作する
- [ ] スワイプでページ切り替えできる
- [ ] いいね数が表示される

### 基本機能
- [ ] ログイン/ログアウト
- [ ] ルート一覧表示
- [ ] ルート詳細表示
- [ ] マップ表示
- [ ] ダークモード切り替え

### UI/UX
- [ ] ボタンのタップ反応が良い
- [ ] スクロールが滑らか
- [ ] アニメーションが自然
- [ ] エラーメッセージが表示される

---

## 🚀 次のステップ

シミュレーターテストが完了したら:

1. **実機テスト** - GPS記録と写真撮影のフルテスト
2. **パフォーマンステスト** - メモリ使用量、バッテリー消費
3. **長時間テスト** - 1時間以上の記録
4. **ネットワークエラーテスト** - 機内モードでのオフライン動作

---

**作成者**: AI Assistant  
**最終更新**: 2025-11-20  
**対象バージョン**: WanMap v1.0.0 (Phase 2完了後)
