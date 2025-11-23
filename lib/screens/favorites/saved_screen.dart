import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/favorites/favorite_route_card.dart';
import '../../widgets/favorites/bookmarked_pin_card.dart';

/// 保存済み画面（お気に入りルート・保存したピン）
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _routesScrollController = ScrollController();
  final ScrollController _pinsScrollController = ScrollController();

  int _routesOffset = 0;
  int _pinsOffset = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _routesScrollController.addListener(_onRoutesScroll);
    _pinsScrollController.addListener(_onPinsScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _routesScrollController.dispose();
    _pinsScrollController.dispose();
    super.dispose();
  }

  void _onRoutesScroll() {
    if (_routesScrollController.position.pixels >=
        _routesScrollController.position.maxScrollExtent * 0.8) {
      _loadMoreRoutes();
    }
  }

  void _onPinsScroll() {
    if (_pinsScrollController.position.pixels >=
        _pinsScrollController.position.maxScrollExtent * 0.8) {
      _loadMorePins();
    }
  }

  void _loadMoreRoutes() {
    setState(() {
      _routesOffset += _pageSize;
    });
  }

  void _loadMorePins() {
    setState(() {
      _pinsOffset += _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanMapColors.cardDark : Colors.white,
        elevation: 0,
        title: Text(
          '保存済み',
          style: WanMapTypography.heading2,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: WanMapColors.accent,
          labelColor: WanMapColors.accent,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
          tabs: const [
            Tab(text: 'ルート'),
            Tab(text: 'ピン'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRoutesTab(isDark),
          _buildPinsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildRoutesTab(bool isDark) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return _buildLoginPrompt(isDark);
    }

    final params = FavoriteRoutesParams(
      userId: user.id,
      limit: _pageSize,
      offset: _routesOffset,
    );
    final favoritesAsync = ref.watch(favoriteRoutesProvider(params));

    return favoritesAsync.when(
      data: (routes) {
        if (routes.isEmpty && _routesOffset == 0) {
          return _buildEmptyState(
            isDark,
            Icons.favorite_border,
            'お気に入りルートがありません',
            '気になるルートを保存してみましょう',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _routesOffset = 0;
            });
            ref.invalidate(favoriteRoutesProvider);
          },
          child: ListView.builder(
            controller: _routesScrollController,
            padding: const EdgeInsets.all(WanMapSpacing.medium),
            itemCount: routes.length + 1,
            itemBuilder: (context, index) {
              if (index == routes.length) {
                return _buildLoadingIndicator();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: WanMapSpacing.medium),
                child: FavoriteRouteCard(
                  route: routes[index],
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/route_detail',
                      arguments: routes[index].routeId,
                    );
                  },
                  onUnfavorite: () async {
                    final service = ref.read(favoritesServiceProvider);
                    try {
                      await service.removeFavorite(
                        userId: user.id,
                        routeId: routes[index].routeId,
                      );
                      ref.invalidate(favoriteRoutesProvider);
                    } catch (e) {
                      print('Error removing favorite: $e');
                    }
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

  Widget _buildPinsTab(bool isDark) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return _buildLoginPrompt(isDark);
    }

    final params = BookmarkedPinsParams(
      userId: user.id,
      limit: _pageSize,
      offset: _pinsOffset,
    );
    final bookmarksAsync = ref.watch(bookmarkedPinsProvider(params));

    return bookmarksAsync.when(
      data: (pins) {
        if (pins.isEmpty && _pinsOffset == 0) {
          return _buildEmptyState(
            isDark,
            Icons.bookmark_border,
            '保存したピンがありません',
            '気になるピンを保存してみましょう',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _pinsOffset = 0;
            });
            ref.invalidate(bookmarkedPinsProvider);
          },
          child: ListView.builder(
            controller: _pinsScrollController,
            padding: const EdgeInsets.all(WanMapSpacing.medium),
            itemCount: pins.length + 1,
            itemBuilder: (context, index) {
              if (index == pins.length) {
                return _buildLoadingIndicator();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: WanMapSpacing.medium),
                child: BookmarkedPinCard(
                  pin: pins[index],
                  onTap: () {
                    // ピン詳細を表示
                    // TODO: ピン詳細ダイアログの実装
                  },
                  onUnbookmark: () async {
                    final service = ref.read(favoritesServiceProvider);
                    try {
                      await service.removePinBookmark(
                        userId: user.id,
                        pinId: pins[index].pinId,
                      );
                      ref.invalidate(bookmarkedPinsProvider);
                    } catch (e) {
                      print('Error removing bookmark: $e');
                    }
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

  Widget _buildLoginPrompt(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Text(
            'ログインが必要です',
            style: WanMapTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanMapSpacing.medium),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WanMapColors.accent,
            ),
            child: const Text('ログイン'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Text(
            title,
            style: WanMapTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanMapSpacing.small),
          Text(
            subtitle,
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
