import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/badge_provider.dart';
import '../theme/app_colors.dart';

/// Badge Unlock Helper
/// 
/// Helper utilities for checking and displaying badge unlocks.
/// Call this after walk completion or other achievement events.
class BadgeUnlockHelper {
  /// Check for newly unlocked badges after a walk or achievement
  /// 
  /// This should be called after:
  /// - Walk completion
  /// - New pin creation
  /// - New follower gained
  /// - Any other achievement event
  /// 
  /// Returns list of newly unlocked badge IDs
  static Future<List<String>> checkAndUnlockBadges({
    required String userId,
    required WidgetRef ref,
  }) async {
    try {
      final badgeService = ref.read(badgeServiceProvider);
      
      // Check and unlock eligible badges
      final newlyUnlockedIds = await badgeService.checkAndUnlockBadges(
        userId: userId,
      );
      
      // If any new badges were unlocked, invalidate providers to refresh UI
      if (newlyUnlockedIds.isNotEmpty) {
        ref.invalidate(userBadgesProvider(userId));
        ref.invalidate(badgesByCategoryProvider(userId));
        ref.invalidate(badgeStatisticsProvider(userId));
      }
      
      return newlyUnlockedIds;
    } catch (e) {
      debugPrint('Error checking badges: $e');
      return [];
    }
  }

  /// Show badge unlock dialog when new badges are unlocked
  /// 
  /// Call this after checkAndUnlockBadges returns non-empty list
  static Future<void> showBadgeUnlockDialog({
    required BuildContext context,
    required int badgeCount,
  }) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: WanMapColors.accent,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('新しいバッジを獲得！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              badgeCount == 1
                  ? '新しいバッジを獲得しました！'
                  : '$badgeCount個の新しいバッジを獲得しました！',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('後で見る'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to badge list screen
              // Note: This requires proper navigation setup
              // Navigator.pushNamed(context, '/badges');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WanMapColors.accent,
            ),
            child: const Text('バッジを見る'),
          ),
        ],
      ),
    );
  }

  /// Show badge unlock snackbar (less intrusive than dialog)
  /// 
  /// Use this for quick feedback without interrupting user flow
  static void showBadgeUnlockSnackbar({
    required BuildContext context,
    required int badgeCount,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: WanMapColors.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                badgeCount == 1
                    ? '新しいバッジを獲得しました！'
                    : '$badgeCount個の新しいバッジを獲得しました！',
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '見る',
          onPressed: () {
            // Navigate to badge list screen
            // Navigator.pushNamed(context, '/badges');
          },
        ),
      ),
    );
  }
}

/// Extension method for easier badge checking from ConsumerStatefulWidget
extension BadgeUnlockExtension on WidgetRef {
  /// Convenient method to check and show badge unlocks
  Future<void> checkAndShowBadgeUnlocks({
    required String userId,
    required BuildContext context,
    bool showDialog = false,
  }) async {
    final newlyUnlockedIds = await BadgeUnlockHelper.checkAndUnlockBadges(
      userId: userId,
      ref: this,
    );

    if (newlyUnlockedIds.isNotEmpty && context.mounted) {
      if (showDialog) {
        await BadgeUnlockHelper.showBadgeUnlockDialog(
          context: context,
          badgeCount: newlyUnlockedIds.length,
        );
      } else {
        BadgeUnlockHelper.showBadgeUnlockSnackbar(
          context: context,
          badgeCount: newlyUnlockedIds.length,
        );
      }
    }
  }
}
