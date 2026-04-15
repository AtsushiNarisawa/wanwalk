import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
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
      backgroundColor: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          '公式ルート',
          style: WanWalkTypography.headlineSmall.copyWith(
            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: WanWalkColors.textSecondary),
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

          // フィルタ・ソートバー（チップ形式）
          _buildFilterChips(context, isDark, areasAsync, selectedAreaId, sortOption),

          const SizedBox(height: WanWalkSpacing.xs),

          // 件数表示
          routesAsync.when(
            data: (routes) => _buildRouteCountHeader(isDark, routes.length),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),

          // ルートカード一覧
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
      padding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.lg,
        vertical: WanWalkSpacing.sm,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ルート名・説明文で検索',
          hintStyle: WanWalkTypography.bodyMedium.copyWith(
            color: isDark ? WanWalkColors.textTertiaryDark : WanWalkColors.textTertiaryLight,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
          ),
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
          fillColor: isDark ? WanWalkColors.surfaceDark : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: WanWalkColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// フィルタ・ソートチップ
  Widget _buildFilterChips(
    BuildContext context,
    bool isDark,
    AsyncValue areasAsync,
    String? selectedAreaId,
    RouteSortOption sortOption,
  ) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
        children: [
          // エリアフィルタチップ
          areasAsync.when(
            data: (areas) {
              final selectedArea = selectedAreaId != null
                  ? areas.firstWhere(
                      (a) => a.id == selectedAreaId,
                      orElse: () => areas.first,
                    )
                  : null;
              return _FilterChip(
                icon: Icons.location_on_outlined,
                label: selectedArea?.name ?? 'すべてのエリア',
                isActive: selectedAreaId != null,
                isDark: isDark,
                onTap: () => _showAreaFilter(context, isDark, areas, selectedAreaId),
              );
            },
            loading: () => const SizedBox(width: 100),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(width: WanWalkSpacing.sm),
          // ソートチップ
          _FilterChip(
            icon: Icons.sort,
            label: sortOption.label,
            isActive: sortOption != RouteSortOption.popularity,
            isDark: isDark,
            onTap: () => _showSortOptions(context, isDark, sortOption),
          ),
        ],
      ),
    );
  }

  /// エリアフィルタ選択ダイアログ
  void _showAreaFilter(BuildContext context, bool isDark, List<dynamic> areas, String? selectedAreaId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: WanWalkSpacing.md),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
              child: Text(
                'エリアを選択',
                style: WanWalkTypography.titleMedium.copyWith(
                  color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.md),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildFilterOption(
                    context, isDark,
                    'すべてのエリア',
                    selectedAreaId == null,
                    () {
                      ref.read(selectedAreaIdProviderForPublicRoutes.notifier).state = null;
                      Navigator.pop(context);
                    },
                  ),
                  ...areas.map((area) => _buildFilterOption(
                    context, isDark,
                    area.name,
                    selectedAreaId == area.id,
                    () {
                      ref.read(selectedAreaIdProviderForPublicRoutes.notifier).state = area.id;
                      Navigator.pop(context);
                    },
                  )),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + WanWalkSpacing.md),
          ],
        ),
      ),
    );
  }

  /// ソートオプション選択ダイアログ
  void _showSortOptions(BuildContext context, bool isDark, RouteSortOption current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: WanWalkSpacing.md),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
              child: Text(
                '並び替え',
                style: WanWalkTypography.titleMedium.copyWith(
                  color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.md),
            ...RouteSortOption.values.map((option) => _buildFilterOption(
              context, isDark,
              option.label,
              current == option,
              () {
                ref.read(sortOptionProvider.notifier).state = option;
                Navigator.pop(context);
              },
            )),
            SizedBox(height: MediaQuery.of(context).padding.bottom + WanWalkSpacing.md),
          ],
        ),
      ),
    );
  }

  /// フィルタオプション行
  Widget _buildFilterOption(BuildContext context, bool isDark, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg, vertical: WanWalkSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: WanWalkTypography.bodyLarge.copyWith(
                  color: isSelected
                      ? WanWalkColors.primary
                      : (isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: WanWalkColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  /// 件数表示ヘッダー
  Widget _buildRouteCountHeader(bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.lg,
        vertical: WanWalkSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '$count件のルート',
            style: WanWalkTypography.bodyMedium.copyWith(
              color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
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
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
        itemCount: routes.length,
        itemBuilder: (context, index) {
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
      ),
    );
  }

  /// 空の状態
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanWalkSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: WanWalkColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.route,
                size: 40,
                color: WanWalkColors.accent,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.lg),
            Text(
              '該当するルートがありません',
              style: WanWalkTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            Text(
              '検索条件やエリアを変更してみてください',
              style: WanWalkTypography.bodyMedium.copyWith(
                color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
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
        padding: const EdgeInsets.all(WanWalkSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: WanWalkColors.error),
            const SizedBox(height: WanWalkSpacing.md),
            Text(
              'エラーが発生しました',
              style: WanWalkTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            Text(
              error.toString(),
              style: WanWalkTypography.bodySmall.copyWith(
                color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WanWalkSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(officialRoutesProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WanWalkColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// フィルタチップ
class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? WanWalkColors.primary.withOpacity(0.12)
              : (isDark ? WanWalkColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? WanWalkColors.primary
                : (isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? WanWalkColors.primary
                  : (isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: WanWalkTypography.bodySmall.copyWith(
                color: isActive
                    ? WanWalkColors.primary
                    : (isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isActive
                  ? WanWalkColors.primary
                  : (isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight),
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
        margin: const EdgeInsets.only(bottom: WanWalkSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: WanWalkColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultThumbnail(),
                    )
                  : _buildDefaultThumbnail(),
            ),
            // ルート情報
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(WanWalkSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: WanWalkTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route.description,
                          style: WanWalkTypography.bodySmall.copyWith(
                            color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: WanWalkSpacing.sm),
                    Wrap(
                      spacing: WanWalkSpacing.xs,
                      runSpacing: WanWalkSpacing.xs,
                      children: [
                        _buildInfoChip(
                          Icons.straighten,
                          route.formattedDistance,
                        ),
                        if (route.estimatedMinutes > 0)
                          _buildInfoChip(
                            Icons.schedule,
                            '${route.estimatedMinutes}分',
                          ),
                        _buildDifficultyChip(route.difficultyLevel),
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
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WanWalkColors.accent.withOpacity(0.2),
            WanWalkColors.accentLight.withOpacity(0.1),
          ],
        ),
      ),
      child: const Icon(
        Icons.route,
        size: 40,
        color: WanWalkColors.accent,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: WanWalkColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: WanWalkColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: WanWalkTypography.caption.copyWith(
              color: WanWalkColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 難易度バッジ（DESIGN_TOKENS.md §2 — Wildboundsトーン3段階）
  Widget _buildDifficultyChip(DifficultyLevel difficulty) {
    Color bg;
    Color fg;
    switch (difficulty) {
      case DifficultyLevel.easy:
        bg = WanWalkColors.levelEasy;
        fg = Colors.white;
        break;
      case DifficultyLevel.moderate:
        bg = WanWalkColors.bgTertiary;
        fg = WanWalkColors.textSecondary;
        break;
      case DifficultyLevel.hard:
        bg = WanWalkColors.accentPrimaryHover;
        fg = Colors.white;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          fontFamily: 'NotoSansJP',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: fg,
          height: 1.2,
        ),
      ),
    );
  }
}
