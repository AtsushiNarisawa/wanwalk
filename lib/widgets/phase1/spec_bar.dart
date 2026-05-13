import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../models/official_route.dart';
import '../../utils/distance_formatter.dart';

/// SpecBar — ルート詳細のヒーロー直下に置く4点スペック表示。
/// モバイル: 2×2 グリッド。数値は Inter + tabular figures。null 時は em-dash。
class SpecBar extends StatelessWidget {
  final double? distanceKm;
  final int? estimatedMinutes;
  final double? elevationMeters;
  final DifficultyLevel? difficulty;

  const SpecBar({
    super.key,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.elevationMeters,
    required this.difficulty,
  });

  factory SpecBar.fromRoute(OfficialRoute route) {
    double? elevation = route.elevationGainMeters;
    if (elevation == null) {
      final raw = route.petInfo?.others;
      if (raw != null) {
        final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
        if (match != null) {
          elevation = double.tryParse(match.group(1)!);
        }
      }
    }
    return SpecBar(
      distanceKm: route.distanceMeters > 0 ? route.distanceMeters / 1000 : null,
      estimatedMinutes: route.estimatedMinutes > 0 ? route.estimatedMinutes : null,
      elevationMeters: elevation,
      difficulty: route.difficultyLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <_SpecItem>[
      _SpecItem(
        icon: PhosphorIcons.path(),
        label: '距離',
        value: distanceKm != null
            ? formatDistance((distanceKm! * 1000).round())
            : '—',
      ),
      _SpecItem(
        icon: PhosphorIcons.clock(),
        label: '所要時間',
        value: estimatedMinutes != null ? '約 $estimatedMinutes 分' : '—',
      ),
      // L7 (2026-05-13): em-dash → 「データ準備中」の柔らかいプレースホルダに切替。
      // SSoT 化（DB カラム + 自動算出）は公開後 Phase 3 で実施。
      _SpecItem(
        icon: PhosphorIcons.mountains(),
        label: '高低差',
        value: elevationMeters != null
            ? '${elevationMeters!.toStringAsFixed(0)} m'
            : 'データ準備中',
        isPlaceholder: elevationMeters == null,
      ),
      _SpecItem(
        icon: PhosphorIcons.chartLineUp(),
        label: '難易度',
        value: difficulty?.label ?? 'データ準備中',
        dotColor: _difficultyColor(difficulty),
        isPlaceholder: difficulty == null,
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: WanWalkColors.borderSubtle),
          bottom: BorderSide(color: WanWalkColors.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.s4,
        vertical: WanWalkSpacing.s5,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _SpecCell(item: items[0])),
              Expanded(child: _SpecCell(item: items[1])),
            ],
          ),
          const SizedBox(height: WanWalkSpacing.s5),
          Row(
            children: [
              Expanded(child: _SpecCell(item: items[2])),
              Expanded(child: _SpecCell(item: items[3])),
            ],
          ),
        ],
      ),
    );
  }

  static Color? _difficultyColor(DifficultyLevel? level) {
    switch (level) {
      case DifficultyLevel.easy:
        return WanWalkColors.levelEasy;
      case DifficultyLevel.moderate:
        return WanWalkColors.levelModerate;
      case DifficultyLevel.hard:
        return WanWalkColors.levelHard;
      case null:
        return null;
    }
  }
}

class _SpecItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? dotColor;
  final bool isPlaceholder;

  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
    this.dotColor,
    this.isPlaceholder = false,
  });
}

class _SpecCell extends StatelessWidget {
  final _SpecItem item;
  const _SpecCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          item.icon,
          size: 24,
          color: WanWalkColors.accentPrimary,
        ),
        const SizedBox(width: WanWalkSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label.toUpperCase(),
                style: WanWalkTypography.wwLabel,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (item.dotColor != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item.dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      item.value,
                      style: WanWalkTypography.wwNumeric.copyWith(
                        fontSize: item.isPlaceholder ? 13 : 16,
                        height: 1.3,
                        color: item.isPlaceholder
                            ? WanWalkColors.textTertiary
                            : WanWalkColors.textPrimary,
                        fontStyle: item.isPlaceholder
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
