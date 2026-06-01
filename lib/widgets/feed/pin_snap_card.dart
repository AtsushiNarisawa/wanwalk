import 'package:flutter/material.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_icons.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';
import '../../models/recent_pin_post.dart';

/// 愛犬家のスナップ（コミュニティピン）用のコンパクトカード。
///
/// ホーム末尾の横スクロールカルーセルで使う写真ファーストの小型カード。
/// DESIGN_TOKENS 準拠: 影なし・1:1 サムネ・Phosphor アイコン・抑制された配色。
class PinSnapCard extends StatelessWidget {
  final RecentPinPost pin;
  final bool isDark;
  final VoidCallback onTap;

  /// カードの横幅（カルーセル内）
  static const double cardWidth = 150;

  const PinSnapCard({
    super.key,
    required this.pin,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1:1 サムネイル
            ClipRRect(
              borderRadius: BorderRadius.circular(WanWalkSpacing.radiusMd),
              child: AspectRatio(
                aspectRatio: 1,
                child: pin.photoUrl.isNotEmpty
                    ? Image.network(
                        pin.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(height: WanWalkSpacing.s2),
            // タイトル
            Text(
              pin.title.isNotEmpty ? pin.title : 'おすすめスポット',
              style: WanWalkTypography.wwBodySm.copyWith(
                color: WanWalkColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // 投稿者名・エリア
            Text(
              _byline(),
              style: WanWalkTypography.wwLabel.copyWith(
                color: WanWalkColors.textTertiary,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: WanWalkColors.accentPrimarySoft,
        alignment: Alignment.center,
        child: Icon(
          WanWalkIcons.image,
          size: WanWalkIcons.sizeMd,
          color: WanWalkColors.accentPrimary,
        ),
      );

  String _byline() {
    final name = pin.userName.isNotEmpty ? pin.userName : 'WanWalkユーザー';
    final area = pin.areaName ?? '';
    return area.isNotEmpty ? '$name・$area' : name;
  }
}
