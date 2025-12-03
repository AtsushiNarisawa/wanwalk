import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/route_service.dart';
import '../models/official_route.dart';

/// ソート順の選択肢
enum RouteSortOption {
  popularity('人気順', 'popularity'),
  distanceAsc('距離が短い順', 'distance_asc'),
  distanceDesc('距離が長い順', 'distance_desc'),
  durationAsc('時間が短い順', 'duration_asc'),
  durationDesc('時間が長い順', 'duration_desc'),
  newest('新着順', 'newest');

  const RouteSortOption(this.label, this.value);
  final String label;
  final String value;
}

/// 検索クエリを管理するProvider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 選択中のエリアIDを管理するProvider
final selectedAreaIdProviderForPublicRoutes = StateProvider<String?>((ref) => null);

/// ソート順を管理するProvider
final sortOptionProvider = StateProvider<RouteSortOption>((ref) => RouteSortOption.popularity);

/// 公式ルート一覧を取得するProvider（official_routes用）
final officialRoutesProvider = FutureProvider.autoDispose<List<OfficialRoute>>((ref) async {
  final searchQuery = ref.watch(searchQueryProvider);
  final areaId = ref.watch(selectedAreaIdProviderForPublicRoutes);
  final sortOption = ref.watch(sortOptionProvider);

  final routeService = RouteService();
  final routes = await routeService.searchOfficialRoutes(
    searchQuery: searchQuery.isEmpty ? null : searchQuery,
    areaId: areaId,
    sortBy: sortOption.value,
    limit: 100, // 全件表示のため上限を引き上げ
  );

  return routes.map((json) {
    try {
      return OfficialRoute.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      print('❌ OfficialRoute.fromJson エラー: $e');
      print('❌ 問題のJSON: $json');
      rethrow;
    }
  }).toList();
});
