import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/area.dart';
import '../services/supabase_service.dart';

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
    final supabase = SupabaseService.client;
    
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
final filteredAreasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final searchQuery = ref.watch(searchQueryProviderForAreaList);
  final selectedPrefecture = ref.watch(selectedPrefectureProviderForAreaList);
  final sortOption = ref.watch(areaSortOptionProvider);

  try {
    final supabase = SupabaseService.client;
    
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
    
    return (response as List).cast<Map<String, dynamic>>();
  } catch (e) {
    print('❌ エリア一覧取得エラー: $e');
    rethrow;
  }
});
