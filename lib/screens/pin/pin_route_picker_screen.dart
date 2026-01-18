import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_spacing.dart';
import '../../config/wanmap_typography.dart';
import '../../providers/official_route_provider.dart';
import '../../providers/official_routes_screen_provider.dart';
import '../../providers/area_provider.dart';
import '../../models/official_route.dart';
import '../pin/pin_location_picker_screen.dart';

/// ピン投稿用のルート選択画面
/// 
/// 近くのルートを一覧表示し、ルートを選択する
class PinRoutePickerScreen extends ConsumerStatefulWidget {
  const PinRoutePickerScreen({super.key});

  @override
  ConsumerState<PinRoutePickerScreen> createState() => _PinRoutePickerScreenState();
}

class _PinRoutePickerScreenState extends ConsumerState<PinRoutePickerScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // デフォルトソートを「距離が短い順」に設定
    Future.microtask(() {
      ref.read(sortOptionProvider.notifier).state = RouteSortOption.distanceAsc;
      ref.read(searchQueryProvider.notifier).state = '';
      ref.read(selectedAreaIdProviderForPublicRoutes.notifier).state = null;
    });

    // 検索テキストの変更を監視
    _searchController.addListener(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.read(searchQueryProvider.notifier).state = _searchController.text;
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routesAsync = ref.watch(officialRoutesProvider);
    final areasAsync = ref.watch(areasProvider);
    final selectedAreaId = ref.watch(selectedAreaIdProviderForPublicRoutes);
    final sortOption = ref.watch(sortOptionProvider);

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: const Text('ルートを選択'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ガイドメッセージ
          Container(
            padding: const EdgeInsets.all(WanMapSpacing.md),
            margin: const EdgeInsets.all(WanMapSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? WanMapColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: WanMapColors.primary,
                  size: 20,
                ),
                const SizedBox(width: WanMapSpacing.sm),
                Expanded(
                  child: Text(
                    'ピンを投稿するルートを選択してください',
                    style: WanMapTypography.bodySmall.copyWith(
                      color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 検索バー
          _buildSearchBar(isDark),

          // フィルタ・ソートバー
          _buildFilterSortBar(context, isDark, areasAsync, selectedAreaId, sortOption),

          const SizedBox(height: WanMapSpacing.sm),

          // ルート一覧
          Expanded(
            child: routesAsync.when(
              data: (routes) {
                if (routes.isEmpty) {
                  return _buildEmptyState(isDark);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.md),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return _buildRouteCard(context, isDark, route);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(isDark, error),
            ),
          ),
        ],
      ),
    );
  }

  /// 検索バー
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ルート名・説明文で検索',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
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
    AsyncValue areasAsync,
    String? selectedAreaId,
    RouteSortOption sortOption,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: WanMapSpacing.sm),
          // エリアフィルタ
          areasAsync.when(
            data: (areas) {
              return DropdownButtonFormField<String?>(
                value: selectedAreaId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'エリア',
                  prefixIcon: const Icon(Icons.location_on, size: 20),
                  filled: true,
                  fillColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
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
                  ...areas.map<DropdownMenuItem<String?>>((area) {
                    return DropdownMenuItem<String?>(
                      value: area.id,
                      child: Text(area.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  ref.read(selectedAreaIdProviderForPublicRoutes.notifier).state = value;
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: WanMapSpacing.sm),
          // ソート順
          DropdownButtonFormField<RouteSortOption>(
            value: sortOption,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'ソート',
              prefixIcon: const Icon(Icons.sort, size: 20),
              filled: true,
              fillColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: RouteSortOption.values.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option.label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(sortOptionProvider.notifier).state = value;
              }
            },
          ),
        ],
      ),
    );
  }

  /// ルートカード
  Widget _buildRouteCard(BuildContext context, bool isDark, OfficialRoute route) {
    return Card(
      margin: const EdgeInsets.only(bottom: WanMapSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDark ? WanMapColors.cardDark : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PinLocationPickerScreen(
                routeId: route.id,
                routeName: route.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(WanMapSpacing.md),
          child: Row(
            children: [
              // ルートアイコン
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: WanMapColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.route,
                  color: WanMapColors.primary,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: WanMapSpacing.md),
              
              // ルート情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: WanMapTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 16,
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(route.distanceMeters / 1000).toStringAsFixed(1)}km',
                          style: WanMapTypography.bodySmall.copyWith(
                            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${route.estimatedMinutes}分',
                          style: WanMapTypography.bodySmall.copyWith(
                            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 矢印アイコン
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 空状態
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: WanMapSpacing.md),
          Text(
            'ルートが見つかりませんでした',
            style: WanMapTypography.titleMedium.copyWith(
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  /// エラー状態
  Widget _buildErrorState(bool isDark, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: WanMapSpacing.md),
          Text(
            'エラーが発生しました',
            style: WanMapTypography.titleMedium.copyWith(
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: WanMapSpacing.sm),
          Text(
            error.toString(),
            style: WanMapTypography.bodySmall.copyWith(
              color: Colors.red[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
