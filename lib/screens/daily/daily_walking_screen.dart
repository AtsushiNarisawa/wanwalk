import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../widgets/location_permission_dialog.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../models/walk_mode.dart';
import '../../providers/gps_provider_riverpod.dart';
import '../../providers/active_walk_provider.dart';
import '../../services/profile_service.dart';
import '../../services/walk_save_service.dart';
import '../../services/photo_service.dart';
import '../../widgets/zoom_control_widget.dart';
import '../../widgets/walk_completion_card.dart';
import '../../utils/logger.dart';

/// 日常散歩中画面
/// - リアルタイムGPS追跡
/// - 統計情報表示
/// - シンプルなUI（公式ルート表示なし）
class DailyWalkingScreen extends ConsumerStatefulWidget {
  const DailyWalkingScreen({super.key});

  @override
  ConsumerState<DailyWalkingScreen> createState() => _DailyWalkingScreenState();
}

class _DailyWalkingScreenState extends ConsumerState<DailyWalkingScreen> {
  final MapController _mapController = MapController();
  bool _isFollowingUser = true;
  bool _showRouteInfo = true; // 統計情報の表示/非表示
  final PhotoService _photoService = PhotoService();
  final List<File> _photoFiles = []; // 散歩中の写真を一時保存（散歩終了時にアップロード）

  @override
  void initState() {
    super.initState();
    // 自動的に記録開始しない（スタートボタンを待つ）
    // ただし、現在地は取得しておく（地図表示のため）
    _initializeLocation();
  }

  /// 初期位置を取得（記録は開始しない）
  Future<void> _initializeLocation() async {
    final gpsNotifier = ref.read(gpsProviderRiverpod.notifier);
    await gpsNotifier.getCurrentLocation();
  }

  /// A3: 戻る操作のハンドリング（最小化 or 中止）。
  ///
  /// PopScope（システムバック・スワイプバック）と戻るボタンの両方から呼ばれる。
  /// 旧実装は「中止」を選んでも GPS を止めずに pop していたため、記録が回り続け
  /// 新規散歩も開始できないデッドロックになっていた。これを解消する。
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
              backgroundColor: WanWalkColors.accent,
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
      // 記録を破棄して終了（GPS を確実に停止）
      ref.read(gpsProviderRiverpod.notifier).cancelRecording();
      ref.read(activeWalkProvider.notifier).endWalk();
      if (mounted) Navigator.of(context).pop();
    }
    // 'cancel_dialog' / null → 画面に留まる
  }

  /// 散歩を開始
  Future<void> _startWalking() async {
    final gpsNotifier = ref.read(gpsProviderRiverpod.notifier);
    
    // GPS権限チェック
    final hasPermission = await gpsNotifier.checkPermission();
    if (!hasPermission) {
      if (mounted) {
        await showLocationPermissionDialog(context);
        if (mounted) Navigator.of(context).pop();
      }
      return;
    }

    // GPS記録開始（日常散歩を明示。outing 後に daily を継承しないようにする）
    final success = await gpsNotifier.startRecording(mode: WalkMode.daily);
    if (!success) {
      if (mounted) {
        await showLocationPermissionDialog(context);
        if (mounted) Navigator.of(context).pop();
      }
      return;
    }

    // A3: グローバル散歩状態を配線（バナーからの復帰に使用）
    ref.read(activeWalkProvider.notifier).startWalk(mode: WalkMode.daily);
  }

  /// 散歩を終了
  Future<void> _finishWalking() async {
    // 写真選択ダイアログを表示
    final shouldAddPhotos = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('散歩を終了'),
        content: const Text('写真を追加しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('スキップ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WanWalkColors.accent,
            ),
            child: const Text('写真を選択'),
          ),
        ],
      ),
    );

    // 写真を選択
    if (shouldAddPhotos == true) {
      await _selectPhotos();
    }

    // 終了確認
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('散歩を終了'),
        content: Text(_photoFiles.isEmpty 
          ? '散歩を終了してもよろしいですか？'
          : '散歩を終了します。選択した${_photoFiles.length}枚の写真をアップロードします。'),
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

    if (confirmed != true) return;

    final gpsNotifier = ref.read(gpsProviderRiverpod.notifier);
    final gpsState = ref.read(gpsProviderRiverpod);

    // Supabaseから現在のユーザーIDを取得
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      // 未ログイン: 保存できないので記録を破棄して閉じる
      gpsNotifier.cancelRecording();
      ref.read(activeWalkProvider.notifier).endWalk();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインしていないため記録を保存できません'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // A5: 記録状態を変えずにスナップショットを生成（保存失敗時もデータ保持）
    final route = gpsNotifier.buildCurrentRoute(
      userId: userId,
      title: '日常の散歩',
      description: '日常散歩',
    );

    if (route == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('記録できる位置情報がまだありません。少し歩いてからお試しください'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final distanceMeters = gpsState.distance;
    final durationMinutes = (gpsState.elapsedSeconds / 60).ceil();

    // 1. Supabaseに散歩記録を保存
    final walkSaveService = WalkSaveService();
    final walkId = await walkSaveService.saveWalk(
      route: route,
      userId: userId,
      walkMode: WalkMode.daily,
    );

    if (!mounted) return;

    // A5: 保存失敗 → 記録は破棄せず、リトライ導線を提示
    if (walkId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('記録の保存に失敗しました。電波の良い場所で再度お試しください'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: '再試行',
            textColor: Colors.white,
            onPressed: _finishWalking,
          ),
        ),
      );
      return; // finalizeWalk は呼ばない → データ保持
    }

    // === ここから保存成功 ===
    if (kDebugMode) {
      appLog('✅ 日常散歩記録保存成功: walkId=$walkId, 写真数=${_photoFiles.length}枚');
    }

    // A5: 保存成功したので記録を確定終了してリセット
    gpsNotifier.finalizeWalk();
    ref.read(activeWalkProvider.notifier).endWalk();

    // 2. 散歩中に撮影した写真をアップロード（A8: 失敗を集計して通知）
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('写真$photoFailCount枚のアップロードに失敗しました（散歩記録は保存されています）'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
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

    // 散歩完了シートを表示
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WalkCompletionSheet(
        formattedDistance: gpsState.formattedDistance,
        formattedDuration: gpsState.formattedDuration,
      ),
    );
    if (mounted) Navigator.of(context).pop(route);
  }

  /// 記録を一時停止
  void _pauseRecording() {
    ref.read(gpsProviderRiverpod.notifier).pauseRecording();
  }

  /// 記録を再開
  void _resumeRecording() {
    ref.read(gpsProviderRiverpod.notifier).resumeRecording();
  }

  /// 写真を選択（散歩終了時）
  Future<void> _selectPhotos() async {
    try {
      if (kDebugMode) {
        appLog('📷 写真選択開始...');
      }
      
      // ギャラリーから写真を選択
      final file = await _photoService.pickImageFromGallery();
      
      if (file == null) {
        if (kDebugMode) {
          appLog('❌ 写真選択がキャンセルされました');
        }
        return;
      }

      if (kDebugMode) {
        appLog('✅ 写真選択成功: ${file.path}');
      }

      // 写真をローカルリストに追加
      setState(() {
        _photoFiles.add(file);
      });

      if (kDebugMode) {
        appLog('✅ 写真追加成功: ${_photoFiles.length}枚');
      }
    } catch (e) {
      if (kDebugMode) {
        appLog('❌ 写真選択エラー: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gpsState = ref.watch(gpsProviderRiverpod);

    // CEO決定 案B: マップをSafeArea内に収め、上部はベージュ帯で塗る
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topInset,
              child: Container(color: WanWalkColors.bgSecondary),
            ),
            Positioned(
              top: topInset,
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildMap(gpsState),
            ),
            _buildTopOverlay(isDark),
            if (_showRouteInfo) _buildBottomOverlay(isDark, gpsState),
            _buildFloatingButton(gpsState),
          ],
        ),
      ),
    );
  }

  /// マップ表示
  Widget _buildMap(GpsState gpsState) {
    final center = gpsState.currentLocation ?? const LatLng(35.6762, 139.6503);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
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
        ),
        // 歩いたルートを表示
        if (gpsState.currentRoutePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: gpsState.currentRoutePoints.map((p) => p.latLng).toList(),
                strokeWidth: 4.0,
                color: WanWalkColors.accent.withValues(alpha: 0.8),
              ),
            ],
          ),
        // 現在位置マーカー
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
                  '日常の散歩',
                  style: WanWalkTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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

  /// 下部オーバーレイ（統計情報）
  Widget _buildBottomOverlay(bool isDark, GpsState gpsState) {
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

              const SizedBox(height: WanWalkSpacing.md),

              // コントロールボタン
              if (!gpsState.isInitialized) ...[
                // スタートボタン（記録開始前）
                ElevatedButton(
                  onPressed: _startWalking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                              ? Colors.green
                              : Colors.orange,
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

  /// フローティングボタン
  Widget _buildFloatingButton(GpsState gpsState) {
    return Stack(
      children: [
        // ズームコントロール（左下）
        Positioned(
          left: WanWalkSpacing.lg,
          bottom: 280,
          child: ZoomControlWidget(
            mapController: _mapController,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
        ),
        // 現在地ボタン（右下）
        Positioned(
          right: WanWalkSpacing.lg,
          bottom: 280,
          child: FloatingActionButton(
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
        ),
      ],
    );
  }
}

/// 統計アイテム
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
