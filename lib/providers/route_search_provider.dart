import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_search_params.dart';
import '../services/route_search_service.dart';
import 'auth_provider.dart';

/// RouteSearchService プロバイダー
final routeSearchServiceProvider = Provider<RouteSearchService>((ref) {
  return RouteSearchService(Supabase.instance.client);
});

/// ルート検索結果プロバイダー
final routeSearchResultsProvider = FutureProvider.family<
    List<SearchRouteResult>,
    RouteSearchParams>((ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final service = ref.read(routeSearchServiceProvider);
  return await service.searchRoutes(
    userId: user.id,
    params: params,
  );
});

/// 検索パラメータ状態管理
class RouteSearchStateNotifier extends StateNotifier<RouteSearchParams> {
  RouteSearchStateNotifier() : super(RouteSearchParams.empty);

  /// 検索クエリを更新
  void updateQuery(String? query) {
    state = state.copyWith(query: query);
  }

  /// エリアフィルターを更新
  void updateAreaFilter(List<String>? areaIds) {
    state = state.copyWith(areaIds: areaIds);
  }

  /// 難易度フィルターを更新
  void updateDifficultyFilter(List<String>? difficulties) {
    state = state.copyWith(difficulties: difficulties);
  }

  /// 距離範囲フィルターを更新
  void updateDistanceRange(double? minKm, double? maxKm) {
    state = state.copyWith(
      minDistanceKm: minKm,
      maxDistanceKm: maxKm,
    );
  }

  /// 所要時間範囲フィルターを更新
  void updateDurationRange(int? minMin, int? maxMin) {
    state = state.copyWith(
      minDurationMin: minMin,
      maxDurationMin: maxMin,
    );
  }

  /// 特徴タグフィルターを更新
  void updateFeaturesFilter(List<String>? features) {
    state = state.copyWith(features: features);
  }

  /// 季節フィルターを更新
  void updateSeasonsFilter(List<String>? seasons) {
    state = state.copyWith(bestSeasons: seasons);
  }

  /// ソート順を更新
  void updateSortBy(RouteSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  /// オフセットを更新（ページネーション）
  void updateOffset(int offset) {
    state = state.copyWith(offset: offset);
  }

  /// フィルターをクリア
  void clearFilters() {
    state = RouteSearchParams.empty;
  }

  /// 次のページ
  void nextPage() {
    state = state.copyWith(offset: state.offset + state.limit);
  }

  /// 前のページ
  void previousPage() {
    if (state.offset >= state.limit) {
      state = state.copyWith(offset: state.offset - state.limit);
    }
  }

  /// 最初のページに戻る
  void resetPagination() {
    state = state.copyWith(offset: 0);
  }
}

/// 検索パラメータステートプロバイダー
final routeSearchStateProvider = StateNotifierProvider<RouteSearchStateNotifier, RouteSearchParams>((ref) {
  return RouteSearchStateNotifier();
});
