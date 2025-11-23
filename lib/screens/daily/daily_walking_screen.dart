import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/walk_mode.dart';
import '../../providers/gps_provider_riverpod.dart';
import '../../services/profile_service.dart';
import '../../services/walk_save_service.dart';

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

  @override
  void initState() {
    super.initState();
    _startWalking();
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
      title: '日常の散歩',
      description: '日常散歩',
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
          walkMode: WalkMode.daily,
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

        print('✅ 日常散歩記録保存成功: walkId=$walkId');

        // 2. プロフィールを自動更新
        final profileService = ProfileService();
        await profileService.updateWalkingProfile(
          userId: userId,
          distanceMeters: distanceMeters,
          durationMinutes: durationMinutes,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '散歩記録を保存しました！\n${gpsState.formattedDistance} / ${gpsState.formattedDuration}'
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

  /// 記録を一時停止
  void _pauseRecording() {
    ref.read(gpsProviderRiverpod.notifier).pauseRecording();
  }

  /// 記録を再開
  void _resumeRecording() {
    ref.read(gpsProviderRiverpod.notifier).resumeRecording();
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
          _buildBottomOverlay(isDark, gpsState),

          // フローティングボタン（現在位置追従）
          _buildFloatingButton(gpsState),
        ],
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
          urlTemplate: 'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=8c3872c6b1d5471a0e8c88cc69ed4f',
          userAgentPackageName: 'com.doghub.wanmap',
        ),
        // 歩いたルートを表示
        if (gpsState.currentRoutePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: gpsState.currentRoutePoints.map((p) => p.latLng).toList(),
                strokeWidth: 4.0,
                color: WanMapColors.accent.withOpacity(0.8),
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
                  '日常の散歩',
                  style: WanMapTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
          ),
        ),
      ),
    );
  }

  /// フローティングボタン
  Widget _buildFloatingButton(GpsState gpsState) {
    return Positioned(
      right: WanMapSpacing.lg,
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
          color: WanMapColors.accent,
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
