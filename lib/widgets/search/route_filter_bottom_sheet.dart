import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/route_search_provider.dart';
import '../../providers/area_provider.dart';

/// ルートフィルターボトムシート
class RouteFilterBottomSheet extends ConsumerStatefulWidget {
  const RouteFilterBottomSheet({super.key});

  @override
  ConsumerState<RouteFilterBottomSheet> createState() =>
      _RouteFilterBottomSheetState();
}

class _RouteFilterBottomSheetState
    extends ConsumerState<RouteFilterBottomSheet> {
  late List<String> _selectedDifficulties;
  late List<String> _selectedFeatures;
  late List<String> _selectedSeasons;
  late List<String> _selectedAreaIds;
  late RangeValues _distanceRange;
  late RangeValues _durationRange;

  @override
  void initState() {
    super.initState();
    final params = ref.read(routeSearchStateProvider);
    _selectedDifficulties = params.difficulties ?? [];
    _selectedFeatures = params.features ?? [];
    _selectedSeasons = params.bestSeasons ?? [];
    _selectedAreaIds = params.areaIds ?? [];
    _distanceRange = RangeValues(
      params.minDistanceKm ?? 0,
      params.maxDistanceKm ?? 20,
    );
    _durationRange = RangeValues(
      (params.minDurationMin ?? 0).toDouble(),
      (params.maxDurationMin ?? 180).toDouble(),
    );
  }

  void _applyFilters() {
    final notifier = ref.read(routeSearchStateProvider.notifier);
    
    notifier.updateDifficultyFilter(
      _selectedDifficulties.isEmpty ? null : _selectedDifficulties,
    );
    notifier.updateFeaturesFilter(
      _selectedFeatures.isEmpty ? null : _selectedFeatures,
    );
    notifier.updateSeasonsFilter(
      _selectedSeasons.isEmpty ? null : _selectedSeasons,
    );
    notifier.updateAreaFilter(
      _selectedAreaIds.isEmpty ? null : _selectedAreaIds,
    );
    notifier.updateDistanceRange(
      _distanceRange.start == 0 ? null : _distanceRange.start,
      _distanceRange.end == 20 ? null : _distanceRange.end,
    );
    notifier.updateDurationRange(
      _durationRange.start == 0 ? null : _durationRange.start.toInt(),
      _durationRange.end == 180 ? null : _durationRange.end.toInt(),
    );
    notifier.resetPagination();

    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedDifficulties = [];
      _selectedFeatures = [];
      _selectedSeasons = [];
      _selectedAreaIds = [];
      _distanceRange = const RangeValues(0, 20);
      _durationRange = const RangeValues(0, 180);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final areas = ref.watch(areasProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.only(top: WanMapSpacing.small),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ヘッダー
          Padding(
            padding: const EdgeInsets.all(WanMapSpacing.medium),
            child: Row(
              children: [
                Text(
                  'フィルター',
                  style: WanMapTypography.heading2,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('クリア'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
          // フィルター内容
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(WanMapSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 難易度フィルター
                  _buildSectionTitle('難易度', isDark),
                  const SizedBox(height: WanMapSpacing.small),
                  _buildDifficultyChips(isDark),
                  const SizedBox(height: WanMapSpacing.large),
                  
                  // 距離フィルター
                  _buildSectionTitle('距離', isDark),
                  const SizedBox(height: WanMapSpacing.small),
                  _buildDistanceSlider(isDark),
                  const SizedBox(height: WanMapSpacing.large),
                  
                  // 所要時間フィルター
                  _buildSectionTitle('所要時間', isDark),
                  const SizedBox(height: WanMapSpacing.small),
                  _buildDurationSlider(isDark),
                  const SizedBox(height: WanMapSpacing.large),
                  
                  // エリアフィルター
                  _buildSectionTitle('エリア', isDark),
                  const SizedBox(height: WanMapSpacing.small),
                  areas.when(
                    data: (areaList) => _buildAreaChips(areaList, isDark),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: WanMapSpacing.large),
                  
                  // 特徴フィルター
                  _buildSectionTitle('特徴', isDark),
                  const SizedBox(height: WanMapSpacing.small),
                  _buildFeatureChips(isDark),
                  const SizedBox(height: WanMapSpacing.large),
                  
                  // 季節フィルター
                  _buildSectionTitle('おすすめの季節', isDark),
                  const SizedBox(height: WanMapSpacing.small),
                  _buildSeasonChips(isDark),
                ],
              ),
            ),
          ),
          // 適用ボタン
          Padding(
            padding: const EdgeInsets.all(WanMapSpacing.medium),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WanMapColors.accent,
                  padding: const EdgeInsets.symmetric(
                    vertical: WanMapSpacing.medium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'フィルターを適用',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: WanMapTypography.heading3.copyWith(
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildDifficultyChips(bool isDark) {
    final difficulties = [
      {'value': 'easy', 'label': '簡単'},
      {'value': 'moderate', 'label': '普通'},
      {'value': 'hard', 'label': '難しい'},
    ];

    return Wrap(
      spacing: WanMapSpacing.small,
      children: difficulties.map((diff) {
        final value = diff['value']!;
        final label = diff['label']!;
        final isSelected = _selectedDifficulties.contains(value);

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDifficulties.add(value);
              } else {
                _selectedDifficulties.remove(value);
              }
            });
          },
          selectedColor: WanMapColors.accent.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? WanMapColors.accent : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDistanceSlider(bool isDark) {
    return Column(
      children: [
        RangeSlider(
          values: _distanceRange,
          min: 0,
          max: 20,
          divisions: 20,
          labels: RangeLabels(
            '${_distanceRange.start.toStringAsFixed(1)}km',
            '${_distanceRange.end.toStringAsFixed(1)}km',
          ),
          onChanged: (values) {
            setState(() {
              _distanceRange = values;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.medium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_distanceRange.start.toStringAsFixed(1)}km'),
              Text('${_distanceRange.end.toStringAsFixed(1)}km'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSlider(bool isDark) {
    return Column(
      children: [
        RangeSlider(
          values: _durationRange,
          min: 0,
          max: 180,
          divisions: 18,
          labels: RangeLabels(
            '${_durationRange.start.toInt()}分',
            '${_durationRange.end.toInt()}分',
          ),
          onChanged: (values) {
            setState(() {
              _durationRange = values;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.medium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_durationRange.start.toInt()}分'),
              Text('${_durationRange.end.toInt()}分'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAreaChips(List<dynamic> areas, bool isDark) {
    return Wrap(
      spacing: WanMapSpacing.small,
      children: areas.map((area) {
        final areaId = area.id;
        final areaName = area.displayName;
        final isSelected = _selectedAreaIds.contains(areaId);

        return FilterChip(
          label: Text(areaName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedAreaIds.add(areaId);
              } else {
                _selectedAreaIds.remove(areaId);
              }
            });
          },
          selectedColor: WanMapColors.accent.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? WanMapColors.accent : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureChips(bool isDark) {
    final features = [
      {'value': 'scenic_view', 'label': '景色が良い'},
      {'value': 'cafe_nearby', 'label': 'カフェ近く'},
      {'value': 'shaded', 'label': '木陰が多い'},
      {'value': 'riverside', 'label': '川沿い'},
      {'value': 'seaside', 'label': '海沿い'},
      {'value': 'mountain', 'label': '山道'},
    ];

    return Wrap(
      spacing: WanMapSpacing.small,
      children: features.map((feature) {
        final value = feature['value']!;
        final label = feature['label']!;
        final isSelected = _selectedFeatures.contains(value);

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedFeatures.add(value);
              } else {
                _selectedFeatures.remove(value);
              }
            });
          },
          selectedColor: WanMapColors.accent.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? WanMapColors.accent : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeasonChips(bool isDark) {
    final seasons = [
      {'value': 'spring', 'label': '春'},
      {'value': 'summer', 'label': '夏'},
      {'value': 'autumn', 'label': '秋'},
      {'value': 'winter', 'label': '冬'},
    ];

    return Wrap(
      spacing: WanMapSpacing.small,
      children: seasons.map((season) {
        final value = season['value']!;
        final label = season['label']!;
        final isSelected = _selectedSeasons.contains(value);

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSeasons.add(value);
              } else {
                _selectedSeasons.remove(value);
              }
            });
          },
          selectedColor: WanMapColors.accent.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? WanMapColors.accent : null,
          ),
        );
      }).toList(),
    );
  }
}
