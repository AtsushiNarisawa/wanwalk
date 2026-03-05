import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../providers/area_provider.dart';
import '../../providers/area_list_screen_provider.dart';
import 'route_list_screen.dart';
import 'hakone_sub_area_screen.dart';

/// エリア一覧画面（検索・フィルタ・ソート対応）
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
      print('🟢 AreaListScreen.build() called');
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final areasAsync = ref.watch(filteredAreasProvider);
    final prefecturesAsync = ref.watch(prefecturesProvider);
    final selectedPrefecture = ref.watch(selectedPrefectureProviderForAreaList);
    final sortOption = ref.watch(areaSortOptionProvider);

    return Scaffold(
      backgroundColor: isDark
          ? WanWalkColors.backgroundDark
          : WanWalkColors.backgroundLight,
      appBar: AppBar(
        title: const Text('エリアを選ぶ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 検索バー
          _buildSearchBar(context, isDark),
          const SizedBox(height: WanWalkSpacing.md),
          // フィルタ・ソートバー
          _buildFilterSortBar(context, isDark, prefecturesAsync, selectedPrefecture, sortOption),
          const SizedBox(height: WanWalkSpacing.md),
          // 件数表示（固定）
          areasAsync.when(
            data: (areas) => _buildAreaCountHeader(isDark, areas.length),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          // エリアカード一覧（スクロール可能）
          Expanded(
            child: areasAsync.when(
              data: (areas) {
                if (areas.isEmpty) {
                  return _buildEmptyState(isDark, '該当するエリアがありません');
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(filteredAreasProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(WanWalkSpacing.lg),
                    itemCount: areas.length,
                    itemBuilder: (context, index) {
                      final area = areas[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < areas.length - 1 ? WanWalkSpacing.md : 0,
                        ),
                        child: _AreaCard(
                          areaData: area,
                          isDark: isDark,
                          onTap: () {
                            // 箱根グループの場合はサブエリア選択画面へ
                            final isHakoneGroup = area['is_hakone_group'] as bool? ?? false;
                            if (isHakoneGroup) {
                              final subAreas = area['sub_areas'] as List<Map<String, dynamic>>;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HakoneSubAreaScreen(
                                    subAreas: subAreas,
                                  ),
                                ),
                              );
                            } else {
                              // 通常のエリアはルート一覧へ
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
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                if (kDebugMode) {
                  print('❌ エリア一覧読み込みエラー: $error');
                }
                return _buildEmptyState(isDark, 'エリアの読み込みに失敗しました');
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 検索バー
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.md),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'エリア名・説明文で検索',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProviderForAreaList.notifier).state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// フィルタ・ソートバー
  Widget _buildFilterSortBar(
    BuildContext context,
    bool isDark,
    AsyncValue<List<String>> prefecturesAsync,
    String? selectedPrefecture,
    AreaSortOption sortOption,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.md),
      child: Column(
        children: [
          // 都道府県フィルタ
          prefecturesAsync.when(
            data: (prefectures) {
              return DropdownButtonFormField<String?>(
                value: selectedPrefecture,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: '都道府県',
                  prefixIcon: const Icon(Icons.location_city, size: 20),
                  filled: true,
                  fillColor: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('すべて', overflow: TextOverflow.ellipsis),
                  ),
                  ...prefectures.map<DropdownMenuItem<String?>>((prefecture) {
                    return DropdownMenuItem<String?>(
                      value: prefecture,
                      child: Text(prefecture, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  ref.read(selectedPrefectureProviderForAreaList.notifier).state = value;
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: WanWalkSpacing.sm),
          // ソート順
          DropdownButtonFormField<AreaSortOption>(
            value: sortOption,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'ソート',
              prefixIcon: const Icon(Icons.sort, size: 20),
              filled: true,
              fillColor: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
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
        ],
      ),
    );
  }

  /// 件数表示ヘッダー（固定）
  Widget _buildAreaCountHeader(bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.lg,
        vertical: WanWalkSpacing.sm,
      ),
      child: Text(
        '${count}件のエリア',
        style: WanWalkTypography.bodyMedium.copyWith(
          color: isDark
              ? WanWalkColors.textSecondaryDark
              : WanWalkColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: isDark
                ? WanWalkColors.textSecondaryDark
                : WanWalkColors.textSecondaryLight,
          ),
          const SizedBox(height: WanWalkSpacing.md),
          Text(
            message,
            style: WanWalkTypography.bodyLarge.copyWith(
              color: isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// エリアカード
class _AreaCard extends StatelessWidget {
  final Map<String, dynamic> areaData;
  final bool isDark;
  final VoidCallback onTap;

  const _AreaCard({
    required this.areaData,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final routeCount = areaData['route_count'] as int? ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(WanWalkSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // エリアアイコン
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    WanWalkColors.accent,
                    WanWalkColors.accent.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_city,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: WanWalkSpacing.md),
            // エリア情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          areaData['name'] as String,
                          style: WanWalkTypography.bodyLarge.copyWith(
                            color: isDark
                                ? WanWalkColors.textPrimaryDark
                                : WanWalkColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: WanWalkColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$routeCount件',
                          style: WanWalkTypography.caption.copyWith(
                            color: WanWalkColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WanWalkSpacing.xs),
                  Text(
                    areaData['prefecture'] as String,
                    style: WanWalkTypography.bodySmall.copyWith(
                      color: WanWalkColors.accent,
                    ),
                  ),
                  if (areaData['description'] != null) ...[
                    const SizedBox(height: WanWalkSpacing.xs),
                    Text(
                      areaData['description'] as String,
                      style: WanWalkTypography.caption.copyWith(
                        color: isDark
                            ? WanWalkColors.textSecondaryDark
                            : WanWalkColors.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: WanWalkSpacing.sm),
            // 矢印アイコン
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
