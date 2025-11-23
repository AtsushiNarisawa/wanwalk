import 'package:flutter/material.dart';
import '../../models/badge.dart';
import '../../theme/app_colors.dart';

/// Badge Card Widget
/// 
/// Displays individual badge with:
/// - Badge icon with tier color
/// - Badge name and description
/// - Locked/Unlocked state
/// - Unlock date (if unlocked)
class BadgeCard extends StatelessWidget {
  final Badge badge;

  const BadgeCard({
    super.key,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: badge.isUnlocked ? 2 : 0,
      color: badge.isUnlocked
          ? (isDark ? Colors.grey[850] : Colors.white)
          : (isDark ? Colors.grey[900]!.withOpacity(0.3) : Colors.grey[200]!.withOpacity(0.5)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: badge.isUnlocked
            ? BorderSide(color: badge.tierColor.withOpacity(0.3), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Icon
            _buildBadgeIcon(isDark),
            
            const SizedBox(height: 12),
            
            // Badge Name
            Text(
              badge.nameJa,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: badge.isUnlocked
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // Tier Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badge.tierColor.withOpacity(badge.isUnlocked ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge.tier.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badge.isUnlocked
                      ? badge.tierColor
                      : badge.tierColor.withOpacity(0.4),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Badge Description
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 12,
                color: badge.isUnlocked
                    ? (isDark ? Colors.grey[400] : Colors.grey[600])
                    : (isDark ? Colors.grey[700] : Colors.grey[400]),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Unlock Status
            if (badge.isUnlocked && badge.unlockedAt != null)
              _buildUnlockDate(isDark)
            else
              _buildLockedStatus(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(bool isDark) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: badge.isUnlocked
            ? RadialGradient(
                colors: [
                  badge.tierColor.withOpacity(0.3),
                  badge.tierColor.withOpacity(0.1),
                ],
              )
            : null,
        color: badge.isUnlocked
            ? null
            : (isDark ? Colors.grey[800] : Colors.grey[300]),
      ),
      child: Icon(
        badge.icon,
        size: 36,
        color: badge.isUnlocked
            ? badge.tierColor
            : (isDark ? Colors.grey[700] : Colors.grey[400]),
      ),
    );
  }

  Widget _buildUnlockDate(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          size: 14,
          color: WanMapColors.accent,
        ),
        const SizedBox(width: 4),
        Text(
          _formatUnlockDate(badge.unlockedAt!),
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLockedStatus(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline,
          size: 14,
          color: isDark ? Colors.grey[700] : Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          'ロック中',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  String _formatUnlockDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return '今日獲得';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前に獲得';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}週間前に獲得';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}ヶ月前に獲得';
    } else {
      return '${date.year}/${date.month}/${date.day}に獲得';
    }
  }
}
