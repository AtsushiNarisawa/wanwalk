import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/location_permission_dialog.dart';
import '../../widgets/wanwalk_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_icons.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/nav_flags.dart';
import '../../models/official_route.dart';
import '../../models/route_spot.dart';
import '../../models/walk_mode.dart';
import '../../nav/route_nav_engine.dart';
import '../../utils/map_tile_nudge.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/active_walk_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gps_provider_riverpod.dart';
import '../../providers/nav_controller_provider.dart';
import '../../providers/nav_params_provider.dart';
import '../../providers/route_spots_provider.dart';
import '../../services/profile_service.dart';
import '../../services/walk_save_service.dart';
import '../../services/photo_service.dart';
import '../../services/app_review_service.dart';
import '../../services/local_notification_service.dart';
import '../../widgets/zoom_control_widget.dart';
import '../../widgets/walk_completion_card.dart';

import 'pin_create_screen.dart';
import '../../utils/logger.dart';

/// 散歩中画面（公式ルートを歩いている時）
/// - リアルタイムGPS追跡
/// - ルート進捗表示
/// - ピン投稿ボタン
/// - 統計情報表示
class WalkingScreen extends ConsumerStatefulWidget {
  final OfficialRoute route;

  const WalkingScreen({
    super.key,
    required this.route,
  });

  @override
  ConsumerState<WalkingScreen> createState() => _WalkingScreenState();
}

class _WalkingScreenState extends ConsumerState<WalkingScreen> {
  final MapController _mapController = MapController();
  final PhotoService _photoService = PhotoService();
  final List<File> _photoFiles = []; // 散歩中の写真を一時保存
  bool _isFollowingUser = true;
  bool _showRouteInfo = true;

  // §3 圏外: 地図タイル取得に失敗した最終時刻（壁時計）。直近で失敗していればバナー表示。
  int _lastTileErrorMs = 0;
  // §2 終了忘れサスペンド: ローカル通知を1回だけ出すためのラッチ。
  bool _suspendNotified = false;
  // §7 E: nav_return_parking_view を1散歩1回だけ送るためのラッチ。
  bool _parkingViewLogged = false;
  // §8: 位置権限の permission_result を1回だけ送るためのラッチ。
  bool _permissionLogged = false;
  // 散歩終了処理の再入ガード（保存中の二度押し・再試行で walks が二重保存されるのを防ぐ）。
  bool _finishing = false;
  // §10: 起動時に取得したナビ閾値（未取得時は内蔵既定値）。configure 時に確定し、
  // 全 nav イベントの nav_params_version はこの値から付与する。
  NavParams _navParams = const NavParams();

  @override
  void initState() {
    super.initState();

    // デバッグ：ルートライン情報を出力
    appLog('🚶 WalkingScreen initialized for route: ${widget.route.id}');
    appLog('🛣️ route.routeLine: ${widget.route.routeLine?.length ?? 0} points');
    if (widget.route.routeLine != null && widget.route.routeLine!.isNotEmpty) {
      appLog('🛣️ First 3 points:');
      for (var i = 0; i < widget.route.routeLine!.length && i < 3; i++) {
        final point = widget.route.routeLine![i];
        appLog('  Point $i: lat=${point.latitude}, lon=${point.longitude}');
      }
    } else {
      appLog('⚠️ route.routeLine is null or empty!');
    }
    
    // 自動的に記録開始しない（スタートボタンを待つ）
    // ただし、現在地は取得しておく（地図表示のため）
    _initializeLocation();

    // §2: kill→復元 or バナー復帰でこの画面が「既に記録中」で開かれた場合、
    // ナビエンジンが未構成なら再構成する（_startWalking を通らない経路）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reconfigureNavIfRecording();
    });
  }

  /// 初期位置を取得（記録は開始しない）
  Future<void> _initializeLocation() async {
    final gpsNotifier = ref.read(gpsProviderRiverpod.notifier);
    await gpsNotifier.getCurrentLocation();
  }

  /// 記録中なのにナビ未構成（kill→復元）の場合だけエンジンを再構成する。
  ///
  /// 最小化→バナー復帰（同一プロセス）では navControllerProvider が生存しエンジンは
  /// 既に ready なので何もしない（configure を再実行して進捗を 0 に戻さない）。
  Future<void> _reconfigureNavIfRecording() async {
    if (!mounted) return;
    final gpsState = ref.read(gpsProviderRiverpod);
    if (!gpsState.isRecording || gpsState.walkMode != WalkMode.outing) return;
    if (ref.read(navControllerProvider.notifier).isReady) return; // 稼働中＝復帰
    List<RouteSpot> navSpots = const [];
    try {
      navSpots = await ref.read(routeSpotsProvider(widget.route.id).future);
    } catch (_) {}
    if (!mounted) return;
    _configureNav(navSpots);
  }

  /// 散歩を開始
  Future<void> _startWalking() async {
    final gpsNotifier = ref.read(gpsProviderRiverpod.notifier);

    // GPS権限チェック
    final hasPermission = await gpsNotifier.checkPermission();
    // §9 F: 位置権限の Just-in-time プロンプト結果を計測（1回だけ）。
    if (!_permissionLogged) {
      _permissionLogged = true;
      unawaited(ref.read(analyticsServiceProvider).logPermissionResult(
            type: 'location',
            granted: hasPermission,
            navParamsVersion: ref.read(navParamsProvider).valueOrNull?.version,
          ));
    }
    if (!hasPermission) {
      if (mounted) {
        await showLocationPermissionDialog(context);
        if (mounted) Navigator.of(context).pop();
      }
      return;
    }

    // §8: 散歩開始時に匿名セッションを付与（転換装置の入口修理）。未ログインでも
    // 記録・北極星計測ができるようにする。失敗（匿名無効/オフライン）でも記録は継続し、
    // 保存時に再試行する。
    await ref.read(authProvider.notifier).ensureSession();

    // LAYER1_NAV_SPEC §2: ナビ構成に使うスポットを先読み（記録開始直後の最初の fix を
    // 取りこぼさないよう startRecording より前に解決。通常はルート詳細で取得済みでキャッシュ）。
    List<RouteSpot> navSpots = const [];
    try {
      navSpots = await ref.read(routeSpotsProvider(widget.route.id).future);
    } catch (_) {
      // 取得失敗でも記録は継続（ナビは線のみで進捗を出す）
    }

    // GPS記録開始（おでかけ散歩を明示。kill→復元時のルート再取得に必要）
    final success = await gpsNotifier.startRecording(mode: WalkMode.outing);
    if (!success) {
      if (mounted) {
        await showLocationPermissionDialog(context);
        if (mounted) Navigator.of(context).pop();
      }
      return;
    }

    // LAYER1_NAV_SPEC §2-§7: 沿線距離ナビを起動（記録開始直後に1回だけ）。
    _configureNav(navSpots);

    // A3: グローバル散歩状態を配線（バナーからの復帰に使用）
    ref.read(activeWalkProvider.notifier).startWalk(
          mode: WalkMode.outing,
          routeId: widget.route.id,
          routeName: widget.route.name,
          outingRoute: widget.route,
        );

    // GA4: route_start_walk (Key Event 候補・公式ルートの実利用シグナル)
    unawaited(ref.read(analyticsServiceProvider).logRouteStartWalk(
          routeSlug: widget.route.slug ?? widget.route.id,
          walkMode: WalkMode.outing.value,
          navParamsVersion: ref.read(navParamsProvider).valueOrNull?.version,
        ));
  }

  /// LAYER1_NAV_SPEC §2: 沿線距離ナビエンジンを起動する（記録開始直後に1回だけ）。
  ///
  /// nav 状態は navControllerProvider に持たせるため、最小化→バナー復帰で画面が作り直されても
  /// 進捗は保持される。configure は購読を張り替え進捗を 0 に戻すので、記録中（スタート
  /// ボタン非表示）に本メソッドが再度走らないことが前提。
  void _configureNav(List<RouteSpot> spots) {
    final line = widget.route.routeLine;
    if (line == null || line.length < 2) {
      // 線が無いルートは沿線距離を計算できない → 素の記録に劣化（仕様 §2 許容）
      return;
    }
    final navSpots = <NavSpot>[
      for (final s in spots)
        if (s.distanceFromStart != null)
          NavSpot(
            id: s.id,
            name: s.name,
            distanceFromStart: s.distanceFromStart,
            category: s.category?.value,
            location: s.location, // §11 立寄りの最接近距離算出用
          ),
    ];
    // §10: 起動時にリモート取得済みなら閾値を適用（未取得・失敗時は内蔵既定値）。
    _navParams = ref.read(navParamsProvider).valueOrNull ?? const NavParams();
    final notifier = ref.read(navControllerProvider.notifier);
    notifier.configure(
      line: line,
      spots: navSpots,
      params: _navParams,
      onApproach: _onNavApproach,
      onOffRoute: _onNavOffRoute,
    );
    notifier.attach(
      ref.read(gpsProviderRiverpod.notifier).navFixStream,
      isPaused: () => ref.read(gpsProviderRiverpod).isPaused,
    );
  }

  /// §4 B: スポット接近（沿線距離が distance_from_start を跨いだ）。
  /// Build 42 は既定オフ（NavFlags.approachGuideEnabled=false）。Build 43 でカード+計測を有効化。
  void _onNavApproach(NavApproachEvent event) {
    if (!NavFlags.approachGuideEnabled) return;
    // Build 43: 接近カード表示 + ハプティック + logNavSpotApproach。
  }

  /// §6 D: ルート逸脱エピソード開始。
  /// §14.4: Build 42 は D の UI（復帰バナー/通知）を出さない（recoveryEnabled=false）が、
  /// off_route_event の計測は**常時送る**（accuracy_m/threshold_m がリモート閾値調整の「目」）。
  void _onNavOffRoute(NavOffRouteEvent event) {
    unawaited(ref.read(analyticsServiceProvider).logOffRouteEvent(
          routeSlug: widget.route.slug ?? widget.route.id,
          recovered: false, // Build 43 で復帰/継続秒を追跡（42は開始のみ計上）
          durationSec: 0,
          wasStationary: event.wasStationary,
          accuracyM: event.accuracyM.round(),
          thresholdM: event.thresholdM.round(),
          navParamsVersion: _navParams.version,
        ));
    if (!NavFlags.recoveryEnabled) return;
    // Build 43: 復帰バナー + 最寄り復帰点への点線 + ハプティック。
  }

  /// A3: 戻る操作のハンドリング（最小化 or 中止）。
  ///
  /// PopScope（システムバック・スワイプバック）と戻るボタンの両方から呼ばれる。
  /// 記録中は「記録を続ける（最小化）/ 散歩を中止（破棄）/ キャンセル」を選択させ、
  /// 戻るで GPS が止まらず新規散歩も開始できないデッドロックを解消する。
  Future<void> _handleBackRequest() async {
    final gpsState = ref.read(gpsProviderRiverpod);

    // 記録していない（スタート前）ならそのまま戻る
    if (!gpsState.isRecording) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('散歩はどうしますか？'),
        content: const Text(
          '記録を続けたまま画面を閉じることもできます。\n'
          '下部のバナーからいつでも記録画面に戻れます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel_dialog'),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('abort'),
            child: const Text(
              '散歩を中止',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('minimize'),
            style: ElevatedButton.styleFrom(
              backgroundColor: WanWalkColors.accentPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('記録を続ける'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (choice == 'minimize') {
      // 記録を継続したまま閉じる（バナーから復帰可能）
      Navigator.of(context).pop();
    } else if (choice == 'abort') {
      // 記録を破棄して終了（ナビ状態も破棄）
      ref.read(navControllerProvider.notifier).reset();
      ref.read(gpsProviderRiverpod.notifier).cancelRecording();
      ref.read(activeWalkProvider.notifier).endWalk();
      if (mounted) Navigator.of(context).pop();
    }
    // 'cancel_dialog' / null → 画面に留まる
  }

  /// 散歩を終了
  Future<void> _finishWalking() async {
    // 再入ガード: 保存中(await)の二度押し・再試行で saveWalk が二重実行され walks が
    // 重複保存されるのを防ぐ（北極星=walks件数の汚染防止）。
    if (_finishing) return;
    _finishing = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('散歩を終了'),
        content: const Text('散歩を終了してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WanWalkColors.accent,
            ),
            child: const Text('終了'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      _finishing = false;
      return;
    }

    final gpsNotifier = ref.read(gpsProviderRiverpod.notifier);
    final gpsState = ref.read(gpsProviderRiverpod);

    // LAYER1_NAV_SPEC §5: 完走の生値（カバレッジ/最大進捗/最小ゴール距離/完走フラグ）を確定。
    // 閾値は walks に生値を保存して後から再計算できるようにする。
    final navState = ref.read(navControllerProvider);
    final bool navReady = navState.ready;
    final NavCompletion? navCompletion =
        navReady ? NavCompletion.fromState(navState) : null;
    // §11: 立寄り記録は reset 前に収集する（reset でエンジンが破棄されバッファが消えるため）。
    // 保存は walk 保存成功後にまとめて行う。visited_at の基準は nav 基準時刻（最初の GPS fix の
    // 絶対 epoch）。route.startedAt（記録開始）とは取得レイテンシ分ずれ、復元経路では大きくずれる。
    final navNotifier = ref.read(navControllerProvider.notifier);
    final List<SpotVisit> spotVisits =
        navReady ? navNotifier.collectSpotVisits() : const <SpotVisit>[];
    final int? navStartMs = navReady ? navNotifier.navStartEpochMs : null;

    // Supabaseから現在のユーザーIDを取得
    var userId = Supabase.instance.client.auth.currentUser?.id;

    // §8: セッションが無ければ匿名サインインを試みる（開始時にオフライン等で取れて
    // いなかった場合の保険）。匿名認証導入後、ここで取得できるのが通常経路。
    if (userId == null) {
      await ref.read(authProvider.notifier).ensureSession();
      if (!mounted) return;
      userId = Supabase.instance.client.auth.currentUser?.id;
    }

    if (userId == null) {
      // それでもセッション無し（オフライン/匿名無効）: **記録は破棄せず保持**し、
      // 電波回復後に再試行できるようにする（旧実装の「破棄して閉じる」を撤廃）。
      _finishing = false; // 再試行を許可
      if (mounted) {
        showWanWalkSnackBar(
          context,
          '通信状態を確認して、もう一度「終了」をお試しください（記録は保持しています）',
          type: WanWalkSnackBarType.warning,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: '再試行',
            textColor: Colors.white,
            onPressed: _finishWalking,
          ),
        );
      }
      return; // finalizeWalk/cancel しない → データ保持
    }

    // A5: 記録状態を変えずにスナップショットを生成（保存失敗時もデータ保持）
    final route = gpsNotifier.buildCurrentRoute(
      userId: userId,
      title: '${widget.route.name}を歩きました',
      description: 'おでかけ散歩',
    );

    if (route == null) {
      _finishing = false; // 少し歩いてから再試行を許可
      if (mounted) {
        showWanWalkSnackBar(
          context,
          '記録できる位置情報がまだありません。少し歩いてからお試しください',
          type: WanWalkSnackBarType.warning,
        );
      }
      return;
    }

    final distanceMeters = gpsState.distance;
    final durationMinutes = (gpsState.elapsedSeconds / 60).ceil();

    // 1. Supabaseに散歩記録を保存（§5: 完走の生値を同梱）
    final walkSaveService = WalkSaveService();
    final walkId = await walkSaveService.saveWalk(
      route: route,
      userId: userId,
      walkMode: WalkMode.outing,
      officialRouteId: widget.route.id,
      completion: navCompletion,
    );

    if (!mounted) return;

    // A5: 保存失敗 → 記録は破棄せず、リトライ導線を提示
    if (walkId == null) {
      _finishing = false; // 再試行を許可
      showWanWalkSnackBar(
        context,
        '記録の保存に失敗しました。電波の良い場所で再度お試しください',
        type: WanWalkSnackBarType.error,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: '再試行',
          textColor: Colors.white,
          onPressed: _finishWalking,
        ),
      );
      return; // finalizeWalk は呼ばない → データ保持
    }

    // === ここから保存成功 ===

    // GA4: walk_complete (Key Event 候補・最重要 conversion)
    // §9: nav の生値（進捗/カバレッジ/完走/nav有効）を同梱。未完走でも最終進捗を送る。
    unawaited(ref.read(analyticsServiceProvider).logWalkComplete(
          routeSlug: widget.route.slug ?? widget.route.id,
          walkMode: WalkMode.outing.value,
          distanceM: distanceMeters.round(),
          durationSec: gpsState.elapsedSeconds,
          progressPct: navReady ? navState.progressPct : null,
          coveragePct: navReady ? navState.coveragePct : null,
          isRouteCompleted: navReady ? navState.isCompleted : null,
          navEnabled: navReady,
          // §9/§10: この完走分布がどの閾値セットで測られたかを識別（エンジンが実際に使った版）。
          navParamsVersion: navReady ? _navParams.version : null,
        ));

    // §11: 立寄り記録を walk_spot_visits へ保存（分析用途・失敗しても散歩完了を止めない）。
    // 基準は nav 基準時刻（最初の GPS fix）。未取得時のみ route.startedAt にフォールバック。
    unawaited(walkSaveService.saveSpotVisits(
      walkId: walkId,
      userId: userId,
      visits: spotVisits,
      startTime: navStartMs != null
          ? DateTime.fromMillisecondsSinceEpoch(navStartMs)
          : route.startedAt,
    ));

    if (kDebugMode) {
      appLog('✅ 散歩記録保存成功: walkId=$walkId, 写真数=${_photoFiles.length}枚');
    }

    // A5: 保存成功したので記録を確定終了してリセット
    gpsNotifier.finalizeWalk();
    ref.read(activeWalkProvider.notifier).endWalk();
    // §2: ナビ状態を破棄（次の散歩へ持ち越さない）
    ref.read(navControllerProvider.notifier).reset();

    // 2. 写真をアップロード（A8: 失敗を集計してユーザーに通知）
    int photoFailCount = 0;
    if (_photoFiles.isNotEmpty) {
      if (kDebugMode) {
        appLog('📸 写真アップロード開始: ${_photoFiles.length}枚');
      }
      for (int i = 0; i < _photoFiles.length; i++) {
        final file = _photoFiles[i];
        final photoUrl = await _photoService.uploadWalkPhoto(
          file: file,
          walkId: walkId,
          userId: userId,
          displayOrder: i + 1,
        );
        if (photoUrl == null) {
          photoFailCount++;
          if (kDebugMode) {
            appLog('❌ 写真${i + 1}/${_photoFiles.length}アップロード失敗');
          }
        }
      }
    }

    if (!mounted) return;

    // A8: 写真アップロード失敗をユーザーに通知（散歩記録自体は保存済み）
    if (photoFailCount > 0) {
      showWanWalkSnackBar(
        context,
        '写真$photoFailCount枚のアップロードに失敗しました（散歩記録は保存されています）',
        type: WanWalkSnackBarType.warning,
        duration: const Duration(seconds: 5),
      );
    }

    // 3. プロフィールを自動更新
    final profileService = ProfileService();
    await profileService.updateWalkingProfile(
      userId: userId,
      distanceMeters: distanceMeters,
      durationMinutes: durationMinutes,
    );

    if (!mounted) return;

    // 散歩完了シートを表示（今歩いたルートを除外）
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WalkCompletionSheet(
        formattedDistance: gpsState.formattedDistance,
        formattedDuration: gpsState.formattedDuration,
        currentRouteId: widget.route.id,
        // §5: 控えめな完走表示（祝祭演出はしない）
        isRouteCompleted: navCompletion?.isRouteCompleted ?? false,
      ),
    );
    // レビュー促進: 散歩完了は最大のポジティブな瞬間（シートを閉じた後に検討）
    unawaited(AppReviewService.instance.onStrongPositiveSignal());
    _finishing = false;
    if (mounted) Navigator.of(context).pop(route);
  }

  /// 写真を撮影
  Future<void> _takePhoto() async {
    try {
      if (kDebugMode) {
        appLog('📷 写真撮影開始...');
      }
      
      final file = await _photoService.takePhoto();
      
      if (file == null) {
        if (kDebugMode) {
          appLog('❌ 写真選択がキャンセルされました');
        }
        return;
      }

      if (kDebugMode) {
        appLog('✅ 写真選択成功: ${file.path}');
      }

      setState(() {
        _photoFiles.add(file);
      });

      if (mounted) {
        showWanWalkSnackBar(
          context,
          '写真を追加しました (${_photoFiles.length}枚)',
          type: WanWalkSnackBarType.success,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        appLog('❌ 写真撮影エラー: $e');
      }
      if (mounted) {
        showWanWalkSnackBar(
          context,
          '写真の追加に失敗しました',
          type: WanWalkSnackBarType.error,
        );
      }
    }
  }

  /// ピンを投稿
  Future<void> _createPin() async {
    final currentLocation = ref.read(gpsProviderRiverpod).currentLocation;
    
    if (currentLocation == null) {
      showWanWalkSnackBar(
        context,
        '現在位置が取得できません',
        type: WanWalkSnackBarType.warning,
      );
      return;
    }

    final pin = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PinCreateScreen(
          routeId: widget.route.id,
          routeSlug: widget.route.slug,
          location: currentLocation,
          fromWalking: true,
        ),
      ),
    );

    if (pin != null && mounted) {
      showWanWalkSnackBar(
        context,
        'ピンを投稿しました！',
        type: WanWalkSnackBarType.success,
      );
    }
  }

  /// 記録を一時停止
  void _pauseRecording() {
    ref.read(gpsProviderRiverpod.notifier).pauseRecording();
  }

  /// 記録を再開
  void _resumeRecording() {
    ref.read(gpsProviderRiverpod.notifier).resumeRecording();
  }

  /// 地図の中心位置を計算
  /// 優先順位: routeLine の中心 > 現在地 > startLocation
  LatLng _calculateMapCenter(GpsState gpsState) {
    // 1. routeLine が存在する場合、その中心を計算
    if (widget.route.routeLine != null && widget.route.routeLine!.isNotEmpty) {
      final points = widget.route.routeLine!;
      
      // 緯度・経度の範囲を計算
      double minLat = points[0].latitude;
      double maxLat = points[0].latitude;
      double minLng = points[0].longitude;
      double maxLng = points[0].longitude;
      
      for (final point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
      
      // 中心座標を計算
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      
      appLog('🗺️ Map center calculated from routeLine:');
      appLog('  Center: ($centerLat, $centerLng)');
      appLog('  Bounds: lat[$minLat, $maxLat], lng[$minLng, $maxLng]');
      
      return LatLng(centerLat, centerLng);
    }
    
    // 2. 現在地が存在する場合
    if (gpsState.currentLocation != null) {
      appLog('🗺️ Map center: using current location');
      return gpsState.currentLocation!;
    }
    
    // 3. startLocation をフォールバック
    appLog('🗺️ Map center: using startLocation');
    return widget.route.startLocation;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gpsState = ref.watch(gpsProviderRiverpod);
    // LAYER1_NAV_SPEC §3: 沿線距離ナビの進捗（画面外で生存する Provider を購読）
    final navState = ref.watch(navControllerProvider);
    final navActive = navState.ready && gpsState.isInitialized;

    // §2 終了忘れサスペンド: suspended に遷移したらローカル通知を1回だけ。
    // §7 E: 駐車場戻り情報が初めて出たら nav_return_parking_view を1回だけ計測。
    ref.listen<NavState>(navControllerProvider, (prev, next) {
      if (next.suspended && !(prev?.suspended ?? false) && !_suspendNotified) {
        _suspendNotified = true;
        _onSuspendDetected();
      }
      if (next.returnToParkingMeters != null && !_parkingViewLogged) {
        _parkingViewLogged = true;
        unawaited(ref.read(analyticsServiceProvider).logNavReturnParkingView(
              routeSlug: widget.route.slug ?? widget.route.id,
              navParamsVersion: _navParams.version,
            ));
      }
    });

    // CEO決定 案B: マップをSafeArea内に収め、上部はベージュ帯で塗る（Wildbounds哲学）
    final topInset = MediaQuery.of(context).padding.top;
    // A3: システムバック・スワイプバックも _handleBackRequest を必ず通す
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackRequest();
      },
      child: Scaffold(
      backgroundColor: WanWalkColors.bgSecondary,
      body: Stack(
        children: [
          // 上部: bg-secondary のステータスバー帯
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset,
            child: Container(color: WanWalkColors.bgSecondary),
          ),

          // マップ表示（ステータスバー下から描画）
          Positioned(
            top: topInset,
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildMap(gpsState),
          ),

          // 上部オーバーレイ（タイトル・閉じるボタン）
          _buildTopOverlay(isDark),

          // §3 圏外: 地図タイルが取得できなくても「案内は継続中」と明示（白地図≠故障）
          if (_showOfflineBanner) _buildOfflineBanner(topInset),

          // 下部オーバーレイ（統計情報＋ナビ進捗）
          if (_showRouteInfo) _buildBottomOverlay(isDark, gpsState, navState),

          // フローティングアクションボタン（ピン投稿）
          _buildFloatingButtons(gpsState, navActive),
        ],
      ),
      ),
    );
  }

  /// マップ表示
  Widget _buildMap(GpsState gpsState) {
    // ルートラインが存在する場合は、その中心を計算
    final center = _calculateMapCenter(gpsState);
    final spotsAsync = ref.watch(routeSpotsProvider(widget.route.id));

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        onMapReady: () => nudgeMapTiles(_mapController),
        initialCenter: center,
        initialZoom: 16.0,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) {
            setState(() {
              _isFollowingUser = false;
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.doghub.wanwalk',
          // §3 圏外: タイル取得失敗を記録。直近で失敗していれば「案内は継続中」バナーを出す。
          errorTileCallback: (tile, error, stackTrace) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final wasOffline = now - _lastTileErrorMs < _offlineWindowMs;
            _lastTileErrorMs = now;
            // 非表示→表示への遷移時だけ再描画（タイル毎の setState 連打を避ける）
            if (!wasOffline && mounted) setState(() {});
          },
        ),
        // 公式ルートライン（DESIGN_TOKENS §12-A: accent-primary 深緑）
        if (widget.route.routeLine != null && widget.route.routeLine!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.route.routeLine!,
                strokeWidth: 6.0,
                color: WanWalkColors.accentPrimary,
                borderStrokeWidth: 2.0,
                borderColor: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
        // スポットマーカー（スタート・ゴール・中間スポット）
        spotsAsync.when(
          data: (spots) {
            if (spots.isEmpty) return const SizedBox.shrink();
            return MarkerLayer(
              markers: _buildSpotMarkers(spots),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        // 現在位置マーカー（最前面に表示）
        if (gpsState.currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: gpsState.currentLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// 上部オーバーレイ
  Widget _buildTopOverlay(bool isDark) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(WanWalkSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                // A3: PopScope と同じ戻るハンドラを通す（最小化 or 中止を選択）
                onPressed: _handleBackRequest,
              ),
              Expanded(
                child: Text(
                  widget.route.name,
                  style: WanWalkTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showRouteInfo ? Icons.info : Icons.info_outline,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showRouteInfo = !_showRouteInfo;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 下部オーバーレイ（統計情報＋ナビ進捗）
  Widget _buildBottomOverlay(bool isDark, GpsState gpsState, NavState navState) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(WanWalkSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ドラッグハンドル
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? WanWalkColors.textSecondaryDark
                      : WanWalkColors.textSecondaryLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: WanWalkSpacing.md),

              // LAYER1_NAV_SPEC §3 A: 進捗バー・残距離・次スポット（記録中かつナビ初期化済みのみ）
              if (gpsState.isInitialized && navState.ready)
                _buildNavProgress(isDark, navState),

              // 統計情報
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.straighten,
                    label: '距離',
                    value: gpsState.formattedDistance,
                    isDark: isDark,
                  ),
                  _StatItem(
                    icon: Icons.timer,
                    label: '時間',
                    value: gpsState.formattedDuration,
                    isDark: isDark,
                  ),
                  _StatItem(
                    icon: Icons.location_on,
                    label: 'ポイント',
                    value: '${gpsState.currentPointCount}',
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: WanWalkSpacing.lg),

              // コントロールボタン
              if (!gpsState.isInitialized) ...[
                // スタートボタン（記録開始前）
                ElevatedButton(
                  onPressed: _startWalking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WanWalkColors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: WanWalkSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: WanWalkSpacing.xs),
                      Text('スタート', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ] else ...[
                // 一時停止 & 終了ボタン（記録開始後）
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: gpsState.isPaused
                            ? _resumeRecording
                            : _pauseRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gpsState.isPaused
                              ? WanWalkColors.accentPrimary
                              : WanWalkColors.accentPrimaryHover,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: WanWalkSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(gpsState.isPaused ? Icons.play_arrow : Icons.pause),
                            const SizedBox(width: WanWalkSpacing.xs),
                            Text(gpsState.isPaused ? '再開' : '一時停止'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: WanWalkSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _finishWalking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WanWalkColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: WanWalkSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check),
                            SizedBox(width: WanWalkSpacing.xs),
                            Text('終了'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// LAYER1_NAV_SPEC §3 A: 進捗バー・残距離・次スポット（沿線距離ベース）。
  /// Wildbounds トーン（祝祭演出はしない）。下部パネル統計の直前に差し込む。
  Widget _buildNavProgress(bool isDark, NavState navState) {
    final pct = navState.progressPct.clamp(0.0, 1.0);
    final pctLabel = '${(pct * 100).round()}%';
    final textPrimary =
        isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight;
    final textSecondary =
        isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight;
    final nextSpot = navState.nextSpot;
    final nextRem = navState.nextSpotRemainingMeters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              navState.isCompleted ? 'ルートを歩ききりました' : 'ルート進捗 $pctLabel',
              style: WanWalkTypography.caption.copyWith(color: textSecondary),
            ),
            const Spacer(),
            Text(
              'のこり ${_formatNavDistance(navState.remainingMeters)}',
              style: WanWalkTypography.caption.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: WanWalkColors.accentPrimary.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(
              WanWalkColors.accentPrimary,
            ),
          ),
        ),
        if (nextSpot != null && nextRem != null) ...[
          const SizedBox(height: WanWalkSpacing.sm),
          Row(
            children: [
              Icon(WanWalkIcons.mapPin, size: 16, color: WanWalkColors.accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '次: ${nextSpot.name} まで ${_formatNavDistance(nextRem)}',
                  style: WanWalkTypography.bodySmall.copyWith(color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        // §7 E: 駐車場へ「ルート沿いに戻って約Xkm」（parking スポットがあるルートのみ）。
        // 直線距離+方角はやらない（谷底/対岸での誤誘導の実害を避ける・§7）。
        if (navState.returnToParkingMeters != null) ...[
          const SizedBox(height: WanWalkSpacing.sm),
          Row(
            children: [
              Icon(WanWalkIcons.car, size: 16, color: WanWalkColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '駐車場まで ルート沿いに約 ${_formatNavDistance(navState.returnToParkingMeters!)}',
                  style: WanWalkTypography.bodySmall.copyWith(color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: WanWalkSpacing.md),
        Divider(height: 1, color: WanWalkColors.borderStrong.withValues(alpha: 0.4)),
        const SizedBox(height: WanWalkSpacing.md),
      ],
    );
  }

  /// ナビ用の距離表記（1km 未満は m・以上は km 小数1位）。
  /// ルート総距離の formatDistance（常に km）とは別物（短距離が "0.0km" になるのを避ける）。
  String _formatNavDistance(double meters) {
    final m = meters.round();
    if (m < 1000) return '${m}m';
    return '${(m / 1000).toStringAsFixed(1)}km';
  }

  // §3 圏外バナー: タイル取得失敗から一定時間はバナーを出す（白地図≠故障の明示）。
  static const int _offlineWindowMs = 8000;
  bool get _showOfflineBanner =>
      _lastTileErrorMs != 0 &&
      DateTime.now().millisecondsSinceEpoch - _lastTileErrorMs < _offlineWindowMs;

  /// §3: 圏外（地図タイル取得失敗）でも案内は継続中であることを明示するバナー。
  /// ポリライン・現在地・進捗・残距離はルート読込済みなら圏外でも動く。
  Widget _buildOfflineBanner(double topInset) {
    return Positioned(
      top: topInset + 56,
      left: WanWalkSpacing.md,
      right: WanWalkSpacing.md,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WanWalkSpacing.md,
              vertical: WanWalkSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: WanWalkColors.textPrimaryLight.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(WanWalkIcons.info, size: 18, color: Colors.white),
                const SizedBox(width: WanWalkSpacing.xs),
                Flexible(
                  child: Text(
                    '地図を読み込めませんが、ルート案内は継続中です',
                    style: WanWalkTypography.bodySmall.copyWith(color: Colors.white),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// §2 終了忘れサスペンド: 速度>12km/h継続 or ルートから500m超でナビ判定が止まった。
  /// 「散歩を終了しますか？」をローカル通知で1回だけ知らせる（車移動旅行者向け）。
  Future<void> _onSuspendDetected() async {
    unawaited(LocalNotificationService().showNotification(
      id: 4201,
      title: '散歩を終了しますか？',
      body: 'ルートから大きく離れたようです。散歩を終える場合はアプリで「終了」を押してください。',
    ));
    if (mounted) {
      showWanWalkSnackBar(
        context,
        '移動が速いようです。散歩を終える場合は「終了」を押してください',
        type: WanWalkSnackBarType.warning,
        duration: const Duration(seconds: 6),
      );
    }
  }

  /// フローティングボタン
  Widget _buildFloatingButtons(GpsState gpsState, bool navActive) {
    // ナビ進捗セクションのぶん下部パネルが高くなるため FAB を持ち上げる
    final double bottomOffset =
        _showRouteInfo ? (navActive ? 348.0 : 280.0) : 120.0;
    return Stack(
      children: [
        // ズームコントロール（左下）
        Positioned(
          left: WanWalkSpacing.lg,
          bottom: bottomOffset,
          child: ZoomControlWidget(
            mapController: _mapController,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
        ),
        // 既存のボタン群（右下）
        Positioned(
          right: WanWalkSpacing.lg,
          bottom: bottomOffset,
          child: Column(
            children: [
              // 写真撮影ボタン
              FloatingActionButton(
                heroTag: "camera_button",
                onPressed: _takePhoto,
                backgroundColor: WanWalkColors.accentPrimary,
                child: Badge(
                  isLabelVisible: _photoFiles.isNotEmpty,
                  label: Text('${_photoFiles.length}'),
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
              const SizedBox(height: WanWalkSpacing.md),
              // ピン投稿ボタン
              FloatingActionButton.extended(
                heroTag: "pin_button",
                onPressed: gpsState.currentLocation != null ? _createPin : null,
                backgroundColor: WanWalkColors.accent,
                icon: const Icon(Icons.push_pin, color: Colors.white),
                label: Text(
                  'ピン投稿',
                  style: WanWalkTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: WanWalkSpacing.md),
              // 現在位置追従ボタン
              FloatingActionButton(
                heroTag: "location_button",
                onPressed: () {
                  if (gpsState.currentLocation != null) {
                    _mapController.move(gpsState.currentLocation!, 16.0);
                    setState(() {
                      _isFollowingUser = true;
                    });
                  }
                },
                backgroundColor: Colors.white,
                child: Icon(
                  _isFollowingUser ? Icons.my_location : Icons.location_searching,
                  color: WanWalkColors.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// スポットマーカーを生成（DESIGN_TOKENS §12-A: route_detail_screen と統一）
  List<Marker> _buildSpotMarkers(List<RouteSpot> spots) {
    if (spots.isEmpty) return [];

    final markers = <Marker>[];
    final processedIndices = <int>{};

    for (int i = 0; i < spots.length; i++) {
      if (processedIndices.contains(i)) continue;

      final spot = spots[i];
      final isStart = spot.spotType == RouteSpotType.start;
      final isEnd = spot.spotType == RouteSpotType.end;

      // スタート地点の場合、同じ位置にゴールがあるかチェック
      if (isStart) {
        final goalIndex = spots.indexWhere((s) =>
          s.spotType == RouteSpotType.end &&
          _isSameLocation(s.location, spot.location)
        );

        if (goalIndex != -1) {
          markers.add(Marker(
            point: spot.location,
            width: 28.0,
            height: 28.0,
            alignment: Alignment.center,
            child: _buildLabeledMarker(label: 'S/G', bg: WanWalkColors.accentPrimary, fontSize: 11),
          ));
          processedIndices.add(i);
          processedIndices.add(goalIndex);
          continue;
        }
      }

      // ゴール地点でスタートと同じ位置の場合はスキップ
      if (isEnd) {
        final startIndex = spots.indexWhere((s) =>
          s.spotType == RouteSpotType.start &&
          _isSameLocation(s.location, spot.location)
        );
        if (startIndex != -1 && processedIndices.contains(startIndex)) {
          continue;
        }
      }

      final isStartOrEnd = isStart || isEnd;
      final markerSize = isStartOrEnd ? 28.0 : 22.0;

      markers.add(Marker(
        point: spot.location,
        width: markerSize,
        height: markerSize,
        alignment: Alignment.center,
        child: _buildSpotMapIcon(spot.spotType, i),
      ));
      processedIndices.add(i);
    }

    return markers;
  }

  bool _isSameLocation(LatLng loc1, LatLng loc2) {
    const threshold = 0.0001;
    return (loc1.latitude - loc2.latitude).abs() < threshold &&
           (loc1.longitude - loc2.longitude).abs() < threshold;
  }

  /// Inter Bold 白文字入りの丸マーカー（S/G/SG 共通）
  Widget _buildLabeledMarker({
    required String label,
    required Color bg,
    required double fontSize,
  }) {
    return Container(
      width: 28.0,
      height: 28.0,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.0),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          color: Colors.white,
          height: 1.0,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// スポットマップアイコン（DESIGN_TOKENS §12-A）
  Widget _buildSpotMapIcon(RouteSpotType spotType, int index) {
    if (spotType == RouteSpotType.start) {
      return _buildLabeledMarker(label: 'S', bg: WanWalkColors.accentPrimary, fontSize: 13);
    }
    if (spotType == RouteSpotType.end) {
      return _buildLabeledMarker(label: 'G', bg: WanWalkColors.accentPrimaryHover, fontSize: 13);
    }

    // 中間スポット: 白背景+グレー枠+グレー数字
    return Container(
      width: 22.0,
      height: 22.0,
      decoration: BoxDecoration(
        color: WanWalkColors.bgPrimary,
        shape: BoxShape.circle,
        border: Border.all(color: WanWalkColors.textSecondary, width: 2.0),
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: WanWalkColors.textSecondary,
          height: 1.0,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: WanWalkColors.accent,
          size: 28,
        ),
        const SizedBox(height: WanWalkSpacing.xs),
        Text(
          label,
          style: WanWalkTypography.caption.copyWith(
            color: isDark
                ? WanWalkColors.textSecondaryDark
                : WanWalkColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: WanWalkTypography.headlineSmall.copyWith(
            color: isDark
                ? WanWalkColors.textPrimaryDark
                : WanWalkColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
