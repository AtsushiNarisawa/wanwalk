import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../providers/push_notification_provider.dart';

/// プリ許可画面（B1 §3.1）。
///
/// オンボーディング完了 → 愛犬登録 →（ここ）→ メイン画面 という挿入位置。
/// CEO 指示: 通知許可率最大化のため「価値先・許可後」「頻度を約束」「あとで設定可能」を必ず添える。
///
/// 結果:
/// - `Navigator.of(context).pop(true)`  : 許可獲得
/// - `Navigator.of(context).pop(false)` : 「あとで」 / 拒否
///
/// 戻り値を見て上位フローが画面遷移する。
class PrePermissionScreen extends ConsumerStatefulWidget {
  const PrePermissionScreen({super.key});

  @override
  ConsumerState<PrePermissionScreen> createState() => _PrePermissionScreenState();
}

class _PrePermissionScreenState extends ConsumerState<PrePermissionScreen> {
  bool _requesting = false;

  Future<void> _onAllow() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    final service = ref.read(notificationPermissionServiceProvider);
    final granted = await service.requestOsPermission();

    if (granted) {
      // 許可されたら即トークン登録（APNs/FCM 取得 + Supabase UPSERT）
      final push = ref.read(pushNotificationServiceProvider);
      await push.registerCurrentDeviceToken();
    }

    if (!mounted) return;
    Navigator.of(context).pop(granted);
  }

  Future<void> _onDefer() async {
    final service = ref.read(notificationPermissionServiceProvider);
    await service.markPrePromptDeferred();
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? WanWalkColors.backgroundDark
        : WanWalkColors.backgroundLight;
    final textPrimary = isDark
        ? WanWalkColors.textPrimaryDark
        : WanWalkColors.textPrimaryLight;
    final textSecondary = isDark
        ? WanWalkColors.textSecondaryDark
        : WanWalkColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              const Spacer(),

              // アイコン（深緑系・抑制トーン）
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: WanWalkColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    PhosphorIcons.bell(),
                    size: 44,
                    color: WanWalkColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                '毎朝、お散歩のベスト\nタイミングをお知らせ',
                textAlign: TextAlign.center,
                style: WanWalkTypography.heading2.copyWith(
                  color: textPrimary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                '日の出時刻に合わせて、\nその日のおすすめルートをお届けします',
                textAlign: TextAlign.center,
                style: WanWalkTypography.body.copyWith(
                  color: textSecondary,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 28),

              _BulletLine(
                text: '通知は1日1回だけ',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _BulletLine(
                text: 'あとで設定からオフにできます',
                isDark: isDark,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _requesting ? null : _onAllow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WanWalkColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _requesting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          '通知をオンにする',
                          style: WanWalkTypography.buttonLarge.copyWith(
                            fontSize: 17,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: _requesting ? null : _onDefer,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: textSecondary,
                ),
                child: Text(
                  'あとで',
                  style: WanWalkTypography.body.copyWith(
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? WanWalkColors.textSecondaryDark
        : WanWalkColors.textSecondaryLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: WanWalkColors.primary.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: WanWalkTypography.bodyMedium.copyWith(
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}
