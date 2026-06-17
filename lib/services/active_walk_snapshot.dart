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

  /// §2 v2: 進行中ナビエンジンのスナップショット（`NavEngineSnapshot.toJson()` の生 Map）。
  /// おでかけ散歩でナビが ready のときのみ非 null。復元時にエンジンへ取り込み、クラッシュ前の
  /// カバレッジ/進捗/方向/接近発火済み/立寄りを引き継ぐ（中途参加によるカバレッジ消失の解消）。
  /// 本サービスはエンジン型に依存しないため生 Map で保持する（直列化は呼び出し側が担う）。
  final Map<String, dynamic>? navSnapshot;

  /// §2/§11: nav 基準時刻（最初の GPS fix の絶対 epoch ms）。復元時にエンジンへ引き継ぎ、
  /// 後続 fix のタイムライン連続性と立寄り visited_at の絶対時刻復元に使う。
  final int? navStartEpochMs;

  const ActiveWalkSnapshot({
    required this.isPaused,
    required this.walkMode,
    required this.startTime,
    required this.pausedTotalMs,
    required this.pausedAt,
    required this.points,
    required this.routeId,
    required this.routeName,
    this.navSnapshot,
    this.navStartEpochMs,
  });

  Map<String, dynamic> toJson() => {
        // v2: ナビ状態（navSnapshot / navStartEpochMs）を追加。version は読込時に無視されるが
        // 形式の世代を残す（旧 v1 = navSnapshot 欠落 → null 扱いで無害に復元）。
        'version': 2,
        'isPaused': isPaused,
        // enum index ではなく value 文字列で保存（並び順変更に強い）
        'walkMode': walkMode.value,
        'startTime': startTime.toIso8601String(),
        'pausedTotalMs': pausedTotalMs,
        'pausedAt': pausedAt?.toIso8601String(),
        'points': points.map((p) => p.toJson()).toList(),
        'routeId': routeId,
        'routeName': routeName,
        'navSnapshot': navSnapshot,
        'navStartEpochMs': navStartEpochMs,
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
      // 旧 v1 スナップショットには無いキー（null 許容で後方互換）。
      navSnapshot: (json['navSnapshot'] as Map?)?.cast<String, dynamic>(),
      navStartEpochMs: (json['navStartEpochMs'] as num?)?.toInt(),
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
