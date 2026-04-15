import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../models/official_route.dart';

/// PetInfoGrid — ルート詳細の「犬連れメモ」。
/// モバイル 1カラム。アイコン左（accent-primary 24px）、ラベル Inter uppercase、
/// 値 Noto Sans JP 15px / line-height 1.7。背景 bg-secondary。空値は非表示。
class PetInfoGrid extends StatelessWidget {
  final PetInfo info;

  const PetInfoGrid({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final items = _collectItems();
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: WanWalkColors.bgSecondary,
        borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
      ),
      padding: const EdgeInsets.all(WanWalkSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _PetInfoRow(item: items[i]),
            if (i < items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: WanWalkSpacing.s4),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: WanWalkColors.borderSubtle,
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<_PetInfoItem> _collectItems() {
    final result = <_PetInfoItem>[];

    void add(String? value, IconData icon, String label) {
      if (value != null && value.trim().isNotEmpty) {
        result.add(_PetInfoItem(icon: icon, label: label, value: value));
      }
    }

    add(info.parking, PhosphorIcons.car(), '駐車場');
    add(info.restroom, PhosphorIcons.toilet(), 'トイレ');
    add(info.waterStation, PhosphorIcons.drop(), '水飲み場');
    add(info.petFacilities, PhosphorIcons.house(), 'ペット施設');
    add(info.surface, PhosphorIcons.roadHorizon(), '路面');
    if (info.bestSeason != null && info.bestSeason!.trim().isNotEmpty) {
      result.add(_PetInfoItem(
        icon: _seasonIcon(info.bestSeason!),
        label: 'ベストシーズン',
        value: info.bestSeason!,
      ));
    }
    add(info.stairs, PhosphorIcons.stairs(), '階段');
    add(info.others, PhosphorIcons.notePencil(), 'その他');

    return result;
  }

  IconData _seasonIcon(String season) {
    final s = season.toLowerCase();
    if (s.contains('春')) return PhosphorIcons.flower();
    if (s.contains('夏')) return PhosphorIcons.sun();
    if (s.contains('秋')) return PhosphorIcons.leaf();
    if (s.contains('冬')) return PhosphorIcons.snowflake();
    return PhosphorIcons.leaf();
  }
}

class _PetInfoItem {
  final IconData icon;
  final String label;
  final String value;

  _PetInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _PetInfoRow extends StatelessWidget {
  final _PetInfoItem item;

  const _PetInfoRow({required this.item});

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
        const SizedBox(width: WanWalkSpacing.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label.toUpperCase(),
                style: WanWalkTypography.wwLabel,
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: const TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  height: 1.7,
                  color: WanWalkColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
