// ==================================================
// Popular Routes Screen for WanMap v2
// ==================================================
// Author: AI Assistant
// Created: 2025-01-17
// Purpose: Display popular routes ranked by likes
// ==================================================

import 'package:flutter/material.dart';
import '../../models/social_model.dart';
import '../../services/social_service.dart';
import '../../widgets/social/like_button.dart';

class PopularRoutesScreen extends StatefulWidget {
  const PopularRoutesScreen({super.key});

  @override
  State<PopularRoutesScreen> createState() => _PopularRoutesScreenState();
}

class _PopularRoutesScreenState extends State<PopularRoutesScreen> {
  final SocialService _socialService = SocialService();
  List<PopularRouteModel> _popularRoutes = [];
  bool _isLoading = true;
  String? _error;
  int _selectedDays = 7; // 7, 30, 90

  @override
  void initState() {
    super.initState();
    _loadPopularRoutes();
  }

  Future<void> _loadPopularRoutes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final routes = await _socialService.getPopularRoutes(
        limit: 50,
        days: _selectedDays,
      );
      
      if (mounted) {
        setState(() {
          _popularRoutes = routes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('人気ルート'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _selectedDays,
            onSelected: (days) {
              setState(() => _selectedDays = days);
              _loadPopularRoutes();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('過去7日間')),
              const PopupMenuItem(value: 30, child: Text('過去30日間')),
              const PopupMenuItem(value: 90, child: Text('過去90日間')),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('エラーが発生しました', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPopularRoutes,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    if (_popularRoutes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '人気ルートがありません',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPopularRoutes,
      child: ListView.builder(
        itemCount: _popularRoutes.length,
        itemBuilder: (context, index) {
          final route = _popularRoutes[index];
          return _buildRouteCard(route, index + 1);
        },
      ),
    );
  }

  Widget _buildRouteCard(PopularRouteModel route, int rank) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ランキング番号とユーザー情報
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(rank),
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              route.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(route.areaDisplay ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${route.likesCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // サムネイル画像
          if (route.thumbnailUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                route.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 48),
                    ),
                  );
                },
              ),
            ),
          
          // ルート情報
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      route.formattedDistance,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      route.formattedDuration,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // アクションボタン
          ButtonBar(
            alignment: MainAxisAlignment.start,
            children: [
              LikeButton(
                routeId: route.routeId,
                initialLikesCount: route.likesCount,
                onLikeChanged: _loadPopularRoutes,
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: ルート詳細画面に遷移
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('詳細'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ランキングに応じた色を取得
  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber; // 金
    if (rank == 2) return Colors.grey; // 銀
    if (rank == 3) return Colors.brown; // 銅
    return Theme.of(context).primaryColor;
  }
}
