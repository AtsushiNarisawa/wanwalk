# WanMap 次のステップ

## ✅ 完了したこと（2025-11-13）

1. **Supabase認証の設定と動作確認**
   - 環境変数の設定（`lib/config/env.dart`）
   - 認証サービスの実装（`lib/services/auth_service.dart`）
   - ログイン/新規登録画面の実装
   - macOSネットワーク権限の設定
   - **ログイン成功を確認！** ✅

2. **プロジェクト構造**
   - Flutter 3.0+ / Dart
   - Riverpod（状態管理）
   - flutter_map（地図表示）
   - geolocator（GPS追跡）
   - Material Design 3

---

## 📋 次にやること

### Phase 4: Supabaseデータベーステーブルの作成

#### **手順：**

1. **Supabaseダッシュボードにアクセス**
   - https://supabase.com/dashboard
   - プロジェクト `wanmap_v2` を選択

2. **SQL Editorを開く**
   - 左メニュー > **SQL Editor**

3. **スキーマを実行**
   - プロジェクトルートの `supabase_schema.sql` ファイルの内容をコピー
   - SQL Editorに貼り付けて **Run** をクリック

4. **テーブル確認**
   - 左メニュー > **Table Editor**
   - 以下のテーブルが作成されているか確認：
     - `users`（ユーザープロフィール）
     - `dogs`（犬の情報）
     - `routes`（散歩ルート）
     - `route_points`（GPS座標）

5. **auth_service.dartのコメント解除**
   - `lib/services/auth_service.dart`の以下の部分のコメントを外す：
   
   ```dart
   // 現在コメントアウトされている部分（56-64行目あたり）
   /*
   if (response.user != null) {
     await _supabase.from(SupabaseTables.users).insert({
       'id': response.user!.id,
       'email': email,
       'display_name': displayName,
       'created_at': DateTime.now().toIso8601String(),
     });
   }
   */
   ```
   
   ↓ コメントを外して以下のようにする：
   
   ```dart
   if (response.user != null) {
     await _supabase.from(SupabaseTables.users).insert({
       'id': response.user!.id,
       'email': email,
       'display_name': displayName,
       'created_at': DateTime.now().toIso8601String(),
     });
   }
   ```

---

### Phase 5: GPS機能のテスト

#### **前提条件：**
- **実機（iPhone/Android）が必要**
- macOSシミュレータではGPS機能は限定的

#### **手順：**

1. **実機を接続**
   ```bash
   flutter devices  # 実機が認識されているか確認
   ```

2. **実機でアプリを起動**
   ```bash
   flutter run -d <device-id>
   ```

3. **マップ画面をテスト**
   - ログイン後、「マップを開く」ボタンをタップ
   - GPS権限の許可を求められたら **許可**
   - 地図が表示され、現在地が表示されるか確認

4. **ルート記録をテスト**
   - 「記録開始」ボタンをタップ
   - 実際に歩いてGPS座標が記録されるか確認
   - 「記録停止」ボタンでルートが保存されるか確認

---

### Phase 6: デバッグログの削除（本番前）

`lib/services/auth_service.dart`から以下のようなデバッグログを削除：

```dart
print('🔵 [AuthService] signUp開始');
print('🔵 [AuthService] email: $email');
// ... その他のprint文
```

---

## 🔄 今後の開発フロー

1. **ローカルMacで開発**
   - `~/projects/webapp/wanmap_v2`

2. **Git管理**
   ```bash
   git add .
   git commit -m "Phase 4: Supabaseテーブル作成"
   git push origin main
   ```

3. **GitHubリポジトリ**
   - https://github.com/Atsushi-Naruse/wanmap_v2

---

## 📚 参考リンク

- **Supabaseダッシュボード**: https://supabase.com/dashboard
- **Flutter公式ドキュメント**: https://docs.flutter.dev
- **flutter_map公式**: https://docs.fleaflet.dev
- **geolocator公式**: https://pub.dev/packages/geolocator

---

## 🐛 トラブルシューティング

### **問題: ネットワーク接続エラー**

**解決方法:**
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

両方に以下が含まれているか確認：

```xml
<key>com.apple.security.network.client</key>
<true/>
```

### **問題: GPS権限エラー**

**解決方法:**
- `ios/Runner/Info.plist`または`android/app/src/main/AndroidManifest.xml`にGPS権限の設定があるか確認
- 実機の設定でアプリにGPS権限が許可されているか確認

---

おやすみなさい！🌙
良い夢を！次回の開発を楽しみにしています！😊
