import 'package:flutter/material.dart';

import '../../config/wanwalk_colors.dart';
import '../../models/route_spot.dart';

/// dog_policy をバッジ + 注記の形で表示する。
/// 表示できる情報がなければ何も描画しない（SizedBox.shrink）。
class DogPolicyBadges extends StatelessWidget {
  final DogPolicy policy;

  const DogPolicyBadges({super.key, required this.policy});

  static const Map<String, String> _sizeLabels = {
    'all': '全犬種OK',
    'small_medium': '中型犬以下',
    'small_only': '小型犬のみ',
  };

  List<String> _buildTags() {
    final tags = <String>[];
    final size = policy.size;
    if (size != null) {
      tags.add(_sizeLabels[size] ?? size);
    }
    final indoor = policy.indoor == true;
    final terrace = policy.terrace == true;
    if (indoor && terrace) {
      tags.add('店内・テラスOK');
    } else if (indoor) {
      tags.add('店内OK');
    } else if (terrace) {
      tags.add('テラスのみ');
    }
    if (policy.leashRequired == true) tags.add('リード必須');
    if (policy.carrierRequired == true) tags.add('キャリー必須');
    final fee = policy.dogFee;
    if (fee != null && fee.isNotEmpty && fee != '無料') {
      tags.add(fee);
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final tags = _buildTags();
    final notes = policy.notes;
    if (tags.isEmpty && (notes == null || notes.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: WanWalkColors.accentPrimarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: WanWalkColors.accentPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              notes,
              style: const TextStyle(
                fontSize: 12,
                height: 1.6,
                color: WanWalkColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
