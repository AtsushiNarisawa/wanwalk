# TestFlight デプロイメントガイド v1.0.0+10

## 📋 事前確認

### ✅ 完了項目
- [x] ビルド番号更新: `1.0.0+9` → `1.0.0+10`
- [x] リリースノート作成
- [x] GitHubへのプッシュ完了
- [x] 機能テスト完了

### ⚠️ 重要な確認事項
1. **Supabaseデータベース更新**
   - [ ] `docs/UPDATE_HAKONE_ACCESS_INFO.sql`を実行済みか？
   - 箱根サブエリアの交通情報が正しく表示されるか確認

2. **環境変数（.env）**
   - [ ] `.env`ファイルがプロジェクトルートに存在するか
   - [ ] Supabase接続情報が正しいか

## 🚀 TestFlightへのアップロード手順

### STEP 1: プロジェクトのクリーンアップ
```bash
cd ~/projects/webapp/wanwalk
flutter clean
flutter pub get
```

### STEP 2: iOSビルドの準備
```bash
cd ios
pod deintegrate || true
pod install
cd ..
```

### STEP 3: Xcodeでプロジェクトを開く
```bash
open ios/Runner.xcworkspace
```

### STEP 4: Xcode設定の確認
1. **General タブ**
   - Display Name: `WanWalk`
   - Bundle Identifier: `com.doghub.wanwalk` (または既存のID)
   - Version: `1.0.0`
   - Build: `10`
   - Minimum Deployments: `iOS 13.0`

2. **Signing & Capabilities タブ**
   - Team: 自分のApple Developer Team
   - Automatically manage signing: チェック
   - Provisioning Profile: 自動選択

### STEP 5: Archiveの作成
1. Xcodeメニュー: `Product` → `Destination` → `Any iOS Device (arm64)`
2. Xcodeメニュー: `Product` → `Archive`
3. ビルド完了まで待機（約5-10分）

### STEP 6: TestFlightへのアップロード
1. Archiveが完成すると`Organizer`ウィンドウが開く
2. 最新のArchiveを選択
3. `Distribute App`ボタンをクリック
4. `App Store Connect`を選択 → `Next`
5. `Upload`を選択 → `Next`
6. 配布オプションを確認 → `Next`
7. 署名オプションを確認 → `Next`（Automatically manage signingの場合）
8. `Upload`をクリック

### STEP 7: App Store Connectでの処理待ち
1. アップロード完了後、App Store Connectでの処理に約10-30分かかります
2. https://appstoreconnect.apple.com にアクセス
3. `マイApp` → `WanWalk` → `TestFlight`タブ
4. 処理中のビルドが表示されます

### STEP 8: TestFlightでのテスト準備
1. ビルドの処理が完了すると、ステータスが`テスト準備完了`になります
2. `テスター`セクションでテスターを追加
3. テスト情報を入力:
   - **新機能**: リリースノートの内容を記載
   - **テスト方法**: アプリの主要機能の確認方法

## 📱 TestFlightでのテスト項目

### 必須テスト項目
- [ ] アプリが正常に起動するか
- [ ] TOPページのセクション順序が正しいか（1.ピン投稿 2.人気コース 3.エリア 4.高評価）
- [ ] 箱根カードをタップしてサブエリア選択画面が表示されるか
- [ ] 箱根サブエリア（仙石原、芦ノ湖など）の交通情報が表示されるか
- [ ] バナーをタップして外部ブラウザが開くか
- [ ] カードのグラデーション背景が表示されているか

### 推奨テスト項目
- [ ] ピン投稿の閲覧・いいね・コメント
- [ ] ルート詳細の表示
- [ ] 地図表示とGPS機能
- [ ] Library機能（アルバム、ピン）

## 🐛 トラブルシューティング

### ビルドエラーが発生した場合
```bash
# 完全クリーンアップ
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks build/
flutter pub get
cd ios && pod install && cd ..

# Xcodeを再起動
killall Xcode
open ios/Runner.xcworkspace
```

### コード署名エラーの場合
1. Xcode: `Runner` → `Signing & Capabilities`
2. `Automatically manage signing`のチェックを外して再度チェック
3. Teamを再選択

### シミュレータエラーの場合
- TestFlightには実機デバイスでのみ配信されるため、シミュレータエラーは無視してOK
- Archive作成時は`Any iOS Device (arm64)`を選択

## 📝 TestFlight配信後の確認事項

1. **App Store Connectでの確認**
   - ビルドのステータス
   - クラッシュレポート
   - メトリクス

2. **テスター招待**
   - 内部テスター（開発チーム）
   - 外部テスター（ベータテスター）

3. **フィードバック収集**
   - TestFlightアプリ内のフィードバック機能
   - スクリーンショットとクラッシュログ

## 🎯 次のステップ

TestFlightでの検証完了後：
1. [ ] フィードバックの収集と分析
2. [ ] 必要に応じて修正版のビルド
3. [ ] App Store本番リリースの準備

---

**質問・サポート**
問題が発生した場合は、エラーメッセージとスクリーンショットを共有してください。
