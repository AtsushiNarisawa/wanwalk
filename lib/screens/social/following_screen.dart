import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/social_provider.dart';
import '../../widgets/social/user_list_item.dart';

/// フォロー中一覧画面
class FollowingScreen extends ConsumerStatefulWidget {
  final String userId;

  const FollowingScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends ConsumerState<FollowingScreen> {
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
    final params = FollowingParams(
      userId: widget.userId,
      limit: _pageSize,
      offset: _offset,
    );
    final followingAsync = ref.watch(socialFollowingProvider(params));

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanMapColors.cardDark : Colors.white,
        elevation: 0,
        title: const Text(
          'フォロー中',
          style: WanMapTypography.heading2,
        ),
      ),
      body: followingAsync.when(
        data: (following) {
          if (following.isEmpty && _offset == 0) {
            return _buildEmptyState(isDark);
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _offset = 0;
              });
              ref.invalidate(socialFollowingProvider);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(WanMapSpacing.medium),
              itemCount: following.length + 1,
              itemBuilder: (context, index) {
                if (index == following.length) {
                  return _buildLoadingIndicator();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: WanMapSpacing.small),
                  child: UserListItem(
                    user: following[index],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/user_profile',
                        arguments: following[index].id,
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
            'フォロー中のユーザーはいません',
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
