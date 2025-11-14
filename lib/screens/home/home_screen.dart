import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../map/map_screen.dart';
import '../routes/routes_list_screen.dart';
import '../routes/public_routes_screen.dart';
import '../routes/favorites_screen.dart';
import '../profile/profile_screen.dart';

/// ホーム画面
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WanMap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'プロフィール',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              Icon(
                Icons.pets,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              
              Text(
                'ようこそ！',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              
              if (user?.email != null)
                Text(
                  user!.email!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MapScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map, size: 28),
                  label: const Text(
                    'マップを開く',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RoutesListScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7ED321),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.list, size: 28),
                  label: const Text(
                    'ルート一覧',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PublicRoutesScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.public, size: 28),
                  label: const Text(
                    '公開ルート',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.favorite, size: 28),
                  label: const Text(
                    'お気に入り',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
