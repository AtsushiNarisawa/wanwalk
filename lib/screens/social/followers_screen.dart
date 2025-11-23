import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/social_provider.dart';
import '../../widgets/social/user_list_item.dart';

/// フォロワー一覧画面
class FollowersScreen extends ConsumerStatefulWidget {
  final String userId;

  const FollowersScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends ConsumerState<FollowersScreen> {
  final ScrollController _scrollController = ScrollController();
  int _offset = 0;
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _offset += _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final params = FollowersParams(
      userId: widget.userId,
      limit: _pageSize,
      offset: _offset,
    );
    final followersAsync = ref.watch(followersProvider(params));

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanMapColors.cardDark : Colors.white,
        elevation: 0,
        title: Text(
          'フォロワー',
          style: WanMapTypography.heading2,
        ),
      ),
      body: followersAsync.when(
        data: (followers) {
          if (followers.isEmpty && _offset == 0) {
            return _buildEmptyState(isDark);
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _offset = 0;
              });
              ref.invalidate(followersProvider);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(WanMapSpacing.medium),
              itemCount: followers.length + 1,
              itemBuilder: (context, index) {
                if (index == followers.length) {
                  return _buildLoadingIndicator();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: WanMapSpacing.small),
                  child: UserListItem(
                    user: followers[index],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/user_profile',
                        arguments: followers[index].id,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(isDark, error.toString()),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Text(
            'フォロワーはまだいません',
            style: WanMapTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.red.shade300 : Colors.red,
          ),
          const SizedBox(height: WanMapSpacing.medium),
          Text(
            'エラーが発生しました',
            style: WanMapTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanMapSpacing.small),
          Text(
            error,
            style: WanMapTypography.caption.copyWith(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(WanMapSpacing.medium),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
