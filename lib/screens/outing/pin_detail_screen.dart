import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../models/route_pin.dart';
import '../../models/spot_review_model.dart';

import '../../providers/route_pin_provider.dart';
import '../../providers/official_route_provider.dart';
import '../../providers/spot_review_provider.dart';
import 'route_detail_screen.dart';
import 'spot_review_form_screen.dart';

/// ピン詳細画面
/// ユーザーが投稿したピンの詳細情報を表示
class PinDetailScreen extends ConsumerStatefulWidget {
  final String pinId;

  const PinDetailScreen({
    super.key,
    required this.pinId,
  });

  @override
  ConsumerState<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends ConsumerState<PinDetailScreen> {


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinAsync = ref.watch(pinByIdProvider(widget.pinId));

    return Scaffold(
      backgroundColor: isDark
          ? WanWalkColors.backgroundDark
          : WanWalkColors.backgroundLight,
      appBar: AppBar(
        title: const Text('ピン詳細'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: pinAsync.when(
        data: (pin) {
          if (pin == null) {
            return Center(
              child: Text(
                'ピンが見つかりません',
                style: WanWalkTypography.bodyLarge.copyWith(
                  color: isDark
                      ? WanWalkColors.textSecondaryDark
                      : WanWalkColors.textSecondaryLight,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 写真ギャラリー（横スクロール）
                if (pin.hasPhotos) _buildPhotoGallery(pin, isDark),

                Padding(
                  padding: const EdgeInsets.all(WanWalkSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトル
                      Text(
                        pin.title,
                        style: WanWalkTypography.headlineMedium.copyWith(
                          color: isDark
                              ? WanWalkColors.textPrimaryDark
                              : WanWalkColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: WanWalkSpacing.md),

                      // ピンタイプバッジ
                      _buildPinTypeBadge(pin.pinType),

                      const SizedBox(height: WanWalkSpacing.xl),

                      // 統計情報
                      _buildStats(pin, isDark),

                      const SizedBox(height: WanWalkSpacing.xl),

                      // コメント
                      if (pin.comment.isNotEmpty) ...[
                        Text(
                          'コメント',
                          style: WanWalkTypography.headlineSmall.copyWith(
                            color: isDark
                                ? WanWalkColors.textPrimaryDark
                                : WanWalkColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: WanWalkSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(WanWalkSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pin.comment,
                            style: WanWalkTypography.bodyMedium.copyWith(
                          color: isDark
                              ? WanWalkColors.textPrimaryDark
                              : WanWalkColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: WanWalkSpacing.xl),
                  ],

                      // このピンがあるルート
                      _buildRouteLink(pin, isDark),

                      const SizedBox(height: WanWalkSpacing.xl),

                      // 位置情報
                      Text(
                        '位置',
                        style: WanWalkTypography.headlineSmall.copyWith(
                          color: isDark
                              ? WanWalkColors.textPrimaryDark
                              : WanWalkColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: WanWalkSpacing.sm),
                      _buildLocationMap(pin, isDark),

                      // 施設情報（facility タイプのみ）
                      _buildFacilityInfo(pin, isDark),

                      const SizedBox(height: WanWalkSpacing.xl),

                      // スポット評価・レビューセクション
                      _buildReviewsSection(pin.id, pin.title, isDark),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark
                    ? WanWalkColors.textSecondaryDark
                    : WanWalkColors.textSecondaryLight,
              ),
              const SizedBox(height: WanWalkSpacing.md),
              Text(
                'ピンの読み込みに失敗しました',
                style: WanWalkTypography.bodyLarge.copyWith(
                  color: isDark
                      ? WanWalkColors.textSecondaryDark
                      : WanWalkColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// このピンがあるルートへのリンク
  Widget _buildRouteLink(RoutePin pin, bool isDark) {
    final routeAsync = ref.watch(routeByIdProvider(pin.routeId));

    return routeAsync.when(
      data: (route) {
        if (route == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'このピンがあるルート',
              style: WanWalkTypography.headlineSmall.copyWith(
                color: isDark
                    ? WanWalkColors.textPrimaryDark
                    : WanWalkColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteDetailScreen(
                      routeId: route.id,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(WanWalkSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: WanWalkColors.accent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // サムネイル
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: route.thumbnailUrl != null
                          ? Image.network(
                              route.thumbnailUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: WanWalkColors.accent.withOpacity(0.1),
                                child: Icon(Icons.map, color: WanWalkColors.accent),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: WanWalkColors.accent.withOpacity(0.1),
                              child: Icon(Icons.map, color: WanWalkColors.accent),
                            ),
                    ),
                    const SizedBox(width: WanWalkSpacing.md),
                    // ルート情報
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            style: WanWalkTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? WanWalkColors.textPrimaryDark
                                  : WanWalkColors.textPrimaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(route.distanceMeters / 1000).toStringAsFixed(1)}km・約${route.estimatedMinutes}分',
                            style: WanWalkTypography.bodySmall.copyWith(
                              color: isDark
                                  ? WanWalkColors.textSecondaryDark
                                  : WanWalkColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: WanWalkColors.accent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// 写真ギャラリー
  Widget _buildPhotoGallery(RoutePin pin, bool isDark) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: pin.photoUrls.length,
        itemBuilder: (context, index) {
          return Image.network(
            pin.photoUrls[index],
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                height: 300,
                color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
                child: Icon(
                  Icons.photo,
                  size: 80,
                  color: isDark
                      ? WanWalkColors.textSecondaryDark
                      : WanWalkColors.textSecondaryLight,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// ピンタイプバッジ
  Widget _buildPinTypeBadge(PinType pinType) {
    Color badgeColor;
    IconData icon;

    switch (pinType) {
      case PinType.scenery:
        badgeColor = Colors.blue;
        icon = Icons.landscape;
        break;
      case PinType.shop:
        badgeColor = Colors.orange;
        icon = Icons.store;
        break;
      case PinType.encounter:
        badgeColor = Colors.pink;
        icon = Icons.pets;
        break;
      case PinType.facility:
        badgeColor = Colors.purple;
        icon = Icons.business;
        break;

      case PinType.other:
        badgeColor = Colors.grey;
        icon = Icons.more_horiz;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.md,
        vertical: WanWalkSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: badgeColor,
            size: 20,
          ),
          const SizedBox(width: WanWalkSpacing.xs),
          Text(
            pinType.label,
            style: WanWalkTypography.bodyMedium.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 統計情報
  Widget _buildStats(RoutePin pin, bool isDark) {

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.favorite,
            label: 'いいね',
            value: '${pin.likesCount}',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: WanWalkSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.photo_library,
            label: '写真',
            value: '${pin.photoCount}枚',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  /// 位置マップ
  Widget _buildLocationMap(RoutePin pin, bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: pin.location,
            initialZoom: 16.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.doghub.wanwalk',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pin.location,
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    color: WanWalkColors.accent,
                    size: 40,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// スポット評価・レビューセクション
  Widget _buildReviewsSection(String spotId, String spotTitle, bool isDark) {
    // 現在のユーザーIDを取得
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userId = currentUser?.id;
    
    // 平均評価を取得
    final averageRatingAsync = ref.watch(spotAverageRatingProvider(spotId));
    // レビュー数を取得
    final reviewCountAsync = ref.watch(spotReviewCountProvider(spotId));
    // レビュー一覧を取得
    final reviewsAsync = ref.watch(spotReviewsProvider(spotId));
    // ユーザーの既存レビューを取得
    final userReviewAsync = userId != null
        ? ref.watch(userSpotReviewProvider((userId: userId, spotId: spotId)))
        : null;

    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションヘッダー
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 20,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: WanWalkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'このスポットの評価',
                      style: WanWalkTypography.headlineSmall.copyWith(
                        color: isDark
                            ? WanWalkColors.textPrimaryDark
                            : WanWalkColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '設備や雰囲気についての評価です',
                      style: WanWalkTypography.bodySmall.copyWith(
                        color: isDark
                            ? WanWalkColors.textSecondaryDark
                            : WanWalkColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: WanWalkSpacing.md),
          
          // 平均評価＋レビュー数表示
          Row(
            children: [
              // 平均評価
              averageRatingAsync.when(
                data: (avg) {
                  if (avg == null) {
                    return Text(
                      '評価なし',
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: isDark
                            ? WanWalkColors.textSecondaryDark
                            : WanWalkColors.textSecondaryLight,
                      ),
                    );
                  }
                  return Row(
                    children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: WanWalkTypography.headlineMedium.copyWith(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                    ],
                  );
                },
                loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(width: WanWalkSpacing.sm),
              // レビュー数

              reviewCountAsync.when(
                data: (count) {
                  return Text(
                    '($count件のレビュー)',
                    style: WanWalkTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanWalkColors.textSecondaryDark
                          : WanWalkColors.textSecondaryLight,
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
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
                      const SizedBox(height: WanWalkSpacing.md),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // ユーザーの既存レビューを取得
                          SpotReviewModel? existingReview;
                          if (userReviewAsync != null) {
                            final asyncValue = userReviewAsync;
                            existingReview = asyncValue.value;
                          }
                          
                          if (!context.mounted) return;
                          
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SpotReviewFormScreen(
                                spotId: spotId,
                                spotTitle: spotTitle,
                                existingReview: existingReview,
                              ),
                            ),
                          );
                          // レビュー投稿成功時はプロバイダーをリフレッシュ
                          if (result == true) {
                            ref.invalidate(spotReviewsProvider(spotId));
                            ref.invalidate(spotAverageRatingProvider(spotId));
                            ref.invalidate(spotReviewCountProvider(spotId));
                            if (userId != null) {
                              ref.invalidate(userSpotReviewProvider((userId: userId, spotId: spotId)));
                            }
                          }
                        },
                        icon: Icon(userReviewAsync != null 
                            ? Icons.edit 
                            : Icons.edit_note),
                        label: Text(userReviewAsync != null 
                            ? 'レビューを編集' 
                            : 'レビューを書く'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WanWalkColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: WanWalkSpacing.lg,
                            vertical: WanWalkSpacing.md,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // レビューカードを表示（最大3件）
            return Column(
              children: [
                ...reviews
                    .take(3)
                    .map((review) => _buildReviewCard(review, isDark))
                    .toList(),
                
                const SizedBox(height: WanWalkSpacing.md),
                
                // レビューを書くボタン
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // ユーザーの既存レビューを取得
                      SpotReviewModel? existingReview;
                      if (userReviewAsync != null) {
                        final asyncValue = userReviewAsync;
                        existingReview = asyncValue.value;
                      }
                      
                      if (!context.mounted) return;
                      
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpotReviewFormScreen(
                            spotId: spotId,
                            spotTitle: spotTitle,
                            existingReview: existingReview,
                          ),
                        ),
                      );
                      // レビュー投稿成功時はプロバイダーをリフレッシュ
                      if (result == true) {
                        ref.invalidate(spotReviewsProvider(spotId));
                        ref.invalidate(spotAverageRatingProvider(spotId));
                        ref.invalidate(spotReviewCountProvider(spotId));
                        if (userId != null) {
                          ref.invalidate(userSpotReviewProvider((userId: userId, spotId: spotId)));
                        }
                      }
                    },
                    icon: Icon(userReviewAsync != null 
                        ? Icons.edit 
                        : Icons.edit_note),
                    label: Text(userReviewAsync != null 
                        ? 'レビューを編集' 
                        : 'レビューを書く'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WanWalkColors.accent,
                      side: BorderSide(color: WanWalkColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: WanWalkSpacing.md),
                    ),
                  ),
                ),
              ],
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
      ),
    );
  }

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
          if (review.hasAnyFacilities) ...[
            const SizedBox(height: WanWalkSpacing.sm),
            Wrap(
              spacing: WanWalkSpacing.xs,
              runSpacing: WanWalkSpacing.xs,
              children: [
                if (review.hasWaterFountain)
                  _buildFacilityChip('水飲み場', Icons.water_drop, isDark),
                if (review.hasDogRun)
                  _buildFacilityChip('ドッグラン', Icons.pets, isDark),
                if (review.hasShade)
                  _buildFacilityChip('日陰', Icons.wb_sunny, isDark),
                if (review.hasToilet)
                  _buildFacilityChip('トイレ', Icons.wc, isDark),
                if (review.hasParking)
                  _buildFacilityChip('駐車場', Icons.local_parking, isDark),
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
  Widget _buildFacilityInfo(RoutePin pin, bool isDark) {
    final facilityInfo = pin.facilityInfo;
    if (facilityInfo == null || pin.pinType != PinType.facility) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: WanWalkSpacing.lg),
        Text(
          '施設情報',
          style: WanWalkTypography.headlineSmall.copyWith(
            color: isDark
                ? WanWalkColors.textPrimaryDark
                : WanWalkColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanWalkSpacing.md),
        
        // 営業時間
        if (facilityInfo['business_hours'] != null)
          _buildInfoSection(
            icon: Icons.access_time,
            title: '営業時間',
            children: [
              _buildInfoRow('平日', facilityInfo['business_hours']['weekday']),
              _buildInfoRow('週末', facilityInfo['business_hours']['weekend']),
              _buildInfoRow('定休日', facilityInfo['business_hours']['closed']),
            ],
            isDark: isDark,
          ),
        
        const SizedBox(height: WanWalkSpacing.md),
        
        // サービス
        if (facilityInfo['services'] != null)
          _buildInfoSection(
            icon: Icons.check_circle,
            title: 'サービス',
            children: [
              Wrap(
                spacing: WanWalkSpacing.sm,
                runSpacing: WanWalkSpacing.sm,
                children: (facilityInfo['services'] as List)
                    .map((service) => Container(
                          margin: const EdgeInsets.only(right: 8, bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(
                              color: Colors.blue.shade700,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            service.toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
            isDark: isDark,
          ),
        
        const SizedBox(height: WanWalkSpacing.md),
        
        // 施設設備
        if (facilityInfo['facilities'] != null)
          _buildInfoSection(
            icon: Icons.home_work,
            title: '施設設備',
            children: [
              Wrap(
                spacing: WanWalkSpacing.sm,
                runSpacing: WanWalkSpacing.sm,
                children: (facilityInfo['facilities'] as List)
                    .map((facility) => Container(
                          margin: const EdgeInsets.only(right: 8, bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(
                              color: Colors.green.shade700,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            facility.toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
            isDark: isDark,
          ),
        
        const SizedBox(height: WanWalkSpacing.md),
        
        // アクセス
        if (facilityInfo['access'] != null)
          _buildInfoSection(
            icon: Icons.directions_car,
            title: 'アクセス',
            children: [
              if (facilityInfo['access']['by_car'] != null)
                _buildInfoRow('車', facilityInfo['access']['by_car']),
              if (facilityInfo['access']['by_train'] != null)
                _buildInfoRow('電車', facilityInfo['access']['by_train']),
              if (facilityInfo['access']['parking'] != null)
                _buildInfoRow('駐車場', facilityInfo['access']['parking']),
            ],
            isDark: isDark,
          ),
        
        const SizedBox(height: WanWalkSpacing.md),
        
        // わんちゃん対応
        if (facilityInfo['dog_friendly'] != null)
          _buildInfoSection(
            icon: Icons.pets,
            title: 'わんちゃん対応',
            children: [
              _buildInfoRow(
                '対応サイズ',
                _getDogSizeText(facilityInfo['dog_friendly']['size']),
              ),
              _buildInfoRow(
                '室内同伴',
                facilityInfo['dog_friendly']['indoor_allowed'] == true ? '可能' : '不可',
              ),
              _buildInfoRow(
                'リード',
                facilityInfo['dog_friendly']['leash_required'] == true ? '必要' : '不要',
              ),
              _buildInfoRow(
                'ワクチン',
                facilityInfo['dog_friendly']['vaccination_required'] == true ? '必要' : '不要',
              ),
            ],
            isDark: isDark,
          ),
        
        const SizedBox(height: WanWalkSpacing.md),
        
        // お問い合わせ
        if (facilityInfo['contact'] != null)
          _buildInfoSection(
            icon: Icons.phone,
            title: 'お問い合わせ',
            children: [
              if (facilityInfo['contact']['phone'] != null)
                _buildInfoRow('電話', facilityInfo['contact']['phone']),
              if (facilityInfo['contact']['email'] != null)
                _buildInfoRow('メール', facilityInfo['contact']['email']),
              if (facilityInfo['contact']['website'] != null)
                _buildInfoRow('ウェブサイト', facilityInfo['contact']['website']),
              if (facilityInfo['contact']['instagram'] != null)
                _buildInfoRow('Instagram', facilityInfo['contact']['instagram']),
            ],
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
            ),
            const SizedBox(width: WanWalkSpacing.sm),
            Text(
              title,
              style: WanWalkTypography.bodyMedium.copyWith(
                color: isDark
                    ? WanWalkColors.textPrimaryDark
                    : WanWalkColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: WanWalkSpacing.sm),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: WanWalkSpacing.lg, bottom: WanWalkSpacing.xs),
      child: Text('$label: $value'),
    );
  }

  String _getDogSizeText(String? size) {
    switch (size) {
      case 'small':
        return '小型犬';
      case 'medium':
        return '中型犬';
      case 'large':
        return '大型犬';
      case 'all':
        return '全サイズ対応';
      default:
        return '不明';
    }
  }
}
/// 統計カード
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: WanWalkColors.accent,
            size: 24,
          ),
          const SizedBox(height: WanWalkSpacing.xs),
          Text(
            label,
            style: WanWalkTypography.caption.copyWith(
              color: isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: WanWalkSpacing.xs),
          Text(
            value,
            style: WanWalkTypography.bodyMedium.copyWith(
              color: isDark
                  ? WanWalkColors.textPrimaryDark
                  : WanWalkColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


}
