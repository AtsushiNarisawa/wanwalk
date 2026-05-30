import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/route_model.dart';
import '../models/walk_mode.dart';

/// A11: 進行中の散歩記録（GPS）を端末ローカルへ退避するスナップショット。
///
/// GPS 記録状態はこれまで GpsService / GpsNotifier のメモリのみで保持されており、
/// OS によるバックグラウンド kill・クラッシュで全消失していた。本スナップショットを
/// 定期的に SharedPreferences へ保存し、再起動時に復元することでデータ喪失を防ぐ。
class ActiveWalkSnapshot {
  /// 一時停止中か。
  final bool isPaused;

  /// 記録開始時のモード（daily / outing）。
  final WalkMode walkMode;

  /// 記録開始時刻。
  final DateTime startTime;

  /// 一時停止の累積ミリ秒（A9 の経過時間控除を復元するため）。
  final int pausedTotalMs;

  /// 現在の一時停止が始まった時刻（停止中のみ非 null）。
  final DateTime? pausedAt;

  /// 記録済みのルートポイント。
  final List<RoutePoint> points;

  /// おでかけ散歩の公式ルートID（復帰時の再取得に使用）。
  final String? routeId;

  /// おでかけ散歩の公式ルート名。
  final String? routeName;

  const ActiveWalkSnapshot({
    required this.isPaused,
    required this.walkMode,
    required this.startTime,
    required this.pausedTotalMs,
    required this.pausedAt,
    required this.points,
    required this.routeId,
    required this.routeName,
  });

  Map<String, dynamic> toJson() => {
        'version': 1,
        'isPaused': isPaused,
        // enum index ではなく value 文字列で保存（並び順変更に強い）
        'walkMode': walkMode.value,
        'startTime': startTime.toIso8601String(),
        'pausedTotalMs': pausedTotalMs,
        'pausedAt': pausedAt?.toIso8601String(),
        'points': points.map((p) => p.toJson()).toList(),
        'routeId': routeId,
        'routeName': routeName,
      };

  factory ActiveWalkSnapshot.fromJson(Map<String, dynamic> json) {
    return ActiveWalkSnapshot(
      isPaused: json['isPaused'] as bool? ?? false,
      walkMode: WalkMode.fromString(json['walkMode'] as String? ?? 'daily'),
      startTime: DateTime.parse(json['startTime'] as String),
      pausedTotalMs: (json['pausedTotalMs'] as num?)?.toInt() ?? 0,
      pausedAt: json['pausedAt'] == null
          ? null
          : DateTime.parse(json['pausedAt'] as String),
      points: (json['points'] as List<dynamic>? ?? const [])
          .map((e) => RoutePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      routeId: json['routeId'] as String?,
      routeName: json['routeName'] as String?,
    );
  }
}

/// [ActiveWalkSnapshot] の SharedPreferences への読み書きを担うストア。
///
/// すべて best-effort：永続化の失敗が記録本体を止めないよう例外は握り、
/// 破損データ読込時は破棄して通常起動へフォールバックする（起動ループ防止）。
class ActiveWalkSnapshotStore {
  ActiveWalkSnapshotStore._();

  static const String _key = 'active_walk_snapshot_v1';

  static Future<void> save(ActiveWalkSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(snapshot.toJson()));
    } catch (_) {
      // best-effort：保存失敗は記録継続を妨げない
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  static Future<ActiveWalkSnapshot?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ActiveWalkSnapshot.fromJson(json);
    } catch (_) {
      // 破損スナップショットは捨てる（毎起動で復元に失敗し続けないように）
      await clear();
      return null;
    }
  }
}
