import 'package:wanmap_v2/models/route_model.dart';

/// トリップ（旅行計画）モデル
class TripModel {
  final String? id;
  final String userId;
  final String title;
  final String? description;
  final String? destination;
  final DateTime startDate;
  final DateTime endDate;
  final String? thumbnailUrl;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 関連データ（JOIN時に取得）
  final List<RouteModel>? routes;
  final int? routeCount;
  final double? totalDistance;
  final int? totalDuration;

  TripModel({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    this.destination,
    required this.startDate,
    required this.endDate,
    this.thumbnailUrl,
    this.isPublic = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.routes,
    this.routeCount,
    this.totalDistance,
    this.totalDuration,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// JSONからモデルを作成
  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      destination: json['destination'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      thumbnailUrl: json['thumbnail_url'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      routeCount: json['route_count'] as int?,
      totalDistance: (json['total_distance'] as num?)?.toDouble(),
      totalDuration: json['total_duration'] as int?,
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'destination': destination,
      'start_date': startDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'end_date': endDate.toIso8601String().split('T')[0],
      'thumbnail_url': thumbnailUrl,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 日数を計算
  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// フォーマットされた期間（例：2025年12月1日〜3日）
  String get formattedDateRange {
    final start = '${startDate.year}年${startDate.month}月${startDate.day}日';
    final end = '${endDate.month}月${endDate.day}日';
    return '$start〜$end';
  }

  /// フォーマットされた統計サマリー
  String get statsSummary {
    final days = durationDays;
    final routes = routeCount ?? 0;
    return '$days日間・$routesルート';
  }

  /// コピーを作成（一部フィールドを更新）
  TripModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? thumbnailUrl,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RouteModel>? routes,
    int? routeCount,
    double? totalDistance,
    int? totalDuration,
  }) {
    return TripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      routes: routes ?? this.routes,
      routeCount: routeCount ?? this.routeCount,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}

/// トリップとルートの関連モデル
class TripRouteModel {
  final String? id;
  final String tripId;
  final String routeId;
  final int? dayNumber;
  final int sequenceOrder;
  final String? notes;
  final DateTime createdAt;
  
  // 関連データ（JOIN時に取得）
  final RouteModel? route;

  TripRouteModel({
    this.id,
    required this.tripId,
    required this.routeId,
    this.dayNumber,
    this.sequenceOrder = 0,
    this.notes,
    DateTime? createdAt,
    this.route,
  }) : createdAt = createdAt ?? DateTime.now();

  /// JSONからモデルを作成
  factory TripRouteModel.fromJson(Map<String, dynamic> json) {
    return TripRouteModel(
      id: json['id'] as String?,
      tripId: json['trip_id'] as String,
      routeId: json['route_id'] as String,
      dayNumber: json['day_number'] as int?,
      sequenceOrder: json['sequence_order'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      route: json['route'] != null 
          ? RouteModel.fromJson(json['route'] as Map<String, dynamic>)
          : null,
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'route_id': routeId,
      'day_number': dayNumber,
      'sequence_order': sequenceOrder,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
