import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 接続状態プロバイダー
/// オンライン状態プロバイダー（一時的に無効化 - ConnectivityService削除済み）
// final isOnlineProvider = StreamProvider<bool>((ref) {
//   return service.connectivityStream;
// });

/// 同期サービスプロバイダー（一時的に無効化）
// final syncServiceProvider = Provider((ref) => SyncService());

/// 同期状態プロバイダー
final isSyncingProvider = StateProvider<bool>((ref) => false);

// 未同期ルート数プロバイダー（削除済み - Isar依存のため）

/// 手動同期アクション（一時的に無効化）
class SyncActions {
  // final Ref _ref; // 未使用のため削除

  SyncActions(Ref ref);

  // TODO: SyncService 実装後に有効化
  // Future<SyncResult> sync() async {
  //   final syncService = _ref.read(syncServiceProvider);
  //   _ref.read(isSyncingProvider.notifier).state = true;
  //   try {
  //     final result = await syncService.sync();
  //     _ref.invalidate(pendingRoutesCountProvider);
  //     return result;
  //   } finally {
  //     _ref.read(isSyncingProvider.notifier).state = false;
  //   }
  // }

  // Future<void> autoSync() async {
  //   final syncService = _ref.read(syncServiceProvider);
  //   await syncService.autoSync();
  //   _ref.invalidate(pendingRoutesCountProvider);
  // }
}

final syncActionsProvider = Provider((ref) => SyncActions(ref));
