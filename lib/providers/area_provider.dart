import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/area.dart';

/// Supabaseクライアントのインスタンス取得
final _supabase = Supabase.instance.client;

/// エリア一覧を取得するProvider
final areasProvider = FutureProvider<List<Area>>((ref) async {
  print('🔵 areasProvider: Starting to fetch areas...');
  try {
    print('🔵 Querying Supabase areas table...');
    final response = await _supabase
        .from('areas')
        .select('id, name, prefecture, description, center_point, created_at')
        .order('name', ascending: true);

    print('🔵 Response received: ${response.runtimeType}');
    print('🔵 Response data: $response');
    
    final areas = (response as List).map((json) => Area.fromJson(json)).toList();
    print('✅ Successfully fetched ${areas.length} areas');
    return areas;
  } catch (e, stackTrace) {
    print('❌ Failed to fetch areas: $e');
    print('❌ Stack trace: $stackTrace');
    throw Exception('Failed to fetch areas: $e');
  }
});

/// 特定のエリアIDでエリア情報を取得するProvider
final areaByIdProvider = FutureProvider.family<Area?, String>((ref, areaId) async {
  try {
    final response = await _supabase
        .from('areas')
        .select()
        .eq('id', areaId)
        .maybeSingle();

    if (response == null) return null;
    return Area.fromJson(response);
  } catch (e) {
    throw Exception('Failed to fetch area: $e');
  }
});

/// 選択中のエリアIDを管理するProvider
class SelectedAreaNotifier extends StateNotifier<String?> {
  SelectedAreaNotifier() : super(null);

  void selectArea(String? areaId) {
    state = areaId;
  }

  void clearSelection() {
    state = null;
  }
}

final selectedAreaIdProvider = StateNotifierProvider<SelectedAreaNotifier, String?>(
  (ref) => SelectedAreaNotifier(),
);

/// 選択中のエリア情報を取得するProvider
final selectedAreaProvider = Provider<AsyncValue<Area?>>((ref) {
  final areaId = ref.watch(selectedAreaIdProvider);
  if (areaId == null) {
    return const AsyncValue.data(null);
  }
  return ref.watch(areaByIdProvider(areaId));
});
