import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show asin, cos, sin, sqrt;
import '../../../widgets/location_permission_dialog.dart';
import '../../../config/wanwalk_colors.dart';
import '../../../config/wanwalk_icons.dart';
import '../../../config/wanwalk_typography.dart';
import '../../../config/wanwalk_spacing.dart';
import '../../../providers/gps_provider_riverpod.dart';
import '../../../providers/official_route_provider.dart';
import '../../../providers/area_provider.dart';
import '../../../models/area.dart';
import '../../../providers/route_pin_provider.dart';

import '../../../models/official_route.dart';

import '../../../widgets/zoom_control_widget.dart';
import '../../outing/area_list_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../outing/pin_detail_screen.dart';
import '../../pin/pin_route_picker_screen.dart';
import '../../pin/pin_location_picker_screen.dart';
import '../../../utils/logger.dart';

/// MapTab - 全画面地図 + Bottom Sheet UI
/// 
/// 構成:
/// - 全画面地図表示
/// - 最寄りルート1件をカード表示
/// - スワイプ可能なBottom Sheet（近くのおすすめルート）
/// - 上部: 検索バー + エリア一覧ボタン
class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isFirstLoad = true;
  
  // Bottom Sheet制御
  late AnimationController _bottomSheetController;
  double _bottomSheetHeight = 110.0; // 最小化状態
  final double _minHeight = 110.0;
  final double _midHeight = 300.0;
  final double _maxHeight = 500.0;
  
  // 検索・フィルター
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = ''; // 検索キーワード

  @override
  void initState() {
    super.initState();
    _bottomSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // アプリ起動時に現在地を取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }
  
  /// 現在地を初期化
  Future<void> _initializeLocation() async {
    if (kDebugMode) {
      appLog('🗺️ MAP画面: GPS初期化開始');
    }
    final gpsNotifier = ref.read(gpsProviderRiverpod.notifier);
    await gpsNotifier.getCurrentLocation();
    
    final gpsState = ref.read(gpsProviderRiverpod);
    if (kDebugMode) {
      if (gpsState.currentLocation != null) {
        appLog('✅ MAP画面: GPS取得成功 ${gpsState.currentLocation!.latitude},${gpsState.currentLocation!.longitude}');
      } else {
        appLog('❌ MAP画面: GPS取得失敗');
      }
    }
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 現在地に移動
  Future<void> _moveToCurrentLocation() async {
    final gpsState = ref.read(gpsProviderRiverpod);
    if (gpsState.currentLocation != null) {
      _mapController.move(gpsState.currentLocation!, 15.0);
      setState(() {
        _currentLocation = gpsState.currentLocation;
      });
    } else {
      if (mounted) await showLocationPermissionDialog(context);
    }
  }

  /// Bottom Sheetの高さを切り替え
  void _toggleBottomSheetHeight() {
    setState(() {
      if (_bottomSheetHeight == _minHeight) {
        _bottomSheetHeight = _midHeight;
      } else if (_bottomSheetHeight == _midHeight) {
        _bottomSheetHeight = _maxHeight;
      } else {
        _bottomSheetHeight = _minHeight;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final areasAsync = ref.watch(areasProvider);
    
    // GPS情報を監視して現在地を更新
    final gpsState = ref.watch(gpsProviderRiverpod);
    if (gpsState.currentLocation != null && _currentLocation != gpsState.currentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentLocation = gpsState.currentLocation;
        });
        if (_isFirstLoad && _currentLocation != null) {
          _mapController.move(_currentLocation!, 13.0);
          _isFirstLoad = false;
        }
      });
    }

    return Scaffold(
      backgroundColor: WanWalkColors.bgPrimary,
      body: Stack(
        children: [
          // 全画面地図
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(35.3192, 139.5503),
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.doghub.wanwalk',
              ),
              // 現在地マーカー
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              // 全エリアのルートマーカー
              areasAsync.when(
                data: (areas) => _buildAllRoutesMarkers(context, ref, areas),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              // ユーザー投稿ピンマーカー
              _buildPinMarkers(context, ref),

            ],
          ),

          // 上部: 検索バー + エリア一覧ボタン
          _buildTopBar(isDark),

          // Bottom Sheet: 近くのおすすめルート
          _buildBottomSheet(isDark),

          // 右下: 現在地ボタン + ズームコントロール
          _buildMapControls(),

          // 右下: ピン投稿FAB
          _buildPinPostFAB(isDark),
        ],
      ),
    );
  }

  /// 上部バー: 検索 + エリア一覧ボタン
  Widget _buildTopBar(bool isDark) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: WanWalkSpacing.s4,
      right: WanWalkSpacing.s4,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: WanWalkColors.bgPrimary,
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          border: Border.all(color: WanWalkColors.borderSubtle, width: 1),
        ),
        child: Row(
          children: [
            // 検索アイコン
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Icon(
                WanWalkIcons.magnifyingGlass,
                color: WanWalkColors.textSecondary,
                size: WanWalkIcons.sizeMd,
              ),
            ),
            // 検索入力欄
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ルート名で検索',
                  hintStyle: WanWalkTypography.wwBody.copyWith(
                    color: WanWalkColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: WanWalkTypography.wwBody,
                onSubmitted: (value) {
                  setState(() {
                    _searchKeyword = value.trim();
                  });
                },
                onChanged: (value) {
                  setState(() {
                    _searchKeyword = value.trim();
                  });
                },
              ),
            ),
            // エリア一覧ボタン
            IconButton(
              icon: Icon(
                WanWalkIcons.list,
                color: WanWalkColors.textPrimary,
                size: WanWalkIcons.sizeMd,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AreaListScreen()),
                );
              },
              tooltip: 'エリア一覧',
            ),
          ],
        ),
      ),
    );
  }


  /// ルートカード（共通）
  Widget _buildRouteCard(OfficialRoute route, double distance, bool isDark, {bool isClosest = false}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailScreen(routeId: route.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(WanWalkSpacing.s4),
        decoration: BoxDecoration(
          color: WanWalkColors.bgPrimary,
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          border: Border.all(
            color: isClosest ? WanWalkColors.borderStrong : WanWalkColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // サムネイル
            ClipRRect(
              borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
              child: route.thumbnailUrl != null
                  ? Image.network(
                      route.thumbnailUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultThumbnail(),
                    )
                  : _buildDefaultThumbnail(),
            ),
            const SizedBox(width: WanWalkSpacing.s4),
            // ルート情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 最寄りバッジ
                  if (isClosest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: WanWalkColors.accentPrimarySoft,
                        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
                      ),
                      child: Text(
                        '最寄り',
                        style: WanWalkTypography.wwLabel.copyWith(
                          color: WanWalkColors.accentPrimary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  if (isClosest) const SizedBox(height: 6),
                  // ルート名
                  Text(
                    route.name,
                    style: WanWalkTypography.wwH4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 距離情報
                  Row(
                    children: [
                      Icon(
                        WanWalkIcons.personWalk,
                        size: WanWalkIcons.sizeXs,
                        color: WanWalkColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        route.formattedDistance,
                        style: WanWalkTypography.wwCaption,
                      ),
                      const SizedBox(width: WanWalkSpacing.s3),
                      Icon(
                        WanWalkIcons.mapPin,
                        size: WanWalkIcons.sizeXs,
                        color: WanWalkColors.accentPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)}km',
                        style: WanWalkTypography.wwNumeric.copyWith(
                          fontSize: 13,
                          color: WanWalkColors.accentPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 矢印アイコン
            Icon(
              WanWalkIcons.caretRight,
              size: WanWalkIcons.sizeSm,
              color: WanWalkColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Sheet: 近くのおすすめルート
  Widget _buildBottomSheet(bool isDark) {
    final gpsState = ref.watch(gpsProviderRiverpod);
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _bottomSheetHeight -= details.delta.dy;
            _bottomSheetHeight = _bottomSheetHeight.clamp(_minHeight, _maxHeight);
          });
        },
        onVerticalDragEnd: (details) {
          // スナップ動作
          setState(() {
            if (_bottomSheetHeight < (_minHeight + _midHeight) / 2) {
              _bottomSheetHeight = _minHeight;
            } else if (_bottomSheetHeight < (_midHeight + _maxHeight) / 2) {
              _bottomSheetHeight = _midHeight;
            } else {
              _bottomSheetHeight = _maxHeight;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          height: _bottomSheetHeight,
          decoration: BoxDecoration(
            color: WanWalkColors.bgPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(WanWalkSpacing.radiusLg)),
            border: Border(
              top: BorderSide(color: WanWalkColors.borderSubtle, width: 1),
              left: BorderSide(color: WanWalkColors.borderSubtle, width: 1),
              right: BorderSide(color: WanWalkColors.borderSubtle, width: 1),
            ),
          ),
          child: Column(
            children: [
              // ドラッグハンドル
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: WanWalkColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ヘッダー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.s4),
                child: Row(
                  children: [
                    Text(
                      '近くのおすすめルート',
                      style: WanWalkTypography.wwH3,
                    ),
                    const Spacer(),
                    // 展開/折りたたみボタン
                    IconButton(
                      icon: Icon(
                        _bottomSheetHeight == _minHeight
                            ? WanWalkIcons.caretUp
                            : WanWalkIcons.caretDown,
                        color: WanWalkColors.textPrimary,
                        size: WanWalkIcons.sizeMd,
                      ),
                      onPressed: _toggleBottomSheetHeight,
                    ),
                  ],
                ),
              ),
              // 最小化時は Divider とリストを非表示
              if (_bottomSheetHeight > _minHeight) ...[
                const Divider(height: 1),
                // ルートリスト
                Expanded(
                  child: gpsState.currentLocation == null
                      ? _buildLoadingState(isDark)
                      : _buildRoutesList(isDark),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ローディング状態
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            WanWalkIcons.mapPin,
            size: 40,
            color: WanWalkColors.textSecondary,
          ),
          const SizedBox(height: WanWalkSpacing.s3),
          Text(
            '現在地を取得中...',
            style: WanWalkTypography.wwCaption,
          ),
        ],
      ),
    );
  }

  /// ルートリスト
  Widget _buildRoutesList(bool isDark) {
    final gpsState = ref.watch(gpsProviderRiverpod);
    final routesAsync = ref.watch(allRoutesProvider);

    return routesAsync.when(
      data: (allRoutes) {
        final nearbyRoutes = _getRecommendedRoutes(gpsState.currentLocation!, allRoutes);
        
        // 検索キーワードでフィルタリング
        final filteredRoutes = _filterRoutesBySearch(nearbyRoutes);
        
        if (filteredRoutes.isEmpty) {
          return _buildEmptyState(isDark, isSearchResult: _searchKeyword.isNotEmpty);
        }

        // Bottom Sheetには全ルートを表示（地図上のカードとは別UI）
        return ListView.builder(
          padding: const EdgeInsets.all(WanWalkSpacing.s4),
          itemCount: filteredRoutes.length,
          itemBuilder: (context, index) {
            final routeData = filteredRoutes[index];
            final route = routeData['route'] as OfficialRoute;
            final distance = routeData['distance'] as double;

            return Padding(
              padding: const EdgeInsets.only(bottom: WanWalkSpacing.s4),
              child: _buildRouteCard(route, distance, isDark),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildEmptyState(isDark),
    );
  }

  /// 0件の場合のUI
  Widget _buildEmptyState(bool isDark, {bool isSearchResult = false}) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(WanWalkSpacing.s5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSearchResult ? WanWalkIcons.magnifyingGlass : WanWalkIcons.mapTrifold,
                size: 48,
                color: WanWalkColors.textSecondary,
              ),
              const SizedBox(height: WanWalkSpacing.s4),
              Text(
                isSearchResult
                    ? '「$_searchKeyword」に一致する\nルートが見つかりませんでした'
                    : '現在地から50km以内に\nおすすめルートがありません',
                textAlign: TextAlign.center,
                style: WanWalkTypography.wwBodySm.copyWith(
                  color: WanWalkColors.textSecondary,
                ),
              ),
              const SizedBox(height: WanWalkSpacing.s5),
              if (isSearchResult)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchKeyword = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WanWalkColors.accentPrimary,
                    foregroundColor: WanWalkColors.textInverse,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
                    ),
                  ),
                  icon: Icon(WanWalkIcons.x, size: WanWalkIcons.sizeSm),
                  label: const Text('検索をクリア'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AreaListScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WanWalkColors.accentPrimary,
                    foregroundColor: WanWalkColors.textInverse,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
                    ),
                  ),
                  icon: Icon(WanWalkIcons.list, size: WanWalkIcons.sizeSm),
                  label: const Text('エリア一覧を見る'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 地図コントロール（現在地 + ズーム）
  Widget _buildMapControls() {
    return Positioned(
      right: WanWalkSpacing.s4,
      top: MediaQuery.of(context).padding.top + 72,
      child: Column(
        children: [
          // 現在地ボタン
          FloatingActionButton(
            heroTag: 'map_current_location',
            mini: true,
            backgroundColor: WanWalkColors.bgPrimary,
            foregroundColor: WanWalkColors.accentPrimary,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
              side: BorderSide(color: WanWalkColors.borderSubtle, width: 1),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              _moveToCurrentLocation();
            },
            tooltip: '現在地に移動',
            child: Icon(WanWalkIcons.mapPin, size: WanWalkIcons.sizeMd),
          ),
          const SizedBox(height: WanWalkSpacing.s2),
          // ズームコントロール
          ZoomControlWidget(
            mapController: _mapController,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
        ],
      ),
    );
  }

  /// ピン投稿FAB(右下)
  Widget _buildPinPostFAB(bool isDark) {
    return Positioned(
      right: WanWalkSpacing.s4,
      bottom: _bottomSheetHeight + 80,
      child: FloatingActionButton.extended(
        heroTag: 'map_pin_post',
        onPressed: () {
          HapticFeedback.lightImpact();
          _showPinTypeSelection(isDark);
        },
        backgroundColor: WanWalkColors.accentPrimary,
        foregroundColor: WanWalkColors.textInverse,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
        ),
        icon: Icon(WanWalkIcons.plus, size: WanWalkIcons.sizeSm),
        label: Text(
          'ピンを投稿',
          style: WanWalkTypography.wwBodySm.copyWith(
            color: WanWalkColors.textInverse,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// ピン投稿タイプ選択ボトムシート
  void _showPinTypeSelection(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WanWalkColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(WanWalkSpacing.radiusLg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(WanWalkSpacing.s5),
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
                      color: WanWalkColors.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: WanWalkSpacing.s5),
                // タイトル
                Text('ピンを投稿', style: WanWalkTypography.wwH2),
                const SizedBox(height: 4),
                Text(
                  '投稿タイプを選択してください',
                  style: WanWalkTypography.wwCaption,
                ),
                const SizedBox(height: WanWalkSpacing.s6),
                // ルートに投稿ボタン
                _buildPinTypeButton(
                  icon: WanWalkIcons.path,
                  title: 'ルートに投稿',
                  description: 'みんなのピン',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PinRoutePickerScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: WanWalkSpacing.s3),
                // 自由なスポットボタン
                _buildPinTypeButton(
                  icon: WanWalkIcons.mapPin,
                  title: '自由なスポット',
                  description: '場所を自由に投稿',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PinLocationPickerScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: WanWalkSpacing.s4),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ピン投稿タイプボタン
  Widget _buildPinTypeButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: WanWalkColors.textPrimary,
          side: BorderSide(color: WanWalkColors.borderStrong, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Row(
          children: [
            Icon(icon, size: WanWalkIcons.sizeLg, color: WanWalkColors.accentPrimary),
            const SizedBox(width: WanWalkSpacing.s4),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: WanWalkTypography.wwH4),
                  const SizedBox(height: 2),
                  Text(description, style: WanWalkTypography.wwCaption),
                ],
              ),
            ),
            Icon(
              WanWalkIcons.caretRight,
              size: WanWalkIcons.sizeSm,
              color: WanWalkColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 全エリアのルートマーカーを構築
  /// DESIGN_TOKENS §12-A: ルートマーカー（スタート）は `accent-primary` + 中央に「S」
  Widget _buildAllRoutesMarkers(BuildContext context, WidgetRef ref, List<Area> areas) {
    List<Marker> allMarkers = [];

    for (final area in areas) {
      final routesAsync = ref.watch(routesByAreaProvider(area.id));

      routesAsync.whenData((routes) {
        for (final route in routes) {
          allMarkers.add(
            Marker(
              point: route.startLocation,
              width: 28,
              height: 28,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailScreen(routeId: route.id),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: WanWalkColors.accentPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: WanWalkColors.textInverse, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'S',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.0,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      });
    }

    return MarkerLayer(markers: allMarkers);
  }

  /// デフォルトのサムネイル画像
  Widget _buildDefaultThumbnail() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: WanWalkColors.accentPrimarySoft,
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusSm),
      ),
      child: Icon(
        WanWalkIcons.path,
        size: 28,
        color: WanWalkColors.accentPrimary,
      ),
    );
  }

  /// 現在地から近いおすすめルートを取得（20km以内）
  List<Map<String, dynamic>> _getRecommendedRoutes(
    LatLng currentLocation,
    List<OfficialRoute> allRoutes,
  ) {
    if (kDebugMode) {
      appLog('🔵 _getRecommendedRoutes: currentLocation=${currentLocation.latitude},${currentLocation.longitude}');
      appLog('🔵 Total routes: ${allRoutes.length}');
    }
    
    final List<Map<String, dynamic>> nearbyRoutes = [];

    for (final route in allRoutes) {
      final distance = _calculateDistance(
        currentLocation,
        route.startLocation,
      );

      if (kDebugMode && distance <= 100.0) {
        appLog('  🔵 Route: ${route.name} at ${route.startLocation.latitude},${route.startLocation.longitude} - ${distance.toStringAsFixed(1)}km');
      }

      if (distance <= 50.0) {
        nearbyRoutes.add({
          'route': route,
          'distance': distance,
        });
        if (kDebugMode) {
          appLog('  ✅ Found nearby route: ${route.name} (${distance.toStringAsFixed(1)}km)');
        }
      }
    }

    nearbyRoutes.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    
    if (kDebugMode) {
      appLog('🔵 Total nearby routes (<=50km): ${nearbyRoutes.length}');
    }
    
    return nearbyRoutes;
  }

  /// 検索キーワードでルートをフィルタリング（ルート名のみ）
  List<Map<String, dynamic>> _filterRoutesBySearch(List<Map<String, dynamic>> routes) {
    if (_searchKeyword.isEmpty) {
      return routes;
    }

    final keyword = _searchKeyword.toLowerCase();
    
    return routes.where((routeData) {
      final route = routeData['route'] as OfficialRoute;
      // ルート名で部分一致検索（大文字小文字を区別しない）
      return route.name.toLowerCase().contains(keyword);
    }).toList();
  }

  /// Haversine公式で2地点間の距離を計算（km単位）
  double _calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371.0;
    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final dLat = (point2.latitude - point1.latitude) * pi / 180;
    final dLon = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));

    return R * c;
  }

  /// ピンマーカーを構築
  /// DESIGN_TOKENS §12-A: ピンは `accent-secondary` (#B8905C) + 中央 MapPin アイコン
  Widget _buildPinMarkers(BuildContext context, WidgetRef ref) {
    final pinsAsync = ref.watch(allPinsProvider);

    return pinsAsync.when(
      data: (pins) {
        if (pins.isEmpty) {
          return const SizedBox.shrink();
        }

        return MarkerLayer(
          markers: pins.map((pin) {
            return Marker(
              point: pin.location,
              width: 28,
              height: 28,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PinDetailScreen(pinId: pin.id),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: WanWalkColors.accentGold,
                        shape: BoxShape.circle,
                        border: Border.all(color: WanWalkColors.textInverse, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        WanWalkIcons.mapPin,
                        color: WanWalkColors.textInverse,
                        size: 14,
                      ),
                    ),
                    if (pin.isOfficial)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            WanWalkIcons.sealCheck,
                            color: WanWalkColors.accentPrimary,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) {
        if (kDebugMode) {
          appLog('❌ ピンマーカー表示エラー: $error');
        }
        return const SizedBox.shrink();
      },
    );
  }
}
