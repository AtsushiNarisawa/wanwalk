import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/walk_mode.dart';

/// 散歩記録中の状態
/// GPS記録の補助情報（散歩モード、ルートID）を保持
class ActiveWalkState {
  final bool isWalking;
  final WalkMode? walkMode; // daily or outing
  final String? routeId; // お出かけ散歩の公式ルートID
  final String? routeName; // お出かけ散歩の公式ルート名

  const ActiveWalkState({
    this.isWalking = false,
    this.walkMode,
    this.routeId,
    this.routeName,
  });

  ActiveWalkState copyWith({
    bool? isWalking,
    WalkMode? walkMode,
    String? routeId,
    String? routeName,
  }) {
    return ActiveWalkState(
      isWalking: isWalking ?? this.isWalking,
      walkMode: walkMode ?? this.walkMode,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
    );
  }

  /// 散歩を開始
  ActiveWalkState start({
    required WalkMode mode,
    String? routeId,
    String? routeName,
  }) {
    return ActiveWalkState(
      isWalking: true,
      walkMode: mode,
      routeId: routeId,
      routeName: routeName,
    );
  }

  /// 散歩を終了（状態をクリア）
  ActiveWalkState clear() {
    return const ActiveWalkState();
  }
}

/// 散歩状態管理Notifier
class ActiveWalkNotifier extends StateNotifier<ActiveWalkState> {
  ActiveWalkNotifier() : super(const ActiveWalkState());

  /// 散歩を開始
  void startWalk({
    required WalkMode mode,
    String? routeId,
    String? routeName,
  }) {
    state = state.start(
      mode: mode,
      routeId: routeId,
      routeName: routeName,
    );
  }

  /// 散歩を終了
  void endWalk() {
    state = state.clear();
  }
}

/// グローバル散歩状態Provider
final activeWalkProvider = StateNotifierProvider<ActiveWalkNotifier, ActiveWalkState>((ref) {
  return ActiveWalkNotifier();
});
