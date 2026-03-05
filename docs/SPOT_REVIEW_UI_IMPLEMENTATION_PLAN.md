# スポット評価・レビュー UI実装計画

## 📅 作成日
2025-12-14

## 🎯 実装目標
`pin_detail_screen.dart` にスポット評価・レビュー表示セクションを追加する

---

## 📋 現状分析

### 既存ファイル構造
**ファイル:** `lib/screens/outing/pin_detail_screen.dart`  
**総行数:** 907行  
**主要セクション順序:**
1. 写真ギャラリー (188行)
2. タイトル (196行)
3. ピンタイプバッジ (209行)
4. 統計情報 (214行)
5. コメント（投稿者） (219行)
6. 位置情報マップ (260行)
7. **🆕 レビューセクション挿入位置** (262行付近)
8. みんなのコメントセクション (265行)

### データフロー
```
pin_detail_screen.dart
  ↓ watch
pinByIdProvider(pinId) → RoutePin
  ↓ pinId (spotId)
spotReviewsProvider(pinId) → List<SpotReviewModel>
spotAverageRatingProvider(pinId) → double?
spotReviewCountProvider(pinId) → int
```

---

## 🔧 実装手順

### Step 1: Provider Import追加
**場所:** 10行目付近（import セクション）

```dart
import '../../providers/spot_review_provider.dart';
import '../../models/spot_review_model.dart';
```

### Step 2: レビューセクションをbuildに追加
**場所:** 262行目（位置情報マップの後）

```dart
const SizedBox(height: WanWalkSpacing.xl),

// スポット評価・レビューセクション
_buildReviewsSection(pin.id, isDark),

const SizedBox(height: WanWalkSpacing.xl),

// みんなのコメントセクション
_buildCommentsSection(commentsAsync, commentCount, currentUser, isDark, pin),
```

### Step 3: `_buildReviewsSection` メソッドを実装
**場所:** 906行目（ファイルの最後、`}` の直前）

```dart
/// スポット評価・レビューセクション
Widget _buildReviewsSection(String spotId, bool isDark) {
  // 平均評価を取得
  final averageRatingAsync = ref.watch(spotAverageRatingProvider(spotId));
  // レビュー数を取得
  final reviewCountAsync = ref.watch(spotReviewCountProvider(spotId));
  // レビュー一覧を取得
  final reviewsAsync = ref.watch(spotReviewsProvider(spotId));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // セクションヘッダー（星評価＋レビュー数）
      Row(
        children: [
          Icon(
            Icons.star,
            size: 20,
            color: Colors.amber,
          ),
          const SizedBox(width: WanWalkSpacing.xs),
          Text(
            'スポット評価',
            style: WanWalkTypography.headlineSmall.copyWith(
              color: isDark
                  ? WanWalkColors.textPrimaryDark
                  : WanWalkColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 平均評価表示
          averageRatingAsync.when(
            data: (avg) {
              if (avg == null) return const SizedBox.shrink();
              return Row(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: WanWalkTypography.headlineSmall.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: WanWalkSpacing.xs),
                  Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              );
            },
            loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      
      const SizedBox(height: WanWalkSpacing.sm),

      // レビュー数表示
      reviewCountAsync.when(
        data: (count) {
          if (count == 0) {
            return Text(
              'まだレビューがありません',
              style: WanWalkTypography.bodySmall.copyWith(
                color: isDark
                    ? WanWalkColors.textSecondaryDark
                    : WanWalkColors.textSecondaryLight,
              ),
            );
          }
          return Text(
            '$count件のレビュー',
            style: WanWalkTypography.bodySmall.copyWith(
              color: isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),

      const SizedBox(height: WanWalkSpacing.md),

      // レビュー一覧
      reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(WanWalkSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 48,
                      color: isDark
                          ? WanWalkColors.textSecondaryDark
                          : WanWalkColors.textSecondaryLight,
                    ),
                    const SizedBox(height: WanWalkSpacing.sm),
                    Text(
                      'このスポットの最初のレビューを投稿しませんか？',
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: isDark
                            ? WanWalkColors.textSecondaryDark
                            : WanWalkColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // レビューカードを表示（最大3件）
          return Column(
            children: reviews.take(3).map((review) => _buildReviewCard(review, isDark)).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Container(
          padding: const EdgeInsets.all(WanWalkSpacing.md),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'レビューの読み込みに失敗しました',
            style: WanWalkTypography.bodySmall.copyWith(color: Colors.red),
          ),
        ),
      ),
    ],
  );
}
```

### Step 4: `_buildReviewCard` メソッドを実装

```dart
/// レビューカード
Widget _buildReviewCard(SpotReviewModel review, bool isDark) {
  return Container(
    margin: const EdgeInsets.only(bottom: WanWalkSpacing.md),
    padding: const EdgeInsets.all(WanWalkSpacing.md),
    decoration: BoxDecoration(
      color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー：星評価＋日時
        Row(
          children: [
            // 星評価
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: Colors.amber,
                );
              }),
            ),
            const Spacer(),
            // 相対時間
            Text(
              review.relativeTime,
              style: WanWalkTypography.bodySmall.copyWith(
                color: isDark
                    ? WanWalkColors.textSecondaryDark
                    : WanWalkColors.textSecondaryLight,
              ),
            ),
          ],
        ),

        if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
          const SizedBox(height: WanWalkSpacing.sm),
          // レビューテキスト
          Text(
            review.reviewText!,
            style: WanWalkTypography.bodyMedium.copyWith(
              color: isDark
                  ? WanWalkColors.textPrimaryDark
                  : WanWalkColors.textPrimaryLight,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // 設備情報アイコン
        if (review.hasFacilities) ...[
          const SizedBox(height: WanWalkSpacing.sm),
          Wrap(
            spacing: WanWalkSpacing.xs,
            runSpacing: WanWalkSpacing.xs,
            children: [
              if (review.hasWaterFountain) _buildFacilityChip('水飲み場', Icons.water_drop, isDark),
              if (review.hasDogRun) _buildFacilityChip('ドッグラン', Icons.pets, isDark),
              if (review.hasShade) _buildFacilityChip('日陰', Icons.wb_sunny, isDark),
              if (review.hasToilet) _buildFacilityChip('トイレ', Icons.wc, isDark),
              if (review.hasParking) _buildFacilityChip('駐車場', Icons.local_parking, isDark),
            ],
          ),
        ],

        // 写真プレビュー（あれば）
        if (review.photoCount > 0) ...[
          const SizedBox(height: WanWalkSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.photo_library,
                size: 16,
                color: isDark
                    ? WanWalkColors.textSecondaryDark
                    : WanWalkColors.textSecondaryLight,
              ),
              const SizedBox(width: WanWalkSpacing.xs),
              Text(
                '${review.photoCount}枚の写真',
                style: WanWalkTypography.bodySmall.copyWith(
                  color: isDark
                      ? WanWalkColors.textSecondaryDark
                      : WanWalkColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
```

### Step 5: `_buildFacilityChip` メソッドを実装

```dart
/// 設備情報チップ
Widget _buildFacilityChip(String label, IconData icon, bool isDark) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: WanWalkSpacing.sm,
      vertical: WanWalkSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: WanWalkColors.accent.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: WanWalkColors.accent),
        const SizedBox(width: 4),
        Text(
          label,
          style: WanWalkTypography.bodySmall.copyWith(
            color: WanWalkColors.accent,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
```

---

## ✅ 実装チェックリスト

- [ ] Step 1: Provider import追加
- [ ] Step 2: レビューセクションをbuildに追加
- [ ] Step 3: `_buildReviewsSection` メソッド実装
- [ ] Step 4: `_buildReviewCard` メソッド実装
- [ ] Step 5: `_buildFacilityChip` メソッド実装
- [ ] Git commit: "Add: ピン詳細画面にスポット評価・レビュー表示セクションを追加"
- [ ] Git push
- [ ] Mac側でflutter run & 動作確認

---

## 📸 期待される表示

### レビューセクション
```
⭐ スポット評価                           4.5 ⭐
2件のレビュー

┌─────────────────────────────────────┐
│ ⭐⭐⭐⭐⭐              3時間前      │
│                                     │
│ 絶景スポット！芦ノ湖の全景が一望でき│
│ 富士山も見えました。愛犬のぱんち... │
│                                     │
│ 🚰日陰  🚻トイレ  🅿️駐車場         │
│ 📷 3枚の写真                        │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ⭐⭐⭐⭐              3時間前       │
│                                     │
│ ランチ休憩に最適な場所です。ベンチ...│
│                                     │
│ 🚻トイレ  🅿️駐車場  ☕カフェ近く   │
│ 📷 2枚の写真                        │
└─────────────────────────────────────┘
```

---

## 🎯 次のフェーズ

**Phase 1完了後:**
- Phase 2: レビュー投稿画面の実装
- Phase 3: レビュー編集・削除機能
- Phase 4: レビュー詳細画面（写真フルサイズ表示）

---

**作成者:** UI実装計画システム  
**実装担当:** 次回セッション  
**推定実装時間:** 30-45分
