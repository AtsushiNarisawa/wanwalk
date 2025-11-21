import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/env.dart';
import '../../config/wanmap_colors.dart';
import '../../models/spot_model.dart';
import '../../providers/spot_provider.dart';
import '../../providers/auth_provider.dart';

/// わんスポット詳細画面
class SpotDetailScreen extends StatefulWidget {
  final String spotId;
  
  const SpotDetailScreen({
    super.key,
    required this.spotId,
  });

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  final MapController _mapController = MapController();
  bool _hasUpvoted = false;

  @override
  void initState() {
    super.initState();
    _loadSpotDetail();
    _checkUpvoteStatus();
  }

  /// スポット詳細を読み込み
  Future<void> _loadSpotDetail() async {
    final spotProvider = context.read<SpotProvider>();
    await spotProvider.getSpotDetail(widget.spotId);
  }

  /// upvote状態をチェック
  Future<void> _checkUpvoteStatus() async {
    final authProvider = context.read<AuthProvider>();
    final spotProvider = context.read<SpotProvider>();
    final userId = authProvider.currentUser?.id;
    
    if (userId != null) {
      final hasUpvoted = await spotProvider.hasUserUpvoted(
        spotId: widget.spotId,
        userId: userId,
      );
      
      if (mounted) {
        setState(() {
          _hasUpvoted = hasUpvoted;
        });
      }
    }
  }

  /// upvote/un-upvote
  Future<void> _toggleUpvote() async {
    final authProvider = context.read<AuthProvider>();
    final spotProvider = context.read<SpotProvider>();
    final userId = authProvider.currentUser?.id;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログインが必要です'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final isUpvoted = await spotProvider.upvoteSpot(
      spotId: widget.spotId,
      userId: userId,
    );
    
    if (mounted) {
      setState(() {
        _hasUpvoted = isUpvoted;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUpvoted ? 'いいねしました' : 'いいねを取り消しました'),
          backgroundColor: WanMapColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// URLをコピー
  void _copyUrl(String url) {
    // URLをクリップボードにコピー（url_launcherなしで実装）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL: $url'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 電話番号をコピー
  void _copyPhone(String phoneNumber) {
    // 電話番号をクリップボードにコピー（url_launcherなしで実装）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('電話番号: $phoneNumber'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// スポットを削除
  Future<void> _deleteSpot(SpotModel spot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スポットを削除'),
        content: Text('「${spot.name}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final authProvider = context.read<AuthProvider>();
      final spotProvider = context.read<SpotProvider>();
      final userId = authProvider.currentUser?.id;
      
      if (userId != null) {
        final success = await spotProvider.deleteSpot(widget.spotId, userId);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('スポットを削除しました'),
                backgroundColor: WanMapColors.success,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('削除に失敗しました'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WanMapColors.background,
      body: Consumer<SpotProvider>(
        builder: (context, spotProvider, child) {
          if (spotProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          final spot = spotProvider.selectedSpot;
          if (spot == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'スポット情報を取得できませんでした',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSpotDetail,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            );
          }
          
          return CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: WanMapColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    spot.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                  background: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: spot.location,
                      initialZoom: 16.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=${Environment.thunderforestApiKey}',
                        userAgentPackageName: 'com.example.wanmap',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: spot.location,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.place,
                              color: WanMapColors.accent,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  // 自分のスポットの場合は削除ボタンを表示
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.currentUser?.id == spot.userId) {
                        return IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteSpot(spot),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              
              // コンテンツ
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // カテゴリバッジ
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: WanMapColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: WanMapColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          spot.category.displayName,
                          style: const TextStyle(
                            color: WanMapColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // いいねボタン
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _toggleUpvote,
                            icon: Icon(
                              _hasUpvoted ? Icons.favorite : Icons.favorite_border,
                              color: _hasUpvoted ? Colors.red : Colors.grey,
                            ),
                            label: Text('${spot.upvoteCount}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (spot.rating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    spot.ratingDisplay,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // 説明
                      if (spot.description != null && spot.description!.isNotEmpty) ...[
                        const Text(
                          '説明',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          spot.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // 情報
                      const Text(
                        '情報',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // 住所
                      if (spot.address != null && spot.address!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.location_on,
                          label: spot.address!,
                          onTap: null,
                        ),
                      
                      // 電話番号
                      if (spot.phone != null && spot.phone!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.phone,
                          label: spot.phone!,
                          onTap: () => _copyPhone(spot.phone!),
                        ),
                      
                      // ウェブサイト
                      if (spot.website != null && spot.website!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.language,
                          label: spot.website!,
                          onTap: () => _copyUrl(spot.website!),
                        ),
                      
                      // 認証済みバッジ
                      if (spot.isVerified) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '認証済みスポット',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 情報行
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  
  const _InfoRow({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: WanMapColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: onTap != null ? WanMapColors.primary : Colors.grey[700],
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}
