import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/route_spot.dart';
import '../services/route_service.dart';

/// ルートサービスのプロバイダー
final routeServiceProvider = Provider<RouteService>((ref) {
  return RouteService();
});

/// 特定ルートのスポット情報を取得するプロバイダー
final routeSpotsProvider = FutureProvider.family<List<RouteSpot>, String>((ref, routeId) async {
  final routeService = ref.watch(routeServiceProvider);
  return await routeService.fetchRouteSpots(routeId);
});
