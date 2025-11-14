import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';
import 'route_detail_screen.dart';

/// ユーザーのルート一覧を取得するProvider
final userRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  
  return RouteService().getUserRoutes(user.id);
});

/// ルート一覧画面
class RoutesListScreen extends ConsumerWidget {
  const RoutesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(userRoutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ルート一覧'),
        actions: [
          // テストデータ作成ボタン（開発用）
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'テストデータ作成',
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user == null) return;
              
              // ローディング表示
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('テストデータを作成中...')),
              );
              
              try {
                await RouteService().createTestData(user.id);
                
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('テストデータを作成しました！'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // リスト更新
                ref.invalidate(userRoutesProvider);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('エラー: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: routesAsync.when(
        data: (routes) {
          if (routes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'まだルートがありません',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '右上の🐛ボタンでテストデータを作成できます',
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
              ref.invalidate(userRoutesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return _RouteCard(route: route);
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

/// ルートカード
class _RouteCard extends StatelessWidget {
  final RouteModel route;

  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
         onTap: () {
          if (route.id != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RouteDetailScreen(routeId: route.id!),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
