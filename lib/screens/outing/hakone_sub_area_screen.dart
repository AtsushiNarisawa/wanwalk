import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/area_provider.dart';
import 'route_list_screen.dart';

/// 箱根サブエリア選択画面
class HakoneSubAreaScreen extends ConsumerWidget {
  final List<Map<String, dynamic>> subAreas;

  const HakoneSubAreaScreen({
    super.key,
    required this.subAreas,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: const Text('箱根エリアを選ぶ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // DogHubバナー
          Padding(
            padding: const EdgeInsets.all(WanMapSpacing.lg),
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse('https://www.dog-hub.shop/');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/doghub_banner.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // サブエリア一覧
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
              itemCount: subAreas.length,
              itemBuilder: (context, index) {
                final area = subAreas[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < subAreas.length - 1 ? WanMapSpacing.md : WanMapSpacing.lg,
                  ),
                  child: _HakoneSubAreaCard(
                    areaData: area,
                    isDark: isDark,
                    onTap: () {
                      ref.read(selectedAreaIdProvider.notifier).selectArea(area['id']);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RouteListScreen(
                            areaId: area['id'],
                            areaName: area['name'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 箱根サブエリアカード
class _HakoneSubAreaCard extends StatelessWidget {
  final Map<String, dynamic> areaData;
  final bool isDark;
  final VoidCallback onTap;

  const _HakoneSubAreaCard({
    required this.areaData,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = areaData['name'] as String;
    final description = areaData['description'] as String?;
    final routeCount = areaData['route_count'] as int? ?? 0;

    // エリア名から「箱根・」を除去してサブエリア名を取得
    final subAreaName = name.replaceFirst('箱根・', '');

    // エリアごとのアイコンとカラー
    final iconData = _getAreaIcon(subAreaName);
    final accentColor = _getAreaColor(subAreaName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(WanMapSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // エリアアイコン
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor,
                        accentColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: WanMapSpacing.md),
                // エリア名とルート数
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subAreaName,
                        style: WanMapTypography.titleLarge.copyWith(
                          color: isDark
                              ? WanMapColors.textPrimaryDark
                              : WanMapColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.route,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$routeCount件のルート',
                            style: WanMapTypography.bodySmall.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
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
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: WanMapSpacing.md),
              Text(
                description,
                style: WanMapTypography.bodySmall.copyWith(
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// エリアごとのアイコンを返す
  IconData _getAreaIcon(String subAreaName) {
    if (subAreaName.contains('仙石原')) {
      return Icons.grass; // DogHub所在地、高原
    } else if (subAreaName.contains('芦ノ湖')) {
      return Icons.water; // 湖
    } else if (subAreaName.contains('湯本')) {
      return Icons.hot_tub; // 温泉
    } else if (subAreaName.contains('宮ノ下')) {
      return Icons.museum; // 美術館・文化
    } else if (subAreaName.contains('強羅')) {
      return Icons.terrain; // 高原・山
    }
    return Icons.location_city;
  }

  /// エリアごとのカラーを返す
  Color _getAreaColor(String subAreaName) {
    if (subAreaName.contains('仙石原')) {
      return const Color(0xFF4CAF50); // 緑（高原）
    } else if (subAreaName.contains('芦ノ湖')) {
      return const Color(0xFF2196F3); // 青（湖）
    } else if (subAreaName.contains('湯本')) {
      return const Color(0xFFFF9800); // オレンジ（温泉）
    } else if (subAreaName.contains('宮ノ下')) {
      return const Color(0xFF9C27B0); // 紫（文化）
    } else if (subAreaName.contains('強羅')) {
      return const Color(0xFF795548); // 茶（山）
    }
    return WanMapColors.accent;
  }
}
