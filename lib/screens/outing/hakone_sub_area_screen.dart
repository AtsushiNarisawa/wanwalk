import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../providers/area_provider.dart';
import 'route_list_screen.dart';

/// 箱根サブエリア選択画面（Build 28 Wildboundsトーン刷新）
class HakoneSubAreaScreen extends ConsumerWidget {
  final List<Map<String, dynamic>> subAreas;

  const HakoneSubAreaScreen({
    super.key,
    required this.subAreas,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: WanWalkColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: WanWalkColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: WanWalkColors.textPrimary),
        title: const Text(
          '箱根エリアを選ぶ',
          style: TextStyle(
            fontFamily: 'NotoSerifJP',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: WanWalkColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WanWalkSpacing.s4,
          WanWalkSpacing.s2,
          WanWalkSpacing.s4,
          WanWalkSpacing.s8,
        ),
        children: [
          // 箱根の散歩拠点（DogHub）バナー
          _DogHubBanner(),
          const SizedBox(height: WanWalkSpacing.s6),
          // サブエリアカード一覧
          for (int i = 0; i < subAreas.length; i++) ...[
            _HakoneSubAreaCard(
              areaData: subAreas[i],
              onTap: () {
                ref
                    .read(selectedAreaIdProvider.notifier)
                    .selectArea(subAreas[i]['id']);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteListScreen(
                      areaId: subAreas[i]['id'],
                      areaName: subAreas[i]['name'],
                    ),
                  ),
                );
              },
            ),
            if (i < subAreas.length - 1)
              const SizedBox(height: WanWalkSpacing.s3),
          ],
        ],
      ),
    );
  }
}

/// 箱根の散歩拠点（DogHub）バナー
class _DogHubBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse('https://dog-hub.shop/hotel/');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(WanWalkSpacing.s5),
        decoration: BoxDecoration(
          color: WanWalkColors.bgSecondary,
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          border: Border.all(color: WanWalkColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: WanWalkColors.accentPrimarySoft,
                borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
              ),
              alignment: Alignment.center,
              child: Icon(
                PhosphorIcons.dog(),
                color: WanWalkColors.accentPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: WanWalkSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '箱根の散歩拠点',
                    style: WanWalkTypography.wwLabel.copyWith(
                      color: WanWalkColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'DogHub仙石原',
                    style: TextStyle(
                      fontFamily: 'NotoSerifJP',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.3,
                      color: WanWalkColors.textPrimary,
                    ),
                  ),
                  Text(
                    'カフェ・ドッグラン・一時預かり',
                    style: WanWalkTypography.wwCaption,
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.arrowUpRight(),
              size: 16,
              color: WanWalkColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 箱根サブエリアカード
class _HakoneSubAreaCard extends StatelessWidget {
  final Map<String, dynamic> areaData;
  final VoidCallback onTap;

  const _HakoneSubAreaCard({
    required this.areaData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = areaData['name'] as String;
    final description = areaData['description'] as String?;
    final routeCount = areaData['route_count'] as int? ?? 0;
    final subAreaName = name.replaceFirst('箱根・', '');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(WanWalkSpacing.s5),
        decoration: BoxDecoration(
          color: WanWalkColors.bgPrimary,
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          border: Border.all(color: WanWalkColors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subAreaName,
                    style: const TextStyle(
                      fontFamily: 'NotoSerifJP',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      height: 1.3,
                      color: WanWalkColors.textPrimary,
                    ),
                  ),
                  if (routeCount > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '$routeCount コース',
                      style: WanWalkTypography.wwNumeric.copyWith(
                        fontSize: 13,
                        color: WanWalkColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: WanWalkSpacing.s3),
                    Text(
                      description,
                      style: WanWalkTypography.wwBodySm.copyWith(
                        color: WanWalkColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: WanWalkSpacing.s4),
            Icon(
              PhosphorIcons.caretRight(),
              size: 18,
              color: WanWalkColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
