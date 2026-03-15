import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/wanwalk_colors.dart';
import '../../../config/wanwalk_typography.dart';
import '../../../config/wanwalk_spacing.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/dog_provider.dart';
import '../../../providers/user_statistics_provider.dart';
import '../../../models/dog_model.dart';
import '../../auth/auth_selection_screen.dart';
import '../main_screen.dart';
import '../../legal/terms_of_service_screen.dart';
import '../../legal/privacy_policy_screen.dart';


import '../../profile/profile_edit_screen.dart';
import '../../dogs/dog_edit_screen.dart';
import '../../settings/settings_screen.dart';
import '../../../utils/logger.dart';

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
          appLog('🐕 ProfileTab: Loading dogs for user $userId');
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
        backgroundColor: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.person, color: WanWalkColors.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                'マイページ',
                style: WanWalkTypography.headlineMedium.copyWith(
                  color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(WanWalkSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: WanWalkSpacing.xl),
              // アバター風アイコン
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WanWalkColors.primary.withOpacity(0.15),
                      WanWalkColors.primaryLight.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 56,
                  color: WanWalkColors.primary,
                ),
              ),
              const SizedBox(height: WanWalkSpacing.lg),
              Text(
                '愛犬との散歩をもっと楽しく',
                style: WanWalkTypography.headlineSmall.copyWith(
                  color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: WanWalkSpacing.sm),
              Text(
                'ログインすると、プロフィール設定や\n愛犬の登録ができます',
                style: WanWalkTypography.bodyMedium.copyWith(
                  color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WanWalkSpacing.xl),
              // 機能紹介
              _UnauthProfileFeature(
                icon: Icons.pets,
                color: WanWalkColors.accent,
                title: '愛犬プロフィール',
                description: '愛犬の情報を登録して管理',
                isDark: isDark,
              ),
              const SizedBox(height: WanWalkSpacing.sm),
              _UnauthProfileFeature(
                icon: Icons.bar_chart_rounded,
                color: WanWalkColors.routeOrange,
                title: '散歩の統計',
                description: '散歩回数や距離をグラフで確認',
                isDark: isDark,
              ),
              const SizedBox(height: WanWalkSpacing.sm),
              _UnauthProfileFeature(
                icon: Icons.emoji_events_outlined,
                color: WanWalkColors.secondary,
                title: 'バッジ＆レベル',
                description: '散歩するほどレベルアップ（今後対応）',
                isDark: isDark,
              ),
              const SizedBox(height: WanWalkSpacing.xl),
              // ログインボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthSelectionScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WanWalkColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'ログイン / 新規登録',
                    style: WanWalkTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: WanWalkSpacing.md),
              Text(
                'ログインなしでもマップの閲覧はできます',
                style: WanWalkTypography.caption.copyWith(
                  color: isDark ? WanWalkColors.textTertiaryDark : WanWalkColors.textTertiaryLight,
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
      backgroundColor: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.person, color: WanWalkColors.accent, size: 28),
            const SizedBox(width: WanWalkSpacing.sm),
            Text(
              'プロフィール',
              style: WanWalkTypography.headlineMedium.copyWith(
                color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(WanWalkSpacing.lg),
            child: Column(
              children: [
                // ユーザー情報カード
                profileAsync.when(
                  data: (profile) => _buildUserInfoCard(context, isDark, profile, currentUser),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _buildUserInfoCard(context, isDark, null, currentUser),
                ),

                const SizedBox(height: WanWalkSpacing.md),

                // 散歩統計カード
                _buildStatisticsCard(context, isDark, userId),

                const SizedBox(height: WanWalkSpacing.md),

                // 愛犬カード
                _buildDogCards(context, isDark, userId, ref),
                
                const SizedBox(height: WanWalkSpacing.md),
                
                // メニューリスト
                _buildMenuList(context, isDark, currentUser, ref),
              ],
            ),
          ),
        ),
    );
  }

  /// 散歩統計カード
  Widget _buildStatisticsCard(BuildContext context, bool isDark, String userId) {
    final statsAsync = ref.watch(userStatisticsProvider(userId));

    return statsAsync.when(
      data: (stats) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(WanWalkSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: WanWalkColors.accent, size: 20),
                    const SizedBox(width: WanWalkSpacing.xs),
                    Text(
                      '散歩の記録',
                      style: WanWalkTypography.titleMedium.copyWith(
                        color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WanWalkSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        value: '${stats.totalWalks}',
                        label: '散歩回数',
                        icon: Icons.directions_walk,
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        value: stats.formattedTotalDistance,
                        label: '総距離',
                        icon: Icons.straighten,
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        value: stats.formattedTotalDuration,
                        label: '総時間',
                        icon: Icons.timer,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WanWalkSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        value: '${stats.areasVisited}',
                        label: 'エリア',
                        icon: Icons.location_on,
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        value: '${stats.routesCompleted}',
                        label: 'ルート',
                        icon: Icons.route,
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        value: '${stats.pinsCreated}',
                        label: 'ピン投稿',
                        icon: Icons.push_pin,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
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
          padding: const EdgeInsets.all(WanWalkSpacing.sm),
          child: Row(
            children: [
              // アバター（左側）
              CircleAvatar(
                radius: 32,
                backgroundColor: WanWalkColors.accent.withOpacity(0.1),
                backgroundImage: profile?.avatarUrl != null
                    ? NetworkImage(profile!.avatarUrl!)
                    : null,
                child: profile?.avatarUrl == null
                    ? const Icon(Icons.person, size: 36, color: WanWalkColors.accent)
                    : null,
              ),
              
              const SizedBox(width: WanWalkSpacing.md),
              
              // ユーザー情報（右側）
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 表示名
                    Text(
                      profile?.displayName ?? 'ユーザー名未設定',
                      style: WanWalkTypography.titleLarge.copyWith(
                        color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: WanWalkSpacing.xs),
                    
                    // メールアドレス
                    if (currentUser?.email != null)
                      Text(
                        currentUser!.email!,
                        style: WanWalkTypography.bodyMedium.copyWith(
                          color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // 編集アイコン
              Icon(
                Icons.edit,
                color: (isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight).withOpacity(0.6),
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
      appLog('🐕 ProfileTab _buildDogCards: ${dogs.length} dogs');
      appLog('🐕 Dogs: ${dogs.map((d) => d.name).join(", ")}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー
        Padding(
          padding: const EdgeInsets.only(left: WanWalkSpacing.xs, bottom: WanWalkSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.pets, color: WanWalkColors.accent, size: 20),
              const SizedBox(width: WanWalkSpacing.xs),
              Text(
                '愛犬情報',
                style: WanWalkTypography.titleMedium.copyWith(
                  color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
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
                  color: WanWalkColors.primary,
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
              padding: const EdgeInsets.all(WanWalkSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pets_outlined,
                      size: 64,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                    const SizedBox(height: WanWalkSpacing.md),
                    Text(
                      '愛犬が登録されていません',
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
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
              appLog('🐕 Building dog card #$index: ${dog.name}');
            }
            return Padding(
              padding: EdgeInsets.only(
                bottom: WanWalkSpacing.xxs,
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
        color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
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
      appLog('🐕 _DogCard.build() called for: ${dog.name}');
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
          padding: const EdgeInsets.all(WanWalkSpacing.sm),
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
              const SizedBox(width: WanWalkSpacing.md),
              
              // 犬の情報（右側）
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 名前
                    Text(
                      dog.name,
                      style: WanWalkTypography.titleLarge.copyWith(
                        color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: WanWalkSpacing.xs),
                    
                    // 犬種
                    Text(
                      dog.breed ?? '犬種不明',
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: WanWalkSpacing.sm),
                    
                    // 年齢とサイズ
                    Row(
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          size: 18,
                          color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                        ),
                        const SizedBox(width: WanWalkSpacing.xxs),
                        Text(
                          dog.ageDisplay,
                          style: WanWalkTypography.bodyMedium.copyWith(
                            color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: WanWalkSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WanWalkSpacing.sm,
                            vertical: WanWalkSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: WanWalkColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            dog.sizeDisplay,
                            style: WanWalkTypography.bodySmall.copyWith(
                              color: WanWalkColors.accent,
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
                color: (isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight).withOpacity(0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isDark;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: WanWalkColors.accent, size: 22),
        const SizedBox(height: WanWalkSpacing.xs),
        Text(
          value,
          style: WanWalkTypography.titleMedium.copyWith(
            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: WanWalkTypography.caption.copyWith(
            color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
          ),
        ),
      ],
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
            : (isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight),
      ),
      title: Text(
        label,
        style: WanWalkTypography.bodyMedium.copyWith(
          color: isDestructive
              ? Colors.red
              : (isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
      ),
      onTap: onTap,
    );
  }
}

/// 未ログイン状態の機能紹介アイテム
class _UnauthProfileFeature extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool isDark;

  const _UnauthProfileFeature({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: WanWalkSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WanWalkTypography.bodyLarge.copyWith(
                    color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: WanWalkTypography.bodySmall.copyWith(
                    color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
