# Supabase クリーンアップ実行計画

**作成日**: 2025-11-27  
**目的**: 未使用のSupabaseリソース（RPC関数、Storageバケット）を削除してデータベースを整理

---

## 📊 削除対象サマリー

| カテゴリ | 削除対象数 | 優先度 |
|---------|-----------|--------|
| RPC関数 | 14個 | 高 |
| RPC関数（確認必要） | 5個 | 中 |
| Storageバケット | 1個 | 高 |
| **合計** | **20個** | - |

---

## 🎯 フェーズ1: RPC関数削除（14個）

### 削除対象のRPC関数

#### 1. `get_all_routes_geojson`
- **理由**: コードで未使用、`get_routes_by_area_geojson` で代替可能
- **影響**: なし

#### 2. `get_areas_simple`
- **理由**: コードで未使用
- **影響**: なし

#### 3. `get_followers`
- **理由**: コードで未使用
- **影響**: なし

#### 4. `get_following`
- **理由**: コードで未使用
- **影響**: なし

#### 5. `get_pins_by_route`
- **理由**: コードで未使用
- **影響**: なし

#### 6. `get_popular_routes` (重複削除)
- **理由**: 2つの同名関数が存在、1つは不要
- **影響**: 1つを保持するため影響なし
- **削除対象**: 引数が `p_limit integer DEFAULT 10` の方

#### 7. `get_route_comparison`
- **理由**: コードで未使用
- **影響**: なし

#### 8. `get_route_likers`
- **理由**: コードで未使用
- **影響**: なし

#### 9. `get_route_pins_with_likes`
- **理由**: コードで未使用
- **影響**: なし

#### 10. `get_walk_photos`
- **理由**: コードで未使用、PhotoServiceで代替実装
- **影響**: なし

#### 11. `has_liked_route`
- **理由**: コードで未使用
- **影響**: なし

#### 12. `is_following`
- **理由**: コードで未使用
- **影響**: なし

#### 13. `mark_all_notifications_read`
- **理由**: コードで未使用
- **影響**: なし

#### 14. `mark_notification_read`
- **理由**: コードで未使用
- **影響**: なし

---

## 🎯 フェーズ2: Storageバケット削除（1個）

### 削除対象のStorageバケット

#### 1. `pix_photos`
- **理由**: コードで未使用、名前のtypoの可能性（`pin_photos`?）
- **ファイル数**: 4個
- **サイズ**: Unset (50 MB)
- **影響**: なし
- **注意**: 削除前にファイル内容を確認推奨

---

## ⚠️ フェーズ3: 確認が必要なRPC関数（5個）

### 削除前に確認が必要

#### 1. `broadcast_system_notification`
- **理由**: 管理用の可能性
- **推奨アクション**: 手動テストで使用状況を確認

#### 2. `calculate_walk_statistics`
- **理由**: バッチ処理での使用の可能性
- **推奨アクション**: 統計計算が正常に動作するか確認

#### 3. `check_user_liked_pin`
- **理由**: 内部的に使用されている可能性
- **推奨アクション**: `toggle_pin_like` 内で呼び出されていないか確認

#### 4. `send_system_notification`
- **理由**: 管理用の可能性
- **推奨アクション**: 手動テストで使用状況を確認

#### 5. `get_popular_routes` (保持する方)
- **理由**: 2つの同名関数のうち、どちらを保持するか確認
- **推奨アクション**: 引数 `p_limit, p_offset, p_days` の方を保持

---

## 📝 削除手順

### ステップ1: RPC関数削除（Supabaseダッシュボード）

1. **Database > Functions** に移動
2. 削除対象の関数を1つずつ選択
3. 「Delete function」をクリック
4. 確認ダイアログで「Confirm」

### ステップ2: Storageバケット削除

1. **Storage** に移動
2. `pix_photos` バケットを選択
3. ファイル内容を確認（必要であればバックアップ）
4. 「Delete bucket」をクリック
5. 確認ダイアログで「Confirm」

---

## ✅ 削除後の確認

### 1. アプリの動作確認
- Mac環境で `flutter run`
- すべての主要機能が正常動作するか確認

### 2. Supabaseログ確認
- Database > Logs でエラーが発生していないか確認

### 3. Git コミット
```bash
cd ~/projects/webapp/wanmap_v2
git add SUPABASE_CLEANUP_PLAN.md
git commit -m "Add Supabase cleanup plan: identify 20 unused resources"
git push origin main
```

---

## 🚨 ロールバック手順

削除後に問題が発生した場合：

1. **RPC関数**: SQL Editorで再作成
2. **Storageバケット**: 新規作成して設定を復元

---

## 📊 期待される効果

- ✅ データベースの整理（未使用リソース20個削除）
- ✅ Supabaseコンソールの見通し改善
- ✅ メンテナンス性向上
- ✅ 混乱の防止（重複関数削除）

---

## 🎯 実行タイミング

**推奨**: 今すぐ実行
- すべての情報が揃っている
- クリーンアップの効果が大きい
- 現在の安定した状態で実行するのが安全

---

## 📝 削除実行ログ

### フェーズ1: RPC関数削除
- [x] `get_all_routes_geojson` - 削除日: 2025-11-27
- [x] `get_areas_simple` - 削除日: 2025-11-27
- [x] `get_followers` - 削除日: 2025-11-27
- [x] `get_following` - 削除日: 2025-11-27
- [x] `get_pins_by_route` - 削除日: 2025-11-27
- [x] `get_popular_routes` (重複) - 削除日: 2025-11-27
- [x] `get_route_comparison` - 削除日: 2025-11-27
- [x] `get_route_likers` - 削除日: 2025-11-27
- [x] `get_route_pins_with_likes` - 削除日: 2025-11-27
- [x] `get_walk_photos` - 削除日: 2025-11-27
- [x] `has_liked_route` - 削除日: 2025-11-27
- [x] `is_following` - 削除日: 2025-11-27
- [x] `mark_all_notifications_read` - 削除日: 2025-11-27
- [x] `mark_notification_read` - 削除日: 2025-11-27

### フェーズ2: Storageバケット削除
- [x] ~~`pix_photos`~~ - **スクリーンショット確認の結果、`pin_photos`が正しいバケット名であり、使用中のため削除不要**

### 最終結果
- ✅ RPC関数: 14個削除完了
- ✅ Storageバケット: すべて使用中のため削除なし
  - `walk-photos` - Phase 3実装済み、使用中
  - `pin_photos` - StorageService使用中
  - `dog-photos` - 使用中
  - `profile-avatars` - 使用中

---

## ✅ 完了確認

- [x] すべてのRPC関数を削除（14個）
- [x] Storageバケット確認（削除不要）
- [ ] アプリの動作確認完了
- [ ] Supabaseログ確認完了
- [ ] Git コミット完了

---

**このドキュメントは削除作業の記録として保存されます。**
