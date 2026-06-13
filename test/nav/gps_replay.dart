import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:wanwalk/nav/nav_geometry.dart';

/// LAYER1_NAV_SPEC §14: 実ルートの LINESTRING から合成GPS列を生成するハーネス。
/// fake Position ストリーム相当の [ReplayFix] 列を作り、ナビエンジンへ注入してテストする。
///
/// 注入パターン（§14.1）:
///   normal / noisy / accuracyDegraded(渓谷30-80m系統誤差) / reverse(逆回り) /
///   shortcut(ショートカット) / midJoin(途中参加) / stationary(匂い嗅ぎ・カフェ) /
///   carDeparture(散歩後の車発進)
///
/// 決定的: 乱数は seed 付き Random のみ（同じ入力→同じ出力でテストが再現する）。

class ReplayFix {
  /// 端末が報告する（ノイズ込みの）位置。
  final LatLng position;

  /// 報告される水平精度(m)。accuracyDegraded で大きくなる。
  final double accuracyM;

  /// 散歩開始からの経過(ms)。
  final int tMillis;

  /// 真の沿線距離(m)。判定の正解として使う（端末は知らない値）。
  final double trueChainage;

  /// 移動中か（stationary の静止区間は false）。
  final bool moving;

  ReplayFix({
    required this.position,
    required this.accuracyM,
    required this.tMillis,
    required this.trueChainage,
    required this.moving,
  });
}

enum ReplayPattern {
  normal,
  noisy,
  accuracyDegraded,
  reverse,
  shortcut,
  midJoin,
  stationary,
  carDeparture,
}

class GpsReplayGenerator {
  final double stepM; // 進行ステップ（geolocator distanceFilter=3 相当）
  final double speedMps; // 犬連れ歩行速度（3km/h ≈ 0.83m/s）

  GpsReplayGenerator({this.stepM = 3.0, this.speedMps = 0.83});

  List<ReplayFix> generate(List<LatLng> line, ReplayPattern pattern, {int seed = 0}) {
    if (line.length < 2) return const [];
    final cum = cumulativeChainage(line);
    final total = cum.last;
    final rng = math.Random(seed);
    switch (pattern) {
      case ReplayPattern.normal:
        return _walk(line, cum, total, rng, noiseSigma: 4, accuracy: 8);
      case ReplayPattern.noisy:
        return _walk(line, cum, total, rng, noiseSigma: 16, accuracy: 16);
      case ReplayPattern.accuracyDegraded:
        return _walk(line, cum, total, rng,
            noiseSigma: 6, accuracy: 8,
            degradeFrom: 0.30 * total, degradeTo: 0.60 * total,
            degradeOffsetM: 55, degradeAccuracy: 60);
      case ReplayPattern.reverse:
        return _walk(line, cum, total, rng, noiseSigma: 4, accuracy: 8, reverse: true);
      case ReplayPattern.shortcut:
        return _walk(line, cum, total, rng,
            noiseSigma: 4, accuracy: 8, skipFrom: 0.35 * total, skipTo: 0.70 * total);
      case ReplayPattern.midJoin:
        return _walk(line, cum, total, rng,
            noiseSigma: 4, accuracy: 8, startChainage: 0.40 * total);
      case ReplayPattern.stationary:
        return _walk(line, cum, total, rng,
            noiseSigma: 4, accuracy: 8, pauseAt: 0.50 * total, pauseSeconds: 90);
      case ReplayPattern.carDeparture:
        final fixes = _walk(line, cum, total, rng, noiseSigma: 4, accuracy: 8);
        return [...fixes, ..._carDeparture(line, cum, total, fixes.last, rng)];
    }
  }

  List<ReplayFix> _walk(
    List<LatLng> line,
    List<double> cum,
    double total,
    math.Random rng, {
    required double noiseSigma,
    required double accuracy,
    bool reverse = false,
    double startChainage = 0,
    double? skipFrom,
    double? skipTo,
    double? degradeFrom,
    double? degradeTo,
    double degradeOffsetM = 0,
    double degradeAccuracy = 0,
    double? pauseAt,
    int pauseSeconds = 0,
  }) {
    final out = <ReplayFix>[];
    final dtMs = (stepM / speedMps * 1000).round();
    int t = 0;
    final n = (total / stepM).floor();
    bool paused = false;
    for (var i = 0; i <= n; i++) {
      final raw = i * stepM;
      double c = reverse ? (total - raw) : (startChainage + raw);
      if (c < 0) c = 0;
      if (c > total) c = total;
      if (!reverse && c < startChainage) continue;

      // ショートカット: スキップ帯は emit せず、時間も進めない（空間的にテレポート相当）。
      // → 前後の good fix 間が「歩行速度では不可能な飛び」になり、coverage 補間が掛からず
      //   スキップ区間が未踏のまま残る（偽完走0 の検証になる）。
      if (skipFrom != null && skipTo != null && c > skipFrom && c < skipTo) {
        continue;
      }

      // 静止（匂い嗅ぎ・カフェ）: pauseAt 付近で一度だけ pauseSeconds 静止する。
      if (pauseAt != null && !paused && c >= pauseAt) {
        paused = true;
        final basePos = pointAtChainage(line, c, cumChain: cum);
        final pauseFixes = (pauseSeconds * 1000 / dtMs).round();
        for (var k = 0; k < pauseFixes; k++) {
          out.add(ReplayFix(
            position: offsetMeters(basePos, _g(rng, 1.5), _g(rng, 1.5)),
            accuracyM: accuracy,
            tMillis: t,
            trueChainage: c,
            moving: false,
          ));
          t += dtMs;
        }
      }

      // 精度劣化（渓谷）: 帯内は系統的に perp 方向へずらし、精度を大きく報告する。
      final inDegrade =
          degradeFrom != null && degradeTo != null && c >= degradeFrom && c <= degradeTo;
      LatLng base;
      double acc;
      if (inDegrade) {
        base = _offsetPerp(line, cum, c, total, degradeOffsetM);
        base = offsetMeters(base, _g(rng, noiseSigma), _g(rng, noiseSigma));
        acc = degradeAccuracy;
      } else {
        base = pointAtChainage(line, c, cumChain: cum);
        base = offsetMeters(base, _g(rng, noiseSigma), _g(rng, noiseSigma));
        acc = accuracy;
      }
      out.add(ReplayFix(
        position: base,
        accuracyM: acc,
        tMillis: t,
        trueChainage: c,
        moving: true,
      ));
      t += dtMs;
    }
    // 端点ちょうどの fix を保証（stepM 端数で末端スポットの dfs を跨ぎ損ねない）。
    final endC = reverse ? 0.0 : total;
    if (out.isNotEmpty && (out.last.trueChainage - endC).abs() > 1.0) {
      final endPos = pointAtChainage(line, endC, cumChain: cum);
      out.add(ReplayFix(
        position: offsetMeters(endPos, _g(rng, accuracy * 0.3), _g(rng, accuracy * 0.3)),
        accuracyM: accuracy,
        tMillis: t,
        trueChainage: endC,
        moving: true,
      ));
    }
    return out;
  }

  /// 散歩終端から車で発進（>12km/h 相当）して経路から離れる fix 列。
  List<ReplayFix> _carDeparture(
    List<LatLng> line,
    List<double> cum,
    double total,
    ReplayFix lastFix,
    math.Random rng,
  ) {
    final out = <ReplayFix>[];
    const carSpeed = 4.2; // ≈15km/h
    final dtMs = 1500;
    final step = carSpeed * dtMs / 1000; // 1フィックスあたりの距離
    int t = lastFix.tMillis + dtMs;
    var pos = lastFix.position;
    // 終端の接線に対して斜めに離脱（道路へ）。
    final end = pointAtChainage(line, total, cumChain: cum);
    final prev = pointAtChainage(line, math.max(0, total - 5), cumChain: cum);
    final dEast = _eastM(prev, end);
    final dNorth = _northM(prev, end);
    final len = math.sqrt(dEast * dEast + dNorth * dNorth);
    final ux = len == 0 ? 1.0 : dEast / len;
    final uy = len == 0 ? 0.0 : dNorth / len;
    for (var k = 0; k < 20; k++) {
      pos = offsetMeters(pos, uy * step, ux * step);
      out.add(ReplayFix(
        position: pos,
        accuracyM: 8,
        tMillis: t,
        trueChainage: total,
        moving: true,
      ));
      t += dtMs;
    }
    return out;
  }

  /// 沿線距離 c の地点で、進行方向に対して垂直に offsetM ずらした座標。
  LatLng _offsetPerp(List<LatLng> line, List<double> cum, double c, double total, double offsetM) {
    final p1 = pointAtChainage(line, c, cumChain: cum);
    final p2 = pointAtChainage(line, math.min(c + 2, total), cumChain: cum);
    final dEast = _eastM(p1, p2);
    final dNorth = _northM(p1, p2);
    final len = math.sqrt(dEast * dEast + dNorth * dNorth);
    if (len == 0) return p1;
    final perpEast = -dNorth / len;
    final perpNorth = dEast / len;
    return offsetMeters(p1, perpNorth * offsetM, perpEast * offsetM);
  }

  double _eastM(LatLng a, LatLng b) {
    final d = haversineMeters(a, LatLng(a.latitude, b.longitude));
    return b.longitude >= a.longitude ? d : -d;
  }

  double _northM(LatLng a, LatLng b) {
    final d = haversineMeters(a, LatLng(b.latitude, a.longitude));
    return b.latitude >= a.latitude ? d : -d;
  }

  /// Box-Muller のガウスノイズ（sigma m）。
  double _g(math.Random rng, double sigma) {
    if (sigma <= 0) return 0;
    final u1 = math.max(1e-9, rng.nextDouble());
    final u2 = rng.nextDouble();
    return sigma * math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }
}
