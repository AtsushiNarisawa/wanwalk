import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_statistics_provider.dart';
import '../../auth/login_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../legal/terms_of_service_screen.dart';
import '../../legal/privacy_policy_screen.dart';
import '../../social/followers_screen.dart';
import '../../social/following_screen.dart';

/// ProfileTab - ユーザープロフィールとアカウント管理
/// 
/// 構成:
/// 1. ユーザー情報カード（アバター、名前、レベル、XP）
/// 2. ソーシャル統計（フォロワー/フォロー中）
/// 3. メニューリスト（設定、編集、愛犬管理など）
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('ログイン'),
              ),
            ],
          ),
        ),
      );
    }

    final statisticsAsync = ref.watch(userStatisticsProvider(userId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'プロフィール',
          style: WanMapTypography.headlineMedium.copyWith(
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('設定画面は準備中です')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(WanMapSpacing.lg),
            child: Column(
              children: [
                // ユーザー情報カード
                _buildUserInfoCard(context, isDark, currentUser, statisticsAsync),
                
                const SizedBox(height: WanMapSpacing.xl),
                
                // ソーシャル統計
                _buildSocialStats(context, isDark, userId),
                
                const SizedBox(height: WanMapSpacing.xl),
                
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
    User? currentUser,
    AsyncValue<dynamic> statisticsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WanMapColors.accent,
            WanMapColors.accent.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: WanMapColors.accent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // アバター
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: currentUser?.userMetadata?['avatar_url'] != null
                ? NetworkImage(currentUser!.userMetadata!['avatar_url'] as String)
                : null,
            child: currentUser?.userMetadata?['avatar_url'] == null
                ? const Icon(Icons.person, size: 60, color: WanMapColors.accent)
                : null,
          ),
          
          const SizedBox(height: WanMapSpacing.md),
          
          // 表示名
          Text(
            currentUser?.userMetadata?['display_name'] as String? ?? 'ユーザー名未設定',
            style: WanMapTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: WanMapSpacing.xs),
          
          // メールアドレス
          if (currentUser?.email != null)
            Text(
              currentUser!.email!,
              style: WanMapTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          
          const SizedBox(height: WanMapSpacing.lg),
          
          // 統計情報
          statisticsAsync.when(
            data: (stats) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_walk, color: Colors.amber, size: 28),
                    const SizedBox(width: WanMapSpacing.xs),
                    Text(
                      '総散歩回数: ${stats.totalWalks}',
                      style: WanMapTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WanMapSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.route, color: Colors.amber, size: 24),
                    const SizedBox(width: WanMapSpacing.xs),
                    Text(
                      '総距離: ${stats.totalDistanceKm.toStringAsFixed(1)} km',
                      style: WanMapTypography.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// ソーシャル統計
  Widget _buildSocialStats(BuildContext context, bool isDark, String userId) {
    return Row(
      children: [
        Expanded(
          child: _SocialStatCard(
            icon: Icons.people_outline,
            label: 'フォロワー',
            value: '0',
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FollowersScreen(userId: userId),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: WanMapSpacing.md),
        Expanded(
          child: _SocialStatCard(
            icon: Icons.person_add_outlined,
            label: 'フォロー中',
            value: '0',
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FollowingScreen(userId: userId),
                ),
              );
            },
          ),
        ),
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
            icon: Icons.edit_outlined,
            label: 'プロフィール編集',
            isDark: isDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('プロフィール編集は準備中です')),
              );
            },
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.pets_outlined,
            label: '愛犬の管理',
            isDark: isDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('愛犬管理は準備中です')),
              );
            },
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.favorite_outline,
            label: 'お気に入り',
            isDark: isDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('お気に入り機能は準備中です')),
              );
            },
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.notifications_outlined,
            label: '通知設定',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.settings_outlined,
            label: '設定',
            isDark: isDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('設定画面は準備中です')),
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
          
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
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

class _SocialStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  const _SocialStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(WanMapSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: WanMapColors.accent),
            const SizedBox(height: WanMapSpacing.sm),
            Text(
              value,
              style: WanMapTypography.headlineMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: WanMapSpacing.xs),
            Text(
              label,
              style: WanMapTypography.caption.copyWith(
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
            ),
          ],
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
