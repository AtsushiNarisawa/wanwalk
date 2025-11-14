import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';
import '../../services/favorite_service.dart';
import 'route_detail_screen.dart';

/// お気に入りルート一覧を取得するProvider
final favoriteRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  
  // お気に入りのルートIDを取得
  final favoriteRouteIds = await FavoriteService().getUserFavoriteRouteIds(user.id);
  
  if (favoriteRouteIds.isEmpty) return [];
  
  // 各ルートの詳細を取得
  final routes = <RouteModel>[];
  for (final routeId in favoriteRouteIds) {
    final route = await RouteService().getRouteDetail(routeId);
    if (route != null) {
      routes.add(route);
    }
  }
  
  return routes;
});

/// お気に入り一覧画面
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(favoriteRoutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お気に入り'),
      ),
      body: routesAsync.when(
        data: (routes) {
          if (routes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'お気に入りがありません',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '公開ルートから気に入ったルートを追加しましょう',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(favoriteRoutesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return _FavoriteRouteCard(route: route, ref: ref);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました\n$error'),
            ],
          ),
        ),
      ),
    );
  }
}

/// お気に入りルートカード
class _FavoriteRouteCard extends StatelessWidget {
  final RouteModel route;
  final WidgetRef ref;

  const _FavoriteRouteCard({required this.route, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RouteDetailScreen(routeId: route.id!),
            ),
          );
          
          // お気に入りから削除された可能性があるので更新
          if (result != null) {
            ref.invalidate(favoriteRoutesProvider);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // お気に入りバッジ
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'お気に入り',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // タイトル
              Text(
                route.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // 説明
              if (route.description != null && route.description!.isNotEmpty)
                Text(
                  route.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: 12),
              
              // 統計情報
              Row(
                children: [
                  Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${(route.distance / 1000).toStringAsFixed(1)} km',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${(route.duration / 60).toStringAsFixed(0)} 分',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    route.formatDate(),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
