import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/official_route.dart';
import '../models/recent_pin_post.dart';

/// フィードアイテムの種別
enum FeedItemType {
  walkSummary,    // 自分の散歩サマリー
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
  final Map<String, dynamic>? extra; // walkSummary, areaFeature用

  const FeedItem({
    required this.type,
    required this.sortDate,
    this.route,
    this.pin,
    this.extra,
  });
}

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
          sortDate: now.add(const Duration(days: 1)), // 常に先頭
          extra: {
            'walkCount': walks.length,
            'totalDistanceKm': (totalDistance / 1000).toStringAsFixed(1),
            'totalMinutes': totalMinutes,
          },
        ));
      }
    } catch (_) {
      // サマリー取得失敗は無視
    }
  }

  // 2. 公式ルート（新着 + 季節おすすめ）
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

    final currentMonth = now.month;
    final currentSeason = _getSeason(currentMonth);

    for (final route in routes) {
      final createdAt = route.createdAt ?? now.subtract(const Duration(days: 30));
      final daysSinceCreated = now.difference(createdAt).inDays;

      // 新着ルート（7日以内）→ブースト
      if (daysSinceCreated <= 7) {
        items.add(FeedItem(
          type: FeedItemType.officialRoute,
          sortDate: createdAt.add(const Duration(hours: 12)), // 少しブースト
          route: route,
          extra: {'isNew': true},
        ));
        continue;
      }

      // 季節おすすめルート
      final bestSeason = route.petInfo?.bestSeason ?? '';
      if (_matchesSeason(bestSeason, currentSeason)) {
        items.add(FeedItem(
          type: FeedItemType.seasonalRoute,
          sortDate: now.subtract(Duration(hours: routes.indexOf(route) * 3)),
          route: route,
          extra: {'season': currentSeason},
        ));
        continue;
      }

      // 通常のルート
      items.add(FeedItem(
        type: FeedItemType.officialRoute,
        sortDate: createdAt,
        route: route,
      ));
    }
  } catch (_) {
    // ルート取得失敗は無視
  }

  // 3. コミュニティピン（RPC経由で最新10件）
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
      } catch (_) {
        // 個別ピンのパースエラーは無視
      }
    }
  } catch (_) {
    // ピン取得失敗は無視
  }

  // 4. エリア特集（箱根を常に含む）
  try {
    final areasResponse = await supabase
        .from('areas')
        .select('id, name, image_url');

    final areas = areasResponse as List;
    // 箱根グループを1つにまとめる
    final hakoneAreas = areas.where((a) => (a['name'] as String).startsWith('箱根')).toList();
    if (hakoneAreas.isNotEmpty) {
      items.add(FeedItem(
        type: FeedItemType.areaFeature,
        sortDate: now.subtract(const Duration(hours: 6)),
        extra: {
          'areaName': '箱根',
          'routeCount': hakoneAreas.length,
          'subAreas': hakoneAreas.map((a) => a['name']).toList(),
        },
      ));
    }
  } catch (_) {
    // エリア取得失敗は無視
  }

  // ソート（sortDate降順）
  items.sort((a, b) => b.sortDate.compareTo(a.sortDate));

  // フィードのバランス調整：ルートが多すぎないよう制限し、
  // ピンやエリアカードが確実に表示されるようインターリーブ
  final balanced = <FeedItem>[];
  final routeItems = items.where((i) => i.type == FeedItemType.officialRoute || i.type == FeedItemType.seasonalRoute).toList();
  final nonRouteItems = items.where((i) => i.type != FeedItemType.officialRoute && i.type != FeedItemType.seasonalRoute).toList();

  // ルートは最大10件に制限
  final limitedRoutes = routeItems.take(10).toList();

  // walkSummaryは先頭
  balanced.addAll(nonRouteItems.where((i) => i.type == FeedItemType.walkSummary));

  // ルート2〜3件ごとにピン/エリアを挟む
  int routeIdx = 0;
  int nonRouteIdx = 0;
  final otherNonRoute = nonRouteItems.where((i) => i.type != FeedItemType.walkSummary).toList();

  while (routeIdx < limitedRoutes.length || nonRouteIdx < otherNonRoute.length) {
    // ルート2件追加
    for (int i = 0; i < 2 && routeIdx < limitedRoutes.length; i++) {
      balanced.add(limitedRoutes[routeIdx++]);
    }
    // 非ルート1件挟む
    if (nonRouteIdx < otherNonRoute.length) {
      balanced.add(otherNonRoute[nonRouteIdx++]);
    }
  }

  return balanced;
});

String _getSeason(int month) {
  if (month >= 3 && month <= 5) return '春';
  if (month >= 6 && month <= 8) return '夏';
  if (month >= 9 && month <= 11) return '秋';
  return '冬';
}

bool _matchesSeason(String bestSeason, String currentSeason) {
  if (bestSeason.contains('通年')) return false; // 通年はブーストしない
  return bestSeason.contains(currentSeason);
}
