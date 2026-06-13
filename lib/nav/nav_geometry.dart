import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// LAYER1_NAV_SPEC §2 沿線距離エンジンの幾何プリミティブ（純Dart）。
///
/// ここには「投影・沿線距離(chainage)・カバレッジ」という、ナビ判定（進捗・接近・
/// 完走・逸脱・駐車場戻り）の全てが依存する基礎関数だけを置く。状態機械や閾値は持たない。
/// Build 42 の route_nav_engine.dart と §14 GPSリプレイ・ハーネスの両方がこれを共有する。
///
/// 重要（§2）:
/// - 距離は「線分への垂線距離」で測る（最近傍頂点ではない）。疎ラインでも誤差が出ない。
/// - chainage は distance_from_start と同じ座標系（ルート起点からの沿線距離）。
/// - 窓付き投影 [projectToLineWindowed] は復路への即時誤吸着を防ぐ（往復近接ルート対策）。

const double kEarthRadiusM = 6378137.0;
const double kMetersPerDegLat = 111320.0;

/// 2点間の大圏距離(m)。
double haversineMeters(LatLng a, LatLng b) {
  final lat1 = a.latitudeInRad;
  final lat2 = b.latitudeInRad;
  final dLat = lat2 - lat1;
  final dLng = (b.longitude - a.longitude) * math.pi / 180.0;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * kEarthRadiusM * math.asin(math.min(1.0, math.sqrt(h)));
}

/// 緯度経度を ref_lat 基準の局所平面直交座標(m)へ（短距離の等距円筒近似）。
/// 線分投影は同一 ref_lat で揃えた平面上で行う。
List<double> _localXY(LatLng p, double refLatRad) {
  final x = (p.longitude * math.pi / 180.0) * kEarthRadiusM * math.cos(refLatRad);
  final y = p.latitudeInRad * kEarthRadiusM;
  return [x, y];
}

/// 点 p を線分 a-b に投影。t は [0,1] にクランプした線分上の位置、perpM は最短距離(m)。
({double t, double perpM}) projectPointOnSegment(LatLng p, LatLng a, LatLng b) {
  final refLatRad = a.latitudeInRad;
  final pp = _localXY(p, refLatRad);
  final aa = _localXY(a, refLatRad);
  final bb = _localXY(b, refLatRad);
  final dx = bb[0] - aa[0];
  final dy = bb[1] - aa[1];
  final seg2 = dx * dx + dy * dy;
  double t;
  if (seg2 == 0) {
    t = 0.0;
  } else {
    t = ((pp[0] - aa[0]) * dx + (pp[1] - aa[1]) * dy) / seg2;
    t = t.clamp(0.0, 1.0);
  }
  final fx = aa[0] + t * dx;
  final fy = aa[1] + t * dy;
  final perp = math.sqrt((pp[0] - fx) * (pp[0] - fx) + (pp[1] - fy) * (pp[1] - fy));
  return (t: t, perpM: perp);
}

/// 各頂点の起点からの累積沿線距離。length == result.last。
List<double> cumulativeChainage(List<LatLng> line) {
  final out = <double>[0.0];
  for (var i = 1; i < line.length; i++) {
    out.add(out[i - 1] + haversineMeters(line[i - 1], line[i]));
  }
  return out;
}

/// ラインの総延長(m)。
double lineLengthMeters(List<LatLng> line) {
  if (line.length < 2) return 0.0;
  double total = 0.0;
  for (var i = 1; i < line.length; i++) {
    total += haversineMeters(line[i - 1], line[i]);
  }
  return total;
}

/// 点をラインへ投影した結果。
class LineProjection {
  /// 起点からの沿線距離(m)。
  final double chainageMeters;

  /// 線分への垂線距離(m)。
  final double perpMeters;

  /// 投影されたセグメント [segmentIndex, segmentIndex+1]。
  final int segmentIndex;

  /// セグメント内の位置 [0,1]。
  final double t;

  const LineProjection({
    required this.chainageMeters,
    required this.perpMeters,
    required this.segmentIndex,
    required this.t,
  });
}

/// 点を全ラインへ投影（最小垂線距離のセグメントを採用）。
/// cumChain を渡すと再計算を省ける。
LineProjection projectToLine(LatLng p, List<LatLng> line, {List<double>? cumChain}) {
  assert(line.length >= 2, 'line must have >= 2 points');
  final chain = cumChain ?? cumulativeChainage(line);
  double bestPerp = double.infinity;
  double bestChain = 0.0;
  int bestSeg = 0;
  double bestT = 0.0;
  for (var i = 0; i < line.length - 1; i++) {
    final r = projectPointOnSegment(p, line[i], line[i + 1]);
    if (r.perpM < bestPerp) {
      bestPerp = r.perpM;
      final segLen = chain[i + 1] - chain[i];
      bestChain = chain[i] + r.t * segLen;
      bestSeg = i;
      bestT = r.t;
    }
  }
  return LineProjection(
    chainageMeters: bestChain,
    perpMeters: bestPerp,
    segmentIndex: bestSeg,
    t: bestT,
  );
}

/// 窓付き投影（§2 即時スナップ禁止の核）。
/// chainage が [windowStartM, windowEndM] に重なるセグメントだけを対象にする。
/// 窓内に候補が無ければ null（呼び出し側が窓を広げる/再捕捉する）。
LineProjection? projectToLineWindowed(
  LatLng p,
  List<LatLng> line,
  List<double> cumChain,
  double windowStartM,
  double windowEndM,
) {
  double bestPerp = double.infinity;
  double bestChain = 0.0;
  int bestSeg = -1;
  double bestT = 0.0;
  for (var i = 0; i < line.length - 1; i++) {
    final segStart = cumChain[i];
    final segEnd = cumChain[i + 1];
    // セグメントの chainage 区間が窓と交差しなければスキップ。
    if (segEnd < windowStartM || segStart > windowEndM) continue;
    final r = projectPointOnSegment(p, line[i], line[i + 1]);
    if (r.perpM < bestPerp) {
      bestPerp = r.perpM;
      bestChain = segStart + r.t * (segEnd - segStart);
      bestSeg = i;
      bestT = r.t;
    }
  }
  if (bestSeg < 0) return null;
  return LineProjection(
    chainageMeters: bestChain,
    perpMeters: bestPerp,
    segmentIndex: bestSeg,
    t: bestT,
  );
}

/// 沿線距離 targetM の地点の座標（chainage→座標の逆変換）。
LatLng pointAtChainage(List<LatLng> line, double targetM, {List<double>? cumChain}) {
  assert(line.isNotEmpty, 'line must not be empty');
  if (line.length < 2 || targetM <= 0) return line.first;
  final chain = cumChain ?? cumulativeChainage(line);
  final total = chain.last;
  if (targetM >= total) return line.last;
  for (var i = 0; i < line.length - 1; i++) {
    if (chain[i + 1] >= targetM) {
      final segLen = chain[i + 1] - chain[i];
      final t = segLen == 0 ? 0.0 : (targetM - chain[i]) / segLen;
      return LatLng(
        line[i].latitude + t * (line[i + 1].latitude - line[i].latitude),
        line[i].longitude + t * (line[i + 1].longitude - line[i].longitude),
      );
    }
  }
  return line.last;
}

/// ある点から dNorthM/dEastM(m) だけずらした座標（合成GPS生成・テスト用）。
LatLng offsetMeters(LatLng p, double dNorthM, double dEastM) {
  final dLat = dNorthM / kMetersPerDegLat;
  final cosLat = math.cos(p.latitudeInRad).abs();
  final dLng = dEastM / (kMetersPerDegLat * (cosLat < 1e-6 ? 1e-6 : cosLat));
  return LatLng(p.latitude + dLat, p.longitude + dLng);
}

/// 完走判定用カバレッジグリッド（§5）。ルートを cellMeters 区画に分割し通過率を測る。
/// 方向・ショートカット・逆回りに非依存（ビットマップ方式）。
class CoverageGrid {
  final double cellMeters;
  final double totalMeters;
  final List<bool> _cells;

  CoverageGrid(this.totalMeters, {this.cellMeters = 25})
      : _cells = List<bool>.filled(
          math.max(1, (totalMeters / cellMeters).ceil()),
          false,
        );

  int get cellCount => _cells.length;
  int get visitedCount => _cells.where((c) => c).length;

  /// 沿線距離 chainageM の区画を訪問済みにする。
  void mark(double chainageM) {
    if (chainageM < 0) chainageM = 0;
    var idx = (chainageM / cellMeters).floor();
    if (idx < 0) idx = 0;
    if (idx >= _cells.length) idx = _cells.length - 1;
    _cells[idx] = true;
  }

  /// [fromM, toM] の全区画を訪問済みにする（精度ゲート落ち区間の補間・§5）。
  void markRange(double fromM, double toM) {
    if (fromM > toM) {
      final tmp = fromM;
      fromM = toM;
      toM = tmp;
    }
    var i = (fromM / cellMeters).floor();
    final end = (toM / cellMeters).floor();
    if (i < 0) i = 0;
    for (; i <= end && i < _cells.length; i++) {
      _cells[i] = true;
    }
  }

  /// 通過率 [0,1]。
  double coverage() => _cells.isEmpty ? 0.0 : visitedCount / _cells.length;

  /// 復元用: 訪問ビットを base64 風の bool 列としてエクスポート/インポート。
  List<bool> exportBits() => List<bool>.unmodifiable(_cells);
  void importBits(List<bool> bits) {
    for (var i = 0; i < bits.length && i < _cells.length; i++) {
      _cells[i] = bits[i];
    }
  }
}
