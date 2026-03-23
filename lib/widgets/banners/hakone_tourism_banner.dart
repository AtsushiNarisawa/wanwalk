import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_typography.dart';
import '../../config/wanwalk_spacing.dart';

/// 箱根観光バナー
/// ホームフィードに表示。まだ行き先を決めていない人に箱根の魅力を伝える。
class HakoneTourismBanner extends StatelessWidget {
  final bool isDark;

  const HakoneTourismBanner({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse('https://map-hakone.staynavi.direct/');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: WanWalkSpacing.lg,
          vertical: WanWalkSpacing.sm,
        ),
        padding: const EdgeInsets.all(WanWalkSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1B5E20).withValues(alpha: 0.08),
              const Color(0xFF2E7D32).withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // 箱根アイコン
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.landscape,
                color: Color(0xFF2E7D32),
                size: 22,
              ),
            ),
            const SizedBox(width: WanWalkSpacing.md),
            // テキスト
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '箱根をもっと楽しむ',
                        style: WanWalkTypography.bodySmall.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PR',
                          style: WanWalkTypography.caption.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '箱根観光デジタルマップで周辺スポットをチェック',
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
              Icons.open_in_new,
              size: 16,
              color: isDark
                  ? WanWalkColors.textTertiaryDark
                  : const Color(0xFF2E7D32).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
