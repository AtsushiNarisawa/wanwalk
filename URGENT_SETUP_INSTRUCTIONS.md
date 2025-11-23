# 🚨 緊急セットアップ手順

## ステップ1: バッジテーブルの修正（最優先）

### Supabase SQL Editor での実行手順

1. **Supabase Dashboard を開く**
   - URL: https://supabase.com/dashboard/project/jkpenklhrlbctebkpvax

2. **SQL Editor に移動**
   - 左メニューから「SQL Editor」をクリック

3. **新しいクエリを作成**
   - 「New query」ボタンをクリック

4. **SQLをコピー＆ペースト**
   ```bash
   # 以下のファイルの内容を全てコピー
   /home/user/webapp/wanmap_v2/FIX_BADGES_TABLE_ALIAS.sql
   ```

5. **実行**
   - 「Run」ボタンをクリック
   - 成功メッセージを確認

### 期待される結果

```
NOTICE:  17個のバッジデータを投入しました
Final badge count: 17
```

### このSQLが行うこと

1. ✅ `badges` ビューを作成（badge_definitions → badges のマッピング）
2. ✅ 17個のバッジデータを自動投入（不足していた場合）
3. ✅ バッジシステムがFlutterアプリで正常動作するようになる

---

## ステップ2: 不足画面の自動実装（自動実行）

以下の画面を順次自動実装します：

### Phase 4: 履歴機能（最優先）
- ✅ `lib/screens/history/history_screen.dart`
- ✅ `lib/screens/history/trip_detail_screen.dart`
- ✅ `lib/screens/history/trip_edit_screen.dart`

### Phase 3: 検索機能（高優先）
- ✅ `lib/screens/search/search_screen.dart`
- ✅ `lib/screens/search/search_results_screen.dart`

### Phase 2: エリア詳細（中優先）
- ✅ `lib/screens/area/area_detail_screen.dart`
- ✅ `lib/screens/area/official_route_screen.dart`

### Phase 5: バッジ詳細
- ✅ `lib/screens/badges/badge_detail_screen.dart`

### その他
- ✅ `lib/models/user_model.dart`

---

## ステップ3: テストユーザーのバッジ解除

バッジテーブル修正後、Supabase SQL Editorで実行：

```sql
-- Test1ユーザーのバッジ解除
SELECT * FROM check_and_unlock_badges(
  (SELECT user_id FROM profiles WHERE display_name = 'test1' LIMIT 1)
);

-- Test2ユーザーのバッジ解除
SELECT * FROM check_and_unlock_badges(
  (SELECT user_id FROM profiles WHERE display_name = 'test2' LIMIT 1)
);

-- Test3ユーザーのバッジ解除
SELECT * FROM check_and_unlock_badges(
  (SELECT user_id FROM profiles WHERE display_name = 'test3' LIMIT 1)
);
```

---

## 完了後の確認事項

### Flutterアプリでの確認

1. ✅ ホーム画面のクイックアクションが表示される
2. ✅ バッジボタンをタップしてバッジリストが表示される
3. ✅ 統計ボタンをタップして統計画面が表示される
4. ✅ プロフィール → 履歴 が表示される
5. ✅ 検索アイコンで検索画面が表示される

---

## トラブルシューティング

### バッジが表示されない場合

1. Supabase SQL Editorで確認：
   ```sql
   SELECT COUNT(*) FROM badges;  -- 17件であることを確認
   SELECT COUNT(*) FROM user_badges;  -- 0件以上であることを確認
   ```

2. Flutterアプリを再起動（Hot Restart: Shift + R）

### 画面遷移でエラーが出る場合

1. Flutter Clean & Rebuild:
   ```bash
   cd /home/user/webapp/wanmap_v2
   flutter clean
   flutter pub get
   flutter run
   ```

---

**次のステップ**: ステップ1のSQL実行完了をお知らせください。その後、自動実装を開始します。
