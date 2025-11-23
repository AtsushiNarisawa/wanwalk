import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/route_service.dart';
import '../../services/profile_service.dart';
import '../../models/profile_model.dart';
import '../auth/login_screen.dart';
import '../social/user_search_screen.dart';
import '../settings/settings_screen.dart';
import '../badges/badge_list_screen.dart';
import 'statistics_dashboard_screen.dart';
import 'profile_edit_screen.dart';

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

/// ユーザープロフィールを取得するProvider
final userProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final profile = await ProfileService().getProfile(user.id);
  
  // プロフィールが存在しない場合は新規作成
  if (profile == null) {
    await ProfileService().createProfile(
      userId: user.id,
      email: user.email!,
    );
    return await ProfileService().getProfile(user.id);
  }
  
  return profile;
});

/// プロフィール画面
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final statsAsync = ref.watch(userStatsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          // ユーザー検索ボタン
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserSearchScreen(),
                ),
              );
            },
          ),
          // 設定ボタン
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ),
              );
            },
          ),
          // ログアウトボタン
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
                try {
                  // ログアウト実行
                  await Supabase.instance.client.auth.signOut();
                  
                  // ログアウト成功メッセージ
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ログアウトしました'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    // ログイン画面に遷移（戻れないように）
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  // エラーハンドリング
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ログアウトに失敗しました: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              
              // アバター画像
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                backgroundImage: profile?.avatarUrl != null
                    ? NetworkImage(profile!.avatarUrl!)
                    : null,
                child: profile?.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),
              
              const SizedBox(height: 16),
              
              // 表示名
              if (profile?.displayName != null)
                Text(
                  profile!.displayName!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              
              const SizedBox(height: 4),
              
              // メールアドレス
              Text(
                user?.email ?? profile?.email ?? 'メールアドレス未設定',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 自己紹介
              if (profile?.bio != null && profile!.bio!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    profile.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // 登録日
              if (profile?.createdAt != null)
                Text(
                  '登録日: ${_formatDate(profile!.createdAt)}',
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
            
            const SizedBox(height: 16),
            
            // バッジコレクションへのリンク
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    Icons.workspace_premium,
                    color: Colors.amber[700],
                  ),
                  title: const Text('バッジコレクション'),
                  subtitle: const Text('獲得したバッジを確認'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BadgeListScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 統計ダッシュボードへのリンク
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    Icons.analytics,
                    color: Colors.blue[700],
                  ),
                  title: const Text('統計ダッシュボード'),
                  subtitle: const Text('詳細な統計とグラフを表示'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsDashboardScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('プロフィール編集'),
                  subtitle: const Text('ニックネーム・自己紹介を編集'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: profile == null
                      ? null
                      : () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => ProfileEditScreen(profile: profile),
                            ),
                          );
                          
                          // 編集成功時はプロフィールを再読み込み
                          if (result == true) {
                            ref.invalidate(userProfileProvider);
                          }
                        },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラー: $error'),
            ],
          ),
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
