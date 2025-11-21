# ⚡ WanMap クイックスタート

**5分でアプリを起動する最短ルート**

---

## 📋 前提条件

- [ ] Supabaseアカウント（WanMapプロジェクト作成済み）
- [ ] Thunderforestアカウント
- [ ] Flutter SDK（インストール済み）

---

## 🚀 セットアップ（5分）

### 1️⃣ Thunderforest APIキー（1分）

```bash
# 1. https://www.thunderforest.com/ でAPIキー取得
# 2. .envファイルを編集
cd /home/user/webapp/wanmap_v2
nano .env

# 3. 以下の行を編集
THUNDERFOREST_API_KEY=your-api-key-here
# ↓
THUNDERFOREST_API_KEY=実際のAPIキー

# Ctrl+O → Enter → Ctrl+X で保存
```

---

### 2️⃣ Supabaseスキーマ（2分）

```bash
# 1. スキーマをコピー
cat /home/user/webapp/wanmap_v2/supabase_schema.sql

# 2. Supabase Studioで実行
# - https://supabase.com/dashboard
# - SQL Editor > New query
# - コピーした内容を貼り付け
# - Run をクリック

# 3. PostGIS有効化
# - Database > Extensions
# - "postgis" を検索
# - Enable をクリック
```

---

### 3️⃣ Storageバケット（1分）

```bash
# Supabase Studio > Storage
# 以下の3つを作成（全てPublic）:
# 1. dog-photos
# 2. spot-photos
# 3. route-photos
```

---

### 4️⃣ Flutter準備（1分）

```bash
# PATHに追加
export PATH="$PATH:/home/user/flutter/bin"

# プロジェクトに移動
cd /home/user/webapp/wanmap_v2

# 依存関係インストール
flutter pub get
```

---

## ▶️ 起動

### Chrome（Web）で起動

```bash
flutter run -d chrome
```

### iOS Simulatorで起動

```bash
# Simulatorを起動
open -a Simulator

# アプリを起動
flutter run -d "iPhone 15 Pro"
```

### Android Emulatorで起動

```bash
# Emulatorを起動
emulator -avd Pixel_7_API_34

# アプリを起動
flutter run -d emulator-5554
```

---

## ✅ 動作確認

1. **スプラッシュ画面**が表示される
2. **ログイン画面**が表示される
3. アカウント作成してログイン
4. **ホーム画面**が表示される

---

## 🔧 トラブルシューティング

### エラー: `THUNDERFOREST_API_KEY not found`

```bash
cat .env | grep THUNDERFOREST
# APIキーが表示されればOK
```

### エラー: `Table 'dogs' does not exist`

Supabaseスキーマが未適用 → Step 2を再実行

### エラー: `flutter: command not found`

```bash
export PATH="$PATH:/home/user/flutter/bin"
```

---

## 📚 詳細ガイド

詳細なセットアップ手順は以下をご参照ください：

- **SETUP_GUIDE_STEP_BY_STEP.md** - ステップバイステップガイド
- **check_supabase_schema.md** - スキーマ確認ガイド
- **PHASE1_MVP_COMPLETION_REPORT.md** - 実装完了レポート

---

## 🎉 セットアップ完了！

アプリが起動したら、以下を試してみましょう：

1. **犬を登録**: プロフィール > 愛犬一覧 > 追加
2. **GPS記録**: ホーム > 記録開始
3. **ルート検索**: ホーム > ルート検索
4. **スポット登録**: ホーム > スポット追加

---

**楽しんでください！** 🐕🗺️✨
