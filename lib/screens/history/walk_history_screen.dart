import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/walk_history_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/history/outing_walk_history_card.dart';
import '../../widgets/history/daily_walk_history_card.dart';
import '../../models/walk_history.dart';

/// 散歩履歴画面
/// - タブ切り替え（お出かけ/日常/すべて）
/// - お出かけ散歩：写真メイン、大きいカード
/// - 日常散歩：シンプル、小さいカード
/// - 月別表示、ページネーション対応
class WalkHistoryScreen extends ConsumerStatefulWidget {
  const WalkHistoryScreen({super.key});

  @override
  ConsumerState<WalkHistoryScreen> createState() => _WalkHistoryScreenState();
}

class _WalkHistoryScreenState extends ConsumerState<WalkHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  int _outingOffset = 0;
  int _dailyOffset = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // 80%スクロールしたら次のページを読み込む
      _loadMore();
    }
  }

  void _loadMore() {
    final currentTab = _tabController.index;
    if (currentTab == 0) {
      // お出かけ散歩
      setState(() {
        _outingOffset += _pageSize;
      });
    } else if (currentTab == 1) {
      // 日常散歩
      setState(() {
        _dailyOffset += _pageSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'ログインが必要です',
            style: WanMapTypography.bodyLarge.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          '散歩履歴',
          style: WanMapTypography.headlineSmall.copyWith(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark
            ? WanMapColors.backgroundDark
            : WanMapColors.backgroundLight,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark
              ? WanMapColors.textPrimaryDark
              : WanMapColors.textPrimaryLight,
        ),
      ),
      body: Column(
        children: [
          // サマリーエリア
          _buildSummarySection(userId, isDark),
          
          // タブバー
          TabBar(
            controller: _tabController,
            indicatorColor: WanMapColors.accent,
            labelColor: WanMapColors.accent,
            unselectedLabelColor: isDark
                ? WanMapColors.textSecondaryDark
                : WanMapColors.textSecondaryLight,
            labelStyle: WanMapTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: WanMapTypography.bodyMedium,
            tabs: const [
              Tab(text: 'すべて'),
              Tab(text: 'お出かけ'),
              Tab(text: '日常'),
            ],
          ),
          
          // タブコンテンツ
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // すべてタブ
                _buildAllTab(userId, isDark),

                // お出かけ散歩タブ
                _buildOutingTab(userId, isDark),

                // 日常散歩タブ
                _buildDailyTab(userId, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// お出かけ散歩タブ
  Widget _buildOutingTab(String userId, bool isDark) {
    final historyAsync = ref.watch(
      outingWalkHistoryProvider(
        OutingHistoryParams(
          userId: userId,
          limit: _pageSize,
          offset: _outingOffset,
        ),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _outingOffset = 0;
        });
        ref.invalidate(outingWalkHistoryProvider);
      },
      child: historyAsync.when(
        data: (histories) {
          if (histories.isEmpty && _outingOffset == 0) {
            return _buildEmptyState(
              isDark,
              Icons.explore_off,
              'まだお出かけ散歩の記録がありません',
              'お出かけルートを歩いて、思い出を残しましょう',
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(WanMapSpacing.lg),
            itemCount: histories.length + 1,
            itemBuilder: (context, index) {
              if (index == histories.length) {
                // ローディングインジケーター
                return _outingOffset > 0
                    ? const Padding(
                        padding: EdgeInsets.all(WanMapSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink();
              }

              final history = histories[index];
              return OutingWalkHistoryCard(
                history: history,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('散歩詳細画面は準備中です')),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(isDark, error.toString()),
      ),
    );
  }

  /// 日常散歩タブ
  Widget _buildDailyTab(String userId, bool isDark) {
    final historyAsync = ref.watch(
      dailyWalkHistoryProvider(
        DailyHistoryParams(
          userId: userId,
          limit: _pageSize,
          offset: _dailyOffset,
        ),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _dailyOffset = 0;
        });
        ref.invalidate(dailyWalkHistoryProvider);
      },
      child: Column(
        children: [
          // 説明文
          Container(
            margin: const EdgeInsets.all(WanMapSpacing.lg),
            padding: const EdgeInsets.all(WanMapSpacing.md),
            decoration: BoxDecoration(
              color: WanMapColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: WanMapColors.accent,
                  size: 20,
                ),
                const SizedBox(width: WanMapSpacing.sm),
                Expanded(
                  child: Text(
                    '日常散歩はログとして記録されています',
                    style: WanMapTypography.caption.copyWith(
                      color: WanMapColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // リスト
          Expanded(
            child: historyAsync.when(
              data: (histories) {
                if (histories.isEmpty && _dailyOffset == 0) {
                  return _buildEmptyState(
                    isDark,
                    Icons.pets,
                    'まだ日常散歩の記録がありません',
                    '毎日の散歩を記録してみましょう',
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: WanMapSpacing.lg,
                  ),
                  itemCount: histories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == histories.length) {
                      return _dailyOffset > 0
                          ? const Padding(
                              padding: EdgeInsets.all(WanMapSpacing.lg),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink();
                    }

                    final history = histories[index];
                    return DailyWalkHistoryCard(
                      history: history,
                      onTap: () {
                        // 簡易モーダル表示
                        _showDailyWalkDetail(context, history, isDark);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(isDark, error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  /// すべてタブ
  Widget _buildAllTab(String userId, bool isDark) {
    final historyAsync = ref.watch(
      allWalkHistoryProvider(
        AllHistoryParams(
          userId: userId,
          limit: 50,
        ),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allWalkHistoryProvider);
      },
      child: historyAsync.when(
        data: (histories) {
          if (histories.isEmpty) {
            return _buildEmptyState(
              isDark,
              Icons.history,
              'まだ散歩の記録がありません',
              '散歩を始めて、記録を残しましょう',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(WanMapSpacing.lg),
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final item = histories[index];

              if (item.type == WalkHistoryType.outing) {
                // お出かけ散歩
                final outing = OutingWalkHistory(
                  walkId: item.walkId,
                  routeId: item.routeId!,
                  routeName: item.routeName!,
                  areaName: item.areaName!,
                  walkedAt: item.walkedAt,
                  distanceMeters: item.distanceMeters,
                  durationSeconds: item.durationSeconds,
                  photoCount: item.photoCount ?? 0,
                  pinCount: item.pinCount ?? 0,
                  photoUrls: item.photoUrls ?? [],
                );
                return OutingWalkHistoryCard(
                  history: outing,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('散歩詳細画面は準備中です')),
                    );
                  },
                );
              } else {
                // 日常散歩
                final daily = DailyWalkHistory(
                  walkId: item.walkId,
                  walkedAt: item.walkedAt,
                  distanceMeters: item.distanceMeters,
                  durationSeconds: item.durationSeconds,
                );
                return DailyWalkHistoryCard(
                  history: daily,
                  onTap: () {
                    _showDailyWalkDetail(context, daily, isDark);
                  },
                );
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(isDark, error.toString()),
      ),
    );
  }

  /// 空状態
  Widget _buildEmptyState(
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: isDark
                  ? WanMapColors.textSecondaryDark.withOpacity(0.5)
                  : WanMapColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: WanMapSpacing.lg),
            Text(
              title,
              style: WanMapTypography.headlineSmall.copyWith(
                color: isDark
                    ? WanMapColors.textPrimaryDark
                    : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WanMapSpacing.sm),
            Text(
              subtitle,
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// エラー状態
  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: WanMapSpacing.lg),
            Text(
              '読み込みエラー',
              style: WanMapTypography.headlineSmall.copyWith(
                color: isDark
                    ? WanMapColors.textPrimaryDark
                    : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: WanMapSpacing.sm),
            Text(
              'データの取得に失敗しました',
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// サマリーセクション
  Widget _buildSummarySection(String userId, bool isDark) {
    final weeklyStatsAsync = ref.watch(weeklyStatisticsProvider(userId));
    final monthlyStatsAsync = ref.watch(monthlyStatisticsProvider(userId));

    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1週間の統計
          Expanded(
            child: weeklyStatsAsync.when(
              data: (stats) => _SummaryCard(
                icon: Icons.calendar_today,
                title: '1週間',
                walksCount: stats.totalWalks,
                distance: stats.formattedDistance,
                duration: stats.formattedDuration,
                color: Colors.blue,
                isDark: isDark,
              ),
              loading: () => _SummaryCardLoading(isDark: isDark),
              error: (_, __) => _SummaryCardError(isDark: isDark),
            ),
          ),
          const SizedBox(width: WanMapSpacing.md),
          // 1ヶ月の統計
          Expanded(
            child: monthlyStatsAsync.when(
              data: (stats) => _SummaryCard(
                icon: Icons.calendar_month,
                title: '1ヶ月',
                walksCount: stats.totalWalks,
                distance: stats.formattedDistance,
                duration: stats.formattedDuration,
                color: Colors.green,
                isDark: isDark,
              ),
              loading: () => _SummaryCardLoading(isDark: isDark),
              error: (_, __) => _SummaryCardError(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  /// 日常散歩詳細モーダル
  void _showDailyWalkDetail(
    BuildContext context,
    DailyWalkHistory history,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(WanMapSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ハンドル
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? WanMapColors.textSecondaryDark
                        : WanMapColors.textSecondaryLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: WanMapSpacing.lg),

              // タイトル
              Text(
                '日常散歩',
                style: WanMapTypography.headlineSmall.copyWith(
                  color: isDark
                      ? WanMapColors.textPrimaryDark
                      : WanMapColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: WanMapSpacing.md),

              // 統計情報
              _DetailRow(
                icon: Icons.calendar_today,
                label: '日時',
                value: DateFormat('yyyy年MM月dd日 HH:mm').format(history.walkedAt),
                isDark: isDark,
              ),
              const SizedBox(height: WanMapSpacing.sm),
              _DetailRow(
                icon: Icons.straighten,
                label: '距離',
                value: history.formattedDistance,
                isDark: isDark,
              ),
              const SizedBox(height: WanMapSpacing.sm),
              _DetailRow(
                icon: Icons.access_time,
                label: '時間',
                value: history.formattedDuration,
                isDark: isDark,
              ),

              const SizedBox(height: WanMapSpacing.xl),

              // 閉じるボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WanMapColors.accent,
                    padding: const EdgeInsets.symmetric(
                      vertical: WanMapSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '閉じる',
                    style: WanMapTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 詳細行
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark
              ? WanMapColors.textSecondaryDark
              : WanMapColors.textSecondaryLight,
        ),
        const SizedBox(width: WanMapSpacing.sm),
        Text(
          label,
          style: WanMapTypography.bodyMedium.copyWith(
            color: isDark
                ? WanMapColors.textSecondaryDark
                : WanMapColors.textSecondaryLight,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: WanMapTypography.bodyLarge.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// サマリーカード
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int walksCount;
  final String distance;
  final String duration;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.walksCount,
    required this.distance,
    required this.duration,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: WanMapSpacing.xs),
              Text(
                title,
                style: WanMapTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.sm),
          Text(
            '$walksCount回',
            style: WanMapTypography.headlineMedium.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.xs),
          Text(
            distance,
            style: WanMapTypography.bodySmall.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
          Text(
            duration,
            style: WanMapTypography.bodySmall.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// サマリーカードローディング
class _SummaryCardLoading extends StatelessWidget {
  final bool isDark;

  const _SummaryCardLoading({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// サマリーカードエラー
class _SummaryCardError extends StatelessWidget {
  final bool isDark;

  const _SummaryCardError({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.error_outline,
          size: 24,
          color: Colors.red.withOpacity(0.5),
        ),
      ),
    );
  }
}
