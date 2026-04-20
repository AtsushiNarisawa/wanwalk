import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';

/// AreaCard — エリア一覧の1枚。
/// 4:3 画像 + Noto Serif JP 20px タイトル + Inter 13px tabular "Nコース"。
/// 画像が無ければ accent-primary-soft 背景の MapTrifold プレースホルダ。
class AreaCard extends StatelessWidget {
  final String name;
  final String prefecture;
  final String? heroImageUrl;
  final int routeCount;
  final VoidCallback onTap;

  const AreaCard({
    super.key,
    required this.name,
    required this.prefecture,
    required this.heroImageUrl,
    required this.routeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
      child: Container(
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
              child: heroImageUrl != null && heroImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: heroImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: WanWalkColors.bgSecondary,
                      ),
                      errorWidget: (_, __, ___) => _Placeholder(),
                    )
                  : _Placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WanWalkSpacing.s5,
                WanWalkSpacing.s4,
                WanWalkSpacing.s5,
                WanWalkSpacing.s5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prefecture.toUpperCase(),
                    style: WanWalkTypography.wwLabel,
                  ),
                  const SizedBox(height: WanWalkSpacing.s2),
                  Text(
                    name,
                    style: WanWalkTypography.wwH4.copyWith(height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WanWalkSpacing.s3),
                  Text(
                    '$routeCount コース',
                    style: WanWalkTypography.wwNumeric.copyWith(
                      fontSize: 13,
                      color: WanWalkColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: WanWalkColors.accentPrimarySoft,
      alignment: Alignment.center,
      child: Icon(
        PhosphorIcons.mapTrifold(),
        size: 48,
        color: WanWalkColors.accentPrimary,
      ),
    );
  }
}
