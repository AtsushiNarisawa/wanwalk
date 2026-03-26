import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/wanwalk_colors.dart';
import '../config/wanwalk_typography.dart';
import '../config/wanwalk_spacing.dart';

/// 周辺の犬連れスポット
/// 箱根ルート詳細画面に表示。DogHubを他のスポットと並列で自然に紹介。
class NearbyDogSpots extends StatelessWidget {
  final String areaId;
  final bool isDark;

  const NearbyDogSpots({super.key, required this.areaId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final spots = _getSpotsForArea(areaId);
    if (spots.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 16,
                color: isDark
                    ? WanWalkColors.textSecondaryDark
                    : WanWalkColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                '周辺の犬連れスポット',
                style: WanWalkTypography.bodySmall.copyWith(
                  color: isDark
                      ? WanWalkColors.textSecondaryDark
                      : WanWalkColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: WanWalkSpacing.sm),
          ...spots.map((spot) => _buildSpotItem(spot, context)),
        ],
      ),
    );
  }

  Widget _buildSpotItem(_NearbySpot spot, BuildContext context) {
    return GestureDetector(
      onTap: spot.url != null
          ? () async {
              final uri = Uri.parse(spot.url!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: WanWalkSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spot.icon,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${spot.name}${spot.distance != null ? '（${spot.distance}）' : ''}',
                    style: WanWalkTypography.bodySmall.copyWith(
                      color: isDark
                          ? WanWalkColors.textPrimaryDark
                          : WanWalkColors.textPrimaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    spot.description,
                    style: WanWalkTypography.bodySmall.copyWith(
                      color: isDark
                          ? WanWalkColors.textTertiaryDark
                          : WanWalkColors.textTertiaryLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (spot.url != null)
              Icon(
                Icons.open_in_new,
                size: 12,
                color: isDark
                    ? WanWalkColors.textTertiaryDark
                    : WanWalkColors.textTertiaryLight,
              ),
          ],
        ),
      ),
    );
  }

  List<_NearbySpot> _getSpotsForArea(String areaId) {
    // 箱根・仙石原
    if (areaId == 'a1111111-1111-1111-1111-111111111115') {
      return [
        _NearbySpot(
          icon: '🐕',
          name: 'DogHub箱根仙石原',
          distance: '仙石原エリア内',
          description: 'カフェ・ドッグラン・一時預かり',
          url: 'https://dog-hub.shop/hotel/',
        ),
        _NearbySpot(
          icon: '☕',
          name: 'Cafe Dining LUDERA',
          distance: null,
          description: 'テラス席犬OK。足柄牛バーガーが人気',
        ),
        _NearbySpot(
          icon: '🍽️',
          name: '銀の穂',
          distance: null,
          description: 'ガーデンテラス席犬OK。釜めし',
        ),
      ];
    }
    // 箱根・宮ノ下
    if (areaId == 'a1111111-1111-1111-1111-111111111113') {
      return [
        _NearbySpot(
          icon: '♨️',
          name: 'NARAYA CAFE',
          distance: '宮ノ下駅近く',
          description: '足湯テラス犬OK',
        ),
        _NearbySpot(
          icon: '🍞',
          name: '渡邊ベーカリー',
          distance: null,
          description: '温泉シチューパン。テイクアウト可',
        ),
        _NearbySpot(
          icon: '🐕',
          name: 'DogHub箱根仙石原',
          distance: '車約15分',
          description: '一時預かり・ドッグラン',
          url: 'https://dog-hub.shop/hotel/',
        ),
      ];
    }
    // 箱根・強羅
    if (areaId == 'a1111111-1111-1111-1111-111111111114') {
      return [
        _NearbySpot(
          icon: '☕',
          name: '一色堂茶廊',
          distance: '強羅公園内',
          description: 'テラス席犬OK',
        ),
        _NearbySpot(
          icon: '🍕',
          name: 'paSeo',
          distance: '強羅駅近く',
          description: 'リード+マナーベルトで店内OK',
        ),
        _NearbySpot(
          icon: '🐕',
          name: 'DogHub箱根仙石原',
          distance: '車約15分',
          description: '一時預かり・ドッグラン',
          url: 'https://dog-hub.shop/hotel/',
        ),
      ];
    }
    // 箱根・湯本
    if (areaId == 'a1111111-1111-1111-1111-111111111112') {
      return [
        _NearbySpot(
          icon: '🍡',
          name: '箱根湯本商店街',
          distance: '駅前',
          description: '温泉まんじゅう・干物の食べ歩き',
        ),
        _NearbySpot(
          icon: '🍵',
          name: 'ちもと本店',
          distance: null,
          description: '名物「湯もち」',
        ),
        _NearbySpot(
          icon: '🐕',
          name: 'DogHub箱根仙石原',
          distance: '車約25分',
          description: '一時預かり・ドッグラン',
          url: 'https://dog-hub.shop/hotel/',
        ),
      ];
    }
    // 箱根・芦ノ湖
    if (areaId == 'a1111111-1111-1111-1111-111111111116') {
      return [
        _NearbySpot(
          icon: '🚢',
          name: '箱根海賊船',
          distance: '元箱根港',
          description: 'ケージで犬乗船OK（30kg以下・300円）',
        ),
        _NearbySpot(
          icon: '🍝',
          name: 'ラ・テラッツァ芦ノ湖',
          distance: null,
          description: 'テラス席犬OK。湖畔のイタリアン',
        ),
        _NearbySpot(
          icon: '🐕',
          name: 'DogHub箱根仙石原',
          distance: '車約20分',
          description: '一時預かり・ドッグラン',
          url: 'https://dog-hub.shop/hotel/',
        ),
      ];
    }
    return [];
  }
}

class _NearbySpot {
  final String icon;
  final String name;
  final String? distance;
  final String description;
  final String? url;

  _NearbySpot({
    required this.icon,
    required this.name,
    this.distance,
    required this.description,
    this.url,
  });
}
