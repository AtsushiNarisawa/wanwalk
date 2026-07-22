import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../utils/map_tile_nudge.dart';
import '../../utils/route_trim.dart';

/// 発着点トリミングのセクション（地図プレビュー＋始点/終点の半径スライダー）。
///
/// 半径（60〜200m・既定120m）で「発着点をぼかす量」を指定し、[EndpointTrimmer] で
/// 保持インデックスへ変換する。変更のたびに確定結果 [TrimOutput] を [onChanged] へ通知する。
/// 生の軌跡は淡色、掲載される保持区間は深緑で描く。
class RouteTrimSection extends StatefulWidget {
  const RouteTrimSection({
    super.key,
    required this.trimmer,
    required this.onChanged,
  });

  final EndpointTrimmer trimmer;
  final ValueChanged<TrimOutput> onChanged;

  @override
  State<RouteTrimSection> createState() => _RouteTrimSectionState();
}

class _RouteTrimSectionState extends State<RouteTrimSection> {
  late double _startRadius;
  late double _endRadius;
  late TrimOutput _out;

  @override
  void initState() {
    super.initState();
    final t = widget.trimmer;
    // 既定120m。短い経路で無効になる場合は下限60mへ。
    final tryDefault =
        t.materialize(startRadius: t.defaultRadius, endRadius: t.defaultRadius);
    if (tryDefault.valid) {
      _startRadius = t.defaultRadius;
      _endRadius = t.defaultRadius;
      _out = tryDefault;
    } else {
      _startRadius = t.minRadius;
      _endRadius = t.minRadius;
      _out = t.materialize(startRadius: t.minRadius, endRadius: t.minRadius);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(_out);
    });
  }

  void _recompute() {
    setState(() {
      _out = widget.trimmer
          .materialize(startRadius: _startRadius, endRadius: _endRadius);
    });
    widget.onChanged(_out);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? WanWalkColors.textSecondaryDark
        : WanWalkColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _TrimMap(
            allPoints: widget.trimmer.points,
            keptStartIdx: _out.startIdx,
            keptEndIdx: _out.endIdx,
          ),
        ),
        const SizedBox(height: WanWalkSpacing.sm),
        Text(
          'ご自宅の場所が分からないよう、道の始まりと終わりを短く隠します。地図の深緑が掲載される範囲です。',
          style: WanWalkTypography.bodySmall.copyWith(color: textSecondary),
        ),
        const SizedBox(height: WanWalkSpacing.sm),
        _radiusSlider(
          label: '始まりを隠す',
          value: _startRadius,
          onChanged: (v) {
            _startRadius = v;
            _recompute();
          },
          isDark: isDark,
        ),
        _radiusSlider(
          label: '終わりを隠す',
          value: _endRadius,
          onChanged: (v) {
            _endRadius = v;
            _recompute();
          },
          isDark: isDark,
        ),
        const SizedBox(height: WanWalkSpacing.xs),
        Text(
          '掲載される距離: 約 ${(_out.distanceMeters / 1000).toStringAsFixed(2)} km',
          style: WanWalkTypography.bodySmall.copyWith(
            color: textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _radiusSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required bool isDark,
  }) {
    final textPrimary = isDark
        ? WanWalkColors.textPrimaryDark
        : WanWalkColors.textPrimaryLight;
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: WanWalkTypography.bodySmall.copyWith(color: textPrimary),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: widget.trimmer.minRadius,
            max: EndpointTrimmer.maxRadius,
            divisions:
                ((EndpointTrimmer.maxRadius - widget.trimmer.minRadius) / 10)
                    .round(),
            activeColor: WanWalkColors.accentPrimary,
            label: '${value.round()}m',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${value.round()}m',
            textAlign: TextAlign.end,
            style: WanWalkTypography.bodySmall.copyWith(color: textPrimary),
          ),
        ),
      ],
    );
  }
}

/// 全軌跡（淡色）＋保持区間（深緑）を重ね描くプレビュー地図。
class _TrimMap extends StatefulWidget {
  const _TrimMap({
    required this.allPoints,
    required this.keptStartIdx,
    required this.keptEndIdx,
  });

  final List<LatLng> allPoints;
  final int keptStartIdx;
  final int keptEndIdx;

  @override
  State<_TrimMap> createState() => _TrimMapState();
}

class _TrimMapState extends State<_TrimMap> {
  static const double _mapHeight = 220;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final all = widget.allPoints;
    if (all.length < 2) {
      return SizedBox(
        height: _mapHeight,
        child: Center(
          child: Text(
            '軌跡を表示できません',
            style: WanWalkTypography.bodySmall,
          ),
        ),
      );
    }
    final start = widget.keptStartIdx.clamp(0, all.length - 1);
    final end = widget.keptEndIdx.clamp(0, all.length - 1);
    final kept = start < end ? all.sublist(start, end + 1) : const <LatLng>[];

    return SizedBox(
      height: _mapHeight,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          onMapReady: () => nudgeMapTiles(_mapController),
          initialCameraFit: CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(all),
            padding: const EdgeInsets.all(28),
          ),
          minZoom: 10,
          maxZoom: 18,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.doghub.wanwalk',
          ),
          // 全軌跡（トリムで除かれる部分も含む）を淡色で
          PolylineLayer(
            polylines: [
              Polyline(
                points: all,
                strokeWidth: 4,
                color: Colors.grey.withValues(alpha: 0.45),
              ),
            ],
          ),
          // 掲載される保持区間を深緑で
          if (kept.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: kept,
                  strokeWidth: 6,
                  color: WanWalkColors.accentPrimary,
                  borderStrokeWidth: 2,
                  borderColor: Colors.white,
                ),
              ],
            ),
          if (kept.length >= 2)
            MarkerLayer(
              markers: [
                _endpointMarker(kept.first),
                _endpointMarker(kept.last),
              ],
            ),
        ],
      ),
    );
  }

  Marker _endpointMarker(LatLng p) => Marker(
        point: p,
        width: 18,
        height: 18,
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            color: WanWalkColors.accentPrimary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      );
}
