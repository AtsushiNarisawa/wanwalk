import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../config/env.dart';
import '../../models/walk_mode.dart';
import '../../providers/gps_provider_riverpod.dart';
import '../../services/profile_service.dart';
import '../../services/walk_save_service.dart';
import '../../services/photo_service.dart';
import '../../services/badge_service.dart';

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
  final PhotoService _photoService = PhotoService();
  final List<File> _photoFiles = []; // 散歩中の写真を一時保存（散歩終了時にアップロード）
  String? _currentWalkId; // 現在の散歩ID（保存時に設定）
  bool _isReady = false; // GPS準備完了フラグ
  double _currentZoom = 15.0; // 現在のズームレベル
  bool _autoZoomTriggered = false; // 自動ズーム遷移が実行されたか
  Timer? _autoZoomTimer; // 自動ズーム用タイマー

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareWalking();
    });
    _startAutoZoomTransition(); // 2秒後に自動ズーム遷移
  }

  @override
  void dispose() {
    _autoZoomTimer?.cancel();
    super.dispose();
  }

  /// 2秒後に自動ズーム遷移（15.0 → 17.0）
  void _startAutoZoomTransition() {
    _autoZoomTimer = Timer(const Duration(seconds: 2), () {
      if (!_autoZoomTriggered && mounted) {
        setState(() {
          _currentZoom = 17.0;
          _autoZoomTriggered = true;
        });
        final gpsState = ref.read(gpsProviderRiverpod);
        if (gpsState.currentLocation != null) {
          _mapController.move(gpsState.currentLocation!, _currentZoom);
        }
        if (kDebugMode) {
          print('🔍 日常散歩: 自動ズーム遷移 15.0 → 17.0');
        }
      }
    });
  }

  /// GPS準備（権限チェック・初期位置取得）
  Future<void> _prepareWalking() async {
    if (kDebugMode) {
      print('📍 DailyWalkingScreen: GPS準備開始');
    }
    
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

    // 現在位置を取得
    await gpsNotifier.getCurrentLocation();
    
    setState(() {
      _isReady = true;
    });

    if (kDebugMode) {
      print('✅ DailyWalkingScreen: GPS準備完了');
    }
  }

  /// 散歩を開始（スタートボタン押下時）
  Future<void> _startWalking() async {
    if (kDebugMode) {
      print('🟢 DailyWalkingScreen: スタートボタン押下 - GPS記録開始');
    }
    
    final gpsNotifier = ref.read(gpsProviderRiverpod.notifier);
    
    // GPS記録開始
    final success = await gpsNotifier.startRecording();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS記録の開始に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              backgroundColor: WanMapColors.accent,
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

        // 散歩IDを保存（写真アップロード用）
        _currentWalkId = walkId;

        if (kDebugMode) {
          print('✅ 日常散歩記録保存成功: walkId=$walkId, 写真数=${_photoFiles.length}枚');
        }

        // 2. 散歩中に撮影した写真をアップロード
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

        // 4. バッジ解除チェック
        final badgeService = BadgeService(Supabase.instance.client);
        final newBadges = await badgeService.checkAndUnlockBadges(userId: userId);
        if (newBadges.isNotEmpty && mounted) {
          if (kDebugMode) {
            print('🏆 新しいバッジを解除しました: ${newBadges.length}個');
          }
        }
        
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

  /// 写真を選択（散歩終了時）
  Future<void> _selectPhotos() async {
    try {
      if (kDebugMode) {
        print('📷 写真選択開始...');
      }
      
      // ギャラリーから写真を選択
      final file = await _photoService.pickImageFromGallery();
      
      if (file == null) {
        if (kDebugMode) {
          print('❌ 写真選択がキャンセルされました');
        }
        return;
      }

      if (kDebugMode) {
        print('✅ 写真選択成功: ${file.path}');
      }

      // 写真をローカルリストに追加
      setState(() {
        _photoFiles.add(file);
      });

      if (kDebugMode) {
        print('✅ 写真追加成功: ${_photoFiles.length}枚');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 写真選択エラー: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gpsState = ref.watch(gpsProviderRiverpod);

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: const Text('日常散歩'),
        backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // マップ表示
          _buildMap(gpsState),

          // 上部オーバーレイ
          _buildTopOverlay(isDark),

          // 下部オーバーレイ（統計情報） - 記録中のみ表示
          if (gpsState.isRecording)
            _buildBottomOverlay(isDark, gpsState),

          // フローティングボタン（現在位置追従）
          _buildFloatingButton(gpsState),

          // 中央ボタン（スタートボタン） - 記録前のみ表示
          if (_isReady && !gpsState.isRecording)
            _buildCenterButton(isDark, gpsState),
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
        initialZoom: _currentZoom,
        onPositionChanged: (position, hasGesture) {
          // ドラッグ操作のみ追従を解除（ズームボタンでは解除しない）
          if (hasGesture && position.zoom == _currentZoom) {
            setState(() {
              _isFollowingUser = false;
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=${Environment.thunderforestApiKey}',
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

              const SizedBox(height: WanMapSpacing.md),

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

  /// ズームイン
  void _zoomIn() {
    if (_currentZoom < 18.0) {
      setState(() {
        _currentZoom = (_currentZoom + 0.5).clamp(14.0, 18.0);
        _autoZoomTriggered = true; // ユーザー操作で自動遷移をキャンセル
      });
      final gpsState = ref.read(gpsProviderRiverpod);
      final center = gpsState.currentLocation ?? const LatLng(35.6762, 139.6503);
      _mapController.move(center, _currentZoom);
      HapticFeedback.lightImpact();
      _showZoomLevel();
    }
  }

  /// ズームアウト
  void _zoomOut() {
    if (_currentZoom > 14.0) {
      setState(() {
        _currentZoom = (_currentZoom - 0.5).clamp(14.0, 18.0);
        _autoZoomTriggered = true; // ユーザー操作で自動遷移をキャンセル
      });
      final gpsState = ref.read(gpsProviderRiverpod);
      final center = gpsState.currentLocation ?? const LatLng(35.6762, 139.6503);
      _mapController.move(center, _currentZoom);
      HapticFeedback.lightImpact();
      _showZoomLevel();
    }
  }

  /// ズームレベルを一時的に表示
  void _showZoomLevel() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ズーム: ${_currentZoom.toStringAsFixed(1)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 400, left: 100, right: 100),
        backgroundColor: Colors.black87,
      ),
    );
  }

  /// フローティングボタン（ズーム + 現在地追従）
  Widget _buildFloatingButton(GpsState gpsState) {
    return Positioned(
      right: WanMapSpacing.lg,
      bottom: gpsState.isRecording ? 280 : 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ズームインボタン
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: _zoomIn,
            backgroundColor: Colors.white,
            child: const Icon(Icons.add, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          // ズームアウトボタン
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            onPressed: _zoomOut,
            backgroundColor: Colors.white,
            child: const Icon(Icons.remove, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          // 現在地追従ボタン
          FloatingActionButton(
            heroTag: 'my_location',
            onPressed: () {
              if (gpsState.currentLocation != null) {
                _mapController.move(gpsState.currentLocation!, _currentZoom);
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
    );
  }

  /// 中央ボタン（スタートボタン）
  Widget _buildCenterButton(bool isDark, GpsState gpsState) {
    return Positioned(
      left: WanMapSpacing.lg,
      right: WanMapSpacing.lg,
      bottom: WanMapSpacing.xl,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 統計情報（記録前も表示）
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: WanMapSpacing.lg,
                vertical: WanMapSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
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
            ),
            const SizedBox(height: WanMapSpacing.md),
            // スタートボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startWalking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 28),
                    SizedBox(width: WanMapSpacing.sm),
                    Text(
                      'スタート',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
