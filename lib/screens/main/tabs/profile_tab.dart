import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/wanwalk_colors.dart';
import '../../../config/wanwalk_icons.dart';
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

/// ProfileTab - プロフィール＋愛犬管理（Phase 2 Wildboundsトーン）
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  @override
  void initState() {
    super.initState();
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
      return _buildUnauthScreen(context);
    }

    final profileAsync = ref.watch(profileProvider(userId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: WanWalkColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: WanWalkColors.bgPrimary,
        foregroundColor: WanWalkColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('プロフィール', style: WanWalkTypography.wwH2),
      ),
      body: RefreshIndicator(
        color: WanWalkColors.accentPrimary,
        onRefresh: () async {
          ref.invalidate(profileProvider(userId));
          ref.invalidate(userStatisticsProvider(userId));
          ref.read(dogProvider.notifier).loadUserDogs(userId);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(WanWalkSpacing.s4),
            child: Column(
              children: [
                profileAsync.when(
                  data: (profile) => _buildUserInfoCard(context, isDark, profile, currentUser),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: WanWalkColors.accentPrimary),
                  ),
                  error: (_, __) => _buildUserInfoCard(context, isDark, null, currentUser),
                ),
                const SizedBox(height: WanWalkSpacing.s4),
                _buildStatisticsCard(context, userId),
                const SizedBox(height: WanWalkSpacing.s4),
                _buildDogCards(context, userId, ref),
                const SizedBox(height: WanWalkSpacing.s4),
                _buildMenuList(context, currentUser, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 未ログイン画面
  Widget _buildUnauthScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: WanWalkColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: WanWalkColors.bgPrimary,
        foregroundColor: WanWalkColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('マイページ', style: WanWalkTypography.wwH2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WanWalkSpacing.s5),
        child: Column(
          children: [
            const SizedBox(height: WanWalkSpacing.s6),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: WanWalkColors.accentPrimarySoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                WanWalkIcons.user,
                size: 48,
                color: WanWalkColors.accentPrimary,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.s5),
            const Text(
              '愛犬との散歩をもっと楽しく',
              style: WanWalkTypography.wwH2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WanWalkSpacing.s2),
            Text(
              'ログインすると、プロフィール設定や\n愛犬の登録ができます',
              style: WanWalkTypography.wwBody.copyWith(color: WanWalkColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WanWalkSpacing.s6),
            _UnauthProfileFeature(
              icon: PhosphorIcons.dog(),
              title: '愛犬プロフィール',
              description: '愛犬の情報を登録して管理',
            ),
            const SizedBox(height: WanWalkSpacing.s2),
            _UnauthProfileFeature(
              icon: WanWalkIcons.chartLineUp,
              title: '散歩の統計',
              description: '散歩回数や距離をグラフで確認',
            ),
            const SizedBox(height: WanWalkSpacing.s2),
            _UnauthProfileFeature(
              icon: WanWalkIcons.trophy,
              title: 'バッジ＆レベル',
              description: '散歩するほどレベルアップ（今後対応）',
            ),
            const SizedBox(height: WanWalkSpacing.s6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthSelectionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WanWalkColors.accentPrimary,
                  foregroundColor: WanWalkColors.textInverse,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  'ログイン / 新規登録',
                  style: WanWalkTypography.wwH4.copyWith(color: WanWalkColors.textInverse),
                ),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.s3),
            Text(
              'ログインなしでもマップの閲覧はできます',
              style: WanWalkTypography.wwCaption,
            ),
          ],
        ),
      ),
    );
  }

  /// 散歩統計カード
  Widget _buildStatisticsCard(BuildContext context, String userId) {
    final statsAsync = ref.watch(userStatisticsProvider(userId));

    return statsAsync.when(
      data: (stats) {
        return Container(
          padding: const EdgeInsets.all(WanWalkSpacing.s4),
          decoration: BoxDecoration(
            color: WanWalkColors.bgPrimary,
            borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
            border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('散歩の記録', style: WanWalkTypography.wwH3),
              const SizedBox(height: WanWalkSpacing.s3),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: '${stats.totalWalks}',
                      label: '散歩回数',
                      icon: WanWalkIcons.personWalk,
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      value: stats.formattedTotalDistance,
                      label: '総距離',
                      icon: WanWalkIcons.ruler,
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      value: stats.formattedTotalDuration,
                      label: '総時間',
                      icon: WanWalkIcons.clock,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WanWalkSpacing.s3),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: '${stats.areasVisited}',
                      label: 'エリア',
                      icon: WanWalkIcons.mapPin,
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      value: '${stats.routesCompleted}',
                      label: 'ルート',
                      icon: WanWalkIcons.path,
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      value: '${stats.pinsCreated}',
                      label: 'ピン投稿',
                      icon: WanWalkIcons.pushpin,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(color: WanWalkColors.accentPrimary)),
      ),
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
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
        );
      },
      borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(WanWalkSpacing.s4),
        decoration: BoxDecoration(
          color: WanWalkColors.bgPrimary,
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: WanWalkColors.accentPrimarySoft,
              backgroundImage: profile?.avatarUrl != null
                  ? NetworkImage(profile!.avatarUrl!)
                  : null,
              child: profile?.avatarUrl == null
                  ? Icon(WanWalkIcons.user, size: 28, color: WanWalkColors.accentPrimary)
                  : null,
            ),
            const SizedBox(width: WanWalkSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.displayName ?? 'ユーザー名未設定',
                    style: WanWalkTypography.wwH4,
                  ),
                  const SizedBox(height: 2),
                  if (currentUser?.email != null)
                    Text(
                      currentUser!.email!,
                      style: WanWalkTypography.wwCaption,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              WanWalkIcons.pencil,
              color: WanWalkColors.textSecondary,
              size: WanWalkIcons.sizeMd,
            ),
          ],
        ),
      ),
    );
  }

  /// 愛犬カードセクション
  Widget _buildDogCards(
    BuildContext context,
    String userId,
    WidgetRef ref,
  ) {
    final dogs = ref.watch(userDogsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: WanWalkSpacing.s1,
            bottom: WanWalkSpacing.s2,
          ),
          child: Row(
            children: [
              const Text('愛犬情報', style: WanWalkTypography.wwH3),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DogEditScreen(userId: userId)),
                  );
                },
                icon: Icon(
                  WanWalkIcons.plus,
                  color: WanWalkColors.accentPrimary,
                  size: WanWalkIcons.sizeLg,
                ),
                tooltip: '愛犬を追加',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
        ),
        if (dogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(WanWalkSpacing.s6),
            decoration: BoxDecoration(
              color: WanWalkColors.bgPrimary,
              borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
              border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
            ),
            child: Column(
              children: [
                Icon(
                  PhosphorIcons.dog(),
                  size: 40,
                  color: WanWalkColors.textTertiary,
                ),
                const SizedBox(height: WanWalkSpacing.s3),
                Text(
                  'まだ愛犬が登録されていません',
                  style: WanWalkTypography.wwBody.copyWith(color: WanWalkColors.textSecondary),
                ),
                const SizedBox(height: WanWalkSpacing.s1),
                Text(
                  '右上の＋ボタンから追加できます',
                  style: WanWalkTypography.wwCaption,
                ),
                const SizedBox(height: WanWalkSpacing.s4),
                ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DogEditScreen(userId: userId)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WanWalkColors.accentPrimary,
                    foregroundColor: WanWalkColors.textInverse,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
                    ),
                  ),
                  icon: Icon(WanWalkIcons.plus, size: WanWalkIcons.sizeSm),
                  label: const Text('愛犬を追加'),
                ),
              ],
            ),
          )
        else
          ...dogs.asMap().entries.map((entry) {
            final dog = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: WanWalkSpacing.s2),
              child: _DogCard(
                dog: dog,
                onTap: () async {
                  HapticFeedback.selectionClick();
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
          }),
      ],
    );
  }

  /// メニューリスト
  Widget _buildMenuList(
    BuildContext context,
    User? currentUser,
    WidgetRef ref,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: WanWalkColors.bgPrimary,
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
        border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: WanWalkIcons.gear,
            label: '設定',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Divider(height: 1, color: WanWalkColors.borderSubtle),
          _MenuItem(
            icon: WanWalkIcons.info,
            label: '利用規約',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
            ),
          ),
          const Divider(height: 1, color: WanWalkColors.borderSubtle),
          _MenuItem(
            icon: WanWalkIcons.lock,
            label: 'プライバシーポリシー',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          const Divider(height: 1, color: WanWalkColors.borderSubtle),
          _MenuItem(
            icon: WanWalkIcons.signOut,
            label: 'ログアウト',
            isDestructive: true,
            onTap: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WanWalkColors.bgPrimary,
        title: const Text('ログアウト', style: WanWalkTypography.wwH3),
        content: const Text('ログアウトしますか？', style: WanWalkTypography.wwBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: WanWalkColors.textSecondary),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: WanWalkColors.semanticError),
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
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ログアウトに失敗しました: $e'),
              backgroundColor: WanWalkColors.semanticError,
            ),
          );
        }
      }
    }
  }
}

class _DogCard extends StatelessWidget {
  final DogModel dog;
  final VoidCallback onTap;

  const _DogCard({required this.dog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(WanWalkSpacing.s3),
        decoration: BoxDecoration(
          color: WanWalkColors.bgPrimary,
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
              child: dog.photoUrl != null && dog.photoUrl!.isNotEmpty
                  ? Image.network(
                      dog.photoUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDogPlaceholder(),
                    )
                  : _buildDogPlaceholder(),
            ),
            const SizedBox(width: WanWalkSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dog.name,
                    style: WanWalkTypography.wwH4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dog.breed ?? '犬種不明',
                    style: WanWalkTypography.wwCaption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WanWalkSpacing.s2),
                  Row(
                    children: [
                      Icon(
                        WanWalkIcons.calendar,
                        size: WanWalkIcons.sizeXs,
                        color: WanWalkColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(dog.ageDisplay, style: WanWalkTypography.wwBodySm),
                      const SizedBox(width: WanWalkSpacing.s3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: WanWalkColors.accentPrimarySoft,
                          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
                        ),
                        child: Text(
                          dog.sizeDisplay,
                          style: WanWalkTypography.wwLabel.copyWith(
                            color: WanWalkColors.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              WanWalkIcons.caretRight,
              color: WanWalkColors.textSecondary,
              size: WanWalkIcons.sizeSm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDogPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: WanWalkColors.accentPrimarySoft,
      alignment: Alignment.center,
      child: Icon(
        PhosphorIcons.dog(),
        size: 28,
        color: WanWalkColors.accentPrimary,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Icon(icon, color: WanWalkColors.accentPrimary, size: WanWalkIcons.sizeMd),
          const SizedBox(height: 6),
          Text(
            value,
            style: WanWalkTypography.wwNumeric.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: WanWalkColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: WanWalkTypography.wwCaption),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? WanWalkColors.semanticError : WanWalkColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color, size: WanWalkIcons.sizeMd),
      title: Text(
        label,
        style: WanWalkTypography.wwBody.copyWith(color: color),
      ),
      trailing: Icon(
        WanWalkIcons.caretRight,
        color: WanWalkColors.textSecondary,
        size: WanWalkIcons.sizeSm,
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}

/// 未ログイン時の機能紹介
class _UnauthProfileFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _UnauthProfileFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.s3),
      decoration: BoxDecoration(
        color: WanWalkColors.bgPrimary,
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
        border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WanWalkColors.accentPrimarySoft,
              borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: WanWalkColors.accentPrimary, size: WanWalkIcons.sizeMd),
          ),
          const SizedBox(width: WanWalkSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WanWalkTypography.wwH4),
                const SizedBox(height: 2),
                Text(description, style: WanWalkTypography.wwCaption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
