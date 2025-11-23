import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/walk_detail_provider.dart';
import '../../services/walk_detail_service.dart';

/// お出かけ散歩詳細画面
/// - ルート地図（フルサイズ）
/// - 歩いた軌跡（青線）
/// - ピン位置（マーカー）
/// - 写真ギャラリー
/// - 散歩データ統計
class WalkDetailScreen extends ConsumerWidget {
  final String walkId;

  const WalkDetailScreen({
    super.key,
    required this.walkId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walkDetailAsync = ref.watch(walkDetailProvider(walkId));

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      body: walkDetailAsync.when(
        data: (detail) {
          if (detail == null) {
            return _buildErrorState(isDark, '散歩データが見つかりませんでした');
          }
          return _buildContent(context, detail, isDark);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(isDark, 'データの取得に失敗しました'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WalkDetail detail, bool isDark) {
    return CustomScrollView(
      slivers: [
        // アプリバー
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: isDark
              ? WanMapColors.backgroundDark
              : WanMapColors.backgroundLight,
          iconTheme: IconThemeData(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildMap(detail, isDark),
          ),
        ),

        // コンテンツ
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: WanMapSpacing.lg),

              // ヘッダー情報
              _buildHeader(detail, isDark),

              const SizedBox(height: WanMapSpacing.xl),

              // 統計情報
              _buildStats(detail, isDark),

              const SizedBox(height: WanMapSpacing.xl),

              // 写真ギャラリー
              if (detail.photoUrls.isNotEmpty) ...[
                _buildPhotoGallery(context, detail, isDark),
                const SizedBox(height: WanMapSpacing.xl),
              ],

              // ピン一覧
              if (detail.pins.isNotEmpty) ...[
                _buildPinsList(detail, isDark),
                const SizedBox(height: WanMapSpacing.xl),
              ],

              // シェアボタン
              _buildShareButton(context, detail, isDark),

              const SizedBox(height: WanMapSpacing.xxxl),
            ],
          ),
        ),
      ],
    );
  }

  /// 地図表示
  Widget _buildMap(WalkDetail detail, bool isDark) {
    // ルート軌跡のポイント
    final routePoints = detail.routePoints.map((p) => p.latLng).toList();

    // 地図の中心とズームを計算
    LatLng center;
    double zoom = 14.0;
    
    if (routePoints.isNotEmpty) {
      // ルートの中心点を計算
      double latSum = 0, lonSum = 0;
      for (var point in routePoints) {
        latSum += point.latitude;
        lonSum += point.longitude;
      }
      center = LatLng(
        latSum / routePoints.length,
        lonSum / routePoints.length,
      );
    } else {
      center = LatLng(35.6762, 139.6503); // デフォルト: 東京
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractFlags.all & ~InteractFlags.rotate,
        ),
      ),
      children: [
        // タイルレイヤー
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.doghub.wanmap',
        ),

        // ルート軌跡
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.0,
                color: Colors.blue.withOpacity(0.7),
              ),
            ],
          ),

        // 開始・終了マーカー
        if (routePoints.isNotEmpty)
          MarkerLayer(
            markers: [
              // 開始マーカー
              Marker(
                point: routePoints.first,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.play_circle,
                  color: Colors.green,
                  size: 40,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // 終了マーカー
              Marker(
                point: routePoints.last,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.stop_circle,
                  color: Colors.red,
                  size: 40,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),

        // ピンマーカー
        if (detail.pins.isNotEmpty)
          MarkerLayer(
            markers: detail.pins.map((pin) {
              return Marker(
                point: pin.location,
                width: 30,
                height: 30,
                child: Icon(
                  _getPinIcon(pin.pinType),
                  color: WanMapColors.accent,
                  size: 30,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// ヘッダー情報
  Widget _buildHeader(WalkDetail detail, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日付
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WanMapSpacing.sm,
              vertical: WanMapSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: WanMapColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormat('yyyy年M月d日(E) HH:mm', 'ja').format(detail.walkedAt),
              style: WanMapTypography.caption.copyWith(
                color: WanMapColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),

          // ルート名
          Text(
            detail.routeName,
            style: WanMapTypography.headlineMedium.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.sm),

          // エリア名
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 18,
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
              ),
              const SizedBox(width: WanMapSpacing.xs),
              Text(
                detail.areaName,
                style: WanMapTypography.bodyLarge.copyWith(
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 統計情報
  Widget _buildStats(WalkDetail detail, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(WanMapSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.straighten,
                    label: '距離',
                    value: detail.formattedDistance,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.access_time,
                    label: '時間',
                    value: detail.formattedDuration,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: WanMapSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.speed,
                    label: '平均ペース',
                    value: detail.averagePace,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.trending_up,
                    label: '難易度',
                    value: detail.difficultyLabel,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 写真ギャラリー
  Widget _buildPhotoGallery(BuildContext context, WalkDetail detail, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Text(
            '写真 (${detail.photoUrls.length})',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: WanMapSpacing.md),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
            itemCount: detail.photoUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < detail.photoUrls.length - 1
                      ? WanMapSpacing.sm
                      : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    // TODO: 写真フルスクリーン表示
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      detail.photoUrls[index],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          color: isDark
                              ? WanMapColors.cardDark
                              : WanMapColors.cardLight,
                          child: Icon(
                            Icons.image_not_supported,
                            color: isDark
                                ? WanMapColors.textSecondaryDark
                                : WanMapColors.textSecondaryLight,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// ピン一覧
  Widget _buildPinsList(WalkDetail detail, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Text(
            'ピン (${detail.pins.length})',
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: WanMapSpacing.md),
        ...detail.pins.map((pin) => _PinCard(pin: pin, isDark: isDark)),
      ],
    );
  }

  /// シェアボタン
  Widget _buildShareButton(BuildContext context, WalkDetail detail, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO: シェア機能実装
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('シェア機能は準備中です')),
            );
          },
          icon: const Icon(Icons.share),
          label: const Text('この散歩をシェア'),
          style: ElevatedButton.styleFrom(
            backgroundColor: WanMapColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: WanMapSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  /// エラー状態
  Widget _buildErrorState(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: WanMapSpacing.lg),
            Text(
              message,
              style: WanMapTypography.bodyLarge.copyWith(
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// ピンタイプからアイコンを取得
  IconData _getPinIcon(PinType type) {
    switch (type) {
      case PinType.scenery:
        return Icons.landscape;
      case PinType.shop:
        return Icons.store;
      case PinType.encounter:
        return Icons.pets;
      case PinType.other:
        return Icons.place;
    }
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
          size: 32,
          color: WanMapColors.accent,
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
        const SizedBox(height: WanMapSpacing.xs),
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

/// ピンカード
class _PinCard extends StatelessWidget {
  final RoutePin pin;
  final bool isDark;

  const _PinCard({
    required this.pin,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: WanMapSpacing.lg,
        right: WanMapSpacing.lg,
        bottom: WanMapSpacing.md,
      ),
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // アイコン
          Container(
            padding: const EdgeInsets.all(WanMapSpacing.sm),
            decoration: BoxDecoration(
              color: WanMapColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPinIcon(pin.pinType),
              color: WanMapColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: WanMapSpacing.md),

          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pin.title,
                  style: WanMapTypography.bodyLarge.copyWith(
                    color: isDark
                        ? WanMapColors.textPrimaryDark
                        : WanMapColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (pin.comment != null && pin.comment!.isNotEmpty) ...[
                  const SizedBox(height: WanMapSpacing.xs),
                  Text(
                    pin.comment!,
                    style: WanMapTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanMapColors.textSecondaryDark
                          : WanMapColors.textSecondaryLight,
                    ),
                  ),
                ],
                if (pin.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: WanMapSpacing.sm),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: pin.photoUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < pin.photoUrls.length - 1
                                ? WanMapSpacing.xs
                                : 0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              pin.photoUrls[index],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPinIcon(PinType type) {
    switch (type) {
      case PinType.scenery:
        return Icons.landscape;
      case PinType.shop:
        return Icons.store;
      case PinType.encounter:
        return Icons.pets;
      case PinType.other:
        return Icons.place;
    }
  }
}

// RoutePin import
import '../../models/route_pin.dart';
