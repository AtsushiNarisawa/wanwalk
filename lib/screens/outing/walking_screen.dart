import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/location_permission_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../models/official_route.dart';
import '../../models/route_spot.dart';
import '../../models/walk_mode.dart';
import '../../providers/gps_provider_riverpod.dart';
import '../../providers/route_spots_provider.dart';
import '../../services/profile_service.dart';
import '../../services/walk_save_service.dart';
import '../../services/photo_service.dart';
import '../../widgets/zoom_control_widget.dart';
import '../../widgets/walk_completion_card.dart';
import 'dart:io';

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
  }

  /// 初期位置を取得（記録は開始しない）
  Future<void> _initializeLocation() async {
    final gpsNotifier = ref.read(gpsProviderRiverpod.notifier);
    await gpsNotifier.getCurrentLocation();
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

    // GPS記録開始
    final success = await gpsNotifier.startRecording();
    if (!success) {
      if (mounted) {
        await showLocationPermissionDialog(context);
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  /// 散歩を終了
  Future<void> _finishWalking() async {
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

    if (confirmed != true) return;

    final gpsNotifier = ref.read(gpsProviderRiverpod.notifier);
    final gpsState = ref.read(gpsProviderRiverpod);
    
    // Supabaseから現在のユーザーIDを取得
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      // GPS記録を停止してから画面を閉じる
      gpsNotifier.stopRecording(
        userId: 'anonymous',
        title: '${widget.route.name}を歩きました',
        description: 'おでかけ散歩',
      );
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

    final route = gpsNotifier.stopRecording(
      userId: userId,
      title: '${widget.route.name}を歩きました',
      description: 'おでかけ散歩',
    );

    if (mounted) {
      if (route != null) {
        final distanceMeters = gpsState.distance;
        final durationMinutes = (gpsState.elapsedSeconds / 60).ceil();
        
        // 1. Supabaseに散歩記録を保存
        final walkSaveService = WalkSaveService();
        final walkId = await walkSaveService.saveWalk(
          route: route,
          userId: userId,
          walkMode: WalkMode.outing,
          officialRouteId: widget.route.id,
        );

        if (walkId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('記録の保存に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (kDebugMode) {
          appLog('✅ 散歩記録保存成功: walkId=$walkId, 写真数=${_photoFiles.length}枚');
        }

        // 2. 写真をアップロード
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
            if (photoUrl != null) {
              if (kDebugMode) {
                appLog('✅ 写真${i + 1}/${_photoFiles.length}アップロード成功');
              }
            } else {
              if (kDebugMode) {
                appLog('❌ 写真${i + 1}/${_photoFiles.length}アップロード失敗');
              }
            }
          }
        }

        // 3. プロフィールを自動更新
        final profileService = ProfileService();
        await profileService.updateWalkingProfile(
          userId: userId,
          distanceMeters: distanceMeters,
          durationMinutes: durationMinutes,
        );
        
        // 散歩完了シートを表示（今歩いたルートを除外）
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => WalkCompletionSheet(
            formattedDistance: gpsState.formattedDistance,
            formattedDuration: gpsState.formattedDuration,
            currentRouteId: widget.route.id,
          ),
        );
        if (mounted) Navigator.of(context).pop(route);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('記録の保存に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('写真を追加しました (${_photoFiles.length}枚)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        appLog('❌ 写真撮影エラー: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('写真の追加に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ピンを投稿
  Future<void> _createPin() async {
    final currentLocation = ref.read(gpsProviderRiverpod).currentLocation;
    
    if (currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('現在位置が取得できません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pin = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PinCreateScreen(
          routeId: widget.route.id,
          location: currentLocation,
          fromWalking: true,
        ),
      ),
    );

    if (pin != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ピンを投稿しました！'),
          backgroundColor: Colors.green,
        ),
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

    // CEO決定 案B: マップをSafeArea内に収め、上部はベージュ帯で塗る（Wildbounds哲学）
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
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

          // 下部オーバーレイ（統計情報）
          if (_showRouteInfo) _buildBottomOverlay(isDark, gpsState),

          // フローティングアクションボタン（ピン投稿）
          _buildFloatingButtons(gpsState),
        ],
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
        initialCenter: center,
        initialZoom: 16.0,
        onPositionChanged: (position, hasGesture) {
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
        // 公式ルートライン（DESIGN_TOKENS §12-A: accent-primary 深緑）
        if (widget.route.routeLine != null && widget.route.routeLine!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.route.routeLine!,
                strokeWidth: 6.0,
                color: WanWalkColors.accentPrimary,
                borderStrokeWidth: 2.0,
                borderColor: Colors.white.withOpacity(0.8),
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
                        color: Colors.black.withOpacity(0.3),
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
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
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
              color: Colors.black.withOpacity(0.2),
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

  /// フローティングボタン
  Widget _buildFloatingButtons(GpsState gpsState) {
    return Stack(
      children: [
        // ズームコントロール（左下）
        Positioned(
          left: WanWalkSpacing.lg,
          bottom: _showRouteInfo ? 280 : 120,
          child: ZoomControlWidget(
            mapController: _mapController,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
        ),
        // 既存のボタン群（右下）
        Positioned(
          right: WanWalkSpacing.lg,
          bottom: _showRouteInfo ? 280 : 120,
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
