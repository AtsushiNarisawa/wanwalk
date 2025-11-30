import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';
import '../../widgets/area_selection_chips.dart';
import '../../widgets/public_routes_map_view.dart';
import '../../widgets/photo_route_card.dart';
import '../outing/route_detail_screen.dart';

/// 選択エリアを管理するProvider
final selectedAreaProvider = StateProvider<String?>((ref) => null);

/// 公開ルート一覧を取得するProvider（エリアフィルタリング対応）
final filteredPublicRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final selectedArea = ref.watch(selectedAreaProvider);
  return RouteService().getPublicRoutes(
    limit: 50,
    area: selectedArea,
  );
});

/// 公開ルート一覧画面（新版）
class PublicRoutesScreen extends ConsumerWidget {
  const PublicRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedArea = ref.watch(selectedAreaProvider);
    final routesAsync = ref.watch(filteredPublicRoutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('公開ルート'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(filteredPublicRoutesProvider);
            },
            tooltip: '更新',
          ),
        ],
      ),
      body: routesAsync.when(
        data: (routes) => _buildContent(context, ref, routes, selectedArea),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  /// コンテンツを構築
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<RouteModel> routes,
    String? selectedArea,
  ) {
    // ルートポイントを読み込んだルートリスト（マップビュー用）
    final routesWithPoints = routes.where((r) => r.points.isNotEmpty).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(filteredPublicRoutesProvider);
      },
      child: CustomScrollView(
        slivers: [
          // エリア選択チップ
          SliverToBoxAdapter(
            child: AreaSelectionChips(
              selectedArea: selectedArea,
              onAreaSelected: (area) {
                ref.read(selectedAreaProvider.notifier).state = area;
              },
            ),
          ),

          // マップビュー（人気ルート一覧ではさまざまなエリアが混在するため非表示）
          // if (routesWithPoints.isNotEmpty)
          //   SliverToBoxAdapter(
          //     child: PublicRoutesMapView(
          //       routes: routesWithPoints,
          //       selectedArea: selectedArea,
          //       onRouteTapped: (routeId) {
          //         Navigator.of(context).push(
          //           MaterialPageRoute(
          //             builder: (_) => RouteDetailScreen(routeId: routeId),
          //           ),
          //         );
          //       },
          //     ),
          //   ),

          // セクションヘッダー
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.list, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'ルート一覧',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${routes.length}件',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ルート一覧
          if (routes.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(context, selectedArea),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final route = routes[index];
                    return PhotoRouteCard(
                      route: route,
                      onTap: () {
                        if (route.id != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RouteDetailScreen(routeId: route.id!),
                            ),
                          );
                        }
                      },
                    );
                  },
                  childCount: routes.length,
                ),
              ),
            ),

          // 下部余白
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  /// 空の状態
  Widget _buildEmptyState(BuildContext context, String? selectedArea) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            selectedArea != null
                ? 'このエリアに公開ルートがありません'
                : '公開ルートがありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedArea != null
                ? '別のエリアを選択してください'
                : 'ルートを公開すると、ここに表示されます',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// エラー状態
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
