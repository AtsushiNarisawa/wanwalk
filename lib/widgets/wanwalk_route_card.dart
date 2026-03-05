import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/wanwalk_colors.dart';
import '../config/wanwalk_typography.dart';
import '../config/wanwalk_spacing.dart';

/// WanWalk ルートカードウィジェット
/// ルート一覧・詳細画面で使用する大きなカード

class WanWalkRouteCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double distance; // km
  final int duration; // 分
  final int? elevation; // m
  final List<LatLng>? routePoints;
  final String? thumbnailUrl;
  final List<String>? tags;
  final int? likeCount;
  final bool isLiked;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const WanWalkRouteCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.distance,
    required this.duration,
    this.elevation,
    this.routePoints,
    this.thumbnailUrl,
    this.tags,
    this.likeCount,
    this.isLiked = false,
    this.onTap,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark 
        ? WanWalkColors.textPrimaryDark 
        : WanWalkColors.textPrimaryLight;
    final secondaryTextColor = isDark 
        ? WanWalkColors.textSecondaryDark 
        : WanWalkColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark 
              ? WanWalkColors.surfaceDark 
              : WanWalkColors.surfaceLight,
          borderRadius: WanWalkSpacing.borderRadiusXL,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // マップサムネイル or 写真
            _buildThumbnail(context),
            
            // コンテンツ
            Padding(
              padding: const EdgeInsets.all(WanWalkSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    title,
                    style: WanWalkTypography.headlineSmall.copyWith(
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // サブタイトル
                  if (subtitle != null) ...[
                    const SizedBox(height: WanWalkSpacing.xxs),
                    Text(
                      subtitle!,
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: secondaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: WanWalkSpacing.md),
                  
                  // 統計情報
                  _buildStats(context),
                  
                  // タグ
                  if (tags != null && tags!.isNotEmpty) ...[
                    const SizedBox(height: WanWalkSpacing.md),
                    _buildTags(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return Stack(
      children: [
        // サムネイル画像 or マップ
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(WanWalkSpacing.radiusXL),
          ),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: thumbnailUrl != null
                ? Image.network(
                    thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildMapThumbnail();
                    },
                  )
                : _buildMapThumbnail(),
          ),
        ),
        
        // グラデーションオーバーレイ（読みやすさ向上）
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(WanWalkSpacing.radiusXL),
              ),
            ),
          ),
        ),
        
        // いいねボタン
        if (onLike != null)
          Positioned(
            top: WanWalkSpacing.md,
            right: WanWalkSpacing.md,
            child: GestureDetector(
              onTap: onLike,
              child: Container(
                padding: const EdgeInsets.all(WanWalkSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? WanWalkColors.error : WanWalkColors.textSecondaryLight,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapThumbnail() {
    if (routePoints == null || routePoints!.isEmpty) {
      return Container(
        color: WanWalkColors.textTertiaryLight,
        child: const Center(
          child: Icon(
            Icons.map,
            size: 48,
            color: WanWalkColors.textSecondaryLight,
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        center: routePoints!.first,
        zoom: 14,
        interactiveFlags: InteractiveFlag.none, // インタラクション無効
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.doghub.wanwalk',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: routePoints!,
              color: WanWalkColors.accent,
              strokeWidth: 4,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark 
        ? WanWalkColors.textSecondaryDark 
        : WanWalkColors.textSecondaryLight;

    return Row(
      children: [
        // 距離
        _StatItem(
          icon: Icons.route,
          value: '${distance.toStringAsFixed(1)}km',
          color: secondaryTextColor,
        ),
        const SizedBox(width: WanWalkSpacing.lg),
        
        // 時間
        _StatItem(
          icon: Icons.access_time,
          value: '$duration分',
          color: secondaryTextColor,
        ),
        
        // 高低差
        if (elevation != null) ...[
          const SizedBox(width: WanWalkSpacing.lg),
          _StatItem(
            icon: Icons.terrain,
            value: '${elevation}m',
            color: secondaryTextColor,
          ),
        ],
        
        const Spacer(),
        
        // いいね数
        if (likeCount != null)
          _StatItem(
            icon: Icons.favorite,
            value: likeCount.toString(),
            color: WanWalkColors.error,
          ),
      ],
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: WanWalkSpacing.xs,
      runSpacing: WanWalkSpacing.xs,
      children: tags!.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WanWalkSpacing.sm,
            vertical: WanWalkSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: WanWalkColors.secondary.withOpacity(0.1),
            borderRadius: WanWalkSpacing.borderRadiusMD,
          ),
          child: Text(
            tag,
            style: WanWalkTypography.labelSmall.copyWith(
              color: WanWalkColors.secondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 統計アイテム（アイコン + 値）
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: WanWalkSpacing.xxs),
        Text(
          value,
          style: WanWalkTypography.labelMedium.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}

/// コンパクトルートカード（リスト表示用）
class WanWalkRouteCardCompact extends StatelessWidget {
  final String title;
  final double distance;
  final int duration;
  final String? thumbnailUrl;
  final VoidCallback? onTap;

  const WanWalkRouteCardCompact({
    super.key,
    required this.title,
    required this.distance,
    required this.duration,
    this.thumbnailUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark 
        ? WanWalkColors.textPrimaryDark 
        : WanWalkColors.textPrimaryLight;
    final secondaryTextColor = isDark 
        ? WanWalkColors.textSecondaryDark 
        : WanWalkColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(WanWalkSpacing.md),
        decoration: BoxDecoration(
          color: isDark 
              ? WanWalkColors.surfaceDark 
              : WanWalkColors.surfaceLight,
          borderRadius: WanWalkSpacing.borderRadiusLG,
        ),
        child: Row(
          children: [
            // サムネイル
            ClipRRect(
              borderRadius: WanWalkSpacing.borderRadiusMD,
              child: SizedBox(
                width: 60,
                height: 60,
                child: thumbnailUrl != null
                    ? Image.network(
                        thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: WanWalkColors.textTertiaryLight,
                            child: const Icon(
                              Icons.map,
                              size: 24,
                              color: WanWalkColors.textSecondaryLight,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: WanWalkColors.textTertiaryLight,
                        child: const Icon(
                          Icons.map,
                          size: 24,
                          color: WanWalkColors.textSecondaryLight,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: WanWalkSpacing.md),
            
            // テキスト情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WanWalkTypography.titleMedium.copyWith(
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WanWalkSpacing.xxs),
                  Row(
                    children: [
                      Icon(
                        Icons.route,
                        size: 14,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: WanWalkSpacing.xxs),
                      Text(
                        '${distance.toStringAsFixed(1)}km',
                        style: WanWalkTypography.labelSmall.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: WanWalkSpacing.sm),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: WanWalkSpacing.xxs),
                      Text(
                        '$duration分',
                        style: WanWalkTypography.labelSmall.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 矢印
            Icon(
              Icons.chevron_right,
              color: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
