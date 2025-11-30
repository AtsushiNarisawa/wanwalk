import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/route_pin.dart';

/// ピン詳細画面
/// ユーザーが投稿したピンの詳細情報を表示
class PinDetailScreen extends ConsumerWidget {
  final RoutePin pin;

  const PinDetailScreen({
    super.key,
    required this.pin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: const Text('ピン詳細'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真ギャラリー（横スクロール）
            if (pin.hasPhotos) _buildPhotoGallery(pin, isDark),

            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    pin.title,
                    style: WanMapTypography.headlineMedium.copyWith(
                      color: isDark
                          ? WanMapColors.textPrimaryDark
                          : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: WanMapSpacing.md),

                  // ピンタイプバッジ
                  _buildPinTypeBadge(pin.pinType),

                  const SizedBox(height: WanMapSpacing.xl),

                  // 統計情報
                  _buildStats(pin, isDark),

                  const SizedBox(height: WanMapSpacing.xl),

                  // コメント
                  if (pin.comment.isNotEmpty) ...[
                    Text(
                      'コメント',
                      style: WanMapTypography.headlineSmall.copyWith(
                        color: isDark
                            ? WanMapColors.textPrimaryDark
                            : WanMapColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: WanMapSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(WanMapSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pin.comment,
                        style: WanMapTypography.bodyMedium.copyWith(
                          color: isDark
                              ? WanMapColors.textPrimaryDark
                              : WanMapColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: WanMapSpacing.xl),
                  ],

                  // 位置情報
                  Text(
                    '位置',
                    style: WanMapTypography.headlineSmall.copyWith(
                      color: isDark
                          ? WanMapColors.textPrimaryDark
                          : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: WanMapSpacing.sm),
                  _buildLocationMap(pin, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
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
                color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                child: Icon(
                  Icons.photo,
                  size: 80,
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
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
      case PinType.other:
        badgeColor = Colors.grey;
        icon = Icons.more_horiz;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanMapSpacing.md,
        vertical: WanMapSpacing.sm,
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
          const SizedBox(width: WanMapSpacing.xs),
          Text(
            pinType.label,
            style: WanMapTypography.bodyMedium.copyWith(
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
        const SizedBox(width: WanMapSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.photo_library,
            label: '写真',
            value: '${pin.photoCount}枚',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: WanMapSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.access_time,
            label: '投稿',
            value: pin.relativeTime,
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
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
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
              userAgentPackageName: 'com.doghub.wanmap',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pin.location,
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    color: WanMapColors.accent,
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
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: WanMapColors.accent,
            size: 24,
          ),
          const SizedBox(height: WanMapSpacing.xs),
          Text(
            label,
            style: WanMapTypography.caption.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: WanMapSpacing.xs),
          Text(
            value,
            style: WanMapTypography.bodyMedium.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
