import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';

/// DogHub箱根仙石原バナー
/// 箱根ルート詳細画面に表示。散歩の拠点としてDogHubを自然に紹介。
class DogHubBanner extends StatelessWidget {
  final bool isDark;

  const DogHubBanner({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse('https://dog-hub.shop/hotel/');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
        padding: const EdgeInsets.all(WanWalkSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? WanWalkColors.cardDark
              : const Color(0xFFFFF8F0), // 温かみのあるベージュ
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE8D5C0).withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            // DogHubアイコン
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: WanWalkColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pets,
                color: WanWalkColors.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: WanWalkSpacing.md),
            // テキスト
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DogHub箱根仙石原',
                    style: WanWalkTypography.bodySmall.copyWith(
                      color: WanWalkColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '散歩の拠点に。カフェ・ドッグラン・一時預かり',
                    style: WanWalkTypography.bodySmall.copyWith(
                      color: isDark
                          ? WanWalkColors.textSecondaryDark
                          : WanWalkColors.textSecondaryLight,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDark
                  ? WanWalkColors.textTertiaryDark
                  : WanWalkColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
