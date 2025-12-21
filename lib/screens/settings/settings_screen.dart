import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/theme_provider.dart';
import 'change_password_screen.dart';
import 'change_email_screen.dart';
import 'help_screen.dart';

/// 設定画面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? WanMapColors.cardDark : Colors.white,
        elevation: 0,
        title: const Text(
          '設定',
          style: WanMapTypography.heading2,
        ),
      ),
      body: ListView(
        children: [
          // アプリ設定セクション
          _buildSectionHeader('アプリ設定', isDark),
          _buildSettingsCard(
            isDark,
            children: [
              _buildThemeSelector(context, ref, isDark, themeMode),
              const Divider(height: 1),
              _buildNotificationSettings(context, isDark),
            ],
          ),
          
          // アカウント設定セクション
          _buildSectionHeader('アカウント', isDark),
          _buildSettingsCard(
            isDark,
            children: [
              _buildSettingsTile(
                context,
                isDark,
                icon: Icons.lock_outline,
                title: 'パスワード変更',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context,
                isDark,
                icon: Icons.email_outlined,
                title: 'メールアドレス変更',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangeEmailScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          // その他セクション
          _buildSectionHeader('その他', isDark),
          _buildSettingsCard(
            isDark,
            children: [
              _buildSettingsTile(
                context,
                isDark,
                icon: Icons.help_outline,
                title: 'ヘルプ・サポート',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context,
                isDark,
                icon: Icons.info_outline,
                title: 'アプリについて',
                subtitle: 'WanWalk v1.0.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'WanWalk',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 WanWalk',
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: WanMapSpacing.large),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WanMapSpacing.medium,
        WanMapSpacing.large,
        WanMapSpacing.medium,
        WanMapSpacing.small,
      ),
      child: Text(
        title,
        style: WanMapTypography.caption.copyWith(
          color: isDark ? Colors.white54 : Colors.black45,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: WanMapSpacing.medium),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    ThemeMode themeMode,
  ) {
    return ListTile(
      leading: const Icon(
        Icons.palette_outlined,
        color: WanMapColors.accent,
      ),
      title: const Text(
        'テーマ',
        style: WanMapTypography.body,
      ),
      subtitle: Text(
        _getThemeModeText(themeMode),
        style: WanMapTypography.caption.copyWith(
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, ref, themeMode),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'ライトモード';
      case ThemeMode.dark:
        return 'ダークモード';
      case ThemeMode.system:
        return 'システム設定に従う';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テーマ設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('ライトモード'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('ダークモード'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('システム設定に従う'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context, bool isDark) {
    return SwitchListTile(
      secondary: const Icon(
        Icons.notifications_outlined,
        color: WanMapColors.accent,
      ),
      title: const Text(
        '通知',
        style: WanMapTypography.body,
      ),
      subtitle: Text(
        '散歩のリマインダーなど',
        style: WanMapTypography.caption.copyWith(
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
      value: true, // TODO: 実際の通知設定状態を取得
      onChanged: (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知設定機能は準備中です')),
        );
      },
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: WanMapColors.accent,
      ),
      title: Text(
        title,
        style: WanMapTypography.body,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: WanMapTypography.caption.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
