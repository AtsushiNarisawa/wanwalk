# 🚀 WanMap セットアップガイド（ステップバイステップ）

このガイドに従って、WanMapアプリを起動できる状態にします。

---

## 📌 Step 1: Thunderforest APIキーの取得

### 1-1. Thunderforestアカウント作成

1. ブラウザで https://www.thunderforest.com/ にアクセス
2. 右上の「Sign Up」をクリック
3. メールアドレスとパスワードを入力して登録
4. メールで届いた確認リンクをクリックして認証

### 1-2. APIキーの取得

1. ログイン後、「Dashboard」に移動
2. 「API Keys」セクションを探す
3. 「Create new API Key」をクリック
4. プロジェクト名（例: WanMap）を入力
5. 作成されたAPIキーをコピー（例: `abc123def456...`）

### 1-3. .envファイルに設定

1. このターミナルで以下のコマンドを実行：

```bash
cd /home/user/webapp/wanmap_v2
nano .env
```

2. 以下の行を見つけて、`your-api-key-here`を実際のAPIキーに置き換え：

```env
THUNDERFOREST_API_KEY=your-api-key-here
```

を

```env
THUNDERFOREST_API_KEY=abc123def456... # 実際のAPIキー
```

に変更

3. `Ctrl + O`（保存）→ `Enter` → `Ctrl + X`（終了）

### ✅ 確認

```bash
cat .env | grep THUNDERFOREST
```

APIキーが正しく表示されればOK！

---

## 📌 Step 2: Supabaseスキーマの適用

### 2-1. Supabase Studioにアクセス

1. ブラウザで https://supabase.com/dashboard にアクセス
2. ログイン（WanMapプロジェクトのアカウント）
3. WanMapプロジェクトを選択

### 2-2. PostGIS拡張機能の有効化

1. 左サイドバーの「Database」をクリック
2. 「Extensions」タブをクリック
3. 検索ボックスに「postgis」と入力
4. 「postgis」の右側にある「Enable」ボタンをクリック
5. 確認ダイアログで「Enable extension」をクリック

### 2-3. SQLスキーマの実行

1. 左サイドバーの「SQL Editor」をクリック
2. 「+ New query」をクリック

3. ローカルの`supabase_schema.sql`の内容をコピー：

```bash
# ターミナルで実行（ファイルの内容を表示）
cat /home/user/webapp/wanmap_v2/supabase_schema.sql
```

4. 表示された内容を**全て選択してコピー**
5. Supabase StudioのSQL Editorに**貼り付け**
6. 右下の「Run」ボタンをクリック
7. 実行完了まで待つ（通常30秒〜1分）

### ✅ 確認

1. 左サイドバーの「Table Editor」をクリック
2. 以下のテーブルが作成されていることを確認：
   - user_profiles
   - dogs
   - routes
   - route_points
   - route_photos
   - route_likes
   - route_comments
   - spots
   - spot_photos
   - spot_comments
   - spot_upvotes

**注意**: エラーが出た場合は、「postgis」拡張機能が有効になっているか確認してください。

---

## 📌 Step 3: Supabase Storageバケットの作成

### 3-1. Storageページにアクセス

1. 左サイドバーの「Storage」をクリック
2. 「Create a new bucket」ボタンをクリック

### 3-2. 各バケットの作成

#### バケット1: dog-photos

1. Bucket name: `dog-photos`
2. 「Public bucket」を**チェック**
3. 「Create bucket」をクリック

#### バケット2: spot-photos

1. 「Create a new bucket」をクリック
2. Bucket name: `spot-photos`
3. 「Public bucket」を**チェック**
4. 「Create bucket」をクリック

#### バケット3: route-photos（既存の場合はスキップ）

1. 既に`route-photos`が存在するか確認
2. 存在しない場合：
   - 「Create a new bucket」をクリック
   - Bucket name: `route-photos`
   - 「Public bucket」を**チェック**
   - 「Create bucket」をクリック

### ✅ 確認

Storageページに以下の3つのバケットが表示されていればOK：
- ✅ dog-photos（Public）
- ✅ spot-photos（Public）
- ✅ route-photos（Public）

---

## 📌 Step 4: Flutter依存関係のインストール

### 4-1. Flutterコマンドの準備

```bash
# PATHにFlutterを追加（このセッションのみ）
export PATH="$PATH:/home/user/flutter/bin"

# Flutter動作確認
flutter --version
```

**期待される出力**:
```
Flutter 3.35.7 • channel stable • ...
```

### 4-2. プロジェクトディレクトリに移動

```bash
cd /home/user/webapp/wanmap_v2
```

### 4-3. 依存関係のインストール

```bash
flutter pub get
```

**期待される出力**:
```
Running "flutter pub get" in wanmap_v2...
Resolving dependencies... (約10〜30秒)
Got dependencies!
```

### ✅ 確認

以下のコマンドでエラーがなければOK：

```bash
flutter analyze
```

**警告（Warning）は問題ありません。エラー（Error）がなければOK！**

---

## 📌 Step 5: アプリの起動

### 5-1. 利用可能なデバイスの確認

```bash
flutter devices
```

**期待される出力例**:
```
Chrome (web)            • chrome            • web-javascript • Google Chrome
macOS (desktop)         • macos             • darwin-arm64   • macOS 14.0
iPhone 15 Pro (mobile)  • 00008110-...      • ios            • iOS 17.0
```

### 5-2. iOS Simulatorの起動（Macの場合）

```bash
# iOS Simulatorを起動
open -a Simulator

# または特定のデバイスを起動
xcrun simctl boot "iPhone 15 Pro"
```

### 5-3. Android Emulatorの起動（Windowsの場合）

```bash
# 利用可能なエミュレータのリスト表示
emulator -list-avds

# エミュレータの起動（名前を指定）
emulator -avd Pixel_7_API_34
```

### 5-4. アプリの起動

#### iOS Simulatorで起動する場合:

```bash
flutter run -d "iPhone 15 Pro"
```

#### Android Emulatorで起動する場合:

```bash
flutter run -d emulator-5554
```

#### Chromeで起動する場合（開発用）:

```bash
flutter run -d chrome
```

### ✅ 確認

アプリが起動し、以下の画面が表示されればOK：
1. **スプラッシュ画面**（WanMapロゴ）
2. **ログイン画面** または **ホーム画面**

---

## 🔧 トラブルシューティング

### エラー1: `THUNDERFOREST_API_KEY not found`

**原因**: APIキーが正しく設定されていない

**解決方法**:
```bash
cd /home/user/webapp/wanmap_v2
cat .env
# THUNDERFOREST_API_KEYの値を確認
```

### エラー2: `Table 'dogs' does not exist`

**原因**: Supabaseスキーマが適用されていない

**解決方法**:
- Supabase StudioでStep 2を再実行
- PostGIS拡張機能が有効か確認

### エラー3: `Storage bucket not found`

**原因**: Storageバケットが作成されていない

**解決方法**:
- Supabase StudioでStep 3を再実行
- バケット名のスペルミスを確認

### エラー4: `flutter: command not found`

**原因**: FlutterがPATHに追加されていない

**解決方法**:
```bash
export PATH="$PATH:/home/user/flutter/bin"
flutter --version
```

### エラー5: GPS機能が動作しない

**原因**: 位置情報権限が許可されていない

**解決方法**:
- iOS: 設定 > プライバシー > 位置情報サービス > WanMap > 許可
- Android: 設定 > アプリ > WanMap > 権限 > 位置情報 > 許可

---

## 📚 追加リソース

### 便利なコマンド

```bash
# ホットリロード: コード変更を即座に反映
# アプリ起動中に 'r' キーを押す

# フルリスタート: 状態をリセットして再起動
# アプリ起動中に 'R' キーを押す

# ログ表示
flutter logs

# ビルドキャッシュのクリア
flutter clean
flutter pub get
```

### Supabase管理

```bash
# データベースのテーブル確認
# Supabase Studio > Table Editor

# Storageの使用量確認
# Supabase Studio > Storage > 各バケットをクリック

# RLSポリシーの確認
# Supabase Studio > Authentication > Policies
```

---

## ✅ セットアップ完了チェックリスト

- [ ] Thunderforest APIキーを取得し、.envに設定
- [ ] Supabase PostGIS拡張機能を有効化
- [ ] Supabaseスキーマを実行（11テーブル作成）
- [ ] Storageバケットを3つ作成（dog-photos, spot-photos, route-photos）
- [ ] `flutter pub get`を実行
- [ ] `flutter run`でアプリが起動

**全てチェックできたら、アプリの開発・テストを開始できます！** 🎉

---

## 🆘 サポート

問題が解決しない場合は、以下の情報を添えてお問い合わせください：

1. エラーメッセージの全文
2. 実行したコマンド
3. 使用しているOS（macOS/Windows/Linux）
4. Flutter/Dartのバージョン（`flutter --version`の出力）

---

**セットアップ成功をお祈りしています！** 🚀✨
