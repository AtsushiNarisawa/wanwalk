import 'package:latlong2/latlong.dart';

/// 散歩ルートのモデル
class RouteModel {
  final String? id;
  final String userId;
  final String? dogId;
  final String title;
  final String? description;
  final List<RoutePoint> points;
  final double distance; // メートル
  final int duration; // 秒
  final DateTime startedAt; // 開始時刻
  final DateTime? endedAt; // 終了時刻
  final bool isPublic;
  final DateTime createdAt;

  RouteModel({
    this.id,
    required this.userId,
    this.dogId,
    required this.title,
    this.description,
    required this.points,
    this.distance = 0.0,
    this.duration = 0,
    DateTime? startedAt,
    this.endedAt,
    this.isPublic = false,
    DateTime? createdAt,
  }) : startedAt = startedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  /// JSONからモデルを作成
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      dogId: json['dog_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      points: [],
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as int? ?? 0,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'dog_id': dogId,
      'title': title,
      'description': description,
      'distance': distance,
      'duration': duration,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 距離を計算（メートル）
  double calculateDistance() {
    if (points.length < 2) return 0.0;

    final Distance calculator = const Distance();
    double totalDistance = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += calculator.as(
        LengthUnit.Meter,
        points[i].latLng,
        points[i + 1].latLng,
      );
    }

    return totalDistance;
  }

  /// 時間をフォーマット（例：1時間30分）
  String formatDuration() {
    if (duration == 0) return '0分';

    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours時間${minutes}分';
    } else {
      return '$minutes分';
    }
  }

  /// 距離をフォーマット（例：1.5km）
  String formatDistance() {
    if (distance == 0) return '0m';

    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    } else {
      return '${distance.toStringAsFixed(0)}m';
    }
  }

  /// 日付をフォーマット（例：2024年1月15日）
  String formatDate() {
    return '${startedAt.year}年${startedAt.month}月${startedAt.day}日';
  }

  /// コピーを作成
  RouteModel copyWith({
    String? id,
    String? userId,
    String? dogId,
    String? title,
    String? description,
    List<RoutePoint>? points,
    double? distance,
    int? duration,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isPublic,
    DateTime? createdAt,
  }) {
    return RouteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dogId: dogId ?? this.dogId,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// ルート上の1ポイント（GPS座標）
class RoutePoint {
  final LatLng latLng;
  final double? altitude;
  final DateTime timestamp;
  final int sequenceNumber;

  RoutePoint({
    required this.latLng,
    this.altitude,
    required this.timestamp,
    required this.sequenceNumber,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latLng: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      altitude: json['altitude']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      sequenceNumber: json['sequence_number'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
      'altitude': altitude,
      'timestamp': timestamp.toIso8601String(),
      'sequence_number': sequenceNumber,
    };
  }
}
