import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 元は `flutter create` デフォルトの widget test（`package:wanwalk_v2/main.dart` +
// `MyApp` を参照）だったが、パッケージ名リネーム（WanMap→WanWalk）後 obsolete 化し
// コンパイル不能なまま残っていた。analysis_options で analyze からは除外されていたが
// `flutter test` では実行され、test/ がほぼ空だった間は誰も気づかなかった（A26）。
// アプリ全体の起動 smoke は Supabase/Riverpod 初期化が絡むためここでは行わず、
// 最小限のウィジェット構築が機能することのみ確認する。
void main() {
  testWidgets('MaterialApp の基本構築が機能する', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('WanWalk'))),
    );
    expect(find.text('WanWalk'), findsOneWidget);
  });
}
