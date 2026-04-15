import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../providers/area_provider.dart';
import '../../providers/area_list_screen_provider.dart';
import '../../widgets/phase1/area_card.dart';
import 'route_list_screen.dart';
import 'hakone_sub_area_screen.dart';
import '../../utils/logger.dart';

/// エリア一覧画面（Phase 1 — Wildboundsトーン）
class AreaListScreen extends ConsumerStatefulWidget {
  const AreaListScreen({super.key});

  @override
  ConsumerState<AreaListScreen> createState() => _AreaListScreenState();
}

class _AreaListScreenState extends ConsumerState<AreaListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProviderForAreaList.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      appLog('🟢 AreaListScreen.build() called');
    }
    final areasAsync = ref.watch(filteredAreasProvider);
    final prefecturesAsync = ref.watch(prefecturesProvider);
    final selectedPrefecture = ref.watch(selectedPrefectureProviderForAreaList);
    final sortOption = ref.watch(areaSortOptionProvider);

    return Scaffold(
      backgroundColor: WanWalkColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: WanWalkColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: WanWalkColors.textPrimary),
        title: const Text(
          'エリアを選ぶ',
          style: TextStyle(
            fontFamily: 'NotoSerifJP',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: WanWalkColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          const SizedBox(height: WanWalkSpacing.s3),
          _buildFilterSortBar(
              context, prefecturesAsync, selectedPrefecture, sortOption),
          const SizedBox(height: WanWalkSpacing.s3),
          areasAsync.when(
            data: (areas) => _buildAreaCountHeader(areas.length),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          Expanded(
            child: areasAsync.when(
              data: (areas) {
                if (areas.isEmpty) {
                  return _buildEmptyState('該当するエリアがありません');
                }
                return RefreshIndicator(
                  color: WanWalkColors.accentPrimary,
                  onRefresh: () async {
                    ref.invalidate(filteredAreasProvider);
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      WanWalkSpacing.s4,
                      WanWalkSpacing.s2,
                      WanWalkSpacing.s4,
                      WanWalkSpacing.s7,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: WanWalkSpacing.s5,
                      crossAxisSpacing: WanWalkSpacing.s4,
                      childAspectRatio: 0.64,
                    ),
                    itemCount: areas.length,
                    itemBuilder: (context, index) {
                      final area = areas[index];
                      final isHakoneGroup =
                          area['is_hakone_group'] as bool? ?? false;
                      return AreaCard(
                        name: area['name'] as String,
                        prefecture: (area['prefecture'] as String?) ?? '',
                        heroImageUrl: area['hero_image_url'] as String?,
                        routeCount: (area['route_count'] as int?) ?? 0,
                        onTap: () {
                          if (isHakoneGroup) {
                            final subAreas = area['sub_areas']
                                as List<Map<String, dynamic>>;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HakoneSubAreaScreen(
                                  subAreas: subAreas,
                                ),
                              ),
                            );
                          } else {
                            ref
                                .read(selectedAreaIdProvider.notifier)
                                .selectArea(area['id']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RouteListScreen(
                                  areaId: area['id'],
                                  areaName: area['name'],
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: WanWalkColors.accentPrimary,
                ),
              ),
              error: (error, stack) {
                if (kDebugMode) {
                  appLog('❌ エリア一覧読み込みエラー: $error');
                }
                return _buildEmptyState('エリアの読み込みに失敗しました');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.s4),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: WanWalkTypography.wwBody,
        decoration: InputDecoration(
          hintText: 'エリア名・説明文で検索',
          hintStyle: WanWalkTypography.wwBody.copyWith(
            color: WanWalkColors.textTertiary,
          ),
          prefixIcon: Icon(
            PhosphorIcons.magnifyingGlass(),
            size: 20,
            color: WanWalkColors.textSecondary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    PhosphorIcons.x(),
                    size: 18,
                    color: WanWalkColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    ref
                        .read(searchQueryProviderForAreaList.notifier)
                        .state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: WanWalkColors.bgSecondary,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: WanWalkSpacing.s4, vertical: WanWalkSpacing.s3),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(WanWalkSpacing.radiusMd),
            borderSide:
                const BorderSide(color: WanWalkColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(WanWalkSpacing.radiusMd),
            borderSide:
                const BorderSide(color: WanWalkColors.accentPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSortBar(
    BuildContext context,
    AsyncValue<List<String>> prefecturesAsync,
    String? selectedPrefecture,
    AreaSortOption sortOption,
  ) {
    InputDecoration deco(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: WanWalkTypography.wwLabel.copyWith(
          color: WanWalkColors.textSecondary,
          letterSpacing: 0.8,
        ),
        prefixIcon: Icon(icon, size: 18, color: WanWalkColors.textSecondary),
        filled: true,
        fillColor: WanWalkColors.bgPrimary,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: WanWalkSpacing.s3, vertical: WanWalkSpacing.s2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          borderSide: const BorderSide(color: WanWalkColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          borderSide: const BorderSide(color: WanWalkColors.accentPrimary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.s4),
      child: Row(
        children: [
          Expanded(
            child: prefecturesAsync.when(
              data: (prefectures) {
                return DropdownButtonFormField<String?>(
                  value: selectedPrefecture,
                  isExpanded: true,
                  style: WanWalkTypography.wwBodySm,
                  decoration: deco('都道府県', PhosphorIcons.mapPin()),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('すべて', overflow: TextOverflow.ellipsis),
                    ),
                    ...prefectures.map<DropdownMenuItem<String?>>((prefecture) {
                      return DropdownMenuItem<String?>(
                        value: prefecture,
                        child:
                            Text(prefecture, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    ref
                        .read(selectedPrefectureProviderForAreaList.notifier)
                        .state = value;
                  },
                );
              },
              loading: () => const SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: WanWalkColors.accentPrimary,
                    ),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox(),
            ),
          ),
          const SizedBox(width: WanWalkSpacing.s3),
          Expanded(
            child: DropdownButtonFormField<AreaSortOption>(
              value: sortOption,
              isExpanded: true,
              style: WanWalkTypography.wwBodySm,
              decoration: deco('並び替え', PhosphorIcons.funnel()),
              items: AreaSortOption.values.map((option) {
                return DropdownMenuItem<AreaSortOption>(
                  value: option,
                  child: Text(option.label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(areaSortOptionProvider.notifier).state = value;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCountHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.s4,
        vertical: WanWalkSpacing.s2,
      ),
      child: Row(
        children: [
          Text(
            '$count',
            style: WanWalkTypography.wwNumeric.copyWith(
              fontSize: 14,
              color: WanWalkColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'エリア',
            style: WanWalkTypography.wwBodySm.copyWith(
              color: WanWalkColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.mapPin(),
            size: 48,
            color: WanWalkColors.textTertiary,
          ),
          const SizedBox(height: WanWalkSpacing.s4),
          Text(
            message,
            style: WanWalkTypography.wwBody.copyWith(
              color: WanWalkColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
