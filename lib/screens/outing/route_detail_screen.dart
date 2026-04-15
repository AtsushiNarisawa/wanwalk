import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../providers/official_route_provider.dart';
import '../../widgets/nearby_dog_spots.dart';
import '../../providers/route_pin_provider.dart';
import '../../providers/gps_provider_riverpod.dart';
import '../../providers/pin_like_provider.dart';
import '../../providers/pin_bookmark_provider.dart';
import '../../providers/pin_comment_provider.dart';
import '../../providers/route_spots_provider.dart';
import '../../widgets/phase1/spec_bar.dart';
import '../../widgets/phase1/pin_card.dart';
import '../../widgets/phase1/pet_info_grid.dart';
import '../../widgets/phase1/route_actions.dart';

import '../../models/official_route.dart';
import '../../models/route_spot.dart';
import '../../models/walk_mode.dart';
import 'walking_screen.dart';
import 'pin_detail_screen.dart';
import 'pin_comment_screen.dart';
import '../daily/daily_walking_screen.dart';
import '../../utils/logger.dart';

/// ルート詳細画面
/// 公式ルートの詳細情報とピン一覧を表示
class RouteDetailScreen extends ConsumerStatefulWidget {
  final String routeId;

  const RouteDetailScreen({
    super.key,
    required this.routeId,
  });

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  // ピンをすべて表示するかどうかの状態
  bool _showAllPins = false;
  
  // MapController：地図の中心とズームを動的に制御
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routeAsync = ref.watch(routeByIdProvider(widget.routeId));
    final pinsAsync = ref.watch(pinsByRouteProvider(widget.routeId));

    return Scaffold(
      backgroundColor: isDark
          ? WanWalkColors.backgroundDark
          : WanWalkColors.backgroundLight,
      appBar: AppBar(
        title: const Text('ルート詳細'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          routeAsync.maybeWhen(
            data: (route) => route != null
                ? Row(
                    children: [
                      BookmarkButton(routeId: route.id),
                      ShareButton(
                        routeName: route.name,
                        areaName: null,
                        slug: null,
                      ),
                      const SizedBox(width: 4),
                    ],
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: routeAsync.maybeWhen(
        data: (route) => route != null ? _buildFAB(context, isDark, route) : null,
        orElse: () => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: routeAsync.when(
        data: (route) {
          if (route == null) {
            return const Center(child: Text('ルートが見つかりません'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 地図セクション
                _buildMapSection(route, pinsAsync, isDark),
                Padding(
                  padding: const EdgeInsets.all(WanWalkSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // ルート名
                  Text(
                    route.name,
                    style: WanWalkTypography.headlineMedium.copyWith(
                      color: isDark
                          ? WanWalkColors.textPrimaryDark
                          : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: WanWalkSpacing.md),

                  // コミュニティメッセージ + フィードバック導線
                  _buildCommunityNote(isDark),

                  const SizedBox(height: WanWalkSpacing.xl),

                  // 統計情報
                  _buildStats(route, isDark),

                  const SizedBox(height: WanWalkSpacing.xl),

                  // 説明
                  _buildDescription(route, isDark),

                  const SizedBox(height: WanWalkSpacing.xl),

                  // ギャラリーセクション（ルートの写真）
                  if (route.galleryImages != null && route.galleryImages!.isNotEmpty) ...[
                    _buildGallerySection(route, isDark),
                    const SizedBox(height: WanWalkSpacing.xl),
                  ],

                  // ルートタイムライン（スポット情報）
                  _buildRouteTimelineSection(route.id, isDark),

                  const SizedBox(height: WanWalkSpacing.xl),

                  // 愛犬家向け情報
                  if (route.petInfo != null && route.petInfo!.hasAnyInfo) ...[
                    _buildPetInfoSection(route.petInfo!, isDark),
                    const SizedBox(height: WanWalkSpacing.xl),
                  ] else ...[
                    // pet_infoがなくてもフィードバックリンクを表示
                    _buildFeedbackOnlyLink(isDark),
                    const SizedBox(height: WanWalkSpacing.xl),
                  ],

                  // 周辺の犬連れスポット（箱根エリアのルートのみ表示）
                  if (route.areaId.startsWith('a1111111-1111-1111-1111-11111111111')) ...[
                    const SizedBox(height: WanWalkSpacing.md),
                    NearbyDogSpots(areaId: route.areaId, isDark: isDark),
                  ],

                  const SizedBox(height: WanWalkSpacing.xl),

                  // ピンセクション
                  _buildPinsSection(context, ref, pinsAsync, isDark),
                  
                  // FABの高さ分のスペース確保
                  const SizedBox(height: 80),
                ],
              ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  /// 地図セクション
  Widget _buildMapSection(OfficialRoute route, AsyncValue pinsAsync, bool isDark) {
    final spotsAsync = ref.watch(routeSpotsProvider(route.id));

    final spots = spotsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <RouteSpot>[],
    );

    final pins = pinsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => [],
    );

    // 全ポイント（ルートライン優先 + spots 補完）。fitCamera に渡す。
    final allPoints = <LatLng>[
      if (route.routeLine != null) ...route.routeLine!,
      ...spots.map((s) => s.location),
    ];

    if (allPoints.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(allPoints);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(40),
          ),
        );
      });
    }

    final initialCenter = allPoints.isNotEmpty
        ? allPoints.first
        : route.startLocation;

    return Container(
      height: 300,
      color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: 15.0,
          minZoom: 10.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.doghub.wanwalk',
          ),
          // ルートライン（DESIGN_TOKENS.md §12-A）
          if (route.routeLine != null && route.routeLine!.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: route.routeLine!,
                  strokeWidth: 6.0,
                  color: WanWalkColors.accentPrimary,
                  borderStrokeWidth: 2.0,
                  borderColor: Colors.white,
                ),
              ],
            )
          else if (spots.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: spots.map((spot) => spot.location).toList(),
                  strokeWidth: 6.0,
                  color: WanWalkColors.accentPrimary,
                  borderStrokeWidth: 2.0,
                  borderColor: Colors.white,
                ),
              ],
            ),
          // ルートスポットマーカー
          // ルートスポットマーカー
          if (spots.isNotEmpty)
            MarkerLayer(
              markers: _buildSpotMarkers(spots, isDark),
            ),
          // スタート/ゴールマーカー（スポットがない場合のフォールバック）
          if (spots.isEmpty)
            MarkerLayer(markers: _buildMarkers(route)),
          // ピンマーカー
          if (pins.isNotEmpty)
            MarkerLayer(
              markers: pins.map<Marker>((pin) {
                return Marker(
                  point: pin.location,
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    color: WanWalkColors.accent,
                    size: 40,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
  /// マーカーを構築（スタート=ゴールの場合は1色の単一マーカー）
  List<Marker> _buildMarkers(OfficialRoute route) {
    
    // route_lineが存在する場合は、その最初と最後の点を使用
    final actualStart = route.routeLine != null && route.routeLine!.isNotEmpty
        ? route.routeLine!.first
        : route.startLocation;
    final actualEnd = route.routeLine != null && route.routeLine!.isNotEmpty
        ? route.routeLine!.last
        : route.endLocation;
    
    
    final isSameLocation = actualStart.latitude == actualEnd.latitude &&
                           actualStart.longitude == actualEnd.longitude;

    if (isSameLocation) {
      // スタート=ゴール: accent-primary 1色の単一マーカー
      return [
        Marker(
          alignment: Alignment.center,
          point: actualStart,
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: WanWalkColors.accentPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ];
    }

    // スタート≠ゴール: スタート accent-primary / ゴール accent-primary-hover
    return [
      Marker(
        alignment: Alignment.center,
        point: actualStart,
        width: 32,
        height: 32,
        child: Container(
          decoration: BoxDecoration(
            color: WanWalkColors.accentPrimary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
      Marker(
        alignment: Alignment.center,
        point: actualEnd,
        width: 32,
        height: 32,
        child: Container(
          decoration: BoxDecoration(
            color: WanWalkColors.accentPrimaryHover,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    ];
  }
  /// Phase 1: SpecBar（距離・所要時間・高低差・難易度）
  Widget _buildStats(OfficialRoute route, bool isDark) {
    return SpecBar.fromRoute(route);
  }

  /// 説明
  Widget _buildDescription(OfficialRoute route, bool isDark) {
    // 体験ストーリーを段落に分割
    final paragraphs = route.description
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ルートについて',
          style: WanWalkTypography.headlineSmall.copyWith(
            color: isDark
                ? WanWalkColors.textPrimaryDark
                : WanWalkColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanWalkSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(WanWalkSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 段落ごとに表示（段落間に区切り線）
              for (int i = 0; i < paragraphs.length; i++) ...[
                if (i > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: WanWalkSpacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          i == 1 ? Icons.hiking : Icons.flag,
                          size: 14,
                          color: WanWalkColors.accent.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: (isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight).withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Text(
                  paragraphs[i],
                  style: WanWalkTypography.bodyMedium.copyWith(
                    color: isDark
                        ? WanWalkColors.textPrimaryDark
                        : WanWalkColors.textPrimaryLight,
                    height: 1.6,
                  ),
                ),
              ],
              const SizedBox(height: WanWalkSpacing.md),
              _DifficultyBadge(
                level: route.difficultyLevel,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 散歩を開始ボタン（散歩中の場合は「進行中の散歩に戻る」ボタンに変更）
  /// Floating Action Button（散歩開始ボタン）
  Widget _buildFAB(BuildContext context, bool isDark, OfficialRoute route) {
    final gpsState = ref.watch(gpsProviderRiverpod);
    final isRecording = gpsState.isRecording;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
      width: double.infinity,
      height: 56,
      child: FloatingActionButton.extended(
        onPressed: () {
          if (isRecording) {
            // 散歩中の場合：進行中の散歩画面へ遷移
            _navigateToActiveWalk(context, gpsState);
          } else {
            // 散歩中でない場合：新しい散歩を開始
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WalkingScreen(route: route),
              ),
            );
          }
        },
        backgroundColor: isRecording 
            ? WanWalkColors.secondary  // 散歩中は異なる色
            : WanWalkColors.accent,
        elevation: 8,
        icon: Icon(
          isRecording ? Icons.my_location : Icons.directions_walk, 
          size: 28,
          color: Colors.white,
        ),
        label: Text(
          isRecording ? '進行中の散歩に戻る' : 'このルートを歩く',
          style: WanWalkTypography.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 進行中の散歩画面へ遷移
  void _navigateToActiveWalk(BuildContext context, GpsState gpsState) {
    if (gpsState.walkMode == WalkMode.daily) {
      // Daily Walk画面へ遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DailyWalkingScreen(),
        ),
      );
    } else {
      // Outing Walk: マップタブから確認する案内
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('別のルートを散歩中です。画面下部のバナーから確認してください。'),
          backgroundColor: WanWalkColors.secondary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Phase 1: みどころセクション（B案: route_spots 全件 + gallery_images フォールバック + 番号タイル）
  Widget _buildRouteTimelineSection(String routeId, bool isDark) {
    final spotsAsync = ref.watch(routeSpotsProvider(routeId));
    final routeAsync = ref.watch(routeByIdProvider(routeId));

    return spotsAsync.when(
      data: (spots) {
        if (spots.isEmpty) {
          return const SizedBox.shrink();
        }
        final sortedSpots = [...spots]
          ..sort((a, b) => a.spotOrder.compareTo(b.spotOrder));

        final gallery = routeAsync.maybeWhen(
          data: (route) => route?.galleryImages ?? const <String>[],
          orElse: () => const <String>[],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'みどころ',
              style: TextStyle(
                fontFamily: 'NotoSerifJP',
                fontWeight: FontWeight.w600,
                fontSize: 22,
                height: 1.4,
                color: WanWalkColors.textPrimary,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.s5),
            ...sortedSpots.map((spot) {
              String? photoUrl;
              final idx = spot.spotOrder - 1;
              if (idx >= 0 && idx < gallery.length && gallery[idx].isNotEmpty) {
                photoUrl = gallery[idx];
              }
              return PinCard(spot: spot, photoUrl: photoUrl);
            }),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(WanWalkSpacing.lg),
          child: CircularProgressIndicator(
            color: WanWalkColors.accentPrimary,
          ),
        ),
      ),
      error: (error, stack) {
        appLog('❌ スポット情報取得エラー: $error');
        return const SizedBox.shrink();
      },
    );
  }

  /// スポットカードの構築
  Widget _buildSpotCard(RouteSpot spot, int index, bool isLast, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タイムライン表示（縦線とアイコン）
        Column(
          children: [
            _buildSpotIcon(spot.spotType, index, isDark),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: WanWalkSpacing.md),
        // スポット情報
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: WanWalkSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // スポット名とタイプ
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spot.name,
                        style: WanWalkTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? WanWalkColors.textPrimaryDark
                              : WanWalkColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    if (spot.isOptional)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: WanWalkColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '立ち寄り任意',
                          style: WanWalkTypography.caption.copyWith(
                            color: WanWalkColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // 距離と時間
                Text(
                  'スタートから ${spot.formattedDistance} • ${spot.formattedTime}',
                  style: WanWalkTypography.bodySmall.copyWith(
                    color: isDark
                        ? WanWalkColors.textSecondaryDark
                        : WanWalkColors.textSecondaryLight,
                  ),
                ),
                // 説明（基本情報のみ）
                if (spot.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    spot.description!,
                    style: WanWalkTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanWalkColors.textPrimaryDark
                          : WanWalkColors.textPrimaryLight,
                    ),
                  ),
                ],
                // アクティビティ提案（最大2個まで表示）
                if (spot.activitySuggestions != null &&
                    spot.activitySuggestions!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: spot.activitySuggestions!.take(2).map((activity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity,
                          style: WanWalkTypography.caption.copyWith(
                            color: Colors.blue,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                // 公式HPリンク（Tipsにリンクがある場合）
                if (spot.tips != null && _extractURL(spot.tips!) != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchURL(_extractURL(spot.tips!)!),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '詳細情報を見る',
                          style: WanWalkTypography.caption.copyWith(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// TipsテキストからURLを抽出
  String? _extractURL(String tips) {
    final urlPattern = RegExp(r'https?://[^\s]+');
    final match = urlPattern.firstMatch(tips);
    return match?.group(0);
  }

  /// URLを開くヘルパーメソッド
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      appLog('Could not launch $urlString');
    }
  }

  /// スポットタイプに応じたアイコン
  Widget _buildSpotIcon(RouteSpotType spotType, int index, bool isDark) {
    IconData? icon;
    Color color;
    bool showNumber = false;
    int? spotNumber;

    switch (spotType) {
      case RouteSpotType.start:
        icon = Icons.flag;
        color = const Color(0xFF4CAF50); // 緑（スタート）
        break;
      case RouteSpotType.landscape:
      case RouteSpotType.photoSpot:
      case RouteSpotType.facility:
        // 中間スポットは番号で表示
        color = Colors.grey; // グレー
        showNumber = true;
        spotNumber = index; // インデックスをそのまま使用
        break;
      case RouteSpotType.end:
        icon = Icons.sports_score;
        color = const Color(0xFFF44336); // 赤（ゴール）
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: showNumber
          ? Center(
              child: Text(
                '$spotNumber',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Icon(icon, color: color, size: 20),
    );
  }

  /// マップ用のスポットアイコン（スタート/ゴールは特に強調）
  /// スポットマーカーを構築（スタート=ゴールの場合は1つに統合）
  List<Marker> _buildSpotMarkers(List<RouteSpot> spots, bool isDark) {
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
          // スタート=ゴールの場合、半分緑・半分赤のマーカーを作成
          appLog('🎯 Start=Goal detected at ${spot.name}');
          markers.add(Marker(
            point: spot.location,
            width: 60.0,
            height: 60.0,
            alignment: Alignment.center,
            child: _buildStartGoalMarker(isDark),
          ));
          processedIndices.add(i);
          processedIndices.add(goalIndex);
          continue;
        }
      }
      
      // ゴール地点でスタートと同じ位置の場合はスキップ（既に処理済み）
      if (isEnd) {
        final startIndex = spots.indexWhere((s) => 
          s.spotType == RouteSpotType.start && 
          _isSameLocation(s.location, spot.location)
        );
        if (startIndex != -1 && processedIndices.contains(startIndex)) {
          continue;
        }
      }
      
      // 通常のマーカー
      final isStartOrEnd = isStart || isEnd;
      final markerSize = isStartOrEnd ? 50.0 : 35.0; // サイズを小さく
      
      markers.add(Marker(
        point: spot.location,
        width: markerSize,
        height: markerSize,
        alignment: Alignment.center,
        child: _buildSpotMapIcon(spot.spotType, i, isDark, isStartOrEnd),
      ));
      processedIndices.add(i);
    }
    
    return markers;
  }
  
  /// 2つの位置が同じかチェック（緯度経度の差が0.0001度未満）
  bool _isSameLocation(LatLng loc1, LatLng loc2) {
    const threshold = 0.0001; // 約10m
    return (loc1.latitude - loc2.latitude).abs() < threshold &&
           (loc1.longitude - loc2.longitude).abs() < threshold;
  }
  
  /// スタート=ゴールの統合マーカー（accent-primary 1色、影なし）
  Widget _buildStartGoalMarker(bool isDark) {
    return Container(
      width: 32.0,
      height: 32.0,
      decoration: BoxDecoration(
        color: WanWalkColors.accentPrimary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.0),
      ),
    );
  }

  Widget _buildSpotMapIcon(RouteSpotType spotType, int index, bool isDark, bool isStartOrEnd) {
    Color color;
    bool showNumber = false;
    int? spotNumber;

    switch (spotType) {
      case RouteSpotType.start:
        color = WanWalkColors.accentPrimary;
        break;
      case RouteSpotType.end:
        color = WanWalkColors.accentPrimaryHover;
        break;
      case RouteSpotType.landscape:
      case RouteSpotType.photoSpot:
      case RouteSpotType.facility:
        color = WanWalkColors.textSecondary;
        showNumber = true;
        spotNumber = index;
        break;
    }

    final containerSize = isStartOrEnd ? 32.0 : 28.0;
    final borderWidth = 2.0;
    const numberFontSize = 13.0;

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: borderWidth),
      ),
      child: showNumber
          ? Center(
              child: Text(
                '$spotNumber',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: numberFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  /// Phase 1: 犬連れメモ（PetInfoGrid）+ 情報フィードバック
  Widget _buildPetInfoSection(PetInfo petInfo, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '犬連れメモ',
          style: TextStyle(
            fontFamily: 'NotoSerifJP',
            fontWeight: FontWeight.w600,
            fontSize: 22,
            height: 1.4,
            color: WanWalkColors.textPrimary,
          ),
        ),
        const SizedBox(height: WanWalkSpacing.s5),
        PetInfoGrid(info: petInfo),
        const SizedBox(height: WanWalkSpacing.s3),
        InkWell(
          onTap: () => _showFeedbackSheet(context),
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: WanWalkSpacing.s3,
                vertical: WanWalkSpacing.s3),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_note,
                  size: 18,
                  color: WanWalkColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '情報の修正を提案する',
                  style: WanWalkTypography.wwBodySm.copyWith(
                    color: WanWalkColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 愛犬家向け情報の個別アイテム
  Widget _buildPetInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: WanWalkColors.accent,
          size: 24,
        ),
        const SizedBox(width: WanWalkSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: WanWalkTypography.bodySmall.copyWith(
                  color: isDark
                      ? WanWalkColors.textSecondaryDark
                      : WanWalkColors.textSecondaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: WanWalkTypography.bodyMedium.copyWith(
                  color: isDark
                      ? WanWalkColors.textPrimaryDark
                      : WanWalkColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ピンセクション
  Widget _buildPinsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue pinsAsync,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'みんなのピン',
          style: WanWalkTypography.headlineSmall.copyWith(
            color: isDark
                ? WanWalkColors.textPrimaryDark
                : WanWalkColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanWalkSpacing.md),
        pinsAsync.when(
          data: (pins) {
            if (pins.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(WanWalkSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.push_pin_outlined,
                        size: 48,
                        color: isDark
                            ? WanWalkColors.textSecondaryDark
                            : WanWalkColors.textSecondaryLight,
                      ),
                      const SizedBox(height: WanWalkSpacing.md),
                      Text(
                        'まだピンがありません',
                        style: WanWalkTypography.bodyLarge.copyWith(
                          color: isDark
                              ? WanWalkColors.textSecondaryDark
                              : WanWalkColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            // 表示するピンの数を決定
            final displayPins = _showAllPins ? pins : pins.take(3).toList();
            final hasMorePins = pins.length > 3;
            
            return Column(
              children: [
                // ピンカードリスト
                ...displayPins.map<Widget>((pin) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: WanWalkSpacing.md),
                  child: GestureDetector(
                    onTap: () {
                      // ピン詳細画面へ遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PinDetailScreen(pinId: pin.id),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // サムネイル画像（固定サイズ120x120）
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: pin.hasPhotos
                                  ? Image.network(
                                      pin.photoUrls.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildDefaultPinImage(),
                                    )
                                  : _buildDefaultPinImage(),
                            ),
                          // テキスト情報
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(WanWalkSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // タイトル
                                  Text(
                                    pin.title,
                                    style: WanWalkTypography.bodyMedium.copyWith(
                                      color: isDark
                                          ? WanWalkColors.textPrimaryDark
                                          : WanWalkColors.textPrimaryLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: WanWalkSpacing.xs),
                                  // コメント
                                  Text(
                                    pin.comment,
                                    style: WanWalkTypography.bodySmall.copyWith(
                                      color: isDark
                                          ? WanWalkColors.textSecondaryDark
                                          : WanWalkColors.textSecondaryLight,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: WanWalkSpacing.sm),
                                  // いいね・コメント・ブックマーク・相対時間
                                  Row(
                                    children: [
                                      _PinLikeButton(
                                        pinId: pin.id,
                                        initialLikesCount: pin.likesCount,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(width: WanWalkSpacing.sm),
                                      _PinCommentButton(
                                        pinId: pin.id,
                                        pinTitle: pin.title,
                                        initialCommentsCount: pin.commentsCount,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(width: WanWalkSpacing.sm),
                                      _PinBookmarkButton(
                                        pinId: pin.id,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(width: WanWalkSpacing.sm),
                                      Text(
                                        pin.relativeTime,
                                        style: WanWalkTypography.caption.copyWith(
                                          color: isDark
                                              ? WanWalkColors.textSecondaryDark
                                              : WanWalkColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
                
                // 「もっと見る」/「閉じる」ボタン
                if (hasMorePins)
                  Padding(
                    padding: const EdgeInsets.only(top: WanWalkSpacing.md),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAllPins = !_showAllPins;
                        });
                      },
                      icon: Icon(_showAllPins ? Icons.expand_less : Icons.expand_more),
                      label: Text(
                        _showAllPins 
                            ? '閉じる' 
                            : 'もっと見る (残り${pins.length - 3}件)',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WanWalkColors.accent,
                        side: BorderSide(color: WanWalkColors.accent),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('エラー: $error'),
        ),
      ],
    );
  }

  /// デフォルトピン画像
  Widget _buildDefaultPinImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: WanWalkColors.accent.withOpacity(0.2),
      ),
      child: Icon(
        Icons.photo,
        size: 40,
        color: WanWalkColors.accent,
      ),
    );
  }

  /// ギャラリーセクション
  Widget _buildGallerySection(OfficialRoute route, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションタイトル
        Text(
          'ルートの写真',
          style: WanWalkTypography.headlineSmall.copyWith(
            color: isDark
                ? WanWalkColors.textPrimaryDark
                : WanWalkColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanWalkSpacing.md),
        // ギャラリー画像（横スクロール）
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
            itemCount: route.galleryImages!.length,
            itemBuilder: (context, index) {
              final imageUrl = route.galleryImages![index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < route.galleryImages!.length - 1
                      ? WanWalkSpacing.md
                      : 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 280,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 280,
                        height: 200,
                        color: isDark
                            ? WanWalkColors.surfaceDark
                            : WanWalkColors.surfaceLight,
                        child: Icon(
                          Icons.image_not_supported,
                          color: isDark
                              ? WanWalkColors.textSecondaryDark
                              : WanWalkColors.textSecondaryLight,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// ルート名の下に表示するコミュニティメッセージ
  Widget _buildCommunityNote(bool isDark) {
    final noteColor = isDark
        ? WanWalkColors.textSecondaryDark
        : WanWalkColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? WanWalkColors.cardDark
            : const Color(0xFFF9F7F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'このルートの情報は最新でない場合があります。'
            'お気づきの点があれば、ぜひ教えてください。'
            'みなさんの声でルート情報を一緒に育てていきます。',
            style: WanWalkTypography.bodySmall.copyWith(
              color: noteColor,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showFeedbackSheet(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note, size: 16, color: WanWalkColors.accent),
                const SizedBox(width: 4),
                Text(
                  '情報の修正を提案する',
                  style: WanWalkTypography.bodySmall.copyWith(
                    color: WanWalkColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// pet_infoがないルート用のフィードバックリンク
  Widget _buildFeedbackOnlyLink(bool isDark) {
    return InkWell(
      onTap: () => _showFeedbackSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.edit_note,
              size: 20,
              color: isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
            ),
            const SizedBox(width: 8),
            Text(
              'このルートの情報を教える',
              style: WanWalkTypography.bodySmall.copyWith(
                color: isDark
                    ? WanWalkColors.textSecondaryDark
                    : WanWalkColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 情報フィードバック用ボトムシート
  void _showFeedbackSheet(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('フィードバックを送るにはログインが必要です')),
      );
      return;
    }

    // ルート詳細画面のScaffoldMessengerを保持（シート閉じた後にSnackBar表示するため）
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FeedbackSheet(
        routeId: widget.routeId,
        userId: user.id,
        scaffoldMessenger: scaffoldMessenger,
      ),
    );
  }
}

/// 情報フィードバック送信シート
class _FeedbackSheet extends StatefulWidget {
  final String routeId;
  final String userId;
  final ScaffoldMessengerState scaffoldMessenger;

  const _FeedbackSheet({
    required this.routeId,
    required this.userId,
    required this.scaffoldMessenger,
  });

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _messageController = TextEditingController();
  String _selectedCategory = 'other';
  bool _isSubmitting = false;

  static const _categories = {
    'parking': '駐車場',
    'surface': '道の状態',
    'water_station': '水飲み場',
    'restroom': 'トイレ',
    'pet_facilities': 'ペット施設',
    'other': 'その他',
  };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      widget.scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('修正内容を入力してください')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await Supabase.instance.client.from('route_feedback').insert({
        'route_id': widget.routeId,
        'user_id': widget.userId,
        'category': _selectedCategory,
        'message': message,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('ご報告ありがとうございます！確認後に反映します。')),
      );
    } catch (e) {
      if (!mounted) return;
      widget.scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('送信に失敗しました。もう一度お試しください。')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: WanWalkSpacing.lg,
          right: WanWalkSpacing.lg,
          top: WanWalkSpacing.lg,
          bottom: bottomInset + WanWalkSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ハンドル
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.lg),

            // タイトル
            Text(
              '情報の修正を提案',
              style: WanWalkTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? WanWalkColors.textPrimaryDark
                    : WanWalkColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '実際に訪れた方や地元の方の情報をお待ちしています',
              style: WanWalkTypography.bodySmall.copyWith(
                color: isDark
                    ? WanWalkColors.textSecondaryDark
                    : WanWalkColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.lg),

            // カテゴリ選択
            Text(
              'カテゴリ',
              style: WanWalkTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? WanWalkColors.textPrimaryDark
                    : WanWalkColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.entries.map((entry) {
                final selected = _selectedCategory == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  selectedColor: WanWalkColors.accent.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: selected
                        ? WanWalkColors.accent
                        : (isDark
                            ? WanWalkColors.textSecondaryDark
                            : WanWalkColors.textSecondaryLight),
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: selected
                        ? WanWalkColors.accent
                        : Colors.grey.withOpacity(0.3),
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: WanWalkSpacing.lg),

            // メッセージ入力
            Text(
              '修正内容',
              style: WanWalkTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? WanWalkColors.textPrimaryDark
                    : WanWalkColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.sm),
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: '例: 駐車場は現在500円に値上がりしています',
                hintStyle: TextStyle(
                  color: isDark
                      ? WanWalkColors.textSecondaryDark.withOpacity(0.5)
                      : WanWalkColors.textSecondaryLight.withOpacity(0.5),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: WanWalkColors.accent),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: WanWalkTypography.bodyMedium.copyWith(
                color: isDark
                    ? WanWalkColors.textPrimaryDark
                    : WanWalkColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.lg),

            // 送信ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WanWalkColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('送信する', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 統計カード
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: WanWalkColors.accent,
            size: 22,
          ),
          const SizedBox(height: 3.0),
          Text(
            label,
            style: WanWalkTypography.caption.copyWith(
              color: isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 3.0),
          Text(
            value,
            style: WanWalkTypography.bodyLarge.copyWith(
              color: isDark
                  ? WanWalkColors.textPrimaryDark
                  : WanWalkColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 14, // 若干フォントサイズを調整
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 難易度バッジ
class _DifficultyBadge extends StatelessWidget {
  final DifficultyLevel level;
  final bool isDark;

  const _DifficultyBadge({
    required this.level,
    required this.isDark,
  });

  Color _getColor() {
    switch (level) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.moderate:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.md,
        vertical: WanWalkSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getColor(),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            color: _getColor(),
            size: 20,
          ),
          const SizedBox(width: WanWalkSpacing.xs),
          Text(
            '難易度: ${level.label}',
            style: WanWalkTypography.bodyMedium.copyWith(
              color: _getColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: WanWalkSpacing.xs),
          Text(
            '(${level.description})',
            style: WanWalkTypography.caption.copyWith(
              color: _getColor(),
            ),
          ),
        ],
      ),
    );
  }
}

/// ピンいいねボタン - 楽観的UI更新対応
class _PinLikeButton extends ConsumerStatefulWidget {
  final String pinId;
  final int initialLikesCount;
  final bool isDark;

  const _PinLikeButton({
    required this.pinId,
    required this.initialLikesCount,
    required this.isDark,
  });

  @override
  ConsumerState<_PinLikeButton> createState() => _PinLikeButtonState();
}

class _PinLikeButtonState extends ConsumerState<_PinLikeButton> {
  @override
  void initState() {
    super.initState();
    // いいね状態を初期化
    Future.microtask(() {
      ref.read(pinLikeActionsProvider).initializePinLikeState(
        widget.pinId,
        widget.initialLikesCount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = ref.watch(pinLikedStateProvider(widget.pinId));
    final likeCount = ref.watch(pinLikeCountProvider(widget.pinId));
    final actions = ref.read(pinLikeActionsProvider);

    return GestureDetector(
      onTap: () async {
        final success = await actions.toggleLike(widget.pinId);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('いいねの更新に失敗しました')),
          );
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            size: 16,
            color: isLiked ? Colors.red : (widget.isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(width: 4),
          Text(
            '$likeCount',
            style: WanWalkTypography.caption.copyWith(
              color: widget.isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// ピンブックマークボタン - 楽観的UI更新対応
class _PinBookmarkButton extends ConsumerStatefulWidget {
  final String pinId;
  final bool isDark;

  const _PinBookmarkButton({
    required this.pinId,
    required this.isDark,
  });

  @override
  ConsumerState<_PinBookmarkButton> createState() => _PinBookmarkButtonState();
}

class _PinBookmarkButtonState extends ConsumerState<_PinBookmarkButton> {
  @override
  void initState() {
    super.initState();
    // ブックマーク状態を初期化
    Future.microtask(() {
      ref.read(pinBookmarkActionsProvider).initializePinBookmarkState(
        widget.pinId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBookmarked = ref.watch(pinBookmarkedStateProvider(widget.pinId));
    final actions = ref.read(pinBookmarkActionsProvider);

    return GestureDetector(
      onTap: () async {
        final success = await actions.toggleBookmark(widget.pinId);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ブックマークの更新に失敗しました')),
          );
        }
      },
      child: Icon(
        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        size: 16,
        color: isBookmarked 
            ? WanWalkColors.accent 
            : (widget.isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
    );
  }
}

/// ピンコメントボタン - 楽観的UI更新対応
class _PinCommentButton extends ConsumerStatefulWidget {
  final String pinId;
  final String pinTitle;
  final int initialCommentsCount;
  final bool isDark;

  const _PinCommentButton({
    required this.pinId,
    required this.pinTitle,
    required this.initialCommentsCount,
    required this.isDark,
  });

  @override
  ConsumerState<_PinCommentButton> createState() => _PinCommentButtonState();
}

class _PinCommentButtonState extends ConsumerState<_PinCommentButton> {
  @override
  void initState() {
    super.initState();
    // コメント数を初期化
    Future.microtask(() {
      ref.read(pinCommentActionsProvider).initializeCommentCount(
        widget.pinId,
        widget.initialCommentsCount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentCount = ref.watch(pinCommentCountProvider(widget.pinId));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PinCommentScreen(
              pinId: widget.pinId,
              pinTitle: widget.pinTitle,
            ),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 16,
            color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '$commentCount',
            style: WanWalkTypography.caption.copyWith(
              color: widget.isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

