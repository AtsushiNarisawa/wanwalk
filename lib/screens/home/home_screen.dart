import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

/// ホーム画面（仮実装）
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WanMap'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        actions: [
          // ログアウトボタン
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authNotifier = ref.read(authNotifierProvider.notifier);
              await authNotifier.signOut();
              
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // アイコン
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pets,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // ウェルカムメッセージ
              const Text(
                'ようこそ、WanMapへ！',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(height: 16),

              // ユーザー情報表示
              userAsync.when(
                data: (user) {
                  if (user == null) {
                    return const Text('ログインしていません');
                  }
                  return Column(
                    children: [
                      Text(
                        'メールアドレス: ${user.email}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      userProfileAsync.when(
                        data: (profile) {
                          if (profile == null) {
                            return const Text('プロフィール読み込み中...');
                          }
                          return Text(
                            '表示名: ${profile['display_name'] ?? '未設定'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, _) => Text('エラー: $error'),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('エラー: $error'),
              ),
              const SizedBox(height: 32),

              // 機能カード
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: Color(0xFF4A90E2),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Phase 2: 認証機能 完成！',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '次のPhaseで実装予定：',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem('📍 地図表示とGPS追跡'),
                      _buildFeatureItem('🗺️ 散歩ルート記録'),
                      _buildFeatureItem('📸 写真共有'),
                      _buildFeatureItem('🐕 愛犬プロフィール'),
                      _buildFeatureItem('⭐ ルートお気に入り'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 情報メッセージ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7ED321).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF7ED321),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF7ED321),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ログイン認証が成功しました！\n右上のアイコンからログアウトできます。',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
