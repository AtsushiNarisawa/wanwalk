import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/wanwalk_colors.dart';
import '../../models/route_pin.dart';
import '../../models/route_spot.dart';
import 'dog_policy_badges.dart';

/// おすすめスポット表示対象のカテゴリ（infrastructure系は除外）
const Set<SpotCategory> _featuredCategories = {
  SpotCategory.viewpoint,
  SpotCategory.cafe,
  SpotCategory.restaurant,
  SpotCategory.park,
  SpotCategory.shop,
  SpotCategory.dogRun,
};

class _MergedSpot {
  final String id;
  final String title;
  final String? description;
  final String? photoUrl;
  final DogPolicy? dogPolicy;

  _MergedSpot({
    required this.id,
    required this.title,
    this.description,
    this.photoUrl,
    this.dogPolicy,
  });
}

String _normalize(String s) =>
    s.replaceAll(RegExp(r'[\s　]+'), '').toLowerCase();

List<_MergedSpot> _mergeSpotsAndPins(
  List<RouteSpot> spots,
  List<RoutePin> pins,
) {
  final result = <_MergedSpot>[];
  final usedPinIds = <String>{};

  // 1. featuredカテゴリの spots を追加（同名 pin と統合）
  final featured = spots
      .where((s) => s.category != null && _featuredCategories.contains(s.category))
      .toList();

  for (final spot in featured) {
    final spotKey = _normalize(spot.name);
    final matching = pins.where((p) {
      final pinKey = _normalize(p.title);
      return pinKey.contains(spotKey) || spotKey.contains(pinKey);
    }).toList();

    if (matching.isNotEmpty) {
      final pin = matching.first;
      usedPinIds.add(pin.id);
      result.add(_MergedSpot(
        id: spot.id,
        title: pin.title,
        description: pin.comment.isNotEmpty ? pin.comment : spot.description,
        photoUrl: pin.photoUrls.isNotEmpty ? pin.photoUrls.first : spot.photoUrl,
        dogPolicy: spot.dogPolicy,
      ));
    } else if (spot.photoUrl != null || (spot.description?.isNotEmpty ?? false)) {
      result.add(_MergedSpot(
        id: spot.id,
        title: spot.name,
        description: spot.description,
        photoUrl: spot.photoUrl,
        dogPolicy: spot.dogPolicy,
      ));
    }
  }

  // 2. spots に統合されなかった公式 pins を追加
  for (final pin in pins) {
    if (usedPinIds.contains(pin.id)) continue;
    result.add(_MergedSpot(
      id: pin.id,
      title: pin.title,
      description: pin.comment.isNotEmpty ? pin.comment : null,
      photoUrl: pin.photoUrls.isNotEmpty ? pin.photoUrls.first : null,
    ));
  }

  // 3. 写真ありを先頭に
  result.sort((a, b) {
    final aHas = a.photoUrl != null;
    final bHas = b.photoUrl != null;
    if (aHas && !bHas) return -1;
    if (!aHas && bHas) return 1;
    return 0;
  });

  return result;
}

/// おすすめスポット（spots + 公式pins 統合表示）
///
/// FEATURED_CATEGORIES に該当する spots と、その他の公式 pins を
/// 名前正規化で重複排除して統合表示する。
class FeaturedSpots extends StatelessWidget {
  final List<RouteSpot> spots;
  final List<RoutePin> officialPins;

  const FeaturedSpots({
    super.key,
    required this.spots,
    required this.officialPins,
  });

  @override
  Widget build(BuildContext context) {
    final merged = _mergeSpotsAndPins(spots, officialPins);
    if (merged.isEmpty) return const SizedBox.shrink();

    final usedPhotos = <String>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: merged.map((item) {
        var photoUrl = item.photoUrl;
        if (photoUrl != null && usedPhotos.contains(photoUrl)) {
          photoUrl = null;
        }
        if (photoUrl != null) usedPhotos.add(photoUrl);
        return _SpotCard(item: item, photoUrl: photoUrl);
      }).toList(),
    );
  }
}

class _SpotCard extends StatelessWidget {
  final _MergedSpot item;
  final String? photoUrl;

  const _SpotCard({required this.item, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null;
    final desc = item.description;

    return Container(
      margin: EdgeInsets.only(bottom: hasPhoto ? 24 : 0),
      padding: EdgeInsets.only(top: 20, bottom: hasPhoto ? 24 : 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: WanWalkColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: TextStyle(
              fontSize: hasPhoto ? 20 : 16,
              fontWeight: FontWeight.w600,
              color: WanWalkColors.textPrimaryLight,
              height: 1.5,
            ),
          ),
          if (desc != null && desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              desc,
              style: TextStyle(
                fontSize: hasPhoto ? 15 : 14,
                fontWeight: FontWeight.w400,
                height: 1.7,
                color: WanWalkColors.textSecondaryLight,
              ),
            ),
          ],
          if (item.dogPolicy != null) DogPolicyBadges(policy: item.dogPolicy!),
          if (hasPhoto) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: photoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: WanWalkColors.borderSubtle.withValues(alpha: 0.3),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: WanWalkColors.borderSubtle.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
