# 🔍 WanMap v2 自動診断レポート

**実行日時**: 2025-11-28  
**診断バージョン**: 1.0  
**プロジェクト**: WanMap v2 (Phase 3実装中)

---

## 📊 プロジェクト概要

### コードベース規模
- **総Dartファイル数**: 155ファイル
- **Models**: 23ファイル
- **Providers**: 22ファイル
- **Screens**: 39ファイル
- **Services**: 28ファイル
- **Widgets**: 34ファイル

### 実装状況
- **Phase 1**: ✅ 完了
- **Phase 2**: ✅ 完了
- **Phase 3**: ⚠️ 部分完了（約80%）
- **Phase 4-5**: ✅ 完了

---

## 🔴 **Critical Issues（アプリが動作しない問題）**

### Issue #1: エリア一覧画面がクラッシュ 🔴 **CRITICAL**

**症状**:
```
Exception: Failed to fetch areas: type 'Null' is not a subtype of type 'num' in type cast
```

**根本原因**: 
`get_areas_simple` RPC関数が **latitude と longitude に null を返している**

**影響**: 
- ユーザーが「エリアを探す」をタップするとアプリがクラッシュ
- おでかけ散歩機能が完全に使用不可
- **App Store審査でリジェクト確実**

**発生場所**:
- `lib/screens/outing/area_list_screen.dart`
- `lib/providers/area_provider.dart` (18-19行目)
- `lib/models/area.dart` (28-29行目)

**実際のデータ**:
```json
{
  "id": "12121212-1212-1212-1212-121212121212",
  "name": "井の頭公園",
  "latitude": null,  // ← 問題！
  "longitude": null,  // ← 問題！
  "description": "井の頭公園は吉祥寺の人気公園..."
}
```

**修正方法**:

**Option A: RPC関数を修正（推奨）**
```sql
-- Supabase SQL Editorで実行
CREATE OR REPLACE FUNCTION get_areas_simple()
RETURNS TABLE (
  id UUID,
  name TEXT,
  prefecture TEXT,
  description TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    a.name,
    a.prefecture,
    a.description,
    ST_Y(a.center_location::geometry) AS latitude,
    ST_X(a.center_location::geometry) AS longitude,
    a.created_at
  FROM areas a
  WHERE a.is_active = TRUE
  ORDER BY a.display_order, a.name;
END;
$$ LANGUAGE plpgsql;
```

**Option B: Providerを修正して通常のテーブルクエリを使用**
```dart
// lib/providers/area_provider.dart
final areasProvider = FutureProvider.autoDispose<List<Area>>((ref) async {
  try {
    // RPC関数ではなく、通常のクエリを使用
    final response = await _supabase
        .from('areas')
        .select('id, name, description, prefecture, created_at')
        .eq('is_active', true)
        .order('display_order');
    
    final areas = (response as List).map((json) {
      // center_locationは使用せず、デフォルト座標を設定
      return Area.fromJson({
        ...json,
        'latitude': 35.6762,  // デフォルト（東京）
        'longitude': 139.6503,
      });
    }).toList();
    
    return areas;
  } catch (e, stackTrace) {
    throw Exception('Failed to fetch areas: $e');
  }
});
```

**優先度**: 🔴 **最高（今すぐ修正必須）**

---

## 🟡 **High Priority Issues（主要機能の問題）**

### Issue #2: Pin写真アップロード機能が未完成 🟡 **HIGH**

**現状確認**:
- ✅ `walk-photos` バケット: **存在する**（2025-11-24作成済み）
- ❌ `route-photos` バケット: **存在しない**
- ⚠️ `pin_photos` バケット: **存在する**（pin-photosではなくpin_photos）

**問題点**:
1. Pin投稿画面で写真を選択できるが、実際にはアップロードされない
2. バケット名の不一致: `pin-photos` (コード) vs `pin_photos` (実際)

**影響**:
- Pinの主要機能（写真付き投稿）が動作しない
- ユーザーエクスペリエンスが著しく低下
- **App Store審査で「機能不完全」とみなされる可能性**

**修正方法**:

**Step 1: コードのバケット名を修正**
```dart
// lib/services/photo_service.dart を確認して修正
// 'pin-photos' → 'pin_photos' に変更
```

**Step 2: Pin投稿画面との統合確認**
- `lib/screens/outing/pin_create_screen.dart` を確認
- PhotoServiceが正しく呼び出されているか確認

**優先度**: 🟡 **高（1週間以内に修正推奨）**

---

## 🟢 **Medium/Low Priority Issues（軽微な問題）**

### Issue #3: ホーム画面のスクロール問題 🟢 **MEDIUM**

**現状**:
- `SingleChildScrollView` は実装されている
- `physics: const AlwaysScrollableScrollPhysics()` も設定済み

**推定原因**:
- エリア一覧のエラーでレイアウトが崩れている可能性
- Issue #1を修正すれば自動的に解決する可能性が高い

**優先度**: 🟢 **中（Issue #1修正後に再確認）**

---

### Issue #4: Thunderforest地図タイル 🟢 **LOW**

**現状**:
- 新しいAPIキー `8c3872c0b1d54471a5e0c685ce76e6ff` に更新済み
- `.env` ファイルに設定済み

**確認方法**:
```bash
# APIキーが有効か確認
curl "https://tile.thunderforest.com/outdoors/1/0/0.png?apikey=8c3872c0b1d54471a5e0c685ce76e6ff"
```

**優先度**: 🟢 **低（実機テスト時に確認）**

---

## ✅ **正常に動作している機能**

### Week 3 データ充実作業
- ✅ 箱根エリア: 15本のルート + 30個のPin
- ✅ 横浜エリア: 10本のルート + 11個のPin
- ✅ 鎌倉エリア: 10本のルート + 12個のPin
- ✅ 合計: 35本のルート + 53個のPin

### Phase 1-2 完了機能
- ✅ 認証（サインアップ・ログイン）
- ✅ GPS追跡
- ✅ 散歩記録保存
- ✅ Pin投稿（写真なし）
- ✅ ルート閲覧
- ✅ 地図表示

### Phase 4-5 完了機能
- ✅ バッジシステム（17種類）
- ✅ ソーシャル機能（フォロー・タイムライン）
- ✅ 通知システム
- ✅ ユーザー統計

---

## 🎯 **App Store申請に向けた修正優先順位**

### 🔴 **Phase 1: Critical Fixes（必須修正）**
**期限**: 3日以内

| 優先度 | タスク | 推定時間 | ブロッカー |
|--------|--------|----------|-----------|
| 1 | Issue #1: エリア一覧クラッシュ修正 | 2-4時間 | ✅ Yes |
| 2 | Issue #1の実機テスト | 1時間 | ✅ Yes |

### 🟡 **Phase 2: High Priority Fixes（重要修正）**
**期限**: 1週間以内

| 優先度 | タスク | 推定時間 | ブロッカー |
|--------|--------|----------|-----------|
| 3 | Issue #2: Pin写真アップロード完成 | 4-6時間 | ⚠️ Partial |
| 4 | Issue #2の実機テスト | 2時間 | ⚠️ Partial |
| 5 | Issue #3: ホーム画面スクロール確認 | 1時間 | ❌ No |

### 🟢 **Phase 3: Polish & Testing（仕上げ）**
**期限**: 2週間以内

| 優先度 | タスク | 推定時間 | ブロッカー |
|--------|--------|----------|-----------|
| 6 | 全機能の実機テスト | 8-10時間 | ❌ No |
| 7 | バグ修正 | 4-8時間 | ❌ No |
| 8 | Thunderforest地図確認 | 1時間 | ❌ No |
| 9 | スクリーンショット作成 | 2-3時間 | ❌ No |
| 10 | プライバシーポリシー作成 | 2-4時間 | ❌ No |

---

## 📅 **推奨スケジュール**

```
今日 (11/28):
  └─ Issue #1 エリア一覧クラッシュ修正 → RPC関数修正 (2-4時間)
  
明日 (11/29):
  ├─ Issue #1 実機テスト (1時間)
  └─ Issue #2 Pin写真アップロード調査 (2時間)
  
週末 (11/30-12/1):
  └─ Issue #2 Pin写真アップロード実装 (4-6時間)
  
来週 (12/2-12/8):
  ├─ 全機能実機テスト (8-10時間)
  ├─ バグ修正 (4-8時間)
  └─ App Store準備物作成 (4-6時間)
  
申請目標: 12/10頃
リリース目標: 12/20頃（クリスマス前）
```

---

## 🚨 **App Store申請ブロッカー**

### ❌ **現在申請不可の理由**

1. **Issue #1**: エリア一覧がクラッシュ → **Critical**
   - Appleリジェクト理由: 2.1 App Completeness

2. **Issue #2**: Pin写真アップロードが未完成 → **High**
   - Appleリジェクト理由: 4.2 Minimum Functionality

### ✅ **申請可能になる条件**

- ✅ Issue #1を修正し、実機テストで動作確認
- ✅ Issue #2を修正し、実機テストで動作確認
- ✅ 最低10時間の実機テスト完了
- ✅ クラッシュゼロを確認
- ✅ スクリーンショット・説明文準備完了

---

## 💡 **次のアクション**

### 🔴 **今すぐやるべきこと**

**Option A: RPC関数修正（推奨・30分）**
```sql
-- Supabase SQL Editorで以下を実行
CREATE OR REPLACE FUNCTION get_areas_simple()
RETURNS TABLE (
  id UUID,
  name TEXT,
  prefecture TEXT,
  description TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    a.name,
    a.prefecture,
    a.description,
    ST_Y(a.center_location::geometry) AS latitude,
    ST_X(a.center_location::geometry) AS longitude,
    a.created_at
  FROM areas a
  WHERE a.is_active = TRUE
  ORDER BY a.display_order, a.name;
END;
$$ LANGUAGE plpgsql;
```

**Option B: Flutter Provider修正（1時間）**
- `lib/providers/area_provider.dart` を修正
- RPC関数を使わず通常のクエリに変更

---

## 📊 **完成度評価**

| カテゴリ | 完成度 | 評価 |
|---------|--------|------|
| 認証機能 | 100% | ✅ 完璧 |
| GPS・散歩記録 | 95% | ✅ ほぼ完成 |
| エリア・ルート閲覧 | **60%** | ❌ **Critical Issue** |
| Pin投稿機能 | 75% | ⚠️ 写真アップロード未完成 |
| ソーシャル機能 | 100% | ✅ 完璧 |
| バッジシステム | 100% | ✅ 完璧 |
| データ充実 | 100% | ✅ 完璧 |
| **総合完成度** | **82%** | ⚠️ **あと2-3週間必要** |

---

## 🎯 **結論**

### **現状**: App Store申請には**まだ早い**

**理由**:
1. エリア一覧がクラッシュする（Critical）
2. Pin写真アップロードが未完成（High）

### **推奨**: 2-3週間後に申請

**修正スケジュール**:
- **今週**: Critical Issues修正（Issue #1, #2）
- **来週**: 実機テスト + バグ修正
- **再来週**: App Store準備
- **12月中旬**: 申請
- **12月下旬**: リリース 🎉

---

**レポート作成日**: 2025-11-28  
**次回診断推奨日**: Issue #1修正後
