import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../providers/area_provider.dart';
import 'route_list_screen.dart';

/// 箱根サブエリア選択画面（Build 29: 0コースのサブエリア非表示）
class HakoneSubAreaScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> subAreas;

  const HakoneSubAreaScreen({
    super.key,
    required this.subAreas,
  });

  @override
  ConsumerState<HakoneSubAreaScreen> createState() => _HakoneSubAreaScreenState();
}

class _HakoneSubAreaScreenState extends ConsumerState<HakoneSubAreaScreen> {
  List<Map<String, dynamic>> _enrichedSubAreas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRouteCounts();
  }

  Future<void> _loadRouteCounts() async {
    final enriched = <Map<String, dynamic>>[];

    for (final area in widget.subAreas) {
      // route_countが既に含まれている場合（area_list_screen経由）はそのまま使う
      if (area.containsKey('route_count') && area['route_count'] != null) {
        enriched.add(area);
        continue;
      }

      // route_countがない場合（home_tab経由）はSupabaseから取得
      final response = await Supabase.instance.client
          .from('official_routes')
          .select('id')
          .eq('area_id', area['id'])
          .eq('is_published', true)
          .count(CountOption.exact);

      enriched.add({
        ...area,
        'route_count': response.count,
      });
    }

    if (mounted) {
      setState(() {
        _enrichedSubAreas = enriched.where((a) => ((a['route_count'] as int?) ?? 0) > 0).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WanWalkColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: WanWalkColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: WanWalkColors.textPrimary),
        title: const Text('箱根エリアを選ぶ', style: WanWalkTypography.wwH2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: WanWalkColors.accentPrimary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                WanWalkSpacing.s4,
                WanWalkSpacing.s2,
                WanWalkSpacing.s4,
                WanWalkSpacing.s8,
              ),
              children: [
                _DogHubBanner(),
                const SizedBox(height: WanWalkSpacing.s6),
                for (int i = 0; i < _enrichedSubAreas.length; i++) ...[
                  _HakoneSubAreaCard(
                    areaData: _enrichedSubAreas[i],
                    onTap: () {
                      ref
                          .read(selectedAreaIdProvider.notifier)
                          .selectArea(_enrichedSubAreas[i]['id']);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RouteListScreen(
                            areaId: _enrichedSubAreas[i]['id'],
                            areaName: _enrichedSubAreas[i]['name'],
                          ),
                        ),
                      );
                    },
                  ),
                  if (i < _enrichedSubAreas.length - 1)
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
                  Text('DogHub仙石原', style: WanWalkTypography.wwH4),
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
                    style: WanWalkTypography.wwH4.copyWith(height: 1.3),
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
