# 包括的デバッグ＆実装チェックリスト

## 📋 このスレッドで実装した機能

### 1. 公開/非公開ルート選択機能
### 2. 公開ルート画面の大幅改善（Phase 1-4）
### 3. macOS vs iOS機能検証

---

## 🔍 機能1: 公開/非公開ルート選択

### 実装内容
- ルート保存時に公開/非公開を選択可能
- デフォルトは非公開
- 編集画面でも切り替え可能

### チェック項目

#### ✅ GPSService
- [ ] `stopRecording()`に`isPublic`パラメータが存在
- [ ] デフォルト値が`false`
- [ ] RouteModel作成時に`isPublic`を渡している

#### ✅ MapScreen（保存ダイアログ）
- [ ] `StatefulBuilder`を使用
- [ ] `isPublic`変数の初期化（false）
- [ ] `SwitchListTile`の実装
- [ ] トグルの動作（onChanged）
- [ ] `stopRecording()`に`isPublic`を渡している

#### ✅ RouteEditScreen
- [ ] 既存の公開設定トグルが維持されている
- [ ] `_isPublic`変数の初期化
- [ ] データベース更新時に`isPublic`を送信

---

## 🔍 機能2: 公開ルート画面改善

### Phase 1: データベース＆モデル

#### ✅ データベーススキーマ
```sql
-- チェック項目
✓ area VARCHAR(50) カラム追加
✓ prefecture VARCHAR(50) カラム追加
✓ thumbnail_url TEXT カラム追加
✓ idx_routes_area インデックス作成
✓ idx_routes_prefecture インデックス作成
```

#### ✅ AreaInfo モデル
- [ ] 6エリアの定義（箱根、伊豆、那須、軽井沢、富士、鎌倉）
- [ ] 各エリアの`center`座標
- [ ] 各エリアの`bounds`座標
- [ ] `getById()`メソッド
- [ ] `detectAreaFromCoordinate()`メソッド

#### ✅ RouteModel 拡張
- [ ] `area`フィールド追加
- [ ] `prefecture`フィールド追加
- [ ] `thumbnailUrl`フィールド追加
- [ ] `fromJson()`で3フィールドをパース
- [ ] `toJson()`で3フィールドをシリアライズ

### Phase 2: 写真付きルートカード

#### ✅ PhotoRouteCard ウィジェット
- [ ] 150x150pxのサムネイル表示
- [ ] 公開バッジ表示
- [ ] エリアバッジ表示（絵文字付き）
- [ ] タイトル、都道府県表示
- [ ] 距離、時間、日付表示
- [ ] 写真なし時のプレースホルダー（犬アイコン）
- [ ] `onTap`コールバック動作

### Phase 3: マップビュー

#### ✅ PublicRoutesMapView ウィジェット
- [ ] FlutterMap統合
- [ ] 複数ルートの同時表示
- [ ] 異なる色のポリライン（8色）
- [ ] ルートマーカー表示
- [ ] マーカータップでのナビゲーション
- [ ] 展開/折りたたみ機能（250px ⇔ 400px）
- [ ] 自動範囲フィット（fitCamera）
- [ ] ダークモード対応
- [ ] 空の状態の表示

### Phase 4: エリア選択＆フィルタリング

#### ✅ AreaSelectionChips ウィジェット
- [ ] 横スクロール対応
- [ ] 「全て」チップ
- [ ] 6エリアチップ
- [ ] 選択状態のハイライト
- [ ] `onAreaSelected`コールバック

#### ✅ RouteService 拡張
- [ ] `getPublicRoutes()`に`area`パラメータ追加
- [ ] エリアフィルタリングのクエリ実装
- [ ] `area`, `prefecture`, `thumbnailUrl`のパース

#### ✅ PublicRoutesScreen（新版）
- [ ] `selectedAreaProvider`の実装
- [ ] `filteredPublicRoutesProvider`の実装
- [ ] CustomScrollViewの使用
- [ ] AreaSelectionChipsの配置
- [ ] PublicRoutesMapViewの配置
- [ ] PhotoRouteCardのリスト表示
- [ ] RefreshIndicator実装
- [ ] 空の状態表示
- [ ] エラー状態表示

---

## 🐛 デバッグ実行

### ステップ1: ファイル存在確認
