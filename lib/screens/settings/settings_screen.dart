import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '表示設定',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return ListTile(
                      leading: const Icon(Icons.brightness_6),
                      title: const Text('テーマ'),
                      subtitle: Text(_getThemeModeLabel(themeProvider.themeMode)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showThemeDialog(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '通知設定',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    return SwitchListTile(
                      secondary: const Icon(Icons.notifications_active),
                      title: const Text('通知を有効にする'),
                      subtitle: const Text('リマインダーやお知らせを受け取る'),
                      value: notificationProvider.settings.enabled,
                      onChanged: (value) {
                        notificationProvider.setEnabled(value);
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    final settings = notificationProvider.settings;
                    return SwitchListTile(
                      secondary: const Icon(Icons.alarm),
                      title: const Text('毎日のリマインダー'),
                      subtitle: Text(
                        '${settings.dailyReminderTime.hour}:${settings.dailyReminderTime.minute.toString().padLeft(2, '0')}に通知',
                      ),
                      value: settings.dailyReminderEnabled,
                      onChanged: settings.enabled
                          ? (value) {
                              notificationProvider.setDailyReminderEnabled(value);
                            }
                          : null,
                    );
                  },
                ),
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    final settings = notificationProvider.settings;
                    return ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('リマインダー時刻'),
                      subtitle: Text(
                        '${settings.dailyReminderTime.hour}:${settings.dailyReminderTime.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: settings.enabled && settings.dailyReminderEnabled,
                      onTap: () {
                        // TODO: Implement reminder time selection
                        // _selectReminderTime(context);
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    return ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('テスト通知を送信'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await notificationProvider.sendTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('テスト通知を送信しました')),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'アプリ情報',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('バージョン'),
                  subtitle: Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('利用規約'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Show terms of service
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('プライバシーポリシー'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Show privacy policy
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'ライトモード';
      case ThemeMode.dark:
        return 'ダークモード';
      case ThemeMode.system:
        return 'システム設定に従う';
    }
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentThemeMode = themeProvider.themeMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テーマ選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('ライトモード'),
              subtitle: const Text('明るい配色'),
              value: ThemeMode.light,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('ダークモード'),
              subtitle: const Text('暗い配色'),
              value: ThemeMode.dark,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('システム設定に従う'),
              subtitle: const Text('端末の設定に合わせる'),
              value: ThemeMode.system,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
