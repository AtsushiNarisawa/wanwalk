import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/walk_detail_service.dart';

/// WalkDetailServiceのプロバイダー
final walkDetailServiceProvider = Provider<WalkDetailService>((ref) {
  return WalkDetailService();
});

/// お出かけ散歩詳細プロバイダー
final walkDetailProvider = FutureProvider.family<WalkDetail?, String>(
  (ref, walkId) async {
    final service = ref.read(walkDetailServiceProvider);
    return await service.getWalkDetail(walkId: walkId);
  },
);
