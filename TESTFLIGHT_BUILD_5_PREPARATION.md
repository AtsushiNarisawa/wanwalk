# TestFlight Build 5 準備ガイド

**ビルド日:** 2025年12月7日  
**バージョン:** 1.0.0+6  
**ビルド番号:** 6

---

## 📦 このビルドに含まれる新機能

### **Phase 1: いいね機能** ✅
- ピン投稿へのいいね/いいね解除
- いいね数の表示
- 楽観的UI更新

### **Phase 2: ブックマーク機能** ✅
- ピン投稿のブックマーク/解除
- ブックマーク数の表示
- 楽観的UI更新

### **Phase 3: コメント機能** ✅
- ピン投稿へのコメント投稿
- コメント一覧表示
- コメント削除（自分のコメントのみ）
- コメント数の表示

### **Phase 3.5: コメント返信機能** ✅
- ピン投稿者のみ返信可能
- 返信先の表示（→ ユーザー名）
- 投稿者バッジの表示
- 返信インジケーター
- 返信キャンセル機能

---

## 🔧 ビルド前の準備

### **Step 1: バージョン番号の更新**

#### **現在のバージョン:**
```yaml
version: 1.0.0+5
```

#### **新しいバージョン:**
```yaml
version: 1.0.0+6
```

#### **更新手順:**
1. `pubspec.yaml` を開く
2. `version: 1.0.0+5` を `version: 1.0.0+6` に変更
3. ファイルを保存

---

### **Step 2: 依存関係の確認**

```bash
cd ~/projects/webapp/wanmap_v2
flutter pub get
flutter doctor
```

**確認項目:**
- ✅ Flutter SDK: 最新版
- ✅ Xcode: 最新版
- ✅ CocoaPods: 最新版
- ✅ 証明書とプロビジョニングプロファイル

---

### **Step 3: Xcodeでのビルド設定**

#### **1. Xcodeを開く**
```bash
cd ~/projects/webapp/wanmap_v2
open ios/Runner.xcworkspace
```

#### **2. ビルド設定を確認**
- **Product > Scheme > Edit Scheme**
- **Run > Build Configuration > Release**
- **Archive > Build Configuration > Release**

#### **3. Bundle Identifierの確認**
- `com.doghub.wanmap` が正しく設定されているか確認

#### **4. チーム設定の確認**
- **Signing & Capabilities**
- Apple Developer チームが選択されているか確認

#### **5. バージョン番号の確認**
- **General > Identity**
- Version: `1.0.0`
- Build: `6`

---

### **Step 4: ビルドの実行**

#### **1. クリーンビルド**
```bash
cd ~/projects/webapp/wanmap_v2
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

#### **2. Archiveの作成**

**Xcode上で:**
1. `Product > Archive`
2. ビルドが完了するまで待つ（5-10分）

**または、コマンドラインで:**
```bash
flutter build ios --release
```

#### **3. TestFlightへのアップロード**

**Organizer画面で:**
1. 作成したArchiveを選択
2. `Distribute App` をクリック
3. `App Store Connect` を選択
4. `Upload` を選択
5. 自動署名を使用
6. `Upload` をクリック

---

## 📝 リリースノート（TestFlight用）

### **日本語版:**

```
バージョン 1.0.0 (Build 6)

【新機能】
✨ ピン投稿へのいいね機能
✨ ピン投稿のブックマーク機能
✨ ピン投稿へのコメント機能
✨ コメント返信機能（投稿者のみ）

【改善点】
🎨 投稿者バッジの追加
🎨 コメント返信先の視覚化
🎨 ダークモード完全対応
🐛 各種バグ修正と安定性向上

【テスト項目】
以下の機能を重点的にテストしてください：
- ピン詳細画面でのいいね機能
- ピン詳細画面でのブックマーク機能
- ピン詳細画面でのコメント投稿・削除
- コメント返信機能（投稿者のみ）
- 投稿者バッジの表示
- ダークモードでの表示

既知の問題や気になる点があれば、フィードバックをお願いします。
```

### **英語版（App Store Connect用）:**

```
Version 1.0.0 (Build 6)

New Features:
✨ Like function for pin posts
✨ Bookmark function for pin posts
✨ Comment function for pin posts
✨ Reply function (pin owners only)

Improvements:
🎨 Added owner badge
🎨 Visualized reply targets
🎨 Full dark mode support
🐛 Various bug fixes and stability improvements

Please test:
- Like function on pin detail screen
- Bookmark function on pin detail screen
- Comment posting/deletion on pin detail screen
- Reply function (pin owners only)
- Owner badge display
- Dark mode display

Please provide feedback on any issues or concerns.
```

---

## ✅ ビルド後のチェックリスト

### **App Store Connectでの確認:**

1. **ビルドの処理完了を待つ**
   - アップロード後、15-30分かかる
   - メールで通知が届く

2. **TestFlightタブを確認**
   - ビルド6が表示されているか
   - 処理ステータスが「準備完了」になっているか

3. **内部テスターに配信**
   - TestFlightの「内部テスト」を選択
   - ビルド6を選択
   - テスターグループに配信

4. **外部テスターに配信（任意）**
   - TestFlightの「外部テスト」を選択
   - ビルド6を選択
   - レビュー提出（審査あり）

---

## 🧪 テスト項目

### **必須テスト項目:**

#### **1. ピン詳細画面**
- [ ] ピン詳細画面が正しく表示される
- [ ] いいねボタンが動作する
- [ ] ブックマークボタンが動作する
- [ ] コメント一覧が表示される
- [ ] コメント投稿ができる
- [ ] 自分のコメントに削除ボタンが表示される

#### **2. コメント返信機能**
- [ ] ピン投稿者のみ「返信する」ボタンが表示される
- [ ] 一般ユーザーには「返信する」ボタンが表示されない
- [ ] 「返信する」をタップすると返信インジケーターが表示される
- [ ] 返信を投稿すると「→ ユーザー名」が表示される
- [ ] ×ボタンで返信キャンセルができる

#### **3. 投稿者バッジ**
- [ ] ピン投稿者のコメントに「投稿者」バッジが表示される
- [ ] バッジの色・デザインが正しい

#### **4. ダークモード**
- [ ] ライトモードで正しく表示される
- [ ] ダークモードで正しく表示される
- [ ] モード切り替えがスムーズ

#### **5. 既存機能**
- [ ] ホーム画面が正しく表示される
- [ ] マップ画面が正しく表示される
- [ ] 記録画面が正しく表示される
- [ ] プロフィール画面が正しく表示される
- [ ] 日常散歩の記録ができる
- [ ] お出かけ散歩の記録ができる

---

## 📊 Git履歴

```bash
d1186e8 docs: Phase 3.5 Step 4 の実装詳細を追加
5362434 feat: ピン投稿者のみ返信可能に制限 + 投稿者バッジ追加
ad926cc docs: Phase 3.5完全実装サマリを追加
55c7064 feat: Phase 3.5 Step 3 - コメント返信機能の完全実装
7327971 fix: PinDetailScreen createState()の戻り値に()を追加
2658c4b feat: Phase 3.5 Step 1 - ピン詳細画面にコメント一覧表示機能を追加
1a1a67b feat: コメント詳細画面の完全実装 (Phase 3完了)
```

---

## 🚨 既知の問題

### **現在確認されている問題:**
- なし（Phase 3.5の実装は完了しており、動作確認済み）

### **保留中の機能:**
- ソーシャル機能（フォロー/フォロワー）
- UI構造の変更（マップタブからの散歩開始）

---

## 📞 サポート

### **問題が発生した場合:**
1. エラーメッセージをスクリーンショット
2. 発生した手順を記録
3. デバイス情報を確認（iOS バージョン、デバイスモデル）
4. フィードバックを送信

---

## 🎯 次のステップ

### **TestFlight配信後:**
1. 内部テスターに配信通知
2. テスト結果の収集
3. バグ修正（必要に応じて）
4. 外部テスターへの配信（任意）
5. 本番リリースの準備

---

**準備完了！ビルドを開始してください！** 🚀
