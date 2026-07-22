import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/submission/route_submission_screen.dart';
import 'route_field_report_sheet.dart';

/// 投稿導線の共通ランチャー。ログインゲート＋シート/画面の起動を一元化する。

/// 新しい道の推薦フォーム（new_route）を開く。
Future<void> openNewRouteSubmission(
  BuildContext context, {
  required String walkId,
  required String entryPoint,
}) async {
  if (Supabase.instance.client.auth.currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('推薦にはログインが必要です')),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          RouteSubmissionScreen(walkId: walkId, entryPoint: entryPoint),
    ),
  );
}

/// 実走報告（field_report）シートを開く。
Future<void> openFieldReport(
  BuildContext context, {
  required String targetRouteId,
  String? walkId,
  String? entryPoint,
}) async {
  if (Supabase.instance.client.auth.currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('報告にはログインが必要です')),
    );
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => RouteFieldReportSheet(
      targetRouteId: targetRouteId,
      walkId: walkId,
      entryPoint: entryPoint,
      scaffoldMessenger: messenger,
    ),
  );
}
