import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import '../../../models/walk_history.dart';
import '../../../models/badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/badge_provider.dart';
import '../../../providers/user_statistics_provider.dart';
import '../../../providers/walk_history_provider.dart';
import '../../../widgets/shimmer/wanmap_shimmer.dart';
import '../../history/walk_history_screen.dart';
import '../../history/outing_walk_detail_screen.dart';
import '../../badges/badge_list_screen.dart';

/// RecordsTab - 思い出ファースト構成
/// 
/// 構成:
/// 1. コンパクトヘッダー（レベル、総距離、エリア数）
/// 2. 今週の統計（1行）
/// 3. タブ切り替え（全て/お出かけ/日常）
/// 4. 最近の散歩リスト
/// 5. バッジコレクション（簡略版）
/// 6. 統計詳細リンク
class RecordsTab extends ConsumerStatefulWidget {
  const RecordsTab({super.key});

  @override
  ConsumerState<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends ConsumerState<RecordsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ライブラリ')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_walk, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('ログインして散歩記録を確認しましょう', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    final statisticsAsync = ref.watch(userStatisticsProvider(userId));
    final badgeStatsAsync = ref.watch(badgeStatisticsProvider(userId));

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.collections, color: WanMapColors.accent, size: 28),
            const SizedBox(width: 8),
            Text(
              'ライブラリ',
              style: WanMapTypography.headlineMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // コンパクトヘッダー
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: statisticsAsync.when(
            data: (stats) => _buildCompactHeader(stats, isDark),
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox(height: 48),
          ),
        ),
      ),
      body: Column(
        children: [
          // 今週の統計（1行）
          statisticsAsync.when(
            data: (stats) => _buildWeeklyStats(stats, isDark),
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // タブバー
          Container(
            color: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
            child: TabBar(
              controller: _tabController,
              labelColor: WanMapColors.accent,
              unselectedLabelColor: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              indicatorColor: WanMapColors.accent,
              labelStyle: WanMapTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: WanMapTypography.bodyMedium,
              tabs: const [
                Tab(text: '全て'),
                Tab(icon: Icon(Icons.explore, size: 20), text: 'お出かけ'),
                Tab(icon: Icon(Icons.directions_walk, size: 20), text: '日常'),
              ],
            ),
          ),

          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWalkList(null, isDark), // 全て
                _buildWalkList(WalkHistoryType.outing, isDark), // お出かけ
                _buildWalkList(WalkHistoryType.daily, isDark), // 日常
              ],
            ),
          ),

          // 下部：バッジ＆統計詳細リンク
          Container(
            padding: const EdgeInsets.all(WanMapSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
              border: Border(
                top: BorderSide(
                  color: isDark ? WanMapColors.borderDark : WanMapColors.borderLight,
                ),
              ),
            ),
            child: Column(
              children: [
                // バッジコレクション（簡略版）
                badgeStatsAsync.when(
                  data: (badgeStats) => _buildCompactBadges(context, badgeStats, isDark),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: WanMapSpacing.sm),
                // 統計詳細リンク
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 統計詳細画面へ遷移
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('統計詳細画面は準備中です')),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('全期間の統計を見る'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WanMapColors.accent,
                    side: const BorderSide(color: WanMapColors.accent),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// コンパクトヘッダー（AppBar下部）
  Widget _buildCompactHeader(dynamic stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg, vertical: WanMapSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CompactStat(
            icon: Icons.star,
            label: 'Lv.${stats.userLevel}',
            color: Colors.amber,
            isDark: isDark,
          ),
          _CompactStat(
            icon: Icons.route,
            label: stats.formattedTotalDistance,
            color: Colors.blue,
            isDark: isDark,
          ),
          _CompactStat(
            icon: Icons.explore,
            label: '${stats.areasVisited}箇所',
            color: WanMapColors.accent,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// 今週の統計（1行）
  Widget _buildWeeklyStats(dynamic stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg, vertical: WanMapSpacing.md),
      decoration: BoxDecoration(
        color: WanMapColors.accent.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: isDark ? WanMapColors.borderDark : WanMapColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '今週の散歩:',
            style: WanMapTypography.bodyMedium.copyWith(
              color: WanMapColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: WanMapSpacing.md),
          // TODO: 今週の統計データを取得（現在は仮データ）
          Expanded(
            child: Text(
              '5回 / 12.5km / 3時間',
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 散歩リスト
  Widget _buildWalkList(WalkHistoryType? filterType, bool isDark) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final outingAsync = ref.watch(outingWalkHistoryProvider(OutingHistoryParams(userId: userId)));
    final dailyAsync = ref.watch(dailyWalkHistoryProvider(DailyHistoryParams(userId: userId)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(outingWalkHistoryProvider(OutingHistoryParams(userId: userId)));
        ref.invalidate(dailyWalkHistoryProvider(DailyHistoryParams(userId: userId)));
      },
      child: outingAsync.when(
        data: (outingWalks) => dailyAsync.when(
          data: (dailyWalks) {
            // フィルタリング
            List<WalkHistoryItem> walks = [];
            if (filterType == null) {
              // 全て：両方の型を統合
              walks = [
                ...outingWalks.map((w) => WalkHistoryItem.fromOuting(w)),
                ...dailyWalks.map((w) => WalkHistoryItem.fromDaily(w)),
              ];
            } else if (filterType == WalkHistoryType.outing) {
              walks = outingWalks.map((w) => WalkHistoryItem.fromOuting(w)).toList();
            } else {
              walks = dailyWalks.map((w) => WalkHistoryItem.fromDaily(w)).toList();
            }

            // 日時でソート
            walks.sort((a, b) => b.walkedAt.compareTo(a.walkedAt));

            if (walks.isEmpty) {
              return _buildEmptyState(filterType, isDark);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(WanMapSpacing.lg),
              itemCount: walks.length,
              itemBuilder: (context, index) {
                final walk = walks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: WanMapSpacing.md),
                  child: _WalkCard(
                    walk: walk,
                    isDark: isDark,
                    onTap: () {
                      if (walk.type == WalkHistoryType.outing) {
                        // お出かけ散歩詳細画面へ
                        // WalkHistoryItemからOutingWalkHistoryを再構成
                        final outingHistory = OutingWalkHistory(
                          walkId: walk.walkId,
                          routeId: walk.routeId ?? '',
                          routeName: walk.routeName ?? '',
                          areaName: walk.areaName ?? '',
                          walkedAt: walk.walkedAt,
                          distanceMeters: walk.distanceMeters,
                          durationSeconds: walk.durationSeconds,
                          photoCount: walk.photoCount ?? 0,
                          pinCount: walk.pinCount ?? 0,
                          photoUrls: walk.photoUrls ?? [],
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OutingWalkDetailScreen(history: outingHistory),
                          ),
                        );
                      } else {
                        // TODO: 日常散歩詳細画面へ遷移
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('日常散歩詳細画面は準備中です')),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildEmptyState(filterType, isDark),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEmptyState(filterType, isDark),
      ),
    );
  }

  /// 空状態
  Widget _buildEmptyState(WalkHistoryType? filterType, bool isDark) {
    String message;
    if (filterType == WalkHistoryType.outing) {
      message = 'お出かけ散歩の記録がありません\n公式ルートを歩いて思い出を残しましょう';
    } else if (filterType == WalkHistoryType.daily) {
      message = '日常散歩の記録がありません\nいつもの散歩を記録してみましょう';
    } else {
      message = '散歩の記録がありません\nさっそく散歩に出かけましょう！';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_walk,
              size: 64,
              color: isDark
                  ? WanMapColors.textSecondaryDark.withOpacity(0.5)
                  : WanMapColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: WanMapSpacing.lg),
            Text(
              message,
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// コンパクトバッジ表示
  Widget _buildCompactBadges(BuildContext context, BadgeStatistics badgeStats, bool isDark) {
    final earnedCount = badgeStats.unlockedBadges;
    final totalCount = badgeStats.totalBadges;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BadgeListScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(WanMapSpacing.md),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: WanMapSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'バッジコレクション',
                    style: WanMapTypography.bodyMedium.copyWith(
                      color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$earnedCount/$totalCount個獲得',
                    style: WanMapTypography.bodySmall.copyWith(
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}

/// コンパクト統計項目
class _CompactStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _CompactStat({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: WanMapSpacing.xs),
        Text(
          label,
          style: WanMapTypography.bodySmall.copyWith(
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 散歩カード
class _WalkCard extends StatelessWidget {
  final WalkHistoryItem walk;
  final bool isDark;
  final VoidCallback onTap;

  const _WalkCard({
    required this.walk,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOuting = walk.type == WalkHistoryType.outing;
    // WalkHistoryItemからoutingデータを直接使用

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真（お出かけ散歩のみ）
            if (isOuting && walk.photoUrls != null && walk.photoUrls!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: walk.photoUrls!.length > 3 ? 3 : walk.photoUrls!.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: WanMapSpacing.xs),
                        child: Image.network(
                          walk.photoUrls![index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
                            child: const Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // カード情報
            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Row(
                    children: [
                      Icon(
                        isOuting ? Icons.explore : Icons.directions_walk,
                        color: WanMapColors.accent,
                        size: 24,
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      Expanded(
                        child: Text(
                          isOuting ? (walk.routeName ?? 'お出かけ散歩') : _formatDateTimeTitle(walk.walkedAt),
                          style: WanMapTypography.bodyLarge.copyWith(
                            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WanMapSpacing.sm),

                  // サブ情報
                  Row(
                    children: [
                      if (isOuting && walk.areaName != null) ...[
                        Icon(Icons.location_on, size: 14, color: WanMapColors.accent),
                        const SizedBox(width: WanMapSpacing.xs),
                        Text(
                          walk.areaName!,
                          style: WanMapTypography.bodySmall.copyWith(
                            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: WanMapSpacing.md),
                      ],
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanMapSpacing.xs),
                      Text(
                        _formatDate(walk.walkedAt),
                        style: WanMapTypography.bodySmall.copyWith(
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WanMapSpacing.sm),

                  // 統計
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.straighten,
                        label: walk.formattedDistance,
                        isDark: isDark,
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      _StatChip(
                        icon: Icons.access_time,
                        label: walk.formattedDuration,
                        isDark: isDark,
                      ),
                      if (isOuting && walk.pinCount != null && walk.pinCount! > 0) ...[
                        const SizedBox(width: WanMapSpacing.sm),
                        _StatChip(
                          icon: Icons.push_pin,
                          label: '${walk.pinCount}個',
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTimeTitle(DateTime date) {
    final hour = date.hour;
    if (hour < 12) {
      return '朝の散歩';
    } else if (hour < 17) {
      return '午後の散歩';
    } else {
      return '夕方の散歩';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) {
      return '今日';
    } else if (diff == 1) {
      return '昨日';
    } else if (diff < 7) {
      return '$diff日前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

/// 統計チップ
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanMapSpacing.sm,
        vertical: WanMapSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: WanMapColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: WanMapColors.accent),
          const SizedBox(width: WanMapSpacing.xs),
          Text(
            label,
            style: WanMapTypography.caption.copyWith(
              color: WanMapColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
