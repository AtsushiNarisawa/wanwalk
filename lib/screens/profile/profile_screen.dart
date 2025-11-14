import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/route_service.dart';

/// ユーザー統計情報
class UserStats {
  final int totalRoutes;
  final double totalDistance;
  final int totalDuration;

  UserStats({
    required this.totalRoutes,
    required this.totalDistance,
    required this.totalDuration,
  });

  String get formattedDistance {
    if (totalDistance >= 1000) {
      return '${(totalDistance / 1000).toStringAsFixed(1)} km';
    } else {
      return '${totalDistance.toStringAsFixed(0)} m';
    }
  }

  String get formattedDuration {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    
    if (hours > 0) {
      return '$hours時間${minutes}分';
    } else {
      return '$minutes分';
    }
  }
}

/// ユーザー統計情報を取得するProvider
final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return UserStats(totalRoutes: 0, totalDistance: 0, totalDuration: 0);
  }

  final routes = await RouteService().getUserRoutes(user.id);
  
  double totalDistance = 0;
  int totalDuration = 0;
  
  for (final route in routes) {
    totalDistance += route.distance;
    totalDuration += route.duration;
  }

  return UserStats(
    totalRoutes: routes.length,
    totalDistance: totalDistance,
    totalDuration: totalDuration,
  );
});

/// プロフィール画面
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ログアウト'),
                  content: const Text('ログアウトしますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('ログアウト'),
                    ),
                  ],
                ),
              );

              if (result == true && context.mounted) {
                await Supabase.instance.client.auth.signOut();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (user?.email != null)
              Text(
                user!.email!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            
            const SizedBox(height: 8),
            
            if (user?.createdAt != null)
              Text(
                '登録日: ${_formatDate(DateTime.parse(user!.createdAt!))}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            
            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bar_chart,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '統計情報',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      statsAsync.when(
                        data: (stats) => Column(
                          children: [
                            _StatItem(
                              icon: Icons.map,
                              label: '総ルート数',
                              value: '${stats.totalRoutes} 件',
                              color: Colors.blue,
                            ),
                            const Divider(height: 24),
                            _StatItem(
                              icon: Icons.straighten,
                              label: '総距離',
                              value: stats.formattedDistance,
                              color: Colors.green,
                            ),
                            const Divider(height: 24),
                            _StatItem(
                              icon: Icons.timer,
                              label: '総時間',
                              value: stats.formattedDuration,
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stack) => Center(
                          child: Text('エラー: $error'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('プロフィール編集'),
                  subtitle: const Text('ニックネーム・自己紹介を編集'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('この機能は今後実装予定です')),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
