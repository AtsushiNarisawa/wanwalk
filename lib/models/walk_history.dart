/// お出かけ散歩履歴モデル
class OutingWalkHistory {
  final String walkId;
  final String routeId;
  final String routeName;
  final String areaName;
  final DateTime walkedAt;
  final double distanceMeters;
  final int durationSeconds;
  final int photoCount;
  final int pinCount;
  final List<String> photoUrls;

  OutingWalkHistory({
    required this.walkId,
    required this.routeId,
    required this.routeName,
    required this.areaName,
    required this.walkedAt,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.photoCount,
    required this.pinCount,
    required this.photoUrls,
  });

  factory OutingWalkHistory.fromJson(Map<String, dynamic> json) {
    return OutingWalkHistory(
      walkId: json['walk_id'] as String,
      routeId: (json['route_id'] as String?) ?? '',
      routeName: (json['route_title'] as String?) ?? json['route_name'] as String? ?? '不明なルート',
      areaName: (json['route_area'] as String?) ?? json['area_name'] as String? ?? '不明なエリア',
      walkedAt: DateTime.parse(json['walked_at'] as String),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['duration_seconds'] as int?) ?? 0,
      photoCount: (json['photo_count'] as int?) ?? 0,
      pinCount: (json['pin_count'] as int?) ?? 0,
      photoUrls: (json['photo_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// 距離のフォーマット済み文字列
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(2)}km';
    }
  }

  /// 時間のフォーマット済み文字列
  String get formattedDuration {
    if (durationSeconds < 60) {
      return '$durationSeconds秒';
    } else if (durationSeconds < 3600) {
      return '${(durationSeconds / 60).toStringAsFixed(0)}分';
    } else {
      final hours = durationSeconds ~/ 3600;
      final minutes = (durationSeconds % 3600) ~/ 60;
      return '$hours時間$minutes分';
    }
  }

  /// サムネイル画像URL（最初の写真）
  String? get thumbnailUrl {
    return photoUrls.isNotEmpty ? photoUrls.first : null;
  }
}

/// 日常散歩履歴モデル
class DailyWalkHistory {
  final String walkId;
  final DateTime walkedAt;
  final double distanceMeters;
  final int durationSeconds;

  DailyWalkHistory({
    required this.walkId,
    required this.walkedAt,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory DailyWalkHistory.fromJson(Map<String, dynamic> json) {
    return DailyWalkHistory(
      walkId: json['walk_id'] as String,
      walkedAt: DateTime.parse(json['walked_at'] as String),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
    );
  }

  /// 距離のフォーマット済み文字列
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(2)}km';
    }
  }

  /// 時間のフォーマット済み文字列
  String get formattedDuration {
    if (durationSeconds < 60) {
      return '$durationSeconds秒';
    } else if (durationSeconds < 3600) {
      return '${(durationSeconds / 60).toStringAsFixed(0)}分';
    } else {
      final hours = durationSeconds ~/ 3600;
      final minutes = (durationSeconds % 3600) ~/ 60;
      return '$hours時間$minutes分';
    }
  }
}

/// 統合散歩履歴アイテム（タブ「すべて」用）
class WalkHistoryItem {
  final String walkId;
  final DateTime walkedAt;
  final double distanceMeters;
  final int durationSeconds;
  final WalkHistoryType type;

  // お出かけ散歩のみ
  final String? routeId;
  final String? routeName;
  final String? areaName;
  final int? photoCount;
  final int? pinCount;
  final List<String>? photoUrls;

  WalkHistoryItem({
    required this.walkId,
    required this.walkedAt,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.type,
    this.routeId,
    this.routeName,
    this.areaName,
    this.photoCount,
    this.pinCount,
    this.photoUrls,
  });

  factory WalkHistoryItem.fromOuting(OutingWalkHistory outing) {
    return WalkHistoryItem(
      walkId: outing.walkId,
      walkedAt: outing.walkedAt,
      distanceMeters: outing.distanceMeters,
      durationSeconds: outing.durationSeconds,
      type: WalkHistoryType.outing,
      routeId: outing.routeId,
      routeName: outing.routeName,
      areaName: outing.areaName,
      photoCount: outing.photoCount,
      pinCount: outing.pinCount,
      photoUrls: outing.photoUrls,
    );
  }

  factory WalkHistoryItem.fromDaily(DailyWalkHistory daily) {
    return WalkHistoryItem(
      walkId: daily.walkId,
      walkedAt: daily.walkedAt,
      distanceMeters: daily.distanceMeters,
      durationSeconds: daily.durationSeconds,
      type: WalkHistoryType.daily,
    );
  }

  /// 距離のフォーマット済み文字列
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(2)}km';
    }
  }

  /// 時間のフォーマット済み文字列
  String get formattedDuration {
    if (durationSeconds < 60) {
      return '$durationSeconds秒';
    } else if (durationSeconds < 3600) {
      return '${(durationSeconds / 60).toStringAsFixed(0)}分';
    } else {
      final hours = durationSeconds ~/ 3600;
      final minutes = (durationSeconds % 3600) ~/ 60;
      return '$hours時間$minutes分';
    }
  }

  /// サムネイル画像URL（お出かけ散歩のみ）
  String? get thumbnailUrl {
    if (type == WalkHistoryType.outing && photoUrls != null && photoUrls!.isNotEmpty) {
      return photoUrls!.first;
    }
    return null;
  }
}

/// 散歩履歴タイプ
enum WalkHistoryType {
  outing, // お出かけ散歩
  daily,  // 日常散歩
}
