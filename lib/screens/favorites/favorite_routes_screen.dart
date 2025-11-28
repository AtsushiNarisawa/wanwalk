import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/favorite_route.dart';
import '../../providers/favorite_provider.dart';
import '../outing/route_detail_screen.dart';

/// お気に入りルート一覧画面
class FavoriteRoutesScreen extends ConsumerWidget {
  const FavoriteRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(userFavoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お気に入りルート'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return _buildEmptyState();
          }
          return _buildFavoriteList(context, favorites);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  /// 空の状態
  Widget _buildEmptyState() {
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
            'お気に入りルートがありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ルート詳細画面で❤️ボタンをタップして\nお気に入りに追加できます',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// エラー状態
  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'お気に入りの読み込みに失敗しました',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// お気に入りリスト
  Widget _buildFavoriteList(BuildContext context, List<FavoriteRoute> favorites) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return _FavoriteRouteCard(favorite: favorite);
      },
    );
  }
}

/// お気に入りルートカード
class _FavoriteRouteCard extends ConsumerWidget {
  final FavoriteRoute favorite;

  const _FavoriteRouteCard({required this.favorite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // ルート詳細画面へ遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RouteDetailScreen(routeId: favorite.routeId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // エリア名
              if (favorite.areaName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    favorite.areaName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              // ルート名
              Row(
                children: [
                  Expanded(
                    child: Text(
                      favorite.routeName ?? '名称未設定',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ルート情報
              Row(
                children: [
                  _buildInfoChip(
                    Icons.straighten,
                    favorite.distanceFormatted,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.access_time,
                    favorite.durationFormatted,
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.trending_up,
                    favorite.difficultyLabelJa,
                    _getDifficultyColor(favorite.difficultyLevel),
                  ),
                ],
              ),

              // Pin数
              if (favorite.totalPins != null && favorite.totalPins! > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${favorite.totalPins}個のピン',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 情報チップ
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 難易度の色を取得
  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
