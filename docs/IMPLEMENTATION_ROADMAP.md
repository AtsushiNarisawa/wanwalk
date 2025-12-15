# WanMap アプリ再設計 - 実装ロードマップ

## 📋 決定事項

### ユーザー要望に基づく最終方針
1. **タブ名称**: 「ホーム」を採用
2. **散歩タイプ選択**: FAB（途中切り替え可能）
3. **ピン投稿タイミング**: いつでも投稿可能
4. **スポット評価**: ピン詳細画面に統合

---

## 🎯 実装の全体像

### 大きな変更の流れ
```
Phase 1: タブの再編成
  ↓
Phase 2: MAP タブの強化（散歩タイプ選択）
  ↓
Phase 3: ピン詳細画面の統合（評価＋コメント）
  ↓
Phase 4: ホームタブの発見機能強化
  ↓
Phase 5: 最終調整＆テスト
```

---

## 📊 Phase 1: タブの再編成

### 目的
タブの名称と役割を明確化し、基盤を整える

### 実装ステップ

#### **Step 1.1: ファイルのリネーム**
```bash
# タブファイルのリネーム
lib/screens/main/tabs/home_tab.dart → home_tab.dart (名称変更なし)
lib/screens/main/tabs/records_tab.dart → library_tab.dart

# インポート文の一括更新
- records_tab → library_tab (全ファイル)
```

**影響範囲:**
- `lib/screens/main/main_screen.dart` - インポート文
- 全ての画面で `RecordsTab` を参照している箇所

**所要時間:** 15分

---

#### **Step 1.2: タブアイコンの変更**
```dart
// main_screen.dart
BottomNavigationBarItem(
  icon: Icon(Icons.home_outlined, size: 28),
  activeIcon: Icon(Icons.home, size: 28),
  label: 'ホーム',  // 変更なし
),
BottomNavigationBarItem(
  icon: Icon(Icons.map_outlined, size: 28),
  activeIcon: Icon(Icons.map, size: 28),
  label: 'マップ',  // 変更なし
),
BottomNavigationBarItem(
  icon: Icon(Icons.history, size: 28),  // NEW: collections → history
  activeIcon: Icon(Icons.history, size: 28),
  label: 'ライブラリ',  // 変更なし
),
BottomNavigationBarItem(
  icon: Icon(Icons.person_outline, size: 28),
  activeIcon: Icon(Icons.person, size: 28),
  label: 'プロフィール',  // 変更なし
),
```

**所要時間:** 5分

---

#### **Step 1.3: library_tab.dartの内容調整**
```dart
/// LibraryTab - 思い出と履歴の振り返り
/// 
/// 構成:
/// 1. コンパクトヘッダー（レベル、総距離、エリア数）
/// 2. 今週の統計（1行）
/// 3. タブ切り替え（全て/お出かけ/日常）
/// 4. 最近の散歩リスト
/// 5. ピン投稿履歴セクション（新規追加）
/// 6. 統計詳細リンク
```

**変更内容:**
- クラス名: `RecordsTab` → `LibraryTab`
- ヘッダーテキスト: 「ライブラリ」
- コメント文の更新

**所要時間:** 10分

---

#### **Step 1.4: ビルド＆動作確認**
- [ ] ビルドエラーがないことを確認
- [ ] 4つのタブが正常に表示されることを確認
- [ ] タブ切り替えが正常に動作することを確認

**所要時間:** 10分

---

### Phase 1 完了条件
- ✅ ファイル名が正しくリネームされている
- ✅ インポート文が全て更新されている
- ✅ タブアイコンが変更されている
- ✅ ビルドエラーがない
- ✅ アプリが正常に動作する

**Phase 1 総所要時間:** 約40分

---

## 📊 Phase 2: MAP タブの強化（散歩タイプ選択）

### 目的
FABから3種類の散歩開始＋ピン投稿を選択可能にする

### 実装ステップ

#### **Step 2.1: 散歩タイプ選択ボトムシート作成**
```dart
// lib/widgets/walk_type_bottom_sheet.dart (新規作成)
class WalkTypeBottomSheet extends StatelessWidget {
  // 4つの選択肢を表示
  // 1. お出かけ散歩（公式コース）
  // 2. 日常散歩（フリー）
  // 3. ピン投稿のみ
  // 4. キャンセル
}
```

**デザイン:**
```
┌─────────────────────────┐
│  散歩の種類を選択        │
├─────────────────────────┤
│  🏃 お出かけ散歩         │
│  公式コースを利用        │
├─────────────────────────┤
│  🚶 日常散歩             │
│  自由に記録              │
├─────────────────────────┤
│  📍 ピン投稿             │
│  散歩記録なし            │
├─────────────────────────┤
│  キャンセル              │
└─────────────────────────┘
```

**所要時間:** 30分

---

#### **Step 2.2: map_tab.dartのFAB処理を変更**
```dart
// 現在: 直接 WalkingScreen に遷移
floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    // 直接遷移
  },
)

// 変更後: ボトムシートを表示
floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    _showWalkTypeBottomSheet(context);
  },
)

void _showWalkTypeBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => WalkTypeBottomSheet(
      onTypeSelected: (type) {
        switch (type) {
          case WalkType.outing:
            // お出かけ散歩開始
            Navigator.push(...);
            break;
          case WalkType.daily:
            // 日常散歩開始
            Navigator.push(...);
            break;
          case WalkType.pinOnly:
            // ピン投稿画面へ
            Navigator.push(...);
            break;
        }
      },
    ),
  );
}
```

**所要時間:** 20分

---

#### **Step 2.3: ピン投稿専用画面の作成**
```dart
// lib/screens/pin/pin_create_screen.dart (新規作成)
class PinCreateScreen extends ConsumerStatefulWidget {
  // 散歩記録なしでピンのみ投稿
  // 写真、タイトル、説明、場所、タグ
  // スポット評価（任意）
}
```

**所要時間:** 60分

---

#### **Step 2.4: 散歩中のタイプ切り替え機能**
```dart
// walking_screen.dart / daily_walking_screen.dart
// 散歩中にボトムシートを表示して切り替え可能に
AppBar(
  actions: [
    IconButton(
      icon: Icon(Icons.swap_horiz),
      onPressed: () {
        _showWalkTypeSwitchSheet(context);
      },
    ),
  ],
)
```

**所要時間:** 30分

---

#### **Step 2.5: ビルド＆動作確認**
- [ ] FABをタップするとボトムシートが表示される
- [ ] お出かけ散歩を選択すると `walking_screen.dart` に遷移
- [ ] 日常散歩を選択すると `daily_walking_screen.dart` に遷移
- [ ] ピン投稿を選択すると `pin_create_screen.dart` に遷移
- [ ] 散歩中にタイプ切り替えができる

**所要時間:** 20分

---

### Phase 2 完了条件
- ✅ ボトムシートが実装されている
- ✅ FABから3種類の散歩＋ピン投稿が選択可能
- ✅ ピン投稿専用画面が実装されている
- ✅ 散歩中のタイプ切り替えが可能
- ✅ ビルドエラーがない

**Phase 2 総所要時間:** 約2.5時間

---

## 📊 Phase 3: ピン詳細画面の統合（評価＋コメント）

### 目的
ピン詳細画面にスポット評価とコメントを統合する

### 実装ステップ

#### **Step 3.1: 現状分析**
```
現在のピン詳細画面 (pin_detail_screen.dart):
- 写真ギャラリー
- 基本情報（タイトル、説明、場所）
- 統計情報
- 位置マップ
- スポット評価セクション (NEW)
- みんなのコメントセクション
```

**確認事項:**
- スポット評価セクションは既に実装済み
- コメントセクションも実装済み
- 統合作業は不要？

**所要時間:** 10分（確認のみ）

---

#### **Step 3.2: UIの調整（必要に応じて）**
```dart
// セクション間の区切りを明確に
Column(
  children: [
    _buildPhotoGallery(...),
    Divider(),
    _buildBasicInfo(...),
    Divider(),
    _buildLocationMap(...),
    Divider(),
    _buildReviewsSection(...),  // スポット評価
    Divider(),
    _buildCommentsSection(...),  // コメント
  ],
)
```

**所要時間:** 20分

---

#### **Step 3.3: セクションヘッダーの改善**
```dart
// スポット評価セクション
Row(
  children: [
    Icon(Icons.star, color: Colors.amber),
    SizedBox(width: 8),
    Text('スポット評価', style: headlineSmall),
    Spacer(),
    Text('平均★4.5 (3件)', style: bodySmall),
  ],
)

// コメントセクション
Row(
  children: [
    Icon(Icons.chat_bubble_outline),
    SizedBox(width: 8),
    Text('みんなのコメント', style: headlineSmall),
    Spacer(),
    Text('(5)', style: bodySmall),
  ],
)
```

**所要時間:** 15分

---

#### **Step 3.4: ビルド＆動作確認**
- [ ] ピン詳細画面が正常に表示される
- [ ] スポット評価セクションが表示される
- [ ] コメントセクションが表示される
- [ ] セクション間の区切りが明確

**所要時間:** 10分

---

### Phase 3 完了条件
- ✅ ピン詳細画面が整理されている
- ✅ スポット評価とコメントが明確に区別されている
- ✅ UI/UXが改善されている
- ✅ ビルドエラーがない

**Phase 3 総所要時間:** 約1時間

---

## 📊 Phase 4: ホームタブの発見機能強化

### 目的
ホームタブを「発見」に特化し、ユーザーがコースやスポットを見つけやすくする

### 実装ステップ

#### **Step 4.1: 現状のhome_tab.dartの内容確認**
```
現在の構成:
1. MAP表示（200px、最新ピン投稿中心）
2. 最新の写真付きピン投稿（横2枚）
3. 今月の人気ルート
4. おすすめエリア（3枚 + 一覧を見るボタン）
```

**方針:**
- 基本構成は維持
- セクション順序の最適化
- 各セクションのUIブラッシュアップ

**所要時間:** 10分（確認のみ）

---

#### **Step 4.2: セクション順序の最適化**
```dart
// 推奨順序
Column(
  children: [
    _buildAreaSelector(),        // エリアから探す
    _buildOfficialRoutes(),      // 公式コース
    _buildLatestPins(),          // 最新ピン投稿
    _buildRecommendedSpots(),    // おすすめスポット (NEW)
    _buildPopularRoutes(),       // 人気ルート
  ],
)
```

**所要時間:** 30分

---

#### **Step 4.3: おすすめスポットセクション追加**
```dart
Widget _buildRecommendedSpots() {
  // spot_reviews から高評価スポットを取得
  final topSpots = ref.watch(topRatedSpotIdsProvider);
  
  return Column(
    children: [
      SectionHeader(
        title: 'おすすめスポット',
        onSeeAllTap: () {
          Navigator.push(...);
        },
      ),
      topSpots.when(
        data: (spots) => ListView.builder(...),
        loading: () => CircularProgressIndicator(),
        error: (e, _) => ErrorWidget(),
      ),
    ],
  );
}
```

**所要時間:** 45分

---

#### **Step 4.4: 各セクションのUIブラッシュアップ**
- 公式コースカードのデザイン改善
- ピン投稿カードのデザイン改善
- エリアセレクターのデザイン改善

**所要時間:** 60分

---

#### **Step 4.5: ビルド＆動作確認**
- [ ] ホームタブが正常に表示される
- [ ] 各セクションが適切な順序で表示される
- [ ] おすすめスポットセクションが表示される
- [ ] タップ操作が正常に動作する

**所要時間:** 15分

---

### Phase 4 完了条件
- ✅ ホームタブが「発見」に特化している
- ✅ おすすめスポットセクションが追加されている
- ✅ UI/UXが改善されている
- ✅ ビルドエラーがない

**Phase 4 総所要時間:** 約2.5時間

---

## 📊 Phase 5: 最終調整＆テスト

### 目的
全体の動作確認とバグ修正

### 実装ステップ

#### **Step 5.1: 全画面の動作確認**
- [ ] ホームタブ → 各セクションが正常に表示
- [ ] マップタブ → FABから散歩開始・ピン投稿が可能
- [ ] ライブラリタブ → 散歩履歴とピン履歴が表示
- [ ] プロフィールタブ → 現状維持

**所要時間:** 30分

---

#### **Step 5.2: ナビゲーションフローのテスト**
```
シナリオ1: 公式コースを見つけて散歩開始
ホーム → 公式コース → コース詳細 → マップで見る → 散歩開始

シナリオ2: ピン投稿のみ
マップ → FAB → ピン投稿のみ → 写真撮影 → 投稿完了

シナリオ3: 散歩中にピン投稿
マップ → FAB → お出かけ散歩 → 散歩中 → ピン投稿 → 散歩継続

シナリオ4: 過去の散歩を振り返る
ライブラリ → 散歩履歴 → 詳細表示 → ピン確認
```

**所要時間:** 45分

---

#### **Step 5.3: バグ修正**
- 発見されたバグを修正
- エッジケースの対応
- エラーハンドリングの改善

**所要時間:** 60分（バグの数による）

---

#### **Step 5.4: パフォーマンステスト**
- [ ] 画面遷移がスムーズ
- [ ] 画像読み込みが高速
- [ ] データ取得が効率的
- [ ] メモリリークがない

**所要時間:** 30分

---

#### **Step 5.5: ドキュメント更新**
- README.md の更新
- 変更履歴の記録
- 既知の問題の記録

**所要時間:** 20分

---

### Phase 5 完了条件
- ✅ 全画面が正常に動作
- ✅ ナビゲーションフローがスムーズ
- ✅ 致命的なバグがない
- ✅ パフォーマンスが良好
- ✅ ドキュメントが更新されている

**Phase 5 総所要時間:** 約3時間

---

## 📈 総合スケジュール

| Phase | 内容 | 所要時間 | 優先度 |
|-------|------|----------|--------|
| Phase 1 | タブの再編成 | 40分 | 🔴 高 |
| Phase 2 | MAP タブの強化 | 2.5時間 | 🔴 高 |
| Phase 3 | ピン詳細画面の統合 | 1時間 | 🟡 中 |
| Phase 4 | ホーム機能強化 | 2.5時間 | 🟡 中 |
| Phase 5 | 最終調整＆テスト | 3時間 | 🔴 高 |
| **合計** | | **約10時間** | |

---

## 🎯 推奨実装順序

### オプション A: 段階的実装（推奨）
```
Day 1: Phase 1 (40分)
Day 2: Phase 2 (2.5時間)
Day 3: Phase 3 (1時間) + Phase 4 前半 (1時間)
Day 4: Phase 4 後半 (1.5時間) + Phase 5 (3時間)
```

### オプション B: 集中実装
```
一気に Phase 1 → 2 → 3 → 4 → 5 (10時間)
※ バグ修正時間を考慮して12時間確保推奨
```

---

## ✅ 各Phaseの開始前チェックリスト

### Phase 1 開始前
- [ ] 現在のコードがGitにコミット済み
- [ ] バックアップ作成済み（ProjectBackup）
- [ ] テストデバイス準備済み

### Phase 2 開始前
- [ ] Phase 1 が完全に完了
- [ ] ビルドエラーがない
- [ ] Git にコミット済み

### Phase 3 開始前
- [ ] Phase 2 が完全に完了
- [ ] 散歩タイプ選択が正常に動作
- [ ] Git にコミット済み

### Phase 4 開始前
- [ ] Phase 3 が完全に完了
- [ ] ピン詳細画面が正常に表示
- [ ] Git にコミット済み

### Phase 5 開始前
- [ ] Phase 1-4 が全て完了
- [ ] 主要機能が動作
- [ ] Git にコミット済み

---

## 🚨 リスク管理

### 高リスク項目
1. **ファイルリネーム** (Phase 1)
   - リスク: インポート文の更新漏れ
   - 対策: grep で全ファイル検索して確認

2. **散歩タイプ切り替え** (Phase 2)
   - リスク: 状態管理が複雑化
   - 対策: Provider の設計を事前に確認

3. **データ整合性** (Phase 3)
   - リスク: 既存データとの互換性
   - 対策: データ移行スクリプトの準備

### 低リスク項目
- UI の微調整
- アイコンの変更
- テキストの修正

---

## 📝 次のアクション

どのPhaseから開始しますか？

1. **Phase 1: タブの再編成** （最も基盤となる、40分）
2. **Phase 2: MAP タブの強化** （ユーザー体験向上、2.5時間）
3. **Phase 3: ピン詳細画面の統合** （既に実装済みの可能性、1時間）
4. **全Phase一気に実装** （10時間、集中作業）

ご指示をお願いします！ 🚀
