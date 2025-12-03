import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ルート削減スクリプト
/// 
/// 各エリアのルート数を削減:
/// - 箱根: 3ルート
/// - 横浜/鎌倉: 2ルート
/// - その他エリア: 1ルート
/// 
/// 選択基準: 散歩回数が多い順（walk_count DESC）
void main() async {
  // Supabase初期化
  await Supabase.initialize(
    url: Platform.environment['SUPABASE_URL'] ?? '',
    anonKey: Platform.environment['SUPABASE_ANON_KEY'] ?? '',
  );

  final supabase = Supabase.instance.client;

  print('🔍 現在のルート状況を確認中...\n');

  // エリア別ルート数の設定
  final areaLimits = {
    '箱根': 3,
    '横浜': 2,
    '鎌倉': 2,
  };

  try {
    // 全ルートを取得
    final response = await supabase
        .from('routes')
        .select('route_id, route_name, area_name, walk_count')
        .order('area_name')
        .order('walk_count', ascending: false);

    final allRoutes = response as List<dynamic>;

    print('📊 全ルート数: ${allRoutes.length}\n');

    // エリアごとにグループ化
    final routesByArea = <String, List<Map<String, dynamic>>>{};
    for (var route in allRoutes) {
      final areaName = route['area_name'] as String;
      routesByArea.putIfAbsent(areaName, () => []);
      routesByArea[areaName]!.add(route as Map<String, dynamic>);
    }

    print('📍 エリア別ルート数:');
    routesByArea.forEach((area, routes) {
      print('  $area: ${routes.length}ルート');
    });
    print('');

    // 削除対象ルートを特定
    final routesToDelete = <String>[];
    final routesToKeep = <Map<String, dynamic>>[];

    routesByArea.forEach((area, routes) {
      final limit = areaLimits[area] ?? 1; // デフォルト1ルート
      
      print('🔧 $area エリア: ${routes.length}ルート → ${limit}ルートに削減');
      
      // 上位N件を残す
      final keep = routes.take(limit).toList();
      final delete = routes.skip(limit).toList();
      
      routesToKeep.addAll(keep);
      
      for (var route in keep) {
        print('  ✅ 残す: ${route['route_name']} (散歩回数: ${route['walk_count'] ?? 0})');
      }
      
      for (var route in delete) {
        print('  ❌ 削除: ${route['route_name']} (散歩回数: ${route['walk_count'] ?? 0})');
        routesToDelete.add(route['route_id'] as String);
      }
      
      print('');
    });

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 削減結果サマリー:');
    print('  全体: ${allRoutes.length}ルート → ${routesToKeep.length}ルート');
    print('  削除対象: ${routesToDelete.length}ルート');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    if (routesToDelete.isEmpty) {
      print('✅ 削除対象ルートはありません。');
      return;
    }

    // 確認プロンプト
    print('⚠️  上記のルートを削除しますか？ (y/n): ');
    final confirmation = stdin.readLineSync();

    if (confirmation?.toLowerCase() != 'y') {
      print('❌ キャンセルしました。');
      return;
    }

    // ルートを削除
    print('\n🗑️  ルートを削除中...');
    
    for (var routeId in routesToDelete) {
      // route_pointsも同時に削除される（CASCADE設定されている場合）
      await supabase.from('routes').delete().eq('route_id', routeId);
      print('  ✅ 削除完了: $routeId');
    }

    print('\n✅ ルート削減が完了しました！');
    print('📊 最終ルート数: ${routesToKeep.length}');

  } catch (e) {
    print('❌ エラーが発生しました: $e');
    exit(1);
  }
}
