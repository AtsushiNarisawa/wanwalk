import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/route_search_params.dart';
import '../outing/route_detail_screen.dart';
import '../../providers/route_search_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/search/search_route_card.dart';
import '../../widgets/search/route_filter_bottom_sheet.dart';

/// ルート検索画面
class RouteSearchScreen extends ConsumerStatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  ConsumerState<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends ConsumerState<RouteSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    ref.read(routeSearchStateProvider.notifier).nextPage();
  }

  void _onSearchChanged(String query) {
    ref.read(routeSearchStateProvider.notifier).updateQuery(
      query.isEmpty ? null : query,
    );
    ref.read(routeSearchStateProvider.notifier).resetPagination();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RouteFilterBottomSheet(),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(routeSearchStateProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchParams = ref.watch(routeSearchStateProvider);
    final searchResults = ref.watch(routeSearchResultsProvider(searchParams));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanMapColors.cardDark : Colors.white,
        elevation: 0,
        title: Text(
          'ルート検索',
          style: WanMapTypography.heading2,
        ),
        actions: [
          if (searchParams.hasFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'フィルターをクリア',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(isDark),
          _buildSortAndFilterBar(isDark, searchParams),
          Expanded(
            child: _buildSearchResults(isDark, searchResults),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.medium),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'ルート名や説明を検索',
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          filled: true,
          fillColor: isDark
              ? WanMapColors.backgroundDark
              : WanMapColors.backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WanMapSpacing.medium,
            vertical: WanMapSpacing.small,
          ),
        ),
      ),
    );
  }

  Widget _buildSortAndFilterBar(bool isDark, RouteSearchParams params) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanMapSpacing.medium,
        vertical: WanMapSpacing.small,
      ),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // ソート選択
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: RouteSortBy.values.map((sortBy) {
                  final isSelected = params.sortBy == sortBy;
                  return Padding(
                    padding: const EdgeInsets.only(right: WanMapSpacing.small),
                    child: ChoiceChip(
                      label: Text(sortBy.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(routeSearchStateProvider.notifier).updateSortBy(sortBy);
                          ref.read(routeSearchStateProvider.notifier).resetPagination();
                        }
                      },
                      selectedColor: WanMapColors.accent.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? WanMapColors.accent : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // フィルターボタン
          IconButton(
            icon: Badge(
              isLabelVisible: params.hasFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterSheet,
            tooltip: 'フィルター',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    bool isDark,
    AsyncValue<List<SearchRouteResult>> searchResults,
  ) {
    return searchResults.when(
      data: (routes) {
        if (routes.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(routeSearchResultsProvider);
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(WanMapSpacing.medium),
            itemCount: routes.length + 1,
            itemBuilder: (context, index) {
              if (index == routes.length) {
                return _buildLoadingIndicator();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: WanMapSpacing.medium),
                child: SearchRouteCard(
                  route: routes[index],
                  onTap: () {
                    // ルート詳細画面へ遷移
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RouteDetailScreen(
                          routeId: routes[index].routeId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(isDark, error.toString()),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Text(
            '検索結果がありません',
            style: WanMapTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanMapSpacing.small),
          Text(
            '別の条件で検索してみてください',
            style: WanMapTypography.body.copyWith(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.red.shade300 : Colors.red,
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Text(
            'エラーが発生しました',
            style: WanMapTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanMapSpacing.small),
          Text(
            error,
            style: WanMapTypography.caption.copyWith(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(WanMapSpacing.medium),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
