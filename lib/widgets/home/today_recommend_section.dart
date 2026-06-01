import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_icons.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../models/official_route.dart';
import '../../providers/morning_reminder_provider.dart';
import '../../screens/outing/route_detail_screen.dart';
import '../../utils/distance_formatter.dart';

/// 「今日のおすすめ」セクション（B2 §3.3）。
///
/// 通知タップ後の deep link で auto-scroll される目印となるため
/// 上位レイアウトから [GlobalKey] を渡せるようにしてある。
///
/// データソースは [todayRecommendRouteProvider]。null の間は何も描画しない。
class TodayRecommendSection extends ConsumerWidget {
  const TodayRecommendSection({super.key, this.sectionKey});

  final GlobalKey? sectionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(todayRecommendRouteProvider);
    return routeAsync.when(
      data: (route) {
        if (route == null) return const SizedBox.shrink();
        return Padding(
          key: sectionKey,
          padding: const EdgeInsets.symmetric(
            horizontal: WanWalkSpacing.s4,
            vertical: WanWalkSpacing.s2,
          ),
          child: _Card(route: route),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.route});

  final OfficialRoute route;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('今日のおすすめ', style: WanWalkTypography.wwH3),
        const SizedBox(height: WanWalkSpacing.s2),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RouteDetailScreen(routeId: route.id),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: WanWalkColors.bgPrimary,
              borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
              border:
                  Border.all(color: WanWalkColors.borderSubtle, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (route.thumbnailUrl != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      route.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: WanWalkColors.accentPrimarySoft,
                        alignment: Alignment.center,
                        child: Icon(
                          WanWalkIcons.path,
                          size: 40,
                          color: WanWalkColors.accentPrimary,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(WanWalkSpacing.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(route.name, style: WanWalkTypography.wwH4),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(WanWalkIcons.ruler,
                              size: WanWalkIcons.sizeXs,
                              color: WanWalkColors.accentPrimary),
                          const SizedBox(width: 4),
                          Text(
                            formatDistance(route.distanceMeters.toInt()),
                            style: WanWalkTypography.wwNumeric.copyWith(
                              fontSize: 12,
                              color: WanWalkColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(WanWalkIcons.clock,
                              size: WanWalkIcons.sizeXs,
                              color: WanWalkColors.accentPrimary),
                          const SizedBox(width: 4),
                          Text(
                            '約${route.estimatedMinutes}分',
                            style: WanWalkTypography.wwNumeric.copyWith(
                              fontSize: 12,
                              color: WanWalkColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: WanWalkSpacing.s3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'ここへ行く',
                            style: WanWalkTypography.wwBodySm.copyWith(
                              color: WanWalkColors.accentPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            WanWalkIcons.caretRight,
                            size: WanWalkIcons.sizeXs,
                            color: WanWalkColors.accentPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
