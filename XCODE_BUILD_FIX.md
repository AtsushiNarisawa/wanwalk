# Xcode Build Error Fix - WanMap v2

## ✅ 修正完了した問題

### 1. Flutter Configuration Files
- ✅ `ios/Flutter/Generated.xcconfig` - 作成済み
- ✅ `ios/Flutter/Debug.xcconfig` - 作成済み
- ✅ `ios/Flutter/Release.xcconfig` - 作成済み
- ✅ `ios/Flutter/flutter_export_environment.sh` - 作成済み

これで **"Generated.xcconfig must exist"** エラーは解決されました。

## 🔧 次のステップ: Team 設定

### Xcode での手順:

1. **Xcode を再起動**
   - Xcode を完全に終了
   - プロジェクトを再度開く: `open ios/Runner.xcworkspace`

2. **Team を再選択**
   - **Runner** target を選択
   - **Signing & Capabilities** タブ
   - **Team**: "Atsushi Narisawa" を再選択
   - **Automatically manage signing** をオンにする

3. **Clean Build Folder**
   - メニュー: **Product** → **Clean Build Folder** (⇧⌘K)
   - これでキャッシュされたエラーがクリアされます

4. **再ビルド**
   - ▶️ ボタンをクリック
   - または **Product** → **Run** (⌘R)

## 📱 デバイス選択

- ✅ **実機**: "成沢敦史のiPhone" または接続されている実機
- ⚠️ **Simulator**: 最初のビルドは実機推奨

## ⚠️ よくあるエラーと対処法

### エラー: "No profiles for 'com.example.wanmapv2' were found"

**解決策:**
1. **Bundle Identifier を変更**:
   - `com.example.wanmapv2` → `com.narisawa.wanmapv2`
   - または: `com.yourdomain.wanmapv2`

2. **Xcode での変更方法**:
   - **General** タブ
   - **Bundle Identifier** フィールドを編集
   - ユニークな識別子に変更

### エラー: "Provisioning profile doesn't include signing certificate"

**解決策:**
1. **Xcode** → **Settings** → **Accounts**
2. あなたの Apple ID を選択
3. **Download Manual Profiles** ボタンをクリック
4. プロジェクトに戻り、Team を再選択

### エラー: "Failed to register bundle identifier"

**解決策:**
1. Bundle Identifier をより具体的に変更:
   - 例: `com.narisawa.atsushi.wanmapv2`
2. Apple Developer Portal で確認
   - https://developer.apple.com/account
   - **Identifiers** セクション

## 🎯 期待される結果

### ✅ ビルド成功後:
- アプリがデバイスにインストールされる
- ログイン画面が表示される
- 基本機能が動作する

### ⏸️ "準備中" 表示:
- プロフィール画面
- お気に入り機能
- 公開ルート
- ソーシャル機能

## 📞 まだエラーが出る場合

以下の情報を共有してください:
1. 新しいエラーメッセージのスクリーンショット
2. **Issue Navigator** (⌘9) の詳細エラー
3. Build log の関連部分

---

**Status**: 🔧 Flutter設定修正完了 → Xcodeで再ビルドしてください  
**次のステップ**: Xcode再起動 → Clean → Build

