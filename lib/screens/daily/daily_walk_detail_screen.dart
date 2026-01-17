import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/walk_history_item.dart';

/// 日常散歩詳細画面
/// 
/// 日常散歩の記録詳細を表示
class DailyWalkDetailScreen extends StatelessWidget {
  final WalkHistoryItem history;

  const DailyWalkDetailScreen({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: const Text('日常散歩の記録'),
        backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WanMapSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーカード
            _buildHeaderCard(isDark),
            
            const SizedBox(height: WanMapSpacing.md),
            
            // 統計情報カード
            _buildStatsCard(isDark),
            
            const SizedBox(height: WanMapSpacing.md),
            
            // 詳細情報カード
            _buildDetailCard(isDark),
          ],
        ),
      ),
    );
  }

  /// ヘッダーカード
  Widget _buildHeaderCard(bool isDark) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(WanMapSpacing.sm),
                  decoration: BoxDecoration(
                    color: WanMapColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pets,
                    color: WanMapColors.accent,
                    size: 32,
                  ),
                ),
                const SizedBox(width: WanMapSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '日常散歩',
                        style: WanMapTypography.headlineSmall.copyWith(
                          color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: WanMapSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                          ),
                          const SizedBox(width: WanMapSpacing.xxs),
                          Text(
                            dateFormat.format(history.walkedAt),
                            style: WanMapTypography.bodyMedium.copyWith(
                              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (history.areaName != null) ...[
              const SizedBox(height: WanMapSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WanMapSpacing.sm,
                  vertical: WanMapSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: WanMapColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.my_location,
                      size: 16,
                      color: WanMapColors.primary,
                    ),
                    const SizedBox(width: WanMapSpacing.xs),
                    Text(
                      history.areaName!,
                      style: WanMapTypography.bodyMedium.copyWith(
                        color: WanMapColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 統計情報カード
  Widget _buildStatsCard(bool isDark) {
    final distance = history.distanceMeters;
    final duration = history.durationSeconds;
    
    final formattedDistance = distance < 1000
        ? '${distance.toStringAsFixed(0)}m'
        : '${(distance / 1000).toStringAsFixed(1)}km';
    
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final formattedDuration = hours > 0
        ? '$hours時間$minutes分'
        : '$minutes分';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '散歩の記録',
              style: WanMapTypography.titleMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: WanMapSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.straighten,
                    label: '距離',
                    value: formattedDistance,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: WanMapSpacing.md),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.access_time,
                    label: '時間',
                    value: formattedDuration,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 統計アイテム
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: WanMapColors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WanMapColors.accent.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: WanMapColors.accent,
            size: 32,
          ),
          const SizedBox(height: WanMapSpacing.sm),
          Text(
            value,
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.xxs),
          Text(
            label,
            style: WanMapTypography.bodySmall.copyWith(
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  /// 詳細情報カード
  Widget _buildDetailCard(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '詳細情報',
              style: WanMapTypography.titleMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: WanMapSpacing.md),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: '散歩ID',
              value: history.walkId.substring(0, 8),
              isDark: isDark,
            ),
            const Divider(height: WanMapSpacing.lg),
            _buildDetailRow(
              icon: Icons.route,
              label: '散歩タイプ',
              value: '日常散歩',
              isDark: isDark,
            ),
            if (history.pinCount != null && history.pinCount! > 0) ...[
              const Divider(height: WanMapSpacing.lg),
              _buildDetailRow(
                icon: Icons.location_on,
                label: 'ピン数',
                value: '${history.pinCount}個',
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 詳細行
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
        ),
        const SizedBox(width: WanMapSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: WanMapTypography.bodyMedium.copyWith(
              color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
            ),
          ),
        ),
        Text(
          value,
          style: WanMapTypography.bodyMedium.copyWith(
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
