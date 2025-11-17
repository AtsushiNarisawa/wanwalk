// ==================================================
// Timeline Screen for WanMap v2
// ==================================================
// Author: AI Assistant
// Created: 2025-01-17
// Purpose: Display timeline of followed users' routes
// ==================================================

import 'package:flutter/material.dart';
import '../../models/social_model.dart';
import '../../services/social_service.dart';
import '../../widgets/social/like_button.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final SocialService _socialService = SocialService();
  List<TimelineItemModel> _timelineItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _socialService.getFollowingTimeline(limit: 50);
      
      if (mounted) {
        setState(() {
          _timelineItems = items;
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
        title: const Text('タイムライン'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimeline,
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
              onPressed: _loadTimeline,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    if (_timelineItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'タイムラインが空です',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'ユーザーをフォローして\n散歩ルートをチェックしましょう',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTimeline,
      child: ListView.builder(
        itemCount: _timelineItems.length,
        itemBuilder: (context, index) {
          final item = _timelineItems[index];
          return _buildTimelineCard(item);
        },
      ),
    );
  }

  Widget _buildTimelineCard(TimelineItemModel item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザー情報
          ListTile(
            leading: CircleAvatar(
              backgroundImage: item.avatarUrl != null
                  ? NetworkImage(item.avatarUrl!)
                  : null,
              child: item.avatarUrl == null
                  ? Text(item.displayName[0].toUpperCase())
                  : null,
            ),
            title: Text(
              item.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item.relativeTime),
            trailing: Text(
              item.areaDisplay ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          // サムネイル画像
          if (item.thumbnailUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                item.thumbnailUrl!,
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
                  item.title,
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
                      item.formattedDistance,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      item.formattedDuration,
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
                routeId: item.routeId,
                initialLikesCount: item.likesCount,
                onLikeChanged: () {
                  // TODO: タイムラインを再読み込みするか、ローカルで更新
                },
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: ルート詳細画面に遷移
                },
                icon: const Icon(Icons.comment_outlined),
                label: const Text('詳細'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
