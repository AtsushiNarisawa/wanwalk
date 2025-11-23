# 🚨 ナビゲーション問題と修正案

## 📋 検証結果サマリー

### ✅ 実装は正しい
- HomeScreen: WalkModeSwitcherを正しく配置 ✅
- WalkModeSwitcher: 実装済み、動作するはず ✅
- WalkModeProvider: 正しく実装 ✅
- WalkMode model: 正しく実装 ✅

### 🚨 ユーザー報告の問題
**「モード切り替えボタンがない」**

---

## 🔍 原因分析

### 可能性1: WalkModeSwitcherの視認性問題 ⚠️ 最有力

**仮説**: WalkModeSwitcherが存在するが、視覚的に目立たない

**理由**:
1. **スクロール位置**: ヘッダー直下にあるため、少しスクロールすると見えなくなる
2. **色の問題**: isDarkモードでグレー系背景、認識しにくい
3. **サイズの問題**: 現在の実装は控えめなデザイン

**証拠**:
```dart
// walk_mode_switcher.dart line 19-34
Container(
  margin: const EdgeInsets.symmetric(
    horizontal: WanMapSpacing.lg,  // 水平マージン
    vertical: WanMapSpacing.md,    // 垂直マージン
  ),
  decoration: BoxDecoration(
    color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
    // ↑ ダークモードだと背景に溶け込む可能性
  ),
```

---

### 可能性2: ユーザーのスクロール状態

**仮説**: ユーザーが下にスクロールしていて、WalkModeSwitcherが画面外

**理由**:
- HomeScreenは `CustomScrollView` を使用
- SliverAppBarは `floating: true` なので上にスクロールで戻る
- しかしWalkModeSwitcherは `SliverToBoxAdapter` なので固定ではない

---

### 可能性3: 色設定の問題

**確認が必要**:
```dart
WanMapColors.cardDark の実際の色
WanMapColors.cardLight の実際の色
WanMapColors.accent の実際の色
```

---

## 🎯 修正案

### 修正1: WalkModeSwitcherを常に表示（SliverPersistentHeaderに変更）

**目的**: スクロールしても常にヘッダー下に表示

**実装**:
```dart
// home_screen.dart を修正
SliverPersistentHeader(
  pinned: true,  // 常に表示
  delegate: _WalkModeSwitcherDelegate(
    child: const WalkModeSwitcher(),
  ),
)
```

**メリット**:
- ✅ スクロールしても見える
- ✅ ユーザーがいつでもモード切り替え可能

**デメリット**:
- ❌ 画面の表示領域が減る

---

### 修正2: WalkModeSwitcherのデザイン改善

**目的**: より目立つデザインに変更

**変更点**:
1. **サイズを大きく**: padding, font sizeを増加
2. **色をはっきりと**: accentカラーを強調
3. **影を追加**: より浮き上がる印象
4. **アニメーション追加**: 注目を集める

**実装**:
```dart
// walk_mode_switcher.dart を修正
decoration: BoxDecoration(
  color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(  // ← 追加
    color: WanMapColors.accent.withOpacity(0.3),
    width: 2,
  ),
  boxShadow: [  // ← 強化
    BoxShadow(
      color: WanMapColors.accent.withOpacity(0.2),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ],
),
```

---

### 修正3: ボトムナビゲーションバーの追加（根本的解決）

**目的**: 主要機能に常にアクセス可能に

**実装**:
```dart
Scaffold(
  body: ...,
  bottomNavigationBar: BottomNavigationBar(
    items: [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: '日常',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.explore),
        label: 'おでかけ',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.emoji_events),
        label: 'バッジ',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart),
        label: '統計',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'プロフィール',
      ),
    ],
    onTap: (index) {
      // モード切り替えやナビゲーション
    },
  ),
)
```

**メリット**:
- ✅ iOS/Androidアプリの標準的なUI
- ✅ ユーザーが迷わない
- ✅ 主要機能に素早くアクセス

**デメリット**:
- ❌ 画面の表示領域が減る
- ❌ 既存のUIから大きく変更

---

## 📊 重複画面の統合計画

### 1. route_detail_screen.dart

**現状**:
- `/screens/outing/route_detail_screen.dart`
- `/screens/routes/route_detail_screen.dart`

**調査が必要**:
1. どちらが使われているか
2. 内容に差異があるか
3. インポート元の確認

**推奨アクション**:
- 使用されている方を特定
- 未使用の方を削除
- インポートパスを統一

---

### 2. statistics_dashboard_screen.dart

**現状**:
- `/screens/profile/statistics_dashboard_screen.dart` ← 使用中
- `/screens/statistics/statistics_dashboard_screen.dart`

**調査結果**:
- `profile/` の方が使われている（BadgeListScreen, ProfileScreen からインポート）
- `statistics/` の方は未使用の可能性

**推奨アクション**:
1. `statistics/` の方を削除
2. 全インポートパスを `profile/` に統一

---

### 3. route_search_screen.dart

**現状**:
- `/screens/search/route_search_screen.dart`
- `/screens/routes/route_search_screen.dart`

**推奨アクション**:
- 使用状況を確認
- 未使用の方を削除

---

## 🎯 優先度付き修正計画

### 🔴 最優先（すぐ実施）

#### 1. WalkModeSwitcherの視認性向上
```
目的: ユーザーがモード切り替えボタンを見つけられるように
方法: デザイン改善（サイズ、色、影、枠線）
所要時間: 15分
```

#### 2. ユーザーへのヒアリング
```
質問:
- HomeScreenは表示されていますか？
- 「WanMap」ロゴは見えますか？
- プロフィールアイコンは見えますか？
- ヘッダー直下に何が表示されていますか？
- スクリーンショットを共有してもらう
```

---

### 🟡 中優先（今週中）

#### 3. 重複画面の統合
```
対象:
- route_detail_screen.dart
- statistics_dashboard_screen.dart
- route_search_screen.dart

所要時間: 1時間
```

#### 4. 未使用画面の削除
```
調査:
- 45画面の使用状況確認
- Phase別の整理
- 未使用画面の特定と削除

所要時間: 2時間
```

---

### 🟢 低優先（将来的に）

#### 5. ボトムナビゲーションバーの追加
```
理由: 大きなUI変更のため、慎重に検討
所要時間: 3時間
```

#### 6. ナビゲーション階層の最適化
```
理由: アプリ全体の設計見直し
所要時間: 4時間
```

---

## 🔧 即時実施する修正

### WalkModeSwitcherの視認性向上

**ファイル**: `/home/user/webapp/wanmap_v2/lib/widgets/walk_mode_switcher.dart`

**変更内容**:
1. 枠線を追加（accentカラー）
2. 影を強化
3. marginを調整

**期待される効果**:
- ユーザーがモード切り替えボタンを見つけやすくなる
- より目立つデザイン

---

## 📸 ユーザーへの確認事項

### スクリーンショットのリクエスト

**確認したい画面**:
1. **HomeScreen全体** - WalkModeSwitcherが表示されているか
2. **ヘッダー直下の領域** - 何が表示されているか
3. **スクロール後** - WalkModeSwitcherが消えるか

### 質問事項

1. **HomeScreenは表示されていますか？**
   - 「WanMap」ロゴが上部に表示されている画面

2. **プロフィールアイコン（人型）は右上に見えますか？**

3. **ヘッダーの下に、何か切り替えボタンのようなものは見えますか？**

4. **現在表示されているのは：**
   - [ ] オレンジ色の「おはよう！」カード
   - [ ] 青色の「おでかけ散歩」カード
   - [ ] その他

5. **画面を一番上までスクロールすると、何が見えますか？**

---

**作成日時**: 2025-11-23
**次のステップ**: WalkModeSwitcherの視認性向上を実施
