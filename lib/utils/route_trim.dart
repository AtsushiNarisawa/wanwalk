import 'package:latlong2/latlong.dart';

import '../config/submission_constants.dart';

/// 発着点トリミング（プライバシー加工）の純ロジック。
///
/// 方針（SUBMISSION_PROGRAM_SPEC / W1スキーマ確定）:
/// - 自動候補: 生の端点から半径 [SubmissionConstants.trimAutoRadiusMeters]（既定120m）を除去。
/// - 投稿者スライダー: 生端点から半径 [SubmissionConstants.trimMinRadiusMeters]（60m）より
///   内側へは戻せない（＝端点に60mより近づけない）。
/// - 生の軌跡（walks.path_geojson）は変更しない。ここで作るのは投稿用のトリム済み線のみ。
///
/// スライダーは「保持する端点の半径」（60〜200m・既定120m）で表現し、半径→インデックスへ
/// 変換して materialize する。これにより60m下限が自然に強制され、ループ経路にも堅牢。

/// path_geojson (LineString・座標は [lng, lat]) を [LatLng] のリストへ復元する。
/// walk_detail_service.dart の読み取り規約と同一。
List<LatLng> decodeLineString(Map<String, dynamic>? geojson) {
  if (geojson == null) return const [];
  if (geojson['type'] != 'LineString') return const [];
  final coords = geojson['coordinates'];
  if (coords is! List) return const [];
  final points = <LatLng>[];
  for (final c in coords) {
    if (c is List && c.length >= 2) {
      final lng = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      points.add(LatLng(lat, lng));
    }
  }
  return points;
}

/// [LatLng] のリストを GeoJSON LineString (座標 [lng, lat]) へ直列化する。
/// walk_save_service.dart の保存規約と同一。
Map<String, dynamic> encodeLineString(List<LatLng> points) {
  return {
    'type': 'LineString',
    'coordinates': [
      for (final p in points) [p.longitude, p.latitude],
    ],
  };
}

const Distance _distance = Distance();

/// 連続する点間の測地距離（メートル）の総和。
double pathDistanceMeters(List<LatLng> points) {
  if (points.length < 2) return 0;
  var total = 0.0;
  for (var i = 0; i < points.length - 1; i++) {
    total += _distance.as(LengthUnit.Meter, points[i], points[i + 1]);
  }
  return total;
}

/// トリミング1回分の確定結果。
class TrimOutput {
  const TrimOutput({
    required this.startIdx,
    required this.endIdx,
    required this.keptPoints,
    required this.distanceMeters,
    required this.valid,
  });

  final int startIdx;
  final int endIdx;
  final List<LatLng> keptPoints;
  final double distanceMeters;

  /// 保持区間が2点以上・startIdx < endIdx を満たすか。
  final bool valid;

  Map<String, dynamic> get geojson => encodeLineString(keptPoints);
}

/// 生の軌跡に対する発着点トリマー。半径（メートル）を受け取り、保持インデックスを算出する。
class EndpointTrimmer {
  EndpointTrimmer(List<LatLng> points) : points = List.unmodifiable(points) {
    final n = this.points.length;
    _dStart = List<double>.filled(n, 0);
    _dEnd = List<double>.filled(n, 0);
    if (n > 0) {
      final rawStart = this.points.first;
      final rawEnd = this.points.last;
      for (var i = 0; i < n; i++) {
        _dStart[i] = _distance.as(LengthUnit.Meter, rawStart, this.points[i]);
        _dEnd[i] = _distance.as(LengthUnit.Meter, rawEnd, this.points[i]);
      }
    }
  }

  final List<LatLng> points;
  late final List<double> _dStart;
  late final List<double> _dEnd;

  double get minRadius => SubmissionConstants.trimMinRadiusMeters; // 60m
  double get defaultRadius => SubmissionConstants.trimAutoRadiusMeters; // 120m
  static const double maxRadius = 200.0;

  /// 生の始点から半径 [r] 以内の先頭区間を除去した「保持開始インデックス」。
  /// 半径外の最初の点。全点が半径内なら points.length（＝無効）を返す。
  int startIndexForRadius(double r) {
    for (var i = 0; i < points.length; i++) {
      if (_dStart[i] >= r) return i;
    }
    return points.length;
  }

  /// 生の終点から半径 [r] 以内の末尾区間を除去した「保持終了インデックス」（inclusive）。
  /// 末尾から見て半径外の最初の点。全点が半径内なら -1（＝無効）を返す。
  int endIndexForRadius(double r) {
    for (var j = points.length - 1; j >= 0; j--) {
      if (_dEnd[j] >= r) return j;
    }
    return -1;
  }

  /// 60m下限で最小トリムしても有効な区間が残るか（＝推薦可能な長さか）。
  bool get isTrimmable {
    if (points.length < 2) return false;
    final s = startIndexForRadius(minRadius);
    final e = endIndexForRadius(minRadius);
    return s < e && (e - s + 1) >= 2;
  }

  /// 指定半径でトリム結果を確定する。半径は [minRadius]〜[maxRadius] にクランプ。
  TrimOutput materialize({required double startRadius, required double endRadius}) {
    final sr = startRadius.clamp(minRadius, maxRadius);
    final er = endRadius.clamp(minRadius, maxRadius);
    var start = startIndexForRadius(sr);
    var end = endIndexForRadius(er);

    // 範囲・整合のクランプ
    if (start >= points.length) start = points.length - 1;
    if (end < 0) end = 0;
    final valid = points.length >= 2 && start < end && (end - start + 1) >= 2;

    final kept = valid ? points.sublist(start, end + 1) : const <LatLng>[];
    return TrimOutput(
      startIdx: start,
      endIdx: end,
      keptPoints: kept,
      distanceMeters: pathDistanceMeters(kept),
      valid: valid,
    );
  }
}
