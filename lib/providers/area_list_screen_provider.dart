import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/area.dart';
import '../config/supabase_config.dart';

/// ソートオプション
enum AreaSortOption {
  routeCount('route_count', 'ルート数順'),
  nameAsc('name_asc', '名前順（あ→ん）'),
  newest('newest', '新着順');

  const AreaSortOption(this.value, this.label);
  final String value;
  final String label;
}

/// 検索クエリ
final searchQueryProviderForAreaList = StateProvider<String>((ref) => '');

/// 選択中の都道府県フィルタ
final selectedPrefectureProviderForAreaList = StateProvider<String?>((ref) => null);

/// ソートオプション
final areaSortOptionProvider = StateProvider<AreaSortOption>((ref) => AreaSortOption.routeCount);

/// 都道府県一覧プロバイダー
final prefecturesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final supabase = SupabaseConfig.client;
    
    final response = await supabase
        .from('areas')
        .select('prefecture')
        .order('prefecture');
    
    final prefectures = (response as List)
        .map((item) => item['prefecture'] as String)
        .toSet() // 重複削除
        .toList();
    
    prefectures.sort(); // あいうえお順
    return prefectures;
  } catch (e) {
    print('❌ 都道府県一覧取得エラー: $e');
    return [];
  }
});

/// エリア一覧（検索・フィルタ・ソート対応）
/// 箱根エリアをグループ化して表示
final filteredAreasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final searchQuery = ref.watch(searchQueryProviderForAreaList);
  final selectedPrefecture = ref.watch(selectedPrefectureProviderForAreaList);
  final sortOption = ref.watch(areaSortOptionProvider);

  try {
    final supabase = SupabaseConfig.client;
    
    // 1. エリア一覧と公式ルート数を取得
    var query = supabase.rpc(
      'get_areas_with_route_count',
      params: {
        'search_query': searchQuery.isEmpty ? null : searchQuery,
        'prefecture_filter': selectedPrefecture,
        'sort_by': sortOption.value,
      },
    );

    final response = await query;
    final areas = (response as List).cast<Map<String, dynamic>>();
    
    // 2. 箱根エリアをグループ化
    return _groupHakoneAreas(areas);
  } catch (e) {
    print('❌ エリア一覧取得エラー: $e');
    rethrow;
  }
});

/// 箱根エリアをグループ化する
List<Map<String, dynamic>> _groupHakoneAreas(List<Map<String, dynamic>> areas) {
  final hakoneAreas = <Map<String, dynamic>>[];
  final otherAreas = <Map<String, dynamic>>[];
  
  for (final area in areas) {
    final name = area['name'] as String;
    if (name.startsWith('箱根・')) {
      print('🔍 箱根エリア検出: $name, route_count: ${area['route_count']}');
      hakoneAreas.add(area);
    } else {
      otherAreas.add(area);
    }
  }
  
  print('📊 箱根エリア合計: ${hakoneAreas.length}件');
  print('📊 箱根エリア合計: ${hakoneAreas.length}件');
  
  // 箱根エリアが複数ある場合のみグループ化
  if (hakoneAreas.length > 1) {
    // 箱根グループの合計ルート数を計算
    final totalRoutes = hakoneAreas.fold<int>(
      0,
      (sum, area) => sum + ((area['route_count'] as int?) ?? 0),
    );
    
    print('📊 箱根グループ合計ルート数: $totalRoutes');
    
    // 箱根親エリアを作成
    final hakoneParent = {
      'id': 'hakone_group', // 特殊ID
      'name': '箱根',
      'prefecture': '神奈川県',
      'description': '神奈川県の人気観光地。温泉、美術館、芦ノ湖など多彩なスポットがあります。',
      'route_count': totalRoutes,
      'is_hakone_group': true, // 箱根グループフラグ
      'sub_areas': hakoneAreas, // サブエリア一覧
    };
    
    print('✅ 箱根グループ作成完了: sub_areas=${hakoneAreas.length}件');
    
    // 箱根親エリアを先頭に、その後に他のエリア
    return [hakoneParent, ...otherAreas];
  } else {
    // 箱根エリアが1つ以下の場合はそのまま返す
    return areas;
  }
}
