import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_icons.dart';
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
      backgroundColor: WanWalkColors.bgPrimary,
      appBar: AppBar(
        title: Text(
          '公式ルート',
          style: WanWalkTypography.wwH2,
        ),
        backgroundColor: WanWalkColors.bgPrimary,
        foregroundColor: WanWalkColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
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
        horizontal: WanWalkSpacing.s4,
        vertical: WanWalkSpacing.s2,
      ),
      child: TextField(
        controller: _searchController,
        style: WanWalkTypography.wwBody,
        decoration: InputDecoration(
          hintText: 'ルート名・説明文で検索',
          hintStyle: WanWalkTypography.wwBody.copyWith(
            color: WanWalkColors.textTertiary,
          ),
          prefixIcon: Icon(
            WanWalkIcons.magnifyingGlass,
            color: WanWalkColors.textSecondary,
            size: WanWalkIcons.sizeMd,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(WanWalkIcons.x, size: WanWalkIcons.sizeSm, color: WanWalkColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: WanWalkColors.bgPrimary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
            borderSide: BorderSide(color: WanWalkColors.borderStrong),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
            borderSide: BorderSide(color: WanWalkColors.borderStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
            borderSide: const BorderSide(color: WanWalkColors.accentPrimary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.s4),
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
                icon: WanWalkIcons.mapPin,
                label: selectedArea?.name ?? 'すべてのエリア',
                isActive: selectedAreaId != null,
                isDark: isDark,
                onTap: () => _showAreaFilter(context, isDark, areas, selectedAreaId),
              );
            },
            loading: () => const SizedBox(width: 100),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(width: WanWalkSpacing.s2),
          // ソートチップ
          _FilterChip(
            icon: WanWalkIcons.list,
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
        decoration: const BoxDecoration(
          color: WanWalkColors.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(WanWalkSpacing.radiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: WanWalkSpacing.s3),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: WanWalkColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.s5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: WanWalkSpacing.s5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('エリアを選択', style: WanWalkTypography.wwH3),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.s3),
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
            SizedBox(height: MediaQuery.of(context).padding.bottom + WanWalkSpacing.s4),
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
        decoration: const BoxDecoration(
          color: WanWalkColors.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(WanWalkSpacing.radiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: WanWalkSpacing.s3),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: WanWalkColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.s5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: WanWalkSpacing.s5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('並び替え', style: WanWalkTypography.wwH3),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.s3),
            ...RouteSortOption.values.map((option) => _buildFilterOption(
              context, isDark,
              option.label,
              current == option,
              () {
                ref.read(sortOptionProvider.notifier).state = option;
                Navigator.pop(context);
              },
            )),
            SizedBox(height: MediaQuery.of(context).padding.bottom + WanWalkSpacing.s4),
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
        padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.s5, vertical: WanWalkSpacing.s4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: WanWalkTypography.wwBody.copyWith(
                  color: isSelected ? WanWalkColors.accentPrimary : WanWalkColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(WanWalkIcons.check, color: WanWalkColors.accentPrimary, size: WanWalkIcons.sizeMd),
          ],
        ),
      ),
    );
  }

  /// 件数表示ヘッダー
  Widget _buildRouteCountHeader(bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.s4,
        vertical: WanWalkSpacing.s2,
      ),
      child: Row(
        children: [
          Text(
            '$count件のルート',
            style: WanWalkTypography.wwCaption,
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
      color: WanWalkColors.accentPrimary,
      onRefresh: () async {
        ref.invalidate(officialRoutesProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.s4),
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
        padding: const EdgeInsets.all(WanWalkSpacing.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              WanWalkIcons.path,
              size: 48,
              color: WanWalkColors.textSecondary,
            ),
            const SizedBox(height: WanWalkSpacing.s4),
            Text('該当するルートがありません', style: WanWalkTypography.wwH4),
            const SizedBox(height: WanWalkSpacing.s2),
            Text(
              '検索条件やエリアを変更してみてください',
              style: WanWalkTypography.wwCaption,
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
        padding: const EdgeInsets.all(WanWalkSpacing.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(WanWalkIcons.warning, size: 56, color: WanWalkColors.semanticError),
            const SizedBox(height: WanWalkSpacing.s3),
            Text('エラーが発生しました', style: WanWalkTypography.wwH4),
            const SizedBox(height: WanWalkSpacing.s2),
            Text(
              error.toString(),
              style: WanWalkTypography.wwCaption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WanWalkSpacing.s5),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(officialRoutesProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WanWalkColors.accentPrimary,
                foregroundColor: WanWalkColors.textInverse,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
                ),
              ),
              child: const Text('再試行'),
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
    final color = isActive ? WanWalkColors.accentPrimary : WanWalkColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? WanWalkColors.accentPrimarySoft : WanWalkColors.bgPrimary,
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
          border: Border.all(
            color: isActive ? WanWalkColors.accentPrimary : WanWalkColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: WanWalkIcons.sizeSm, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: WanWalkTypography.wwBodySm.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            Icon(WanWalkIcons.caretDown, size: WanWalkIcons.sizeSm, color: color),
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
        margin: const EdgeInsets.only(bottom: WanWalkSpacing.s3),
        decoration: BoxDecoration(
          color: WanWalkColors.bgPrimary,
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
        ),
        child: Row(
          children: [
            // サムネイル
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(WanWalkSpacing.radiusMd),
                bottomLeft: Radius.circular(WanWalkSpacing.radiusMd),
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
                padding: const EdgeInsets.all(WanWalkSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: WanWalkTypography.wwH4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route.description,
                          style: WanWalkTypography.wwCaption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: WanWalkSpacing.s2),
                    Wrap(
                      spacing: WanWalkSpacing.s2,
                      runSpacing: WanWalkSpacing.s1,
                      children: [
                        _buildInfoChip(
                          WanWalkIcons.ruler,
                          route.formattedDistance,
                        ),
                        if (route.estimatedMinutes > 0)
                          _buildInfoChip(
                            WanWalkIcons.clock,
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
      color: WanWalkColors.accentPrimarySoft,
      alignment: Alignment.center,
      child: Icon(
        WanWalkIcons.path,
        size: 36,
        color: WanWalkColors.accentPrimary,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: WanWalkColors.accentPrimarySoft,
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: WanWalkIcons.sizeXs, color: WanWalkColors.accentPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: WanWalkTypography.wwLabel.copyWith(
              color: WanWalkColors.accentPrimary,
              letterSpacing: 0.4,
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
