import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dog_provider.dart';
import 'dog_edit_screen.dart';

/// 愛犬一覧画面
class DogListScreen extends ConsumerStatefulWidget {
  const DogListScreen({super.key});

  @override
  ConsumerState<DogListScreen> createState() => _DogListScreenState();
}

class _DogListScreenState extends ConsumerState<DogListScreen> {
  @override
  void initState() {
    super.initState();
    // 初回のみ犬一覧を読み込み
    Future.microtask(() {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        if (kDebugMode) {
          print('🐕 DogListScreen: Loading dogs for user $userId');
        }
        ref.read(dogProvider.notifier).loadUserDogs(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);
    final dogState = ref.watch(dogProvider);
    
    if (kDebugMode) {
      print('🐕 DogListScreen build: dogs=${dogState.dogs.length}, loading=${dogState.isLoading}, error=${dogState.errorMessage}');
    }

    return Scaffold(
      backgroundColor: isDark
          ? WanWalkColors.backgroundDark
          : WanWalkColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanWalkColors.cardDark : Colors.white,
        elevation: 0,
        title: const Text(
          '愛犬の管理',
          style: WanWalkTypography.heading2,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              if (userId == null) return;
              
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DogEditScreen(userId: userId),
                ),
              );
              
              if (result == true) {
                ref.read(dogProvider.notifier).loadUserDogs(userId);
              }
            },
          ),
        ],
      ),
      body: dogState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dogState.errorMessage != null
              ? _buildErrorState(isDark, dogState.errorMessage!)
              : dogState.dogs.isEmpty
                  ? _buildEmptyState(context, isDark, userId)
                  : _buildDogList(context, ref, isDark, userId, dogState.dogs),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String? userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: WanWalkSpacing.large),
          Text(
            '愛犬が登録されていません',
            style: WanWalkTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanWalkSpacing.small),
          Text(
            '愛犬を登録して、散歩記録を管理しましょう',
            style: WanWalkTypography.body.copyWith(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WanWalkSpacing.large),
          ElevatedButton.icon(
            onPressed: () async {
              if (userId == null) return;
              
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DogEditScreen(userId: userId),
                ),
              );
              
              if (result == true && context.mounted) {
                // リロード処理はウィジェットツリーで自動的に行われる
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('愛犬を登録'),
            style: ElevatedButton.styleFrom(
              backgroundColor: WanWalkColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: WanWalkSpacing.large,
                vertical: WanWalkSpacing.small,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDogList(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    String? userId,
    List dogs,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(WanWalkSpacing.medium),
      itemCount: dogs.length,
      itemBuilder: (context, index) {
        final dog = dogs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: WanWalkSpacing.medium),
          color: isDark ? WanWalkColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              if (userId == null) return;
              
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DogEditScreen(
                    userId: userId,
                    dog: dog,
                  ),
                ),
              );
              
              if (result == true) {
                ref.read(dogProvider.notifier).loadUserDogs(userId);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(WanWalkSpacing.medium),
              child: Row(
                children: [
                  // 犬のアバター
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: WanWalkColors.accent.withOpacity(0.2),
                    backgroundImage: dog.photoUrl != null
                        ? NetworkImage(dog.photoUrl!)
                        : null,
                    child: dog.photoUrl == null
                        ? const Icon(
                            Icons.pets,
                            size: 40,
                            color: WanWalkColors.accent,
                          )
                        : null,
                  ),
                  const SizedBox(width: WanWalkSpacing.medium),
                  // 犬の情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dog.name,
                          style: WanWalkTypography.heading3,
                        ),
                        const SizedBox(height: WanWalkSpacing.tiny),
                        if (dog.breed != null)
                          Text(
                            dog.breed!,
                            style: WanWalkTypography.body.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        const SizedBox(height: WanWalkSpacing.tiny),
                        Row(
                          children: [
                            Icon(
                              Icons.cake_outlined,
                              size: 16,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dog.ageDisplay,
                              style: WanWalkTypography.caption.copyWith(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                            const SizedBox(width: WanWalkSpacing.small),
                            Icon(
                              Icons.monitor_weight_outlined,
                              size: 16,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dog.weightDisplay,
                              style: WanWalkTypography.caption.copyWith(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          const SizedBox(height: WanWalkSpacing.medium),
          Text(
            'エラーが発生しました',
            style: WanWalkTypography.heading3.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: WanWalkSpacing.small),
          Text(
            error,
            style: WanWalkTypography.caption.copyWith(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
