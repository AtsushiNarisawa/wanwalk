import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/gps_service.dart';
import '../../services/photo_service.dart';
import '../../config/supabase_config.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../widgets/wanmap_widgets.dart';
import '../../models/route_model.dart';

/// マップ画面
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final GpsService _gpsService = GpsService();
  
  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isPaused = false;
  List<LatLng> _routePoints = [];
  DateTime? _pauseStartTime;
  Duration _totalPauseDuration = Duration.zero;
  List<String> _tempPhotoUrls = []; // 記録中に撮影した写真のURL

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }

    /// マップ初期化
  Future<void> _initializeMap() async {
    // 現在位置を取得
    final position = await _gpsService.getCurrentPosition();
    
    if (mounted) {
      setState(() {
        _currentPosition = position ?? const LatLng(35.6762, 139.6503); // デフォルト：東京
        _isLoading = false;
      });

      // マップが構築された後に移動
      if (_currentPosition != null) {
        // 少し遅延を入れてMapControllerが完全に初期化されるのを待つ
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _mapController.move(_currentPosition!, 15.0);
        }
      }
    }
  }

  /// ルート記録開始
  Future<void> _startRecording() async {
    final success = await _gpsService.startRecording();
    
    if (success && mounted) {
      setState(() {
        _isRecording = true;
        _isPaused = false;  // 一時停止状態をリセット
        _routePoints.clear();
        _tempPhotoUrls.clear();  // 一時写真URLをクリア
        _pauseStartTime = null;  // 一時停止開始時刻をリセット
        _totalPauseDuration = Duration.zero;  // 累積一時停止時間をリセット
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ルート記録を開始しました'),
          backgroundColor: Colors.green,
        ),
      );

      // 定期的にポイントを更新
      _startPointUpdateTimer();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('記録を開始できませんでした。位置情報の権限を確認してください。'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ルート記録を一時停止
  void _pauseRecording() {
    if (!_isRecording || _isPaused) return;

    setState(() {
      _isPaused = true;
      _pauseStartTime = DateTime.now();
    });

    _gpsService.pauseRecording();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('記録を一時停止しました'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// ルート記録を再開
  void _resumeRecording() {
    if (!_isRecording || !_isPaused) return;

    if (_pauseStartTime != null) {
      _totalPauseDuration += DateTime.now().difference(_pauseStartTime!);
    }

    setState(() {
      _isPaused = false;
      _pauseStartTime = null;
    });

    _gpsService.resumeRecording();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('記録を再開しました'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 写真撮影（記録中）
  Future<void> _takePhoto() async {
    if (!_isRecording) return;

    final userId = SupabaseConfig.userId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインしてください')),
        );
      }
      return;
    }

    try {
      // カメラで撮影
      final file = await PhotoService().takePhoto();
      if (file == null) return;

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真をアップロード中...')),
      );

      // 一時的なrouteIdを生成（記録終了時に実際のrouteIdに置き換え）
      final tempRouteId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      // 写真をアップロード
      final storagePath = await PhotoService().uploadPhoto(
        file: file,
        routeId: tempRouteId,
        userId: userId,
      );

      if (storagePath != null && mounted) {
        setState(() {
          _tempPhotoUrls.add(storagePath);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('写真を追加しました（${_tempPhotoUrls.length}枚）'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('写真のアップロードに失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ルート記録停止（ダイアログ表示のみ）
  void _stopRecording() {
    if (kDebugMode) {
      print('🔵 _stopRecording が呼ばれました');
    }
    
    final userId = SupabaseConfig.userId;
    
    if (userId == null) {
      if (kDebugMode) {
        print('❌ userId が null です');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログインしてください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (kDebugMode) {
      print('🔵 記録中かどうか: ${_gpsService.isRecording}');
    }
    
    if (!_gpsService.isRecording) {
      if (kDebugMode) {
        print('❌ 記録していません');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('記録していません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (kDebugMode) {
      print('🔵 ダイアログを表示します（記録はまだ停止していません）');
    }
    // タイトル入力ダイアログを表示（記録は続行中）
    _showSaveRouteDialog(userId);
  }

  /// ルート保存ダイアログ（リデザイン版）
  void _showSaveRouteDialog(String userId) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPublic = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: WanMapSpacing.borderRadiusXL,
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(WanMapSpacing.lg),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(WanMapSpacing.sm),
                          decoration: BoxDecoration(
                            color: WanMapColors.accent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.save,
                            color: WanMapColors.accent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: WanMapSpacing.md),
                        Expanded(
                          child: Text(
                            'お散歩を保存',
                            style: WanMapTypography.headlineSmall.copyWith(
                              color: isDark 
                                  ? WanMapColors.textPrimaryDark 
                                  : WanMapColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: WanMapSpacing.xl),
                    
                    // タイトル入力
                    WanMapTextField(
                      controller: titleController,
                      labelText: 'ルート名',
                      hintText: '朝の散歩、公園コースなど',
                      prefixIcon: Icons.edit,
                    ),
                    
                    const SizedBox(height: WanMapSpacing.lg),
                    
                    // 説明入力
                    WanMapTextField(
                      controller: descriptionController,
                      labelText: '説明（任意）',
                      hintText: 'ルートの特徴やメモ',
                      prefixIcon: Icons.notes,
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: WanMapSpacing.lg),
                    
                    // 公開設定
                    WanMapCard(
                      size: WanMapCardSize.small,
                      padding: const EdgeInsets.all(WanMapSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            isPublic ? Icons.public : Icons.lock,
                            color: isPublic 
                                ? WanMapColors.secondary 
                                : WanMapColors.textSecondaryLight,
                          ),
                          const SizedBox(width: WanMapSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '公開設定',
                                  style: WanMapTypography.titleSmall.copyWith(
                                    color: isDark 
                                        ? WanMapColors.textPrimaryDark 
                                        : WanMapColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: WanMapSpacing.xxs),
                                Text(
                                  isPublic 
                                      ? '他のユーザーが閲覧できます' 
                                      : 'あなただけが閲覧できます',
                                  style: WanMapTypography.labelSmall.copyWith(
                                    color: isDark 
                                        ? WanMapColors.textSecondaryDark 
                                        : WanMapColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isPublic,
                            activeColor: WanMapColors.secondary,
                            onChanged: (value) {
                              setState(() => isPublic = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: WanMapSpacing.xl),
                    
                    // ボタン
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: WanMapButton(
                            text: 'キャンセル',
                            size: WanMapButtonSize.small,
                            variant: WanMapButtonVariant.outlined,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('お散歩を終了しますか？'),
                                  content: const Text('記録したデータを保存せずに終了します。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('戻る'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _gpsService.stopRecording(
                                          userId: '',
                                          title: '',
                                          description: '',
                                          isPublic: false,
                                        );
                                        Navigator.pop(ctx);
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('保存せずに終了', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: WanMapSpacing.sm),
                        Expanded(
                          flex: 5,
                          child: WanMapButton(
                            text: '保存',
                            icon: Icons.check,
                            onPressed: () {
                              final title = titleController.text.trim();
                              
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('ルート名を入力してください'),
                                    backgroundColor: WanMapColors.error,
                                  ),
                                );
                                return;
                              }

                              final route = _gpsService.stopRecording(
                                userId: userId,
                                title: title,
                                description: descriptionController.text.trim(),
                                isPublic: isPublic,
                              );
                              
                              Navigator.pop(context);

                              if (route != null && mounted) {
                                _saveRouteToSupabase(route);
                                
                                // 保存成功後、ホーム画面に戻る
                                Future.delayed(const Duration(milliseconds: 500), () {
                                  if (mounted) {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// ポイント更新タイマー
  void _startPointUpdateTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_isRecording && mounted) {
        setState(() {
          _routePoints = _gpsService.currentRoutePoints
              .map((point) => point.latLng)
              .toList();
        });
        _startPointUpdateTimer();
      }
    });
  }

  /// Supabase にルートを保存
  Future<void> _saveRouteToSupabase(RouteModel route) async {
    if (kDebugMode) {
      print('🔵 保存処理開始');
    }
    if (kDebugMode) {
      print('🔵 ルート情報: title=${route.title}, points=${route.points.length}, distance=${route.distance}');
    }
    
    try {
      if (kDebugMode) {
        print('🔵 routesテーブルに保存中...');
      }
      
      // routes テーブルに保存
      final routeData = await SupabaseConfig.client.from('routes').insert({
        'user_id': route.userId,
        'dog_id': route.dogId,
        'title': route.title,
        'description': route.description,
        'distance': route.distance,
        'duration': route.duration,
        'started_at': route.startedAt.toIso8601String(),
        'ended_at': route.endedAt?.toIso8601String(),
        'is_public': route.isPublic,
      }).select().single();

      final routeId = routeData['id'];
      if (kDebugMode) {
        print('🟢 routesテーブルに保存成功: routeId=$routeId');
      }

      // route_points テーブルにポイントを保存
      if (kDebugMode) {
        print('🔵 route_pointsテーブルに${route.points.length}件保存中...');
      }
      
      final pointsData = route.points.asMap().entries.map((entry) {
        final point = entry.value;
        return {
          'route_id': routeId,
          'latitude': point.latLng.latitude,
          'longitude': point.latLng.longitude,
          'altitude': point.altitude,
          'timestamp': point.timestamp.toIso8601String(),
          'sequence_number': point.sequenceNumber,
        };
      }).toList();

      await SupabaseConfig.client.from('route_points').insert(pointsData);
      if (kDebugMode) {
        print('🟢 route_pointsテーブルに保存成功');
      }

      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;  // 一時停止状態をリセット
          _routePoints.clear();
          _tempPhotoUrls.clear();  // 一時写真URLをクリア
          _pauseStartTime = null;  // 一時停止開始時刻をリセット
          _totalPauseDuration = Duration.zero;  // 累積一時停止時間をリセット
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ルートを保存しました\n距離: ${route.formatDistance()}, 時間: ${route.formatDuration()}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (kDebugMode) {
        print('✅ ルートをSupabaseに保存しました: $routeId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ ルート保存エラー: $e');
      }
      if (kDebugMode) {
        print('❌ スタックトレース: $stackTrace');
      }
      
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;  // 一時停止状態をリセット
          _routePoints.clear();
          _tempPhotoUrls.clear();  // 一時写真URLをクリア
          _pauseStartTime = null;  // 一時停止開始時刻をリセット
          _totalPauseDuration = Duration.zero;  // 累積一時停止時間をリセット
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ルートの保存に失敗しました\n$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: WanMapColors.primaryGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    // 距離と時間の計算（currentRoutePointsから計算）
    double distance = 0.0;
    int duration = 0;
    final points = _gpsService.currentRoutePoints;
    
    if (points.isNotEmpty) {
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i].latLng;
        final p2 = points[i + 1].latLng;
        distance += Geolocator.distanceBetween(
          p1.latitude, p1.longitude,
          p2.latitude, p2.longitude,
        );
      }
      if (points.length > 1) {
        duration = points.last.timestamp.difference(points.first.timestamp).inSeconds;
      }
    }
    
    final pace = distance > 0 ? duration / distance * 1000 : 0.0; // 秒/km

    return Scaffold(
      backgroundColor: isDark 
          ? WanMapColors.backgroundDark 
          : WanMapColors.backgroundLight,
      body: Stack(
        children: [
          // 背景のマップ（全画面）
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentPosition ?? const LatLng(35.6762, 139.6503),
              zoom: 15.0,
            ),
            children: [
              // OpenStreetMapタイル
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.doghub.wanmap',
              ),
              
              // 記録中のルート
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: WanMapColors.accent,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              
              // 現在位置マーカー
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: WanMapColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 半透明オーバーレイ（記録中のみ）
          if (_isRecording)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

          // 上部の統計カード
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopStatsCard(context, distance, duration, pace),
          ),

          // 下部のコントロールパネル
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(context),
          ),

          // 現在位置ボタン
          Positioned(
            right: WanMapSpacing.lg,
            bottom: 200,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 28,
                icon: Icon(
                  Icons.my_location,
                  color: WanMapColors.accent,
                ),
                onPressed: () async {
                  final position = await _gpsService.getCurrentPosition();
                  if (position != null) {
                    setState(() {
                      _currentPosition = position;
                    });
                    _mapController.move(position, 15.0);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 上部の統計カード（Nike Run Club風）
  Widget _buildTopStatsCard(BuildContext context, double distance, int duration, double pace) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final distanceKm = distance / 1000;
    final durationMinutes = duration ~/ 60;
    final durationSeconds = duration % 60;
    final paceMinutes = pace.isFinite ? pace ~/ 60 : 0;
    final paceSeconds = pace.isFinite ? (pace % 60).toInt() : 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? WanMapColors.surfaceDark.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(WanMapSpacing.radiusXXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.only(
        top: 60, // ステータスバー分
        bottom: WanMapSpacing.xl,
        left: WanMapSpacing.xl,
        right: WanMapSpacing.xl,
      ),
      child: Column(
        children: [
          // 記録中インジケーター
          if (_isRecording) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: WanMapColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: WanMapSpacing.xs),
                Text(
                  '記録中',
                  style: WanMapTypography.labelLarge.copyWith(
                    color: WanMapColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: WanMapSpacing.lg),
          ],

          // メイン距離表示（超大サイズ）
          WanMapHeroStat(
            value: distanceKm.toStringAsFixed(2),
            unit: 'km',
            label: '距離',
          ),
          
          const SizedBox(height: WanMapSpacing.xl),
          
          // サブ統計（時間・ペース）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubStat(
                context,
                icon: Icons.access_time,
                value: durationMinutes.toString().padLeft(2, '0'),
                subValue: durationSeconds.toString().padLeft(2, '0'),
                label: '時間',
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark 
                    ? WanMapColors.textTertiaryDark 
                    : WanMapColors.textTertiaryLight,
              ),
              _buildSubStat(
                context,
                icon: Icons.speed,
                value: paceMinutes.toString().padLeft(2, '0'),
                subValue: paceSeconds.toString().padLeft(2, '0'),
                label: 'ペース/km',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// サブ統計アイテム
  Widget _buildSubStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String subValue,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark 
        ? WanMapColors.textPrimaryDark 
        : WanMapColors.textPrimaryLight;
    final secondaryColor = isDark 
        ? WanMapColors.textSecondaryDark 
        : WanMapColors.textSecondaryLight;

    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: WanMapColors.accent,
        ),
        const SizedBox(height: WanMapSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: textColor,
                height: 1.0,
              ),
            ),
            Text(
              ':',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            Text(
              subValue,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: textColor,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: WanMapSpacing.xxs),
        Text(
          label,
          style: WanMapTypography.labelSmall.copyWith(
            color: secondaryColor,
          ),
        ),
      ],
    );
  }

  /// 下部のコントロールパネル
  Widget _buildBottomControls(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? WanMapColors.surfaceDark.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(WanMapSpacing.radiusXXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(WanMapSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // メインコントロールボタン
            WanMapButton(
              text: _isRecording ? 'お散歩を終了' : 'お散歩を開始',
              icon: _isRecording ? Icons.stop : Icons.play_arrow,
              size: WanMapButtonSize.large,
              fullWidth: true,
              variant: _isRecording 
                  ? WanMapButtonVariant.outlined 
                  : WanMapButtonVariant.primary,
              onPressed: () {
                if (_isRecording) {
                  _stopRecording();
                } else {
                  _startRecording();
                }
              },
            ),
            
            // 一時停止ボタン（記録中のみ）
            if (_isRecording) ...[
              const SizedBox(height: WanMapSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: WanMapButton(
                      text: _isPaused ? '再開' : '一時停止',
                      icon: _isPaused ? Icons.play_arrow : Icons.pause,
                      size: WanMapButtonSize.small,
                      variant: WanMapButtonVariant.outlined,
                      onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                    ),
                  ),
                  const SizedBox(width: WanMapSpacing.md),
                  Expanded(
                    child: WanMapButton(
                      text: _tempPhotoUrls.isEmpty 
                          ? '写真' 
                          : '写真 (${_tempPhotoUrls.length})',
                      icon: Icons.camera_alt,
                      size: WanMapButtonSize.small,
                      variant: WanMapButtonVariant.secondary,
                      onPressed: _takePhoto,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
