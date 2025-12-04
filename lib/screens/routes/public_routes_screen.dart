import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/official_route.dart';
import '../../providers/official_routes_screen_provider.dart';
import '../../providers/area_provider.dart';
import '../outing/route_detail_screen.dart';

/// 公式ルート一覧画面（official_routes用）
class PublicRoutesScreen extends ConsumerStatefulWidget {
  const PublicRoutesScreen({super.key});

  @override
  ConsumerState<PublicRoutesScreen> createState() => _PublicRoutesScreenState();
}

class _PublicRoutesScreenState extends ConsumerState<PublicRoutesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // デバウンス処理（300ms後に検索実行）
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
        title: const Text('公式ルート一覧'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(officialRoutesProvider);
            },
            tooltip: '更新',
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索バー
          _buildSearchBar(isDark),

          // フィルタ・ソートバー
          _buildFilterSortBar(context, isDark, areasAsync, selectedAreaId, sortOption),

          // ルート一覧
          Expanded(
            child: routesAsync.when(
              data: (routes) => _buildRouteList(context, isDark, routes),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(context, isDark, error),
            ),
          ),
        ],
      ),
    );
  }

  /// 検索バー
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(WanMapSpacing.md),
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
              return DropdownMenuItem<RouteSortOption>(
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

  /// ルート一覧
  Widget _buildRouteList(BuildContext context, bool isDark, List<OfficialRoute> routes) {
    if (routes.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(officialRoutesProvider);
      },
      child: CustomScrollView(
        slivers: [
          // 固定ヘッダー（件数表示）
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: WanMapSpacing.md,
                vertical: WanMapSpacing.sm,
              ),
              color: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
              child: Text(
                '${routes.length}件のルート',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                ),
              ),
            ),
          ),
          // スクロール可能なルート一覧
          SliverPadding(
            padding: const EdgeInsets.all(WanMapSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final route = routes[index];
                  return _OfficialRouteCard(
                    route: route,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteDetailScreen(routeId: route.id),
                        ),
                      );
                    },
                  );
                },
                childCount: routes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 空の状態
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 80,
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
            const SizedBox(height: WanMapSpacing.md),
            Text(
              '該当する公式ルートがありません',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: WanMapSpacing.sm),
            Text(
              '検索条件やエリアを変更してみてください',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// エラー状態
  Widget _buildErrorState(BuildContext context, bool isDark, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: WanMapSpacing.md),
            Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: WanMapSpacing.sm),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WanMapSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(officialRoutesProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 公式ルートカード
class _OfficialRouteCard extends StatelessWidget {
  final OfficialRoute route;
  final bool isDark;
  final VoidCallback onTap;

  const _OfficialRouteCard({
    required this.route,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: WanMapSpacing.md),
        height: 140, // カード高さを固定
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
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
            // サムネイル
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: route.thumbnailUrl != null
                  ? Image.network(
                      route.thumbnailUrl!,
                      width: 120,
                      height: 140, // カード高さに合わせる
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultThumbnail(),
                    )
                  : _buildDefaultThumbnail(),
            ),
            // ルート情報
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(WanMapSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: WanMapSpacing.xs),
                        Text(
                          route.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: WanMapSpacing.xs,
                      runSpacing: WanMapSpacing.xs,
                      children: [
                        _buildInfoChip(
                          Icons.straighten,
                          route.formattedDistance,
                          isDark,
                        ),
                        _buildDifficultyChip(route.difficultyLevel, isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 120,
      height: 140, // カード高さに合わせる
      color: WanMapColors.accent.withOpacity(0.2),
      child: Icon(
        Icons.route,
        size: 48,
        color: WanMapColors.accent,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: WanMapColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: WanMapColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(DifficultyLevel difficulty, bool isDark) {
    Color chipColor;
    switch (difficulty) {
      case DifficultyLevel.easy:
        chipColor = Colors.green;
        break;
      case DifficultyLevel.moderate:
        chipColor = Colors.orange;
        break;
      case DifficultyLevel.hard:
        chipColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          fontSize: 12,
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
