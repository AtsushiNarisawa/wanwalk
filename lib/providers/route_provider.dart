import 'package:flutter/foundation.dart';
import '../models/route_model.dart';
import '../services/route_service.dart';

/// ルート情報の状態を管理するProvider
class RouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
  
  List<RouteModel> _routes = [];
  List<RouteModel> _publicRoutes = [];
  RouteModel? _selectedRoute;
  bool _isLoading = false;
  String? _errorMessage;
  
  // 検索フィルタ
  String? _areaFilter;
  
  // Getters
  List<RouteModel> get routes => _routes;
  List<RouteModel> get publicRoutes => _publicRoutes;
  RouteModel? get selectedRoute => _selectedRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get areaFilter => _areaFilter;
  bool get hasRoutes => _routes.isNotEmpty;
  bool get hasPublicRoutes => _publicRoutes.isNotEmpty;
  
  /// ユーザーのルート一覧を読み込み
  Future<void> loadUserRoutes(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _routes = await _routeService.getUserRoutes(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'ルート一覧の取得に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 公開ルート一覧を読み込み
  Future<void> loadPublicRoutes({
    int limit = 20,
    String? area,
    bool includePoints = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _areaFilter = area;
    notifyListeners();
    
    try {
      _publicRoutes = await _routeService.getPublicRoutes(
        limit: limit,
        area: area,
        includePoints: includePoints,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '公開ルートの取得に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// ルート詳細を取得
  Future<RouteModel?> getRouteDetail(String routeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final route = await _routeService.getRouteDetail(routeId);
      _isLoading = false;
      
      if (route != null) {
        _selectedRoute = route;
      } else {
        _errorMessage = 'ルート詳細の取得に失敗しました';
      }
      
      notifyListeners();
      return route;
    } catch (e) {
      _errorMessage = 'ルート詳細の取得に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// ルートを保存
  Future<String?> saveRoute(RouteModel route) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final routeId = await _routeService.saveRoute(route);
      
      if (routeId != null) {
        // ローカルリストを更新
        final savedRoute = route.copyWith(id: routeId);
        _routes.insert(0, savedRoute); // 先頭に追加
        _isLoading = false;
        notifyListeners();
      }
      
      return routeId;
    } catch (e) {
      _errorMessage = 'ルートの保存に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// ルートを更新
  Future<bool> updateRoute({
    required String routeId,
    required String userId,
    required String title,
    String? description,
    required bool isPublic,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await _routeService.updateRoute(
        routeId: routeId,
        userId: userId,
        title: title,
        description: description,
        isPublic: isPublic,
      );
      
      if (success) {
        // ローカルリストを更新
        final index = _routes.indexWhere((r) => r.id == routeId);
        if (index != -1) {
          _routes[index] = _routes[index].copyWith(
            title: title,
            description: description,
            isPublic: isPublic,
          );
        }
        
        if (_selectedRoute?.id == routeId) {
          _selectedRoute = _selectedRoute!.copyWith(
            title: title,
            description: description,
            isPublic: isPublic,
          );
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'ルートの更新に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// ルートを削除
  Future<bool> deleteRoute(String routeId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await _routeService.deleteRoute(routeId, userId);
      
      if (success) {
        _routes.removeWhere((r) => r.id == routeId);
        _publicRoutes.removeWhere((r) => r.id == routeId);
        
        if (_selectedRoute?.id == routeId) {
          _selectedRoute = null;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'ルートの削除に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 特定ユーザーの公開ルートを取得
  Future<void> loadPublicRoutesByUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _publicRoutes = await _routeService.getPublicRoutesByUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'ユーザーの公開ルート取得に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// ルートを選択
  void selectRoute(RouteModel route) {
    _selectedRoute = route;
    notifyListeners();
  }
  
  /// ルートの選択を解除
  void clearSelectedRoute() {
    _selectedRoute = null;
    notifyListeners();
  }
  
  /// エリアフィルタを設定
  void setAreaFilter(String? area) {
    _areaFilter = area;
    notifyListeners();
  }
  
  /// フィルタをクリア
  void clearFilters() {
    _areaFilter = null;
    notifyListeners();
  }
  
  /// エラーメッセージをクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// テストデータを作成
  Future<void> createTestData(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _routeService.createTestData(userId);
      // テストデータ作成後、ルート一覧を再読み込み
      await loadUserRoutes(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'テストデータの作成に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
