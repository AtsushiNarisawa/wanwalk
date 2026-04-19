import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../config/wanwalk_colors.dart';
import '../../models/route_spot.dart';

/// ルートタイムライン（番号付き・カテゴリアイコン・写真なし）
///
/// distance_from_start で昇順ソートし、各スポットを 01, 02, .. の
/// 番号バッジ + 縦ライン + カテゴリアイコン + 名前 + 距離 で表示する。
class RouteTimeline extends StatelessWidget {
  final List<RouteSpot> spots;

  const RouteTimeline({super.key, required this.spots});

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = [...spots]..sort((a, b) {
        final ad = a.distanceFromStart ?? a.spotOrder * 1000000;
        final bd = b.distanceFromStart ?? b.spotOrder * 1000000;
        return ad.compareTo(bd);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(sorted.length, (i) {
        final spot = sorted[i];
        final isLast = i == sorted.length - 1;
        final number = (i + 1).toString().padLeft(2, '0');
        return _TimelineRow(
          spot: spot,
          number: number,
          isLast: isLast,
        );
      }),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final RouteSpot spot;
  final String number;
  final bool isLast;

  const _TimelineRow({
    required this.spot,
    required this.number,
    required this.isLast,
  });

  IconData _categoryIcon(SpotCategory? category) {
    switch (category) {
      case SpotCategory.cafe:
        return PhosphorIcons.coffee();
      case SpotCategory.restaurant:
        return PhosphorIcons.forkKnife();
      case SpotCategory.park:
        return PhosphorIcons.tree();
      case SpotCategory.dogRun:
        return PhosphorIcons.dog();
      case SpotCategory.waterStation:
        return PhosphorIcons.drop();
      case SpotCategory.restroom:
        return PhosphorIcons.toilet();
      case SpotCategory.parking:
        return PhosphorIcons.car();
      case SpotCategory.viewpoint:
        return PhosphorIcons.binoculars();
      case SpotCategory.shop:
        return PhosphorIcons.storefront();
      case null:
        return PhosphorIcons.mapPin();
    }
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters}m';
  }

  @override
  Widget build(BuildContext context) {
    final dist = spot.distanceFromStart;
    final desc = spot.description;
    final shortDesc = (desc != null && desc.length > 60)
        ? '${desc.substring(0, 60)}...'
        : desc;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: WanWalkColors.accentPrimary,
                    width: 2,
                  ),
                  color: WanWalkColors.backgroundLight,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: WanWalkColors.accentPrimary,
                    fontFamilyFallback: ['Inter', 'monospace'],
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  constraints: const BoxConstraints(minHeight: 20),
                  color: WanWalkColors.borderSubtle,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 36),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        _categoryIcon(spot.category),
                        size: 16,
                        color: WanWalkColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          spot.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: WanWalkColors.textPrimaryLight,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (dist != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatDistance(dist),
                          style: const TextStyle(
                            fontSize: 12,
                            color: WanWalkColors.textTertiary,
                            fontFeatures: [FontFeature.tabularFigures()],
                            fontFamilyFallback: ['Inter', 'monospace'],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (shortDesc != null) ...[
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      shortDesc,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: WanWalkColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
