import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/official_route.dart';
import '../models/recent_pin_post.dart';

/// フィードアイテムの種別
enum FeedItemType {
  walkSummary,    // 自分の散歩サマリー
  featuredRoute,  // おすすめピックアップ
  officialRoute,  // 公式ルート紹介
  communityPin,   // コミュニティピン
  areaFeature,    // エリア特集
  seasonalRoute,  // 季節おすすめルート
}

/// フィードアイテム（統合型）
class FeedItem {
  final FeedItemType type;
  final DateTime sortDate;
  final OfficialRoute? route;
  final RecentPinPost? pin;
  final Map<String, dynamic>? extra;

  const FeedItem({
    required this.type,
    required this.sortDate,
    this.route,
    this.pin,
    this.extra,
  });
}

/// おすすめピックアップルートプロバイダー
final featuredRouteProvider = FutureProvider<OfficialRoute?>((ref) async {
  final supabase = Supabase.instance.client;
  try {
    final response = await supabase
        .from('featured_routes')
        .select('route_id, label, official_routes(*)')
        .eq('is_active', true)
        .order('display_order')
        .limit(1);

    final list = response as List;
    if (list.isEmpty) return null;

    final routeJson = list.first['official_routes'];
    if (routeJson == null) return null;
    return OfficialRoute.fromJson(routeJson);
  } catch (_) {
    return null;
  }
});

/// ホームフィードプロバイダー
final homeFeedProvider = FutureProvider<List<FeedItem>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  final now = DateTime.now();
  final items = <FeedItem>[];

  // 1. 自分の散歩サマリー（ログイン時のみ）
  if (userId != null) {
    try {
      final weekAgo = now.subtract(const Duration(days: 7));
      final walksResponse = await supabase
          .from('walks')
          .select('distance_meters, duration_minutes')
          .eq('user_id', userId)
          .gte('created_at', weekAgo.toIso8601String());

      final walks = walksResponse as List;
      if (walks.isNotEmpty) {
        double totalDistance = 0;
        int totalMinutes = 0;
        for (final w in walks) {
          totalDistance += (w['distance_meters'] as num?)?.toDouble() ?? 0;
          totalMinutes += (w['duration_minutes'] as num?)?.toInt() ?? 0;
        }
        items.add(FeedItem(
          type: FeedItemType.walkSummary,
          sortDate: now.add(const Duration(days: 1)),
          extra: {
            'walkCount': walks.length,
            'totalDistanceKm': (totalDistance / 1000).toStringAsFixed(1),
            'totalMinutes': totalMinutes,
          },
        ));
      }
    } catch (_) {}
  }

  // 2. ピックアップルートのIDを取得（フィードから重複排除用）
  String? featuredRouteId;
  try {
    final featuredResponse = await supabase
        .from('featured_routes')
        .select('route_id')
        .eq('is_active', true)
        .limit(1);
    final featuredList = featuredResponse as List;
    if (featuredList.isNotEmpty) {
      featuredRouteId = featuredList.first['route_id'] as String;
    }
  } catch (_) {}

  // 3. 公式ルート（最新順）
  try {
    final routesResponse = await supabase
        .from('official_routes')
        .select()
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .limit(20);

    final routes = (routesResponse as List)
        .map((json) => OfficialRoute.fromJson(json))
        .toList();

    for (final route in routes) {
      // ピックアップルートはフィードから除外（上部に別枠で表示するため）
      if (featuredRouteId != null && route.id == featuredRouteId) continue;

      final createdAt = route.createdAt ?? now.subtract(const Duration(days: 30));
      items.add(FeedItem(
        type: FeedItemType.officialRoute,
        sortDate: createdAt,
        route: route,
      ));
    }
  } catch (_) {}

  // 4. コミュニティピン（最新10件）
  try {
    final pinsResponse = await supabase
        .rpc('get_recent_pins', params: {'limit_count': 10});

    for (final pinJson in (pinsResponse as List)) {
      try {
        final pin = RecentPinPost.fromJson(pinJson);
        items.add(FeedItem(
          type: FeedItemType.communityPin,
          sortDate: pin.createdAt,
          pin: pin,
        ));
      } catch (_) {}
    }
  } catch (_) {}

  // ソート（sortDate降順 = 最新順）
  items.sort((a, b) => b.sortDate.compareTo(a.sortDate));

  // バランス調整: ルート最大10件、ルート2件ごとにピンを1件挟む
  final balanced = <FeedItem>[];
  final routeItems = items.where((i) =>
    i.type == FeedItemType.officialRoute || i.type == FeedItemType.seasonalRoute
  ).take(10).toList();
  final nonRouteItems = items.where((i) =>
    i.type != FeedItemType.officialRoute && i.type != FeedItemType.seasonalRoute
  ).toList();

  // walkSummaryは先頭
  balanced.addAll(nonRouteItems.where((i) => i.type == FeedItemType.walkSummary));

  // ルートとピン/エリアをインターリーブ
  int routeIdx = 0;
  int nonRouteIdx = 0;
  final otherNonRoute = nonRouteItems.where((i) => i.type != FeedItemType.walkSummary).toList();

  while (routeIdx < routeItems.length || nonRouteIdx < otherNonRoute.length) {
    for (int i = 0; i < 2 && routeIdx < routeItems.length; i++) {
      balanced.add(routeItems[routeIdx++]);
    }
    if (nonRouteIdx < otherNonRoute.length) {
      balanced.add(otherNonRoute[nonRouteIdx++]);
    }
  }

  return balanced;
});
