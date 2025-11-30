import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanmap_v2/providers/follow_provider.dart';
import 'package:wanmap_v2/screens/profile/user_profile_screen.dart';

class FollowListScreen extends ConsumerWidget {
  final String userId;
  final FollowListType type;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = type == FollowListType.followers
        ? ref.watch(followersProvider(userId))
        : ref.watch(followingProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(type == FollowListType.followers ? 'フォロワー' : 'フォロー中'),
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == FollowListType.followers
                        ? Icons.people_outline
                        : Icons.person_add_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    type == FollowListType.followers
                        ? 'フォロワーはいません'
                        : 'フォロー中のユーザーはいません',
                    style: const TextStyle(
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
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(userId: user.id),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }
}

enum FollowListType {
  followers,
  following,
}
