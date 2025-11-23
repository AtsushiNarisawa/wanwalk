import 'package:flutter/material.dart';

/// バッジモデル
class Badge {
  final String badgeId;
  final String badgeCode;
  final String nameJa;
  final String nameEn;
  final String description;
  final String iconName;
  final BadgeCategory category;
  final BadgeTier tier;
  final DateTime? unlockedAt;
  final bool isNew;
  final bool isUnlocked;

  Badge({
    required this.badgeId,
    required this.badgeCode,
    required this.nameJa,
    required this.nameEn,
    required this.description,
    required this.iconName,
    required this.category,
    required this.tier,
    this.unlockedAt,
    required this.isNew,
    required this.isUnlocked,
  });

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      badgeId: map['badge_id'] as String,
      badgeCode: map['badge_code'] as String,
      nameJa: map['name_ja'] as String,
      nameEn: map['name_en'] as String,
      description: map['description'] as String,
      iconName: map['icon_name'] as String,
      category: BadgeCategory.fromString(map['category'] as String),
      tier: BadgeTier.fromString(map['tier'] as String),
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'] as String)
          : null,
      isNew: map['is_new'] as bool? ?? false,
      isUnlocked: map['is_unlocked'] as bool,
    );
  }

  /// アイコン（Flutter Icons）
  IconData get icon {
    switch (iconName) {
      case 'directions_walk':
        return Icons.directions_walk;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'military_tech':
        return Icons.military_tech;
      case 'explore':
        return Icons.explore;
      case 'public':
        return Icons.public;
      case 'travel_explore':
        return Icons.travel_explore;
      case 'push_pin':
        return Icons.push_pin;
      case 'location_on':
        return Icons.location_on;
      case 'add_location':
        return Icons.add_location;
      case 'place':
        return Icons.place;
      case 'people':
        return Icons.people;
      case 'groups':
        return Icons.groups;
      case 'supervisor_account':
        return Icons.supervisor_account;
      case 'celebration':
        return Icons.celebration;
      case 'new_releases':
        return Icons.new_releases;
      case 'star':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }

  /// ティア別カラー
  Color get tierColor {
    return tier.color;
  }

  /// カテゴリ別カラー
  Color get categoryColor {
    return category.color;
  }
}

/// バッジカテゴリ
enum BadgeCategory {
  distance('distance', '距離', Colors.blue),
  area('area', 'エリア', Colors.green),
  pins('pins', 'ピン', Colors.orange),
  social('social', 'ソーシャル', Colors.purple),
  special('special', '特別', Colors.amber);

  const BadgeCategory(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static BadgeCategory fromString(String value) {
    return BadgeCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BadgeCategory.special,
    );
  }
}

/// バッジティア
enum BadgeTier {
  bronze('bronze', 'ブロンズ', Color(0xFFCD7F32)),
  silver('silver', 'シルバー', Color(0xFFC0C0C0)),
  gold('gold', 'ゴールド', Color(0xFFFFD700)),
  platinum('platinum', 'プラチナ', Color(0xFFE5E4E2));

  const BadgeTier(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static BadgeTier fromString(String value) {
    return BadgeTier.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BadgeTier.bronze,
    );
  }
}

/// バッジ統計
class BadgeStatistics {
  final int totalBadges;
  final int unlockedBadges;
  final int newBadges;
  final Map<BadgeCategory, int> byCategory;
  final Map<BadgeTier, int> byTier;

  BadgeStatistics({
    required this.totalBadges,
    required this.unlockedBadges,
    required this.newBadges,
    required this.byCategory,
    required this.byTier,
  });

  /// 解除率（0.0 ~ 1.0）
  double get unlockProgress {
    if (totalBadges == 0) return 0.0;
    return unlockedBadges / totalBadges;
  }

  /// 解除率パーセンテージ
  String get unlockProgressPercentage {
    return '${(unlockProgress * 100).toStringAsFixed(0)}%';
  }

  static BadgeStatistics fromBadgeList(List<Badge> badges) {
    final unlockedBadges = badges.where((b) => b.isUnlocked).toList();
    final newBadges = badges.where((b) => b.isNew).toList();

    final byCategory = <BadgeCategory, int>{};
    for (final category in BadgeCategory.values) {
      byCategory[category] = unlockedBadges.where((b) => b.category == category).length;
    }

    final byTier = <BadgeTier, int>{};
    for (final tier in BadgeTier.values) {
      byTier[tier] = unlockedBadges.where((b) => b.tier == tier).length;
    }

    return BadgeStatistics(
      totalBadges: badges.length,
      unlockedBadges: unlockedBadges.length,
      newBadges: newBadges.length,
      byCategory: byCategory,
      byTier: byTier,
    );
  }
}
