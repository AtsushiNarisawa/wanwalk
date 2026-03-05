import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show asin, cos, sin, sqrt;
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import '../../../providers/gps_provider_riverpod.dart';
import '../../../providers/official_route_provider.dart';
import '../../../providers/area_provider.dart';
import '../../../models/area.dart';
import '../../../providers/route_pin_provider.dart';

import '../../../models/official_route.dart';
import '../../../models/route_pin.dart';

import '../../../widgets/zoom_control_widget.dart';
import '../../outing/area_list_screen.dart';
import '../../outing/route_detail_screen.dart';
import '../../outing/pin_detail_screen.dart';
import '../../pin/pin_route_picker_screen.dart';
import '../../pin/pin_location_picker_screen.dart';

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
      print('🗺️ MAP画面: GPS初期化開始');
    }
    final gpsNotifier = ref.read(gpsProviderRiverpod.notifier);
    await gpsNotifier.getCurrentLocation();
    
    final gpsState = ref.read(gpsProviderRiverpod);
    if (kDebugMode) {
      if (gpsState.currentLocation != null) {
        print('✅ MAP画面: GPS取得成功 ${gpsState.currentLocation!.latitude},${gpsState.currentLocation!.longitude}');
      } else {
        print('❌ MAP画面: GPS取得失敗');
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
  void _moveToCurrentLocation() {
    final gpsState = ref.read(gpsProviderRiverpod);
    if (gpsState.currentLocation != null) {
      _mapController.move(gpsState.currentLocation!, 15.0);
      setState(() {
        _currentLocation = gpsState.currentLocation;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('現在地を取得できませんでした')),
      );
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
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
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
      left: WanMapSpacing.md,
      right: WanMapSpacing.md,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? WanMapColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              // 検索アイコン
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(
                  Icons.search,
                  color: WanMapColors.accent,
                  size: 24,
                ),
              ),
              // 検索入力欄
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ルート名で検索',
                    hintStyle: WanMapTypography.bodyMedium.copyWith(
                      color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                    ),
                    border: InputBorder.none,
                  ),
                  style: WanMapTypography.bodyMedium.copyWith(
                    color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                  ),
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
                  Icons.list,
                  color: WanMapColors.accent,
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
      ),
    );
  }


  /// ルートカード（共通）
  Widget _buildRouteCard(OfficialRoute route, double distance, bool isDark, {bool isClosest = false}) {
    return Material(
      elevation: isClosest ? 8 : 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RouteDetailScreen(routeId: route.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(WanMapSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? WanMapColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            gradient: isClosest
                ? LinearGradient(
                    colors: [
                      WanMapColors.accent.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Row(
            children: [
              // サムネイル
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: route.thumbnailUrl != null
                    ? Image.network(
                        route.thumbnailUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultThumbnail(),
                      )
                    : _buildDefaultThumbnail(),
              ),
              const SizedBox(width: WanMapSpacing.md),
              // ルート情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 最寄りバッジ
                    if (isClosest)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: WanMapSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: WanMapColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '最寄り',
                          style: WanMapTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    if (isClosest) const SizedBox(height: 4),
                    // ルート名
                    Text(
                      route.name,
                      style: WanMapTypography.bodyLarge.copyWith(
                        color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 距離情報
                    Row(
                      children: [
                        Icon(
                          Icons.directions_walk,
                          size: 14,
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          route.formattedDistance,
                          style: WanMapTypography.bodySmall.copyWith(
                            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: WanMapSpacing.sm),
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: WanMapColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)}km',
                          style: WanMapTypography.bodySmall.copyWith(
                            color: WanMapColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 矢印アイコン
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: WanMapColors.accent,
              ),
            ],
          ),
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
            color: isDark ? WanMapColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ドラッグハンドル
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ヘッダー
              Padding(
                padding: EdgeInsets.symmetric(horizontal: WanMapSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.recommend,
                      color: WanMapColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: WanMapSpacing.xs),
                    Text(
                      '近くのおすすめルート',
                      style: WanMapTypography.headlineSmall.copyWith(
                        color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // 展開/折りたたみボタン
                    IconButton(
                      icon: Icon(
                        _bottomSheetHeight == _minHeight
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: WanMapColors.accent,
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
            Icons.location_searching,
            size: 48,
            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
          ),
          const SizedBox(height: WanMapSpacing.md),
          Text(
            '現在地を取得中...',
            style: WanMapTypography.bodyMedium.copyWith(
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
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
          padding: EdgeInsets.all(WanMapSpacing.md),
          itemCount: filteredRoutes.length,
          itemBuilder: (context, index) {
            final routeData = filteredRoutes[index];
            final route = routeData['route'] as OfficialRoute;
            final distance = routeData['distance'] as double;

            return Padding(
              padding: EdgeInsets.only(bottom: WanMapSpacing.md),
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
          padding: EdgeInsets.all(WanMapSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSearchResult ? Icons.search_off : Icons.explore_off,
                size: 64,
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
              const SizedBox(height: WanMapSpacing.md),
              Text(
                isSearchResult 
                    ? '「$_searchKeyword」に一致する\nルートが見つかりませんでした'
                    : '現在地から50km以内に\nおすすめルートがありません',
                textAlign: TextAlign.center,
                style: WanMapTypography.bodyMedium.copyWith(
                  color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: WanMapSpacing.lg),
              if (isSearchResult)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchKeyword = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WanMapColors.accent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: WanMapSpacing.lg,
                      vertical: WanMapSpacing.md,
                    ),
                  ),
                  icon: const Icon(Icons.clear),
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
                    backgroundColor: WanMapColors.accent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: WanMapSpacing.lg,
                      vertical: WanMapSpacing.md,
                    ),
                  ),
                  icon: const Icon(Icons.list),
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
      right: WanMapSpacing.md,
      top: 160, // 上部バーの下に配置（検索バー + エリア一覧ボタンの高さ考慮）
      child: Column(
        children: [
          // 現在地ボタン
          FloatingActionButton(
            heroTag: 'map_current_location',
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: WanMapColors.accent,
            onPressed: _moveToCurrentLocation,
            tooltip: '現在地に移動',
            child: const Icon(Icons.my_location, size: 20),
          ),
          const SizedBox(height: WanMapSpacing.sm),
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
      right: WanMapSpacing.md,
      bottom: _bottomSheetHeight + 80,
      child: FloatingActionButton.extended(
        heroTag: 'map_pin_post',
        onPressed: () => _showPinTypeSelection(isDark),
        backgroundColor: WanMapColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('ピンを投稿'),
      ),
    );
  }

  /// ピン投稿タイプ選択ボトムシート
  void _showPinTypeSelection(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ハンドル
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // タイトル
                Text(
                  'ピンを投稿',
                  style: WanMapTypography.headlineSmall.copyWith(
                    color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '投稿タイプを選択してください',
                  style: WanMapTypography.bodyMedium.copyWith(
                    color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // ルートに投稿ボタン
                _buildPinTypeButton(
                  context: context,
                  isDark: isDark,
                  icon: Icons.route,
                  title: 'ルートに投稿',
                  description: 'みんなのピン',
                  color: WanMapColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    // ルート選択画面へ遷移
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PinRoutePickerScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 自由なスポットボタン
                _buildPinTypeButton(
                  context: context,
                  isDark: isDark,
                  icon: Icons.location_on,
                  title: '自由なスポット',
                  description: '場所を自由に投稿',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    // 場所選択画面へ遷移（route_idなし）
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PinLocationPickerScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ピン投稿タイプボタン
  Widget _buildPinTypeButton({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WanMapTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: WanMapTypography.bodySmall.copyWith(
                      color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  /// 全エリアのルートマーカーを構築
  Widget _buildAllRoutesMarkers(BuildContext context, WidgetRef ref, List<Area> areas) {
    List<Marker> allMarkers = [];
    
    final areaColors = {
      '箱根': Colors.orange,
      '横浜': Colors.blue,
      '鎌倉': Colors.green,
    };

    for (final area in areas) {
      final routesAsync = ref.watch(routesByAreaProvider(area.id));
      
      routesAsync.whenData((routes) {
        for (final route in routes) {
          final markerColor = areaColors[area.name] ?? WanMapColors.accent;
          
          allMarkers.add(
            Marker(
              point: route.startLocation,
              width: 40,
              height: 40,
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
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.route,
                    color: Colors.white,
                    size: 20,
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: WanMapColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.route,
        size: 32,
        color: WanMapColors.accent,
      ),
    );
  }

  /// 現在地から近いおすすめルートを取得（20km以内）
  List<Map<String, dynamic>> _getRecommendedRoutes(
    LatLng currentLocation,
    List<OfficialRoute> allRoutes,
  ) {
    if (kDebugMode) {
      print('🔵 _getRecommendedRoutes: currentLocation=${currentLocation.latitude},${currentLocation.longitude}');
      print('🔵 Total routes: ${allRoutes.length}');
    }
    
    final List<Map<String, dynamic>> nearbyRoutes = [];

    for (final route in allRoutes) {
      final distance = _calculateDistance(
        currentLocation,
        route.startLocation,
      );

      if (kDebugMode && distance <= 100.0) {
        print('  🔵 Route: ${route.name} at ${route.startLocation.latitude},${route.startLocation.longitude} - ${distance.toStringAsFixed(1)}km');
      }

      if (distance <= 50.0) {
        nearbyRoutes.add({
          'route': route,
          'distance': distance,
        });
        if (kDebugMode) {
          print('  ✅ Found nearby route: ${route.name} (${distance.toStringAsFixed(1)}km)');
        }
      }
    }

    nearbyRoutes.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    
    if (kDebugMode) {
      print('🔵 Total nearby routes (<=50km): ${nearbyRoutes.length}');
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
              width: 45,
              height: 45,
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
                    Icon(
                      _getPinIcon(pin.pinType),
                      color: _getPinColor(pin.pinType),
                      size: 40,
                      shadows: const [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                    if (pin.isOfficial)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.purple,
                            size: 14,
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
          print('❌ ピンマーカー表示エラー: $error');
        }
        return const SizedBox.shrink();
      },
    );
  }

  IconData _getPinIcon(PinType pinType) {
    // すべてのピンを統一マーカー（location_on）で表示し、色で区別
    return Icons.location_on;
  }

  Color _getPinColor(PinType pinType) {
    switch (pinType) {
      case PinType.scenery:
        return Colors.blue;
      case PinType.shop:
        return Colors.orange;
      case PinType.encounter:
        return Colors.green;
      case PinType.facility:
        return Colors.purple;
      case PinType.other:
        return Colors.grey;
    }
  }
}
