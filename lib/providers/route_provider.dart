import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_model.dart';
import '../services/route_service.dart';

/// ルート情報の状態クラス
class RouteState {
  final List<RouteModel> routes;
  final List<RouteModel> publicRoutes;
  final RouteModel? selectedRoute;
  final bool isLoading;
  final String? errorMessage;
  final String? areaFilter;

  RouteState({
    this.routes = const [],
    this.publicRoutes = const [],
    this.selectedRoute,
    this.isLoading = false,
    this.errorMessage,
    this.areaFilter,
  });

  bool get hasRoutes => routes.isNotEmpty;
  bool get hasPublicRoutes => publicRoutes.isNotEmpty;

  RouteState copyWith({
    List<RouteModel>? routes,
    List<RouteModel>? publicRoutes,
    RouteModel? selectedRoute,
    bool? isLoading,
    String? errorMessage,
    String? areaFilter,
    bool clearSelectedRoute = false,
  }) {
    return RouteState(
      routes: routes ?? this.routes,
      publicRoutes: publicRoutes ?? this.publicRoutes,
      selectedRoute: clearSelectedRoute ? null : (selectedRoute ?? this.selectedRoute),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      areaFilter: areaFilter ?? this.areaFilter,
    );
  }
}

/// ルート情報の状態を管理するRiverpod StateNotifier
class RouteNotifier extends StateNotifier<RouteState> {
  final RouteService _routeService = RouteService();

  RouteNotifier() : super(RouteState());

  /// ユーザーのルート一覧を読み込み
  Future<void> loadUserRoutes(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final routes = await _routeService.getUserRoutes(userId);
      state = state.copyWith(routes: routes, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'ルート一覧の取得に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// 公開ルート一覧を読み込み
  Future<void> loadPublicRoutes({
    int limit = 20,
    String? area,
    bool includePoints = true,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, areaFilter: area);

    try {
      final publicRoutes = await _routeService.getPublicRoutes(
        limit: limit,
        area: area,
        includePoints: includePoints,
      );
      state = state.copyWith(publicRoutes: publicRoutes, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: '公開ルートの取得に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// ルート詳細を取得
  Future<RouteModel?> getRouteDetail(String routeId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final route = await _routeService.getRouteDetail(routeId);
      if (route != null) {
        state = state.copyWith(selectedRoute: route, isLoading: false);
      } else {
        state = state.copyWith(
          errorMessage: 'ルート詳細の取得に失敗しました',
          isLoading: false,
        );
      }
      return route;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'ルート詳細の取得に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return null;
    }
  }

  /// ルートを保存
  Future<String?> saveRoute(RouteModel route) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final routeId = await _routeService.saveRoute(route);
      if (routeId != null) {
        await loadUserRoutes(route.userId);
      }
      state = state.copyWith(isLoading: false);
      return routeId;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'ルートの保存に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return null;
    }
  }

  /// ルートを削除
  Future<bool> deleteRoute(String routeId, String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final success = await _routeService.deleteRoute(routeId, userId);
      if (success) {
        final updatedRoutes = state.routes.where((r) => r.id != routeId).toList();
        state = state.copyWith(
          routes: updatedRoutes,
          isLoading: false,
          clearSelectedRoute: state.selectedRoute?.id == routeId,
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'ルートの削除に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// ルートを選択
  void selectRoute(RouteModel route) {
    state = state.copyWith(selectedRoute: route);
  }

  /// ルートの選択を解除
  void clearSelectedRoute() {
    state = state.copyWith(clearSelectedRoute: true);
  }

  /// エラーメッセージをクリア
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// RouteProvider（Riverpod版）
final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) {
  return RouteNotifier();
});

/// 人気の公式ルート一覧を取得するProvider（ホーム画面用）
final popularRoutesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase.rpc('get_popular_routes', params: {
      'p_limit': 5,
      'p_offset': 0,
    }) as List<dynamic>;
    
    return response;
  } catch (e) {
    if (kDebugMode) {
      print('❌ 人気ルート取得エラー: $e');
    }
    return [];
  }
});
