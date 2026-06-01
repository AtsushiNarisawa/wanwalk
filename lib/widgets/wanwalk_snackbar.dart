import 'package:flutter/material.dart';

import '../config/wanwalk_colors.dart';

/// WanWalk 共通 SnackBar（DESIGN_TOKENS §2 セマンティックカラー準拠）。
///
/// 原色 `Colors.red` / `Colors.green` / `Colors.orange` や旧 DogHub パレット
/// （`WanWalkColors.error` 等）を直接使わず、必ずこのヘルパー経由で
/// semantic 色（#A84A3D / #5B7F6B / #B8905C / #5B728A）を使う。
///
/// 使用例:
/// ```dart
/// showWanWalkSnackBar(context, '保存しました', type: WanWalkSnackBarType.success);
/// showWanWalkSnackBar(context, 'エラーが発生しました: $e', type: WanWalkSnackBarType.error);
/// ```
enum WanWalkSnackBarType { success, error, warning, info }

extension WanWalkSnackBarTypeColor on WanWalkSnackBarType {
  Color get color {
    switch (this) {
      case WanWalkSnackBarType.success:
        return WanWalkColors.semanticSuccess;
      case WanWalkSnackBarType.error:
        return WanWalkColors.semanticError;
      case WanWalkSnackBarType.warning:
        return WanWalkColors.semanticWarning;
      case WanWalkSnackBarType.info:
        return WanWalkColors.semanticInfo;
    }
  }
}

/// semantic 色で統一された SnackBar を表示する。
///
/// [type] で背景色を決定（既定は info）。[duration] / [action] は任意。
/// 連続表示時に積み上がらないよう、表示前に現在の SnackBar を隠す。
void showWanWalkSnackBar(
  BuildContext context,
  String message, {
  WanWalkSnackBarType type = WanWalkSnackBarType.info,
  Duration? duration,
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: type.color,
      // Flutter の SnackBar 既定表示時間（4 秒）に合わせる。
      duration: duration ?? const Duration(seconds: 4),
      action: action,
    ),
  );
}
