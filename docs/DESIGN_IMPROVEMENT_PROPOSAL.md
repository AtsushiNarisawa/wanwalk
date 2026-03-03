# WanWalk UI Design Improvement Proposal
# shadcn/ui ベースのアプローチ

**作成日**: 2026-03-02  
**対象**: WanWalk Flutter モバイルアプリ  
**参考**: 管理画面での shadcn/ui (Next.js) 導入実績

---

## 1. 背景と目的

### 管理画面との統一性
管理画面では Next.js + shadcn/ui (Radix UI + Tailwind) を採用済み（コミット `c38c902`）。
モバイルアプリにも同じデザイン言語を導入し、**プロダクト全体の統一感**を実現したい。

### 現状の課題

| 課題 | 詳細 | 影響度 |
|------|------|--------|
| 共通ウィジェット未活用 | `wanmap_widgets.dart` 系が screens で **2箇所しか** import されていない | 高 |
| isDark 分散チェック | screens 内に **1,025箇所** の `isDark`/`Theme.of` 直接参照 | 高 |
| WanMapColors 直接参照 | screens 内に **857箇所** の `WanMapColors.xxx` ハードコード | 高 |
| ダークテーマ未完成 | `darkTheme` にカード/ボタン/入力のスタイル未定義（コメント「その他のテーマ設定はライトテーマと同様...」） | 中 |
| アクセントカラーの視認性 | `#A8B5A0`（ソフトグリーン）は CTA として弱い | 中 |
| 画面ファイルの巨大化 | `home_tab.dart` 1,715行、`route_detail_screen.dart` 1,897行（private widget 内包） | 中 |

---

## 2. Flutter 向け shadcn パッケージ比較

### 2-A. `shadcn_ui` (by nank1ro)
- **pub.dev**: https://pub.dev/packages/shadcn_ui
- **ドキュメント**: https://mariuti.com/flutter-shadcn-ui/
- **コンポーネント数**: 約40+
- **特徴**: MaterialApp の上に被せて使える、カスタマイズ性重視
- **スタイル**: Default style（Web の shadcn/ui に近い）
- **利点**: 既存 MaterialApp をそのまま維持して段階的に導入可能

### 2-B. `shadcn_flutter` (by sunarya-thito)
- **pub.dev**: https://pub.dev/packages/shadcn_flutter
- **ドキュメント**: https://sunarya-thito.github.io/shadcn_flutter/
- **コンポーネント数**: 84+
- **特徴**: 独立エコシステム（Material/Cupertino 不要）、New York スタイル
- **スタイル**: New York style（より洗練・角丸小）
- **利点**: GoRouter 対応、LLM 用リファレンス (`llms-full.txt`) 提供

### 推奨: **`shadcn_ui`** (段階的移行に最適)

| 比較項目 | shadcn_ui | shadcn_flutter |
|----------|-----------|----------------|
| 既存 MaterialApp との互換 | **完全互換** | ShadcnApp 推奨 |
| 移行リスク | **低** | 中〜高 |
| コンポーネント数 | 40+ | 84+ |
| Riverpod 共存 | **問題なし** | 問題なし |
| flutter_map 共存 | **問題なし** | 要検証 |
| 段階的導入 | **画面単位で可能** | 可能だがやや複雑 |

**理由**: WanWalk は既に MaterialApp + Riverpod + flutter_map という構成が確立しており、shadcn_ui なら既存コードを壊さずに**1画面ずつ**コンポーネントを置換できます。

---

## 3. 導入アプローチ

### Phase 1: 基盤整備（1日）

#### 1-1. パッケージ追加
```yaml
# pubspec.yaml に追加
dependencies:
  shadcn_ui: ^0.x.x  # 最新安定版
```

#### 1-2. テーマトークンの統合
現在の `WanMapColors` / `WanMapTypography` / `WanMapSpacing` を
shadcn_ui のテーマシステムと統合するブリッジレイヤーを作成。

```dart
// lib/config/wanwalk_shadcn_theme.dart
import 'package:shadcn_ui/shadcn_ui.dart';
import 'wanmap_colors.dart';

/// WanWalk ブランドカラーで shadcn テーマを構築
class WanWalkShadcnTheme {
  static ShadThemeData get light => ShadThemeData(
    brightness: Brightness.light,
    colorScheme: ShadColorScheme.fromName(
      'zinc', // ベース: ニュートラル
      // primary を WanWalk ブランドカラーでオーバーライド
    ),
    // WanWalk 既存のタイポグラフィを維持
  );
}
```

#### 1-3. カラーパレットの改善
管理画面と統一した配色に更新：

| 用途 | 現在 | 提案 | 理由 |
|------|------|------|------|
| Primary | `#8B6F47` (wood-brown) | `#8B6F47` **維持** | ブランドカラー |
| CTA/Accent | `#A8B5A0` (soft-green) | `#E67E22` (warm-orange) | 管理画面と統一、視認性向上 |
| Secondary | `#D4A574` (golden-brown) | `#D4A574` **維持** | 温かみ |
| Destructive | `#C17B6B` (terracotta) | `#EF4444` (red-500) | shadcn 標準に近づける |
| Muted BG | `#F5F1E8` (DogHub beige) | `#F5F1E8` **維持** | ブランドらしさ |

### Phase 2: コアコンポーネント置換（2-3日）

shadcn_ui コンポーネントで既存ウィジェットを段階的に置き換え:

#### 置換マッピング

| 現在の WanMap ウィジェット | shadcn_ui コンポーネント | 優先度 |
|---------------------------|------------------------|--------|
| `WanMapButton` | `ShadButton` (primary/secondary/outline/ghost) | **高** |
| `WanMapCard` / `WanMapHeroCard` | `ShadCard` | **高** |
| `WanMapTextField` | `ShadInput` / `ShadTextArea` | **高** |
| `WanMapSearchField` | `ShadInput` + search icon | **高** |
| 自前 `Chip` | `ShadBadge` | 中 |
| `AlertDialog` (Material) | `ShadDialog` / `ShadAlertDialog` | 中 |
| `BottomSheet` (Material) | `ShadSheet` | 中 |
| `showSnackBar` | `ShadToast` / `ShadSonner` | 中 |
| 自前 `Switch` | `ShadSwitch` | 低 |
| 自前 `Checkbox` | `ShadCheckbox` | 低 |
| `CircularProgressIndicator` | `ShadProgress` | 低 |
| 自前 `Tabs` | `ShadTabs` | 低 |

### Phase 3: 画面リファクタリング（3-5日）

優先度の高い画面から順に:

#### 3-1. ホーム画面 (`home_tab.dart`, 1,715行)
- セクションを独立ウィジェットに分離
- `ShadCard` ベースのルートカード、エリアカード
- `ShadBadge` でタグ表示
- ヒーローセクションにカルーセル追加

#### 3-2. ルート詳細画面 (`route_detail_screen.dart`, 1,897行)
- `ShadCard` でスポットカード
- `ShadTabs` で情報/レビュー/アクセスのタブ切替
- `ShadBadge` で難易度表示
- `ShadButton` でアクションボタン

#### 3-3. プロフィール画面 (`profile_tab.dart`, 626行)
- `ShadAvatar` でユーザーアイコン
- `ShadCard` で統計カード
- `ShadSeparator` でセクション区切り

#### 3-4. 散歩タブ（bottom sheet → `ShadSheet` or full screen）
- モーダルシートを `ShadSheet` に置き換え
- ウォークタイプ選択を `ShadButton` ペアに

### Phase 4: ダークテーマ完成 + アニメーション（2日）

- shadcn テーマのダークモード自動対応を活用
- 散在する `isDark` チェック (1,025箇所) を `Theme.of(context)` 経由に統一
- ページ遷移アニメーションの追加
- ボタン/カードのホバー・タップアニメーション

---

## 4. 具体的なコード例

### Before (現在)
```dart
// lib/screens/main/tabs/home_tab.dart 内のルートカード
Container(
  decoration: BoxDecoration(
    color: isDark ? WanMapColors.surfaceDark : WanMapColors.surfaceLight,
    borderRadius: WanMapSpacing.borderRadiusXL,
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), ...)],
  ),
  child: Column(
    children: [
      // 手動でサムネイル構築
      ClipRRect(borderRadius: ..., child: Image.network(...)),
      Padding(
        padding: EdgeInsets.all(WanMapSpacing.lg),
        child: Column(
          children: [
            Text(title, style: WanMapTypography.headlineSmall.copyWith(
              color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
            )),
            // ... 30行以上のスタイリングコード
          ],
        ),
      ),
    ],
  ),
)
```

### After (shadcn_ui)
```dart
// lib/widgets/route/wanwalk_route_card.dart
ShadCard(
  padding: EdgeInsets.zero,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // サムネイル
      ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        child: CachedNetworkImage(
          imageUrl: route.thumbnailUrl ?? '',
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => Shimmer(...),
          errorWidget: (_, __, ___) => _MapThumbnail(route),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル - テーマから自動で色取得
            Text(route.title, style: theme.textTheme.titleLarge),
            SizedBox(height: 4),
            Text(route.areaName, style: theme.textTheme.bodyMedium),
            SizedBox(height: 12),
            // タグを ShadBadge で
            Wrap(
              spacing: 8,
              children: [
                ShadBadge(child: Text('${route.distanceKm} km')),
                ShadBadge.outline(child: Text('${route.durationMin}分')),
                if (route.difficulty != null)
                  ShadBadge.destructive(child: Text(route.difficulty!)),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
)
```

### Before (ボタン)
```dart
WanMapButton(
  text: 'お散歩を開始',
  icon: Icons.directions_walk,
  size: WanMapButtonSize.large,
  variant: WanMapButtonVariant.primary,
  onPressed: () {},
)
```

### After (shadcn_ui ボタン)
```dart
ShadButton(
  icon: Icon(Icons.directions_walk, size: 20),
  size: ShadButtonSize.lg,
  child: Text('お散歩を開始'),
  onPressed: () {},
)
// outline variant
ShadButton.outline(
  child: Text('キャンセル'),
  onPressed: () {},
)
// ghost variant
ShadButton.ghost(
  icon: Icon(Icons.share),
  child: Text('シェア'),
  onPressed: () {},
)
```

---

## 5. ファイル構成（提案）

```
lib/
├── config/
│   ├── wanwalk_theme.dart          # shadcn テーマ統合 (NEW)
│   ├── wanmap_colors.dart          # 既存維持 → 段階的に theme に統合
│   ├── wanmap_typography.dart      # 既存維持 → 段階的に theme に統合
│   └── wanmap_spacing.dart         # 既存維持
├── widgets/
│   ├── common/                     # shadcn ベースの共通コンポーネント (NEW)
│   │   ├── ww_route_card.dart      # ShadCard ベース
│   │   ├── ww_area_card.dart       # ShadCard ベース
│   │   ├── ww_spot_card.dart       # ShadCard ベース
│   │   ├── ww_stat_card.dart       # ShadCard ベース
│   │   ├── ww_pin_card.dart        # ShadCard ベース
│   │   ├── ww_empty_state.dart     # 共通空状態
│   │   └── ww_section_header.dart  # セクション見出し
│   ├── wanmap_button.dart          # → 段階的に ShadButton へ
│   ├── wanmap_card.dart            # → 段階的に ShadCard へ
│   └── ...
├── screens/
│   ├── main/tabs/
│   │   ├── home_tab.dart           # リファクタリング (1715行 → ~400行)
│   │   ├── home/                   # セクション分離 (NEW)
│   │   │   ├── popular_routes_section.dart
│   │   │   ├── recent_pins_section.dart
│   │   │   ├── recommended_areas_section.dart
│   │   │   └── top_rated_spots_section.dart
│   │   └── ...
```

---

## 6. スケジュール

| Phase | 内容 | 期間 | リスク |
|-------|------|------|--------|
| **Phase 1** | 基盤整備（パッケージ追加、テーマ統合、カラー改善） | 1日 | 低 |
| **Phase 2** | コアコンポーネント置換（Button, Card, Input, Badge） | 2-3日 | 低 |
| **Phase 3** | 画面リファクタリング（Home, RouteDetail, Profile） | 3-5日 | 中 |
| **Phase 4** | ダークテーマ完成 + アニメーション | 2日 | 低 |
| **合計** | | **8-11日** | |

---

## 7. リスクと対策

| リスク | 影響 | 対策 |
|--------|------|------|
| shadcn_ui の Flutter バージョン互換性 | ビルド失敗 | 導入前に `flutter pub get` で検証 |
| flutter_map との干渉 | マップ表示崩れ | Phase 1 でマップ画面のみ先行テスト |
| 既存の大量 isDark チェック | 一括変更の工数 | Phase 2-3 で画面単位で段階的に対応 |
| Riverpod プロバイダとの組合せ | ステート管理競合 | shadcn_ui は見た目のみ、ステートは Riverpod 維持 |

---

## 8. 管理画面との統一ポイント

| 要素 | 管理画面 (Next.js) | モバイル (Flutter) |
|------|--------------------|--------------------|
| デザインシステム | shadcn/ui | shadcn_ui |
| カラートークン | CSS Variables | WanWalk ShadThemeData |
| ブランドカラー | `#E67E22` | `#E67E22` (統一) |
| コンポーネント | Button, Card, Badge, Dialog, Table, Tabs | ShadButton, ShadCard, ShadBadge, ShadDialog, ShadTable, ShadTabs |
| ダークモード | Tailwind dark: | ShadThemeData dark |
| 角丸 | radius-md (6px) | 8px (近い値に統一) |
| フォント | System font | Noto Sans JP (日本語最適化) |

---

## 9. 次のステップ

1. **承認**: このプロポーザルの方向性を確認
2. **Phase 1 開始**: `shadcn_ui` パッケージ追加 + テーマブリッジ作成
3. **PoC**: ホーム画面の1セクションだけ shadcn_ui で試作
4. **フィードバック**: 見た目・操作感を確認
5. **Phase 2-4**: 承認後に本格的に展開

---

## 10. まとめ

管理画面で shadcn/ui を導入した実績を活かし、Flutter アプリにも **`shadcn_ui`** パッケージで同じデザイン言語を導入する提案です。

**最大のメリット**:
- プロダクト全体（Web管理画面 + モバイルアプリ）の**デザイン統一**
- 既存コードを壊さない**段階的移行**
- コンポーネント標準化による**コード量50%削減**（home_tab.dart: 1,715行 → ~400行）
- ダークモード**自動対応**（散在する1,025箇所の isDark チェックを解消）
