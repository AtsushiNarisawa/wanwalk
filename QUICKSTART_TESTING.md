# WanMap - クイックスタートテストガイド

**最速でシミュレーターテストを開始する手順**

---

## ⚡ 5分で始めるテスト（macOS）

### 1. プロジェクトディレクトリに移動
```bash
cd ~/Projects/wanmap_v2
```

### 2. 依存関係をインストール
```bash
flutter pub get
```

### 3. シミュレーターを起動

**iOS:**
```bash
open -a Simulator
```

**Android:**
```bash
~/Library/Android/sdk/emulator/emulator -list-avds  # 利用可能なAVDを確認
~/Library/Android/sdk/emulator/emulator -avd Pixel_7_Pro_API_33  # 起動
```

### 4. アプリを起動
```bash
flutter run
```

デバイスを選択して実行開始！

---

## 🧪 Phase 2機能を素早くテスト

### GPS記録の一時停止/再開（2分）

1. **位置情報を設定**
   - iOS: `Simulator → Features → Location → Apple`
   - Android: `Emulator → ... → Location → 35.6762, 139.6503`

2. **記録テスト**
   ```
   マップ画面 → 「お散歩を開始」
   → 「一時停止」ボタンをタップ
   → ボタンが「再開」に変わることを確認 ✅
   → 「再開」ボタンをタップ
   → ボタンが「一時停止」に戻ることを確認 ✅
   → 「お散歩を終了」→ タイトル入力 → 保存
   ```

### 写真フルスクリーン表示（1分）

```
ホーム → 公開ルート → 写真付きルートをタップ
→ 写真サムネイルをタップ
→ ピンチズーム動作確認 ✅
→ 左右スワイプで切り替え確認 ✅
```

### いいね数表示（30秒）

```
ホーム → 公開ルート
→ ハートアイコン♥と数字を確認 ✅
```

---

## 🔧 よくあるエラーと解決方法

### エラー: "No devices found"
```bash
# シミュレーターを起動
open -a Simulator
```

### エラー: "Xcode not found"
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### エラー: コンパイルエラー
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📱 実機テストに切り替える場合

```bash
# iPhoneをUSBで接続
flutter devices  # デバイスが表示されることを確認
flutter run -d "Your iPhone Name"
```

---

## 📚 詳細ガイド

より詳しい情報は以下を参照:
- **SIMULATOR_TESTING_GUIDE.md** - シミュレーター完全ガイド
- **PHASE2_BUG_FIXES.md** - 修正内容の詳細
- **RELEASE_PREPARATION.md** - リリース準備状況

---

**Happy Testing! 🎉**
