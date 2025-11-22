import 'package:latlong2/latlong.dart';

/// ピンの種類
enum PinType {
  scenery('scenery', '景色', '美しい景色や風景'),
  shop('shop', '店舗', 'カフェやペットショップなど'),
  encounter('encounter', '出会い', '他のワンちゃんとの出会い'),
  other('other', 'その他', 'その他の体験や発見');

  const PinType(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static PinType fromString(String value) {
    switch (value) {
      case 'scenery':
        return PinType.scenery;
      case 'shop':
        return PinType.shop;
      case 'encounter':
        return PinType.encounter;
      case 'other':
        return PinType.other;
      default:
        return PinType.other;
    }
  }
}

/// ルートピンモデル（ユーザーが公式ルート上に投稿する体験・発見）
class RoutePin {
  final String id;
  final String routeId; // 所属する公式ルートID
  final String userId; // 投稿者
  final LatLng location; // ピンの位置
  final PinType pinType;
  final String title; // タイトル（例：「絶景の富士山ビュー」）
  final String comment; // コメント
  final List<String> photoUrls; // 写真URL（最大5枚）
  final int likesCount; // いいね数
  final DateTime createdAt;

  RoutePin({
    required this.id,
    required this.routeId,
    required this.userId,
    required this.location,
    required this.pinType,
    required this.title,
    required this.comment,
    this.photoUrls = const [],
    this.likesCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Supabaseから取得したJSONをRoutePinオブジェクトに変換
  factory RoutePin.fromJson(Map<String, dynamic> json) {
    // location: PostGISのPOINT型をパース
    final locationData = json['location'];
    LatLng location;

    if (locationData is Map) {
      final coords = locationData['coordinates'] as List;
      location = LatLng(
        (coords[1] as num).toDouble(), // 緯度
        (coords[0] as num).toDouble(), // 経度
      );
    } else if (locationData is String) {
      // WKT形式: "POINT(139.1071 35.2328)"
      final coordsMatch = RegExp(r'POINT\(([0-9.\-]+)\s+([0-9.\-]+)\)').firstMatch(locationData);
      if (coordsMatch != null) {
        final lon = double.parse(coordsMatch.group(1)!);
        final lat = double.parse(coordsMatch.group(2)!);
        location = LatLng(lat, lon);
      } else {
        throw ArgumentError('Invalid PostGIS Point format: $locationData');
      }
    } else {
      throw ArgumentError('Invalid location data type: ${locationData.runtimeType}');
    }

    // photo_urlsは別テーブル（route_pin_photos）から取得される場合がある
    // ここではJOINされた結果を想定
    List<String> photoUrls = [];
    if (json['photo_urls'] != null) {
      if (json['photo_urls'] is List) {
        photoUrls = (json['photo_urls'] as List).map((e) => e.toString()).toList();
      }
    }

    return RoutePin(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      userId: json['user_id'] as String,
      location: location,
      pinType: PinType.fromString(json['pin_type'] as String? ?? 'other'),
      title: json['title'] as String,
      comment: json['comment'] as String? ?? '',
      photoUrls: photoUrls,
      likesCount: json['likes_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// RoutePinオブジェクトをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_id': routeId,
      'user_id': userId,
      'location': {
        'type': 'Point',
        'coordinates': [location.longitude, location.latitude],
      },
      'pin_type': pinType.value,
      'title': title,
      'comment': comment,
      'photo_urls': photoUrls,
      'likes_count': likesCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 写真の枚数
  int get photoCount => photoUrls.length;

  /// 写真があるかどうか
  bool get hasPhotos => photoUrls.isNotEmpty;

  /// 相対時間表示（例：「3日前」「2時間前」）
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 0) {
      return '${diff.inDays}日前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}時間前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }

  RoutePin copyWith({
    String? id,
    String? routeId,
    String? userId,
    LatLng? location,
    PinType? pinType,
    String? title,
    String? comment,
    List<String>? photoUrls,
    int? likesCount,
    DateTime? createdAt,
  }) {
    return RoutePin(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      pinType: pinType ?? this.pinType,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      photoUrls: photoUrls ?? this.photoUrls,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'RoutePin(id: $id, title: $title, routeId: $routeId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutePin && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
