import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/dog_provider.dart';
import '../../../models/dog_model.dart';
import '../../auth/auth_selection_screen.dart';
import '../main_screen.dart';
import '../../legal/terms_of_service_screen.dart';
import '../../legal/privacy_policy_screen.dart';


import '../../profile/profile_edit_screen.dart';
import '../../dogs/dog_edit_screen.dart';
import '../../settings/settings_screen.dart';

/// ProfileTab - ユーザープロフィールとアカウント管理
/// 
/// 構成:
/// 1. ユーザー情報カード（アバター、名前、レベル、XP）
/// 2. ソーシャル統計（フォロワー/フォロー中）
/// 3. メニューリスト（設定、編集、愛犬管理など）
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  @override
  void initState() {
    super.initState();
    // 初回表示時に犬データをロード
    Future.microtask(() {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        if (kDebugMode) {
          print('🐕 ProfileTab: Loading dogs for user $userId');
        }
        ref.read(dogProvider.notifier).loadUserDogs(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);
    
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('プロフィール')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: WanMapSpacing.lg),
              Text(
                'ログインしてプロフィールを確認',
                style: WanMapTypography.bodyLarge.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: WanMapSpacing.xl),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthSelectionScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WanMapColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ログイン / 新規登録',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final profileAsync = ref.watch(profileProvider(userId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.person, color: WanMapColors.accent, size: 28),
            const SizedBox(width: WanMapSpacing.sm),
            Text(
              'プロフィール',
              style: WanMapTypography.headlineMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(WanMapSpacing.lg),
            child: Column(
              children: [
                // ユーザー情報カード
                profileAsync.when(
                  data: (profile) => _buildUserInfoCard(context, isDark, profile, currentUser),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _buildUserInfoCard(context, isDark, null, currentUser),
                ),
                
                const SizedBox(height: WanMapSpacing.md),
                
                // 愛犬カード
                _buildDogCards(context, isDark, userId, ref),
                
                const SizedBox(height: WanMapSpacing.md),
                
                // メニューリスト
                _buildMenuList(context, isDark, currentUser, ref),
              ],
            ),
          ),
        ),
    );
  }

  /// ユーザー情報カード
  Widget _buildUserInfoCard(
    BuildContext context,
    bool isDark,
    ProfileData? profile,
    User? currentUser,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(WanMapSpacing.sm),
          child: Row(
            children: [
              // アバター（左側）
              CircleAvatar(
                radius: 32,
                backgroundColor: WanMapColors.accent.withOpacity(0.1),
                backgroundImage: profile?.avatarUrl != null
                    ? NetworkImage(profile!.avatarUrl!)
                    : null,
                child: profile?.avatarUrl == null
                    ? const Icon(Icons.person, size: 36, color: WanMapColors.accent)
                    : null,
              ),
              
              const SizedBox(width: WanMapSpacing.md),
              
              // ユーザー情報（右側）
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 表示名
                    Text(
                      profile?.displayName ?? 'ユーザー名未設定',
                      style: WanMapTypography.titleLarge.copyWith(
                        color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: WanMapSpacing.xs),
                    
                    // メールアドレス
                    if (currentUser?.email != null)
                      Text(
                        currentUser!.email!,
                        style: WanMapTypography.bodyMedium.copyWith(
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // 編集アイコン
              Icon(
                Icons.edit,
                color: (isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight).withOpacity(0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 愛犬カードセクション
  Widget _buildDogCards(
    BuildContext context,
    bool isDark,
    String userId,
    WidgetRef ref,
  ) {
    final dogs = ref.watch(userDogsProvider(userId));
    
    if (kDebugMode) {
      print('🐕 ProfileTab _buildDogCards: ${dogs.length} dogs');
      print('🐕 Dogs: ${dogs.map((d) => d.name).join(", ")}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー
        Padding(
          padding: const EdgeInsets.only(left: WanMapSpacing.xs, bottom: WanMapSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.pets, color: WanMapColors.accent, size: 20),
              const SizedBox(width: WanMapSpacing.xs),
              Text(
                '愛犬情報',
                style: WanMapTypography.titleMedium.copyWith(
                  color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 愛犬追加ボタン（ヘッダーに統合）
              IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DogEditScreen(userId: userId)),
                  );
                },
                icon: Icon(
                  Icons.add_circle_outline,
                  color: WanMapColors.primary,
                  size: 28,
                ),
                tooltip: '愛犬を追加',
              ),
            ],
          ),
        ),

        // 愛犬リスト
        if (dogs.isEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(WanMapSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pets_outlined,
                      size: 64,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                    const SizedBox(height: WanMapSpacing.md),
                    Text(
                      '愛犬が登録されていません',
                      style: WanMapTypography.bodyMedium.copyWith(
                        color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...dogs.asMap().entries.map((entry) {
            final index = entry.key;
            final dog = entry.value;
            if (kDebugMode) {
              print('🐕 Building dog card #$index: ${dog.name}');
            }
            return Padding(
              padding: EdgeInsets.only(
                bottom: WanMapSpacing.xxs,
              ),
              child: _DogCard(
                dog: dog,
                isDark: isDark,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DogEditScreen(userId: userId, dog: dog),
                    ),
                  );
                  if (result == true) {
                    ref.read(dogProvider.notifier).loadUserDogs(userId);
                  }
                },
              ),
            );
          }).toList(),
      ],
    );
  }

  /// メニューリスト
  Widget _buildMenuList(
    BuildContext context,
    bool isDark,
    User? currentUser,
    WidgetRef ref,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.settings_outlined,
            label: '設定',
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.description_outlined,
            label: '利用規約',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
            ),
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            label: 'プライバシーポリシー',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.logout,
            label: 'ログアウト',
            isDark: isDark,
            isDestructive: true,
            onTap: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }

  /// ログアウト処理
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        await Supabase.instance.client.auth.signOut();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ログアウトしました')),
          );
          
          // ログアウト後もメイン画面を表示（未ログイン状態）
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ログアウトに失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// 愛犬カードウィジェット
class _DogCard extends StatelessWidget {
  final DogModel dog;
  final bool isDark;
  final VoidCallback onTap;

  const _DogCard({
    required this.dog,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🐕 _DogCard.build() called for: ${dog.name}');
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(WanMapSpacing.sm),
          child: Row(
            children: [
              // 犬の写真（左側）
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: dog.photoUrl != null && dog.photoUrl!.isNotEmpty
                    ? Image.network(
                        dog.photoUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 64,
                            height: 64,
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            child: const Icon(Icons.pets, size: 28, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        width: 64,
                        height: 64,
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        child: const Icon(Icons.pets, size: 28, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: WanMapSpacing.md),
              
              // 犬の情報（右側）
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 名前
                    Text(
                      dog.name,
                      style: WanMapTypography.titleLarge.copyWith(
                        color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: WanMapSpacing.xs),
                    
                    // 犬種
                    Text(
                      dog.breed ?? '犬種不明',
                      style: WanMapTypography.bodyMedium.copyWith(
                        color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: WanMapSpacing.sm),
                    
                    // 年齢とサイズ
                    Row(
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          size: 18,
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                        const SizedBox(width: WanMapSpacing.xxs),
                        Text(
                          dog.ageDisplay,
                          style: WanMapTypography.bodyMedium.copyWith(
                            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: WanMapSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WanMapSpacing.sm,
                            vertical: WanMapSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: WanMapColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            dog.sizeDisplay,
                            style: WanMapTypography.bodySmall.copyWith(
                              color: WanMapColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 編集アイコン
              Icon(
                Icons.edit,
                color: (isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight).withOpacity(0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isDark,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.red
            : (isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight),
      ),
      title: Text(
        label,
        style: WanMapTypography.bodyMedium.copyWith(
          color: isDestructive
              ? Colors.red
              : (isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
      ),
      onTap: onTap,
    );
  }
}
