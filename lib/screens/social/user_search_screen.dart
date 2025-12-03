import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanmap_v2/models/profile_model.dart';
import 'package:wanmap_v2/providers/follow_provider.dart';
import 'package:wanmap_v2/screens/profile/user_profile_screen.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = _searchQuery.isEmpty
        ? const AsyncValue<List<ProfileModel>>.data([])
        : ref.watch(userSearchProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー検索'),
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ユーザー名またはメールで検索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // 検索結果
          Expanded(
            child: searchResults.when(
              data: (users) {
                if (_searchQuery.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'ユーザーを検索',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'ユーザーが見つかりませんでした',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserListTile(user: user);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('エラー: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListTile extends ConsumerWidget {
  final ProfileModel user;

  const _UserListTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowingAsync = ref.watch(isFollowingProvider(user.id));

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(user.displayName?[0].toUpperCase() ?? '?')
            : null,
      ),
      title: Text(user.displayName ?? 'Unknown User'),
      subtitle: user.bio != null ? Text(user.bio!) : null,
      trailing: isFollowingAsync.when(
        data: (isFollowing) => ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(followActionsProvider).toggleFollow(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFollowing ? 'フォロー解除しました' : 'フォローしました',
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('エラー: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.primary,
            foregroundColor: isFollowing
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(isFollowing ? 'フォロー中' : 'フォロー'),
        ),
        loading: () => const SizedBox(
          width: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const Icon(Icons.error),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(userId: user.id),
          ),
        );
      },
    );
  }
}
