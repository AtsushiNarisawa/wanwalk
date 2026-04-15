import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/wanwalk_colors.dart';
import '../config/wanwalk_spacing.dart';
import '../config/wanwalk_typography.dart';

/// GPSオフ / 位置情報未許可時の誘導ダイアログ
///
/// DESIGN_TOKENS.md 準拠（Wildboundsトーン）。
/// 「設定を開く」ボタンで openAppSettings() を呼び出し、iOS 設定 > WanWalk へ直接遷移。
Future<void> showLocationPermissionDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: WanWalkColors.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusLg),
      ),
      title: const Text(
        '現在地を取得できません',
        style: TextStyle(
          fontFamily: 'NotoSerifJP',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: WanWalkColors.textPrimary,
        ),
      ),
      content: Text(
        '位置情報の利用が許可されていない可能性があります。\n設定アプリから「位置情報」をオンにしてください。',
        style: WanWalkTypography.wwBodySm,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'キャンセル',
            style: WanWalkTypography.wwBodySm.copyWith(
              color: WanWalkColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await openAppSettings();
          },
          child: const Text(
            '設定を開く',
            style: TextStyle(
              fontFamily: 'NotoSansJP',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: WanWalkColors.accentPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
