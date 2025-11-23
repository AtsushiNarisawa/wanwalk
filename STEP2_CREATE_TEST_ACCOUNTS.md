# ステップ2: テストアカウント作成ガイド

## 📋 目的

Phase 5のテストには、3つのテストアカウントが必要です:
1. **test1@example.com** - 散歩マスター（最も活発なユーザー）
2. **test2@example.com** - バッジコレクター
3. **test3@example.com** - ソーシャルユーザー

---

## 🚀 実行手順

### 方法A: アプリからアカウント作成（推奨）

この方法が最も簡単で確実です。

#### 手順

1. **アプリを起動**
   ```bash
   cd /home/user/webapp/wanmap_v2
   flutter run
   ```
   ⏳ アプリが起動するまで待つ（初回は数分かかる場合があります）

2. **ログイン画面で「新規登録」をタップ**

3. **アカウント1を作成**
   - メールアドレス: `test1@example.com`
   - パスワード: `Test1234!`
   - 「登録」をタップ
   - ✅ 登録成功メッセージを確認

4. **ログアウト**
   - ホーム画面 → プロフィールアイコン → 設定 → ログアウト

5. **アカウント2を作成**
   - メールアドレス: `test2@example.com`
   - パスワード: `Test1234!`
   - 「登録」をタップ

6. **ログアウト**

7. **アカウント3を作成**
   - メールアドレス: `test3@example.com`
   - パスワード: `Test1234!`
   - 「登録」をタップ

---

### 方法B: Supabase Dashboardから作成

アプリが起動しない場合の代替方法です。

#### 手順

1. **Supabase Dashboard を開く**
   - URL: https://supabase.com/dashboard/project/jkpenklhrlbctebkpvax
   - 左メニュー → 「Authentication」をクリック

2. **「Users」タブを選択**

3. **「Add user」ボタンをクリック**

4. **アカウント1を作成**
   - 「Create a new user」を選択
   - Email: `test1@example.com`
   - Password: `Test1234!`
   - 「Create user」をクリック
   - ✅ ユーザーが一覧に表示されることを確認

5. **同様にアカウント2、3を作成**
   - Email: `test2@example.com`, Password: `Test1234!`
   - Email: `test3@example.com`, Password: `Test1234!`

---

## ✅ アカウント作成確認

### Supabase Dashboardで確認

1. **Supabase Dashboard → Authentication → Users**

2. **3つのユーザーが表示されることを確認**
   - ✅ test1@example.com
   - ✅ test2@example.com
   - ✅ test3@example.com

---

## 📝 ユーザーIDを取得

テストデータスクリプトで使用するため、各ユーザーのUUIDをコピーします。

### 手順

1. **Supabase Dashboard → Authentication → Users**

2. **test1@example.com の行をクリック**
   - 右側にユーザー詳細が表示される
   - 「User UID」欄のUUIDをコピー
   - 📋 メモ帳などに保存:
     ```
     User 1 (test1@example.com): [ここにUUIDを貼り付け]
     ```

3. **test2@example.com のUUIDをコピー**
   - 同様に「User UID」をコピー
   - 📋 メモ:
     ```
     User 2 (test2@example.com): [ここにUUIDを貼り付け]
     ```

4. **test3@example.com のUUIDをコピー**
   - 同様に「User UID」をコピー
   - 📋 メモ:
     ```
     User 3 (test3@example.com): [ここにUUIDを貼り付け]
     ```

### UUIDの例

正しいUUIDは以下のような形式です:
```
a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

---

## 📝 実行結果メモ

- [ ] アカウント1作成完了
  - Email: test1@example.com
  - UUID: ________________________________

- [ ] アカウント2作成完了
  - Email: test2@example.com
  - UUID: ________________________________

- [ ] アカウント3作成完了
  - Email: test3@example.com
  - UUID: ________________________________

- [ ] Supabase Dashboardで3ユーザー確認完了: ✅ はい / ❌ いいえ

---

## 🐛 トラブルシューティング

### エラー: "Email already exists"
**原因**: すでに同じメールアドレスが登録されている  
**対処**: 
- 既存のユーザーを使用する（UUIDを取得してステップ3へ）
- または別のメールアドレスを使用（例: `test1-alt@example.com`）

### エラー: "Invalid password"
**原因**: パスワードが要件を満たしていない  
**対処**: 最低8文字、英数字を含むパスワードを使用

### エラー: "Email confirmation required"
**原因**: メール認証が必要な設定になっている  
**対処**: 
1. Supabase Dashboard → Authentication → Settings
2. 「Email confirmation」を無効化
3. または確認メールからリンクをクリック

---

**UUIDを3つ全てコピーしたら、ステップ3に進みます！**
