import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../config/env.dart';
import '../../models/official_route.dart';
import '../../models/route_spot.dart';
import '../../models/walk_mode.dart';
import '../../providers/gps_provider_riverpod.dart';
import '../../providers/route_spots_provider.dart';
import '../../services/profile_service.dart';
import '../../services/walk_save_service.dart';
import '../../services/photo_service.dart';
import '../../widgets/zoom_control_widget.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'pin_create_screen.dart';

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
    if (kDebugMode) {
      print('🚶 WalkingScreen initialized for route: ${widget.route.id}');
    }
    if (kDebugMode) {
      print('🛣️ route.routeLine: ${widget.route.routeLine?.length ?? 0} points');
    }
    if (widget.route.routeLine != null && widget.route.routeLine!.isNotEmpty) {
      if (kDebugMode) {
        print('🛣️ First 3 points:');
      }
      for (var i = 0; i < widget.route.routeLine!.length && i < 3; i++) {
        final point = widget.route.routeLine![i];
        if (kDebugMode) {
          print('  Point $i: lat=${point.latitude}, lon=${point.longitude}');
        }
      }
    } else {
      if (kDebugMode) {
        print('⚠️ route.routeLine is null or empty!');
      }
    }
    
    // 自動的に記録開始しない（スタートボタンを待つ）
    // ただし、現在地は取得しておく（地図表示のため）
    _initializeLocation();
  }

  // [BUG-H03 修正] MapController の dispose を追加（メモリリーク防止）
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('位置情報の権限が必要です'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // GPS記録開始
    final success = await gpsNotifier.startRecording();
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS記録の開始に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
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
              backgroundColor: WanMapColors.accent,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ユーザー情報が取得できませんでした'),
          backgroundColor: Colors.red,
        ),
      );
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
          print('✅ 散歩記録保存成功: walkId=$walkId, 写真数=${_photoFiles.length}枚');
        }

        // 2. 写真をアップロード
        if (_photoFiles.isNotEmpty) {
          if (kDebugMode) {
            print('📸 写真アップロード開始: ${_photoFiles.length}枚');
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
                print('✅ 写真${i + 1}/${_photoFiles.length}アップロード成功');
              }
            } else {
              if (kDebugMode) {
                print('❌ 写真${i + 1}/${_photoFiles.length}アップロード失敗');
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '散歩記録を保存しました！${_photoFiles.isNotEmpty ? " (写真${_photoFiles.length}枚)" : ""}\n${gpsState.formattedDistance} / ${gpsState.formattedDuration}'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(route);
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
        print('📷 写真撮影開始...');
      }
      
      final file = await _photoService.takePhoto();
      
      if (file == null) {
        if (kDebugMode) {
          print('❌ 写真選択がキャンセルされました');
        }
        return;
      }

      if (kDebugMode) {
        print('✅ 写真選択成功: ${file.path}');
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
        print('❌ 写真撮影エラー: $e');
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
      
      if (kDebugMode) {
        print('🗺️ Map center calculated from routeLine:');
      }
      if (kDebugMode) {
        print('  Center: ($centerLat, $centerLng)');
      }
      if (kDebugMode) {
        print('  Bounds: lat[$minLat, $maxLat], lng[$minLng, $maxLng]');
      }
      
      return LatLng(centerLat, centerLng);
    }
    
    // 2. 現在地が存在する場合
    if (gpsState.currentLocation != null) {
      if (kDebugMode) {
        print('🗺️ Map center: using current location');
      }
      return gpsState.currentLocation!;
    }
    
    // 3. startLocation をフォールバック
    if (kDebugMode) {
      print('🗺️ Map center: using startLocation');
    }
    return widget.route.startLocation;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gpsState = ref.watch(gpsProviderRiverpod);

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      body: Stack(
        children: [
          // マップ表示
          _buildMap(gpsState),

          // 上部オーバーレイ
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
        // 公式ルートライン（鮮やかなオレンジ色、太線）
        if (widget.route.routeLine != null && widget.route.routeLine!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.route.routeLine!,
                strokeWidth: 6.0, // より太く
                color: const Color(0xFFFF6B35), // 鮮やかなオレンジ色（不透明）
                borderStrokeWidth: 2.0,
                borderColor: Colors.white.withOpacity(0.8), // 白い縁取り
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
          padding: const EdgeInsets.all(WanMapSpacing.md),
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
                  style: WanMapTypography.bodyLarge.copyWith(
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
        padding: const EdgeInsets.all(WanMapSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
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
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: WanMapSpacing.md),

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

              const SizedBox(height: WanMapSpacing.lg),

              // コントロールボタン
              if (!gpsState.isInitialized) ...[
                // スタートボタン（記録開始前）
                ElevatedButton(
                  onPressed: _startWalking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: WanMapSpacing.md,
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
                      SizedBox(width: WanMapSpacing.xs),
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
                            vertical: WanMapSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(gpsState.isPaused ? Icons.play_arrow : Icons.pause),
                            const SizedBox(width: WanMapSpacing.xs),
                            Text(gpsState.isPaused ? '再開' : '一時停止'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: WanMapSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _finishWalking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WanMapColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: WanMapSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check),
                            SizedBox(width: WanMapSpacing.xs),
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
          left: WanMapSpacing.lg,
          bottom: _showRouteInfo ? 280 : 120,
          child: ZoomControlWidget(
            mapController: _mapController,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
        ),
        // 既存のボタン群（右下）
        Positioned(
          right: WanMapSpacing.lg,
          bottom: _showRouteInfo ? 280 : 120,
          child: Column(
            children: [
              // 写真撮影ボタン
              FloatingActionButton(
                heroTag: "camera_button",
                onPressed: _takePhoto,
                backgroundColor: Colors.green,
                child: Badge(
                  isLabelVisible: _photoFiles.isNotEmpty,
                  label: Text('${_photoFiles.length}'),
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
              const SizedBox(height: WanMapSpacing.md),
              // ピン投稿ボタン
              FloatingActionButton.extended(
                heroTag: "pin_button",
                onPressed: gpsState.currentLocation != null ? _createPin : null,
                backgroundColor: WanMapColors.accent,
                icon: const Icon(Icons.push_pin, color: Colors.white),
                label: Text(
                  'ピン投稿',
                  style: WanMapTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: WanMapSpacing.md),
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
                  color: WanMapColors.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// スポットマーカーを生成（スタート・ゴール・中間スポット）
  List<Marker> _buildSpotMarkers(List<RouteSpot> spots) {
    if (spots.isEmpty) return [];

    final markers = <Marker>[];
    
    // スタートとゴールが同じ位置かチェック
    final startSpot = spots.firstWhere((s) => s.spotType == RouteSpotType.start, orElse: () => spots.first);
    final endSpot = spots.firstWhere((s) => s.spotType == RouteSpotType.end, orElse: () => spots.last);
    
    final isSameLocation = (startSpot.location.latitude - endSpot.location.latitude).abs() < 0.0001 &&
                           (startSpot.location.longitude - endSpot.location.longitude).abs() < 0.0001;

    if (isSameLocation) {
      // スタート=ゴールの場合：半分緑・半分赤のマーカー
      markers.add(
        Marker(
          alignment: Alignment.center,
          point: startSpot.location,
          width: 50,
          height: 50,
          child: Stack(
            children: [
              // 左半分：緑（スタート）
              ClipPath(
                clipper: _LeftHalfClipper(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
              // 右半分：赤（ゴール）
              ClipPath(
                clipper: _RightHalfClipper(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
              // 中央のアイコン
              Center(
                child: Icon(
                  Icons.flag,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      );
      
      // 中間スポットを追加（インデックス付き）
      for (int i = 0; i < spots.length; i++) {
        final spot = spots[i];
        if (spot.spotType != RouteSpotType.start && spot.spotType != RouteSpotType.end) {
          markers.add(_buildSpotMarker(spot, i, false));
        }
      }
    } else {
      // スタートとゴールが別の場合：全スポットを表示（インデックス付き）
      for (int i = 0; i < spots.length; i++) {
        final spot = spots[i];
        final isStartOrEnd = spot.spotType == RouteSpotType.start || spot.spotType == RouteSpotType.end;
        markers.add(_buildSpotMarker(spot, i, isStartOrEnd));
      }
    }

    return markers;
  }

  /// 個別スポットマーカーを生成
  Marker _buildSpotMarker(RouteSpot spot, int index, bool isStartOrEnd) {
    final size = isStartOrEnd ? 50.0 : 35.0; // サイズを小さく
    final iconSize = isStartOrEnd ? 24.0 : 16.0;
    final borderWidth = isStartOrEnd ? 3.0 : 2.5;

    Color backgroundColor;
    IconData? icon;
    bool showNumber = false;
    int? spotNumber;

    switch (spot.spotType) {
      case RouteSpotType.start:
        backgroundColor = const Color(0xFF4CAF50); // 緑
        icon = Icons.flag;
        break;
      case RouteSpotType.end:
        backgroundColor = const Color(0xFFF44336); // 赤
        icon = Icons.sports_score;
        break;
      case RouteSpotType.landscape:
      case RouteSpotType.photoSpot:
      case RouteSpotType.facility:
        backgroundColor = const Color(0xFF9E9E9E); // グレー
        showNumber = true;
        spotNumber = index;
        break;
    }

    return Marker(
      alignment: Alignment.center,
      point: spot.location,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: showNumber
            ? Center(
                child: Text(
                  '$spotNumber',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
      ),
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
          color: WanMapColors.accent,
          size: 28,
        ),
        const SizedBox(height: WanMapSpacing.xs),
        Text(
          label,
          style: WanMapTypography.caption.copyWith(
            color: isDark
                ? WanMapColors.textSecondaryDark
                : WanMapColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: WanMapTypography.headlineSmall.copyWith(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 左半分をクリップするClipper
class _LeftHalfClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<ui.Path> oldClipper) => false;
}

/// 右半分をクリップするClipper
class _RightHalfClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    path.addRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height));
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<ui.Path> oldClipper) => false;
}
