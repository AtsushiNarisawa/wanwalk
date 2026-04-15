import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../models/route_spot.dart';

/// PinCard — ルート詳細「みどころ」に1件ずつ並べるカード。
/// B案: route_spots を spot_order 昇順で全件描画。
/// 写真は外部から resolvePhotoUrl で解決（gallery_images フォールバックを呼び出し側で組み立て）。
/// 写真が無ければ accent-primary-soft 背景の番号タイルを表示。
class PinCard extends StatelessWidget {
  final RouteSpot spot;
  final String? photoUrl;

  const PinCard({
    super.key,
    required this.spot,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final numberLabel = spot.spotOrder.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: WanWalkSpacing.s6),
      decoration: BoxDecoration(
        color: WanWalkColors.bgPrimary,
        border: Border.all(color: WanWalkColors.borderSubtle),
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: WanWalkColors.bgSecondary,
                    ),
                    errorWidget: (_, __, ___) =>
                        _NumberTile(label: numberLabel),
                  )
                : _NumberTile(label: numberLabel),
          ),
          Padding(
            padding: const EdgeInsets.all(WanWalkSpacing.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  numberLabel,
                  style: WanWalkTypography.wwNumeric.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: WanWalkColors.accentPrimary,
                    letterSpacing: 1.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: WanWalkSpacing.s2),
                Text(
                  spot.name,
                  style: WanWalkTypography.wwH3,
                ),
                if (spot.description != null &&
                    spot.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: WanWalkSpacing.s3),
                  Text(
                    spot.description!,
                    style: WanWalkTypography.wwBody,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  final String label;
  const _NumberTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WanWalkColors.accentPrimarySoft,
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'NotoSerifJP',
          fontWeight: FontWeight.w700,
          fontSize: 56,
          height: 1.0,
          color: WanWalkColors.accentPrimary,
        ),
      ),
    );
  }
}
