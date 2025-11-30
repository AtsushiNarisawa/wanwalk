// ==================================================
// Statistics Models for WanMap v2
// ==================================================
// Author: AI Assistant
// Created: 2024-11-17
// Purpose: Data models for statistics and reporting features
// ==================================================

/// 期間別統計データモデル
class PeriodStatistics {
  final int totalRoutes;
  final double totalDistance; // メートル
  final int totalDuration; // 秒
  final double avgDistance; // メートル
  final double avgDuration; // 秒

  PeriodStatistics({
    required this.totalRoutes,
    required this.totalDistance,
    required this.totalDuration,
    required this.avgDistance,
    required this.avgDuration,
  });

  factory PeriodStatistics.fromJson(Map<String, dynamic> json) {
    return PeriodStatistics(
      totalRoutes: json['total_routes'] ?? 0,
      totalDistance: (json['total_distance'] ?? 0).toDouble(),
      totalDuration: json['total_duration'] ?? 0,
      avgDistance: (json['avg_distance'] ?? 0).toDouble(),
      avgDuration: (json['avg_duration'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_routes': totalRoutes,
      'total_distance': totalDistance,
      'total_duration': totalDuration,
      'avg_distance': avgDistance,
      'avg_duration': avgDuration,
    };
  }

  /// 総距離をキロメートルで取得
  double get totalDistanceKm => totalDistance / 1000;

  /// 平均距離をキロメートルで取得
  double get avgDistanceKm => avgDistance / 1000;

  /// 総時間を時間単位で取得
  double get totalDurationHours => totalDuration / 3600;

  /// 平均時間を分単位で取得
  double get avgDurationMinutes => avgDuration / 60;

  /// フォーマットされた総距離（例: "12.5 km"）
  String get formattedTotalDistance => '${totalDistanceKm.toStringAsFixed(1)} km';

  /// フォーマットされた平均距離（例: "2.3 km"）
  String get formattedAvgDistance => '${avgDistanceKm.toStringAsFixed(1)} km';

  /// フォーマットされた総時間（例: "2時間30分"）
  String get formattedTotalDuration {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours時間$minutes分';
    }
    return '$minutes分';
  }

  /// フォーマットされた平均時間（例: "25分"）
  String get formattedAvgDuration {
    final minutes = (avgDuration / 60).round();
    return '$minutes分';
  }
}

/// 月別統計データモデル
class MonthlyStatistics {
  final int year;
  final int month;
  final int routeCount;
  final double totalDistance;
  final int totalDuration;

  MonthlyStatistics({
    required this.year,
    required this.month,
    required this.routeCount,
    required this.totalDistance,
    required this.totalDuration,
  });

  factory MonthlyStatistics.fromJson(Map<String, dynamic> json) {
    return MonthlyStatistics(
      year: json['year'],
      month: json['month'],
      routeCount: json['route_count'] ?? 0,
      totalDistance: (json['total_distance'] ?? 0).toDouble(),
      totalDuration: json['total_duration'] ?? 0,
    );
  }

  /// 月のラベル（例: "2024年11月"）
  String get monthLabel => '$year年$month月';

  /// 短い月のラベル（例: "11月"）
  String get shortMonthLabel => '$month月';

  /// 総距離をキロメートルで取得
  double get totalDistanceKm => totalDistance / 1000;
}

/// 週別統計データモデル
class WeeklyStatistics {
  final int year;
  final int week;
  final DateTime weekStartDate;
  final int routeCount;
  final double totalDistance;
  final int totalDuration;

  WeeklyStatistics({
    required this.year,
    required this.week,
    required this.weekStartDate,
    required this.routeCount,
    required this.totalDistance,
    required this.totalDuration,
  });

  factory WeeklyStatistics.fromJson(Map<String, dynamic> json) {
    return WeeklyStatistics(
      year: json['year'],
      week: json['week'],
      weekStartDate: DateTime.parse(json['week_start_date']),
      routeCount: json['route_count'] ?? 0,
      totalDistance: (json['total_distance'] ?? 0).toDouble(),
      totalDuration: json['total_duration'] ?? 0,
    );
  }

  /// 週のラベル（例: "11/10〜"）
  String get weekLabel =>
      '${weekStartDate.month}/${weekStartDate.day}〜';

  /// 総距離をキロメートルで取得
  double get totalDistanceKm => totalDistance / 1000;
}

/// エリア別統計データモデル
class AreaStatistics {
  final String area;
  final String prefecture;
  final int routeCount;
  final double totalDistance;
  final int totalDuration;

  AreaStatistics({
    required this.area,
    required this.prefecture,
    required this.routeCount,
    required this.totalDistance,
    required this.totalDuration,
  });

  factory AreaStatistics.fromJson(Map<String, dynamic> json) {
    return AreaStatistics(
      area: json['area'] ?? '',
      prefecture: json['prefecture'] ?? '',
      routeCount: json['route_count'] ?? 0,
      totalDistance: (json['total_distance'] ?? 0).toDouble(),
      totalDuration: json['total_duration'] ?? 0,
    );
  }

  /// エリア表示名（例: "箱根（神奈川県）"）
  String get displayName => '$area（$prefecture）';

  /// 総距離をキロメートルで取得
  double get totalDistanceKm => totalDistance / 1000;

  /// フォーマットされた総距離
  String get formattedDistance => '${totalDistanceKm.toStringAsFixed(1)} km';
}

/// 愛犬別統計データモデル
class DogStatistics {
  final String dogId;
  final String dogName;
  final int routeCount;
  final double totalDistance;
  final int totalDuration;
  final double avgDistance;
  final double avgDuration;

  DogStatistics({
    required this.dogId,
    required this.dogName,
    required this.routeCount,
    required this.totalDistance,
    required this.totalDuration,
    required this.avgDistance,
    required this.avgDuration,
  });

  factory DogStatistics.fromJson(Map<String, dynamic> json) {
    return DogStatistics(
      dogId: json['dog_id'] ?? '',
      dogName: json['dog_name'] ?? '',
      routeCount: json['route_count'] ?? 0,
      totalDistance: (json['total_distance'] ?? 0).toDouble(),
      totalDuration: json['total_duration'] ?? 0,
      avgDistance: (json['avg_distance'] ?? 0).toDouble(),
      avgDuration: (json['avg_duration'] ?? 0).toDouble(),
    );
  }

  /// 総距離をキロメートルで取得
  double get totalDistanceKm => totalDistance / 1000;

  /// 平均距離をキロメートルで取得
  double get avgDistanceKm => avgDistance / 1000;

  /// フォーマットされた総距離
  String get formattedTotalDistance => '${totalDistanceKm.toStringAsFixed(1)} km';

  /// フォーマットされた平均距離
  String get formattedAvgDistance => '${avgDistanceKm.toStringAsFixed(1)} km';
}

/// 時間帯別統計データモデル
class HourlyStatistics {
  final int hour;
  final int routeCount;
  final double totalDistance;
  final int totalDuration;

  HourlyStatistics({
    required this.hour,
    required this.routeCount,
    required this.totalDistance,
    required this.totalDuration,
  });

  factory HourlyStatistics.fromJson(Map<String, dynamic> json) {
    return HourlyStatistics(
      hour: json['hour'],
      routeCount: json['route_count'] ?? 0,
      totalDistance: (json['total_distance'] ?? 0).toDouble(),
      totalDuration: json['total_duration'] ?? 0,
    );
  }

  /// 時間帯ラベル（例: "6:00-7:00"）
  String get hourLabel => '$hour:00-${hour + 1}:00';

  /// 総距離をキロメートルで取得
  double get totalDistanceKm => totalDistance / 1000;
}

/// 累計統計データモデル
class LifetimeStatistics {
  final int totalRoutes;
  final double totalDistance;
  final int totalDuration;
  final DateTime? firstRouteDate;
  final DateTime? lastRouteDate;
  final int uniqueAreas;
  final int uniquePrefectures;

  LifetimeStatistics({
    required this.totalRoutes,
    required this.totalDistance,
    required this.totalDuration,
    this.firstRouteDate,
    this.lastRouteDate,
    required this.uniqueAreas,
    required this.uniquePrefectures,
  });

  factory LifetimeStatistics.fromJson(Map<String, dynamic> json) {
    return LifetimeStatistics(
      totalRoutes: json['total_routes'] ?? 0,
      totalDistance: (json['total_distance'] ?? 0).toDouble(),
      totalDuration: json['total_duration'] ?? 0,
      firstRouteDate: json['first_route_date'] != null
          ? DateTime.parse(json['first_route_date'])
          : null,
      lastRouteDate: json['last_route_date'] != null
          ? DateTime.parse(json['last_route_date'])
          : null,
      uniqueAreas: json['unique_areas'] ?? 0,
      uniquePrefectures: json['unique_prefectures'] ?? 0,
    );
  }

  /// 総距離をキロメートルで取得
  double get totalDistanceKm => totalDistance / 1000;

  /// フォーマットされた総距離
  String get formattedTotalDistance => '${totalDistanceKm.toStringAsFixed(1)} km';

  /// 総時間を時間単位で取得
  double get totalDurationHours => totalDuration / 3600;

  /// フォーマットされた総時間
  String get formattedTotalDuration {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours時間$minutes分';
    }
    return '$minutes分';
  }

  /// 活動期間（日数）
  int get activityDays {
    if (firstRouteDate == null || lastRouteDate == null) return 0;
    return lastRouteDate!.difference(firstRouteDate!).inDays + 1;
  }

  /// 活動期間の表示文字列（例: "365日間"）
  String get activityPeriod => '$activityDays日間';
}
