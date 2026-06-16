import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/area_taxonomy.dart';
import '../utils/logger.dart';

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

    // 需要順（kPrefectureOrder）→ 未掲載は末尾であいうえお順。
    prefectures.sort((a, b) {
      final c = prefectureOrderIndex(a).compareTo(prefectureOrderIndex(b));
      return c != 0 ? c : a.compareTo(b);
    });
    return prefectures;
  } catch (e) {
    appLog('❌ 都道府県一覧取得エラー: $e');
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
    
    // 1. エリア一覧を取得
    var areasQuery = supabase.from('areas').select();
    
    // 検索フィルタ
    if (searchQuery.isNotEmpty) {
      areasQuery = areasQuery.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
    }
    
    // 都道府県フィルタ
    if (selectedPrefecture != null) {
      areasQuery = areasQuery.eq('prefecture', selectedPrefecture);
    }
    
    final areasResponse = await areasQuery;
    final areasList = (areasResponse as List).cast<Map<String, dynamic>>();
    
    // 2. 各エリアのルート数を取得
    final areasWithCount = <Map<String, dynamic>>[];
    for (final area in areasList) {
      final routeCountResponse = await supabase
          .from('official_routes')
          .select('id')
          .eq('area_id', area['id'])
          .eq('is_published', true)
          .count(CountOption.exact);
      
      final routeCount = routeCountResponse.count;
      
      appLog('🔍 ${area['name']}: area_id=${area['id']}, route_count=$routeCount');
      
      areasWithCount.add({
        ...area,
        'route_count': routeCount,
      });
      
      if (area['name'].toString().contains('箱根')) {
        appLog('📊 ${area['name']}: route_count=$routeCount');
      }
    }
    
    // 3. ソート
    areasWithCount.sort((a, b) {
      switch (sortOption) {
        case AreaSortOption.routeCount:
          return (b['route_count'] as int).compareTo(a['route_count'] as int);
        case AreaSortOption.nameAsc:
          return (a['name'] as String).compareTo(b['name'] as String);
        case AreaSortOption.newest:
          return DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']));
      }
    });
    
    appLog('🔍 エリア取得完了: ${areasWithCount.length}件');

    // 4. 箱根サブを tier/group_key で親に合成
    return _groupAreasByTaxonomy(areasWithCount);
  } catch (e) {
    appLog('❌ エリア一覧取得エラー: $e');
    rethrow;
  }
});

/// 箱根サブ(tier='sub'/group_key='hakone')を1つの"箱根"親にまとめる。
/// 旧 name.startsWith('箱根・') ハックを tier ベースに置換。
List<Map<String, dynamic>> _groupAreasByTaxonomy(
    List<Map<String, dynamic>> areas) {
  bool isHakoneSub(Map<String, dynamic> a) =>
      a['tier'] == AreaTier.sub && a['group_key'] == AreaGroupKey.hakone;

  final hakoneSubs = areas.where(isHakoneSub).toList();
  final others = areas.where((a) => !isHakoneSub(a)).toList();

  // 箱根サブが複数あるときだけ親チップに集約（検索で1件のみヒット等は素通し）。
  if (hakoneSubs.length > 1) {
    final totalRoutes = hakoneSubs.fold<int>(
      0,
      (sum, area) => sum + ((area['route_count'] as int?) ?? 0),
    );

    final hakoneParent = {
      'id': 'hakone_group', // 特殊ID
      'name': '箱根',
      'prefecture': '神奈川県',
      'slug': 'hakone',
      'tier': AreaTier.region, // セクション分けでは region 扱い（お出かけエリア）
      'description': '神奈川県の人気観光地。温泉、美術館、芦ノ湖など多彩なスポットがあります。',
      'route_count': totalRoutes,
      'is_hakone_group': true, // 箱根グループフラグ
      'sub_areas': hakoneSubs, // サブエリア一覧
      'hero_image_url':
          'https://jkpenklhrlbctebkpvax.supabase.co/storage/v1/object/public/route-photos/ashinoko_west/01.jpg',
    };

    appLog('✅ 箱根グループ作成完了: sub_areas=${hakoneSubs.length}件');

    // 箱根親を先頭に、その後に他のエリア
    return [hakoneParent, ...others];
  } else {
    // 箱根サブが1件以下ならそのまま返す
    return areas;
  }
}
