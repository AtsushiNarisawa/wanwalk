import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/timeline_service.dart';

/// TimelineServiceのプロバイダー
final timelineServiceProvider = Provider<TimelineService>((ref) {
  return TimelineService();
});

/// コミュニティタイムラインプロバイダー
final communityTimelineProvider = FutureProvider.autoDispose.family<List<TimelineItem>, TimelineParams>(
  (ref, params) async {
    final service = ref.read(timelineServiceProvider);
    return await service.getCommunityTimeline(
      userId: params.userId,
      limit: params.limit,
      offset: params.offset,
    );
  },
);

/// タイムライン取得パラメータ
class TimelineParams {
  final String? userId;
  final int limit;
  final int offset;

  TimelineParams({
    this.userId,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => userId.hashCode ^ limit.hashCode ^ offset.hashCode;
}
