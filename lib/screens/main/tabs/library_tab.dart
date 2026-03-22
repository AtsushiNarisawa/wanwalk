import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanwalk_colors.dart';
import '../../../config/wanwalk_typography.dart';
import '../../../config/wanwalk_spacing.dart';
import '../../../models/walk_history.dart';
import '../../../models/route_pin.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_statistics_provider.dart';
import '../../../providers/walk_history_provider.dart';
import '../../daily/daily_walk_detail_screen.dart';
import '../../../providers/route_pin_provider.dart';
import '../../history/outing_walk_detail_screen.dart';
import '../../outing/pin_detail_screen.dart';
import '../../auth/auth_selection_screen.dart';
import '../../../providers/timeline_provider.dart';
import '../../../services/timeline_service.dart';
import '../../../utils/logger.dart';

/// LibraryTab - 愛犬との散歩の思い出アルバム
/// 
/// 構成:
/// 1. シンプルヘッダー（優しいメッセージ）
/// 2. 今月の散歩回数（控えめ）
/// 3. タブ切り替え（タイムライン/アルバム/お出かけ/日常/ピン投稿）
/// 4. 思い出のタイムライン
/// 5. 写真アルバム
/// 6. ピン投稿履歴
class LibraryTab extends ConsumerStatefulWidget {
  const LibraryTab({super.key});

  @override
  ConsumerState<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<LibraryTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 5タブに変更
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
        backgroundColor: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.collections, color: WanWalkColors.accent, size: 28),
              const SizedBox(width: 8),
              Text(
                'ライブラリ',
                style: WanWalkTypography.headlineMedium.copyWith(
                  color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: _buildUnauthenticatedState(context, isDark),
      );
    }

    final statisticsAsync = ref.watch(userStatisticsProvider(userId));

    return Scaffold(
      backgroundColor: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.collections, color: WanWalkColors.accent, size: 28),
            const SizedBox(width: 8),
            Text(
              'ライブラリ',
              style: WanWalkTypography.headlineMedium.copyWith(
                color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 今月の散歩回数（控えめ）
          statisticsAsync.when(
            data: (stats) => _buildMonthlyWalkCount(stats, isDark),
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // タブバー
          Container(
            color: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
            child: TabBar(
              controller: _tabController,
              labelColor: WanWalkColors.primary,
              unselectedLabelColor: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
              indicatorColor: WanWalkColors.primary,
              indicatorWeight: 3,
              labelStyle: WanWalkTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: WanWalkTypography.bodySmall.copyWith(
                fontSize: 11,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              isScrollable: false,
              tabs: const [
                Tab(icon: Icon(Icons.newspaper, size: 20), text: 'みんな'),
                Tab(icon: Icon(Icons.photo_library, size: 20), text: 'アルバム'),
                Tab(icon: Icon(Icons.luggage, size: 20), text: 'お出かけ'),
                Tab(icon: Icon(Icons.pets, size: 20), text: '日常'),
                Tab(icon: Icon(Icons.location_on, size: 20), text: 'ピン'),
              ],
            ),
          ),

          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCommunityTimeline(isDark), // コミュニティタイムライン
                _buildAlbumTab(isDark), // アルバム
                _buildWalkList(WalkHistoryType.outing, isDark), // お出かけ
                _buildWalkList(WalkHistoryType.daily, isDark), // 日常
                _buildPinHistoryTab(isDark), // ピン投稿履歴
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 今月の散歩回数（実データ）
  Widget _buildMonthlyWalkCount(dynamic stats, bool isDark) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final outingAsync = ref.watch(outingWalkHistoryProvider(OutingHistoryParams(userId: userId)));
    final dailyAsync = ref.watch(dailyWalkHistoryProvider(DailyHistoryParams(userId: userId)));

    // ローディング状態の確認
    if (outingAsync.isLoading || dailyAsync.isLoading) {
      appLog('📊 月間統計: ローディング中...');
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    // エラー状態の確認
    if (outingAsync.hasError || dailyAsync.hasError) {
      appLog('❌ 月間統計: エラー発生 - outing: ${outingAsync.hasError}, daily: ${dailyAsync.hasError}');
      return const SizedBox.shrink();
    }

    // データがある場合のみ表示
    final outingWalks = outingAsync.value ?? [];
    final dailyWalks = dailyAsync.value ?? [];

    // 今月の散歩を集計
    final now = DateTime.now();
    final thisMonthOuting = outingWalks.where((w) => 
      w.walkedAt.year == now.year && w.walkedAt.month == now.month
    ).length;
    final thisMonthDaily = dailyWalks.where((w) => 
      w.walkedAt.year == now.year && w.walkedAt.month == now.month
    ).length;
    final monthlyWalkCount = thisMonthOuting + thisMonthDaily;

    // 今月の総距離を計算
    final thisMonthDistance = outingWalks
        .where((w) => w.walkedAt.year == now.year && w.walkedAt.month == now.month)
        .fold<double>(0, (sum, w) => sum + w.distanceMeters) +
      dailyWalks
        .where((w) => w.walkedAt.year == now.year && w.walkedAt.month == now.month)
        .fold<double>(0, (sum, w) => sum + w.distanceMeters);
    
    final formattedDistance = thisMonthDistance < 1000
        ? '${thisMonthDistance.toStringAsFixed(0)}m'
        : '${(thisMonthDistance / 1000).toStringAsFixed(1)}km';

    // デバッグログ
    appLog('📊 月間統計: 今月の散歩回数=$monthlyWalkCount回, 総距離=$formattedDistance');
    appLog('📊 お出かけ散歩=$thisMonthOuting回, 日常散歩=$thisMonthDaily回');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg, vertical: WanWalkSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WanWalkColors.accent.withOpacity(0.1),
            WanWalkColors.accent.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: WanWalkColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              size: 20,
              color: WanWalkColors.accent,
            ),
          ),
          const SizedBox(width: WanWalkSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今月の記録',
                  style: WanWalkTypography.caption.copyWith(
                    color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$monthlyWalkCount回',
                      style: WanWalkTypography.titleMedium.copyWith(
                        color: WanWalkColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: WanWalkSpacing.sm),
                    Text(
                      '・',
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: WanWalkSpacing.xs),
                    Text(
                      formattedDistance,
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// アルバムタブ（写真グリッド）
  Widget _buildAlbumTab(bool isDark) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final outingAsync = ref.watch(outingWalkHistoryProvider(OutingHistoryParams(userId: userId)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(outingWalkHistoryProvider(OutingHistoryParams(userId: userId)));
      },
      child: outingAsync.when(
        data: (outingWalks) {
          // 全ての写真を収集
          final allPhotos = <Map<String, dynamic>>[];
          for (var walk in outingWalks) {
            for (var photoUrl in walk.photoUrls) {
              allPhotos.add({
                'url': photoUrl,
                'walk': walk,
              });
            }
          }

          if (allPhotos.isEmpty) {
            return _buildEmptyAlbumState(isDark);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: allPhotos.length,
            itemBuilder: (context, index) {
              final photo = allPhotos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OutingWalkDetailScreen(
                        history: photo['walk'] as OutingWalkHistory,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    photo['url'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
                        child: Icon(
                          Icons.broken_image,
                          color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEmptyAlbumState(isDark),
      ),
    );
  }

  /// ピン投稿履歴タブ
  Widget _buildPinHistoryTab(bool isDark) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final pinsAsync = ref.watch(userPinsProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userPinsProvider(userId));
      },
      child: pinsAsync.when(
        data: (pins) {
          if (pins.isEmpty) {
            return _buildEmptyPinHistoryState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(WanWalkSpacing.lg),
            itemCount: pins.length,
            itemBuilder: (context, index) {
              final pin = pins[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: WanWalkSpacing.md),
                child: _PinHistoryCard(
                  pin: pin,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PinDetailScreen(pinId: pin.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEmptyPinHistoryState(isDark),
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

            // 月別にグループ化
            final groupedWalks = _groupWalksByMonth(walks);

            return ListView.builder(
              padding: const EdgeInsets.all(WanWalkSpacing.lg),
              itemCount: _calculateTotalItems(groupedWalks),
              itemBuilder: (context, index) {
                final item = _getItemAtIndex(groupedWalks, index);
                
                // 月ヘッダー
                if (item['type'] == 'header') {
                  final monthData = item['data'] as Map<String, dynamic>;
                  return _buildMonthHeader(
                    monthData['yearMonth'] as String,
                    monthData['walks'] as List<WalkHistoryItem>,
                    isDark,
                  );
                }
                
                // 散歩カード
                final walk = item['data'] as WalkHistoryItem;
                return Padding(
                  padding: const EdgeInsets.only(bottom: WanWalkSpacing.md),
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
                        // 日常散歩詳細画面へ遷移
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DailyWalkDetailScreen(history: walk),
                          ),
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
        padding: const EdgeInsets.all(WanWalkSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_walk,
              size: 64,
              color: isDark
                  ? WanWalkColors.textSecondaryDark.withOpacity(0.5)
                  : WanWalkColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: WanWalkSpacing.lg),
            Text(
              message,
              style: WanWalkTypography.bodyMedium.copyWith(
                color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// アルバムが空の状態
  Widget _buildEmptyAlbumState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanWalkSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: isDark
                  ? WanWalkColors.textSecondaryDark.withOpacity(0.5)
                  : WanWalkColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: WanWalkSpacing.lg),
            Text(
              'まだ写真がありません\nお出かけ散歩で写真を撮って\n思い出を残しましょう！',
              style: WanWalkTypography.bodyMedium.copyWith(
                color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// ピン投稿履歴が空の状態
  Widget _buildEmptyPinHistoryState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanWalkSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.push_pin_outlined,
              size: 64,
              color: isDark
                  ? WanWalkColors.textSecondaryDark.withOpacity(0.5)
                  : WanWalkColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: WanWalkSpacing.lg),
            Text(
              'まだピン投稿がありません\n散歩中に素敵な場所を見つけたら\nピンを立ててみましょう！',
              style: WanWalkTypography.bodyMedium.copyWith(
                color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 未ログイン状態の表示
  Widget _buildUnauthenticatedState(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(WanWalkSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: WanWalkSpacing.xl),
          // イラスト風アイコン
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  WanWalkColors.accent.withOpacity(0.15),
                  WanWalkColors.accentLight.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.collections_bookmark_outlined,
              size: 56,
              color: WanWalkColors.accent,
            ),
          ),
          const SizedBox(height: WanWalkSpacing.lg),
          Text(
            '散歩の思い出を記録しよう',
            style: WanWalkTypography.headlineSmall.copyWith(
              color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanWalkSpacing.sm),
          Text(
            'ログインすると、散歩の記録や写真を\nライブラリに保存できます',
            style: WanWalkTypography.bodyMedium.copyWith(
              color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WanWalkSpacing.xl),
          // 機能紹介カード
          _UnauthFeatureItem(
            icon: Icons.route,
            color: WanWalkColors.routeOrange,
            title: '散歩ルートを記録',
            description: '歩いたルートと距離を自動記録',
            isDark: isDark,
          ),
          const SizedBox(height: WanWalkSpacing.sm),
          _UnauthFeatureItem(
            icon: Icons.photo_library_outlined,
            color: WanWalkColors.accent,
            title: '写真アルバム',
            description: '散歩中の写真を自動でまとめる',
            isDark: isDark,
          ),
          const SizedBox(height: WanWalkSpacing.sm),
          _UnauthFeatureItem(
            icon: Icons.add_location_alt_outlined,
            color: WanWalkColors.secondary,
            title: 'ピン投稿',
            description: 'お気に入りスポットを共有',
            isDark: isDark,
          ),
          const SizedBox(height: WanWalkSpacing.xl),
          // ログインボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthSelectionScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: WanWalkColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'ログイン / 新規登録',
                style: WanWalkTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: WanWalkSpacing.md),
          Text(
            'ログインなしでもマップの閲覧はできます',
            style: WanWalkTypography.caption.copyWith(
              color: isDark ? WanWalkColors.textTertiaryDark : WanWalkColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }

  /// 月別にグループ化
  Map<String, List<WalkHistoryItem>> _groupWalksByMonth(List<WalkHistoryItem> walks) {
    final grouped = <String, List<WalkHistoryItem>>{};
    
    for (final walk in walks) {
      final yearMonth = '${walk.walkedAt.year}年${walk.walkedAt.month}月';
      grouped.putIfAbsent(yearMonth, () => []);
      grouped[yearMonth]!.add(walk);
    }
    
    return grouped;
  }

  /// 月ヘッダーを構築
  Widget _buildMonthHeader(String yearMonth, List<WalkHistoryItem> walks, bool isDark) {
    // 月の統計を計算
    final totalDistance = walks.fold<double>(
      0,
      (sum, walk) => sum + walk.distanceMeters,
    );
    final formattedDistance = totalDistance < 1000
        ? '${totalDistance.toStringAsFixed(0)}m'
        : '${(totalDistance / 1000).toStringAsFixed(1)}km';

    return Container(
      margin: const EdgeInsets.only(bottom: WanWalkSpacing.md, top: WanWalkSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.md,
        vertical: WanWalkSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            WanWalkColors.accent.withOpacity(0.15),
            WanWalkColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WanWalkColors.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: WanWalkColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month,
              size: 18,
              color: WanWalkColors.accent,
            ),
          ),
          const SizedBox(width: WanWalkSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  yearMonth,
                  style: WanWalkTypography.bodyLarge.copyWith(
                    color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${walks.length}回・$formattedDistance',
                  style: WanWalkTypography.bodySmall.copyWith(
                    color: WanWalkColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// リストの総アイテム数を計算（ヘッダー + 散歩カード）
  int _calculateTotalItems(Map<String, List<WalkHistoryItem>> groupedWalks) {
    int count = 0;
    for (final entry in groupedWalks.entries) {
      count += 1; // ヘッダー
      count += entry.value.length; // 散歩カード
    }
    return count;
  }

  /// インデックスに対応するアイテムを取得
  Map<String, dynamic> _getItemAtIndex(Map<String, List<WalkHistoryItem>> groupedWalks, int index) {
    int currentIndex = 0;
    
    for (final entry in groupedWalks.entries) {
      // ヘッダー
      if (currentIndex == index) {
        return {
          'type': 'header',
          'data': {
            'yearMonth': entry.key,
            'walks': entry.value,
          },
        };
      }
      currentIndex++;
      
      // 散歩カード
      for (final walk in entry.value) {
        if (currentIndex == index) {
          return {
            'type': 'walk',
            'data': walk,
          };
        }
        currentIndex++;
      }
    }
    
    // フォールバック（ここには来ないはず）
    return {'type': 'walk', 'data': groupedWalks.values.first.first};
  }

  /// コミュニティタイムライン
  Widget _buildCommunityTimeline(bool isDark) {
    final userId = ref.watch(currentUserIdProvider);
    final timelineAsync = ref.watch(
      communityTimelineProvider(TimelineParams(userId: userId)),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(communityTimelineProvider);
      },
      child: timelineAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.newspaper,
                          size: 64,
                          color: isDark
                              ? WanWalkColors.textSecondaryDark.withOpacity(0.5)
                              : WanWalkColors.textSecondaryLight.withOpacity(0.5),
                        ),
                        const SizedBox(height: WanWalkSpacing.lg),
                        Text(
                          'まだ投稿がありません',
                          style: WanWalkTypography.headlineSmall.copyWith(
                            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: WanWalkSpacing.sm),
                        Text(
                          '散歩中にピンを投稿すると\nここに表示されます',
                          style: WanWalkTypography.bodyMedium.copyWith(
                            color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(WanWalkSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _TimelineCard(
                item: items[index],
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PinDetailScreen(pinId: items[index].pinId),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'データの取得に失敗しました',
            style: WanWalkTypography.bodyMedium.copyWith(
              color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
            ),
          ),
        ),
      ),
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
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
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
                  height: 220, // 200 → 220に拡大
                  width: double.infinity,
                  child: Image.network(
                    walk.photoUrls!.first, // 最初の写真を全幅表示
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),

            // カード情報
            Padding(
              padding: const EdgeInsets.all(WanWalkSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Row(
                    children: [
                      // 絵文字アイコン
                      Text(
                        _getWalkEmoji(walk, isOuting),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: WanWalkSpacing.sm),
                      Expanded(
                        child: Text(
                          isOuting ? (walk.routeName ?? 'お出かけ散歩') : _formatDateTimeTitle(walk.walkedAt),
                          style: WanWalkTypography.bodyLarge.copyWith(
                            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WanWalkSpacing.sm),

                  // サブ情報
                  Row(
                    children: [
                      // エリア名（お出かけ散歩）
                      if (isOuting && walk.areaName != null) ...[
                        Icon(Icons.location_on, size: 14, color: WanWalkColors.accent),
                        const SizedBox(width: WanWalkSpacing.xs),
                        Text(
                          walk.areaName!,
                          style: WanWalkTypography.bodySmall.copyWith(
                            color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: WanWalkSpacing.md),
                      ],
                      // 日常散歩の位置情報（現在地から取得）
                      if (!isOuting) ...[
                        Icon(Icons.my_location, size: 14, color: WanWalkColors.accent),
                        const SizedBox(width: WanWalkSpacing.xs),
                        Text(
                          '現在地',
                          style: WanWalkTypography.bodySmall.copyWith(
                            color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: WanWalkSpacing.md),
                      ],
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanWalkSpacing.xs),
                      Text(
                        _formatDate(walk.walkedAt),
                        style: WanWalkTypography.bodySmall.copyWith(
                          color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WanWalkSpacing.sm),

                  // 統計
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.straighten,
                        label: walk.formattedDistance,
                        isDark: isDark,
                      ),
                      const SizedBox(width: WanWalkSpacing.sm),
                      _StatChip(
                        icon: Icons.access_time,
                        label: walk.formattedDuration,
                        isDark: isDark,
                      ),
                      if (isOuting && walk.pinCount != null && walk.pinCount! > 0) ...[
                        const SizedBox(width: WanWalkSpacing.sm),
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

  String _getWalkEmoji(WalkHistoryItem walk, bool isOuting) {
    if (isOuting) {
      // エリア名から絵文字を推測
      final areaName = walk.areaName ?? '';
      if (areaName.contains('箱根')) return '🏔️';
      if (areaName.contains('鎌倉')) return '🏯';
      if (areaName.contains('横浜')) return '🏙️';
      if (areaName.contains('湖') || areaName.contains('海')) return '🌊';
      return '🗺️'; // デフォルト
    } else {
      // 時間帯から絵文字を選択
      final hour = walk.walkedAt.hour;
      if (hour < 12) return '🌅'; // 朝
      if (hour < 17) return '☀️'; // 午後
      return '🌆'; // 夕方
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
        horizontal: WanWalkSpacing.sm,
        vertical: WanWalkSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: WanWalkColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: WanWalkColors.accent),
          const SizedBox(width: WanWalkSpacing.xs),
          Text(
            label,
            style: WanWalkTypography.caption.copyWith(
              color: WanWalkColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// ピン投稿履歴カード
class _PinHistoryCard extends StatelessWidget {
  final RoutePin pin;
  final bool isDark;
  final VoidCallback onTap;

  const _PinHistoryCard({
    required this.pin,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
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
            // 写真（あれば）
            if (pin.hasPhotos)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 220, // 200 → 220に拡大
                  width: double.infinity,
                  child: Image.network(
                    pin.photoUrls.first, // 最初の写真を全幅表示
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),

            // ピン情報
            Padding(
              padding: const EdgeInsets.all(WanWalkSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ピンタイプバッジ + タイトル
                  Row(
                    children: [
                      _buildPinTypeBadge(),
                      const SizedBox(width: WanWalkSpacing.sm),
                      Expanded(
                        child: Text(
                          pin.title,
                          style: WanWalkTypography.bodyLarge.copyWith(
                            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // コメント
                  if (pin.comment.isNotEmpty) ...[
                    const SizedBox(height: WanWalkSpacing.sm),
                    Text(
                      pin.comment,
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: WanWalkSpacing.sm),

                  // 投稿時刻 + いいね数
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanWalkSpacing.xs),
                      Text(
                        pin.relativeTime,
                        style: WanWalkTypography.caption.copyWith(
                          color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanWalkSpacing.xs),
                      Text(
                        '${pin.likesCount}',
                        style: WanWalkTypography.caption.copyWith(
                          color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: WanWalkSpacing.md),
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanWalkSpacing.xs),
                      Text(
                        '${pin.commentsCount}',
                        style: WanWalkTypography.caption.copyWith(
                          color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                        ),
                      ),
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

  /// ピンタイプバッジ
  Widget _buildPinTypeBadge() {
    Color badgeColor;
    IconData badgeIcon;

    switch (pin.pinType) {
      case PinType.scenery:
        badgeColor = Colors.blue;
        badgeIcon = Icons.landscape;
        break;
      case PinType.shop:
        badgeColor = Colors.orange;
        badgeIcon = Icons.store;
        break;
      case PinType.encounter:
        badgeColor = Colors.green;
        badgeIcon = Icons.pets;
        break;
      case PinType.facility:
        badgeColor = Colors.purple;
        badgeIcon = Icons.business;
        break;

      case PinType.other:
        badgeColor = Colors.grey;
        badgeIcon = Icons.more_horiz;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanWalkSpacing.sm,
        vertical: WanWalkSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: WanWalkSpacing.xs),
          Text(
            pin.pinType.label,
            style: WanWalkTypography.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 未ログイン状態の機能紹介アイテム
class _UnauthFeatureItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool isDark;

  const _UnauthFeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: WanWalkSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WanWalkTypography.bodyLarge.copyWith(
                    color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: WanWalkTypography.bodySmall.copyWith(
                    color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// タイムラインカードウィジェット
class _TimelineCard extends StatelessWidget {
  final TimelineItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _TimelineCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: WanWalkSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
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
            Padding(
              padding: const EdgeInsets.all(WanWalkSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: WanWalkColors.accent.withOpacity(0.2),
                    backgroundImage: item.userAvatarUrl != null
                        ? NetworkImage(item.userAvatarUrl!)
                        : null,
                    child: item.userAvatarUrl == null
                        ? const Icon(Icons.person, size: 18, color: WanWalkColors.accent)
                        : null,
                  ),
                  const SizedBox(width: WanWalkSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.userName,
                          style: WanWalkTypography.bodyMedium.copyWith(
                            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${item.areaName} · ${item.routeName}',
                          style: WanWalkTypography.caption.copyWith(
                            color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.relativeTime,
                    style: WanWalkTypography.caption.copyWith(
                      color: isDark ? WanWalkColors.textTertiaryDark : WanWalkColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (item.hasPhotos)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.md),
                  itemCount: item.photoUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: EdgeInsets.only(
                        right: index < item.photoUrls.length - 1 ? WanWalkSpacing.sm : 0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.photoUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
                            child: const Center(child: Icon(Icons.broken_image, size: 32)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(WanWalkSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _pinTypeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.pinTypeLabel,
                          style: WanWalkTypography.caption.copyWith(
                            color: _pinTypeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: WanWalkSpacing.sm),
                      Expanded(
                        child: Text(
                          item.title,
                          style: WanWalkTypography.bodyLarge.copyWith(
                            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (item.comment.isNotEmpty) ...[
                    const SizedBox(height: WanWalkSpacing.xs),
                    Text(
                      item.comment,
                      style: WanWalkTypography.bodyMedium.copyWith(
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: WanWalkSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        item.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: item.isLiked ? Colors.red : (isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight),
                      ),
                      const SizedBox(width: 4),
                      Text('${item.likesCount}', style: WanWalkTypography.caption.copyWith(
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      )),
                      const SizedBox(width: WanWalkSpacing.md),
                      Icon(Icons.chat_bubble_outline, size: 18,
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text('${item.commentsCount}', style: WanWalkTypography.caption.copyWith(
                        color: isDark ? WanWalkColors.textSecondaryDark : WanWalkColors.textSecondaryLight,
                      )),
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

  Color get _pinTypeColor {
    switch (item.pinType) {
      case 'scenery': return Colors.blue;
      case 'shop': return Colors.orange;
      case 'encounter': return Colors.green;
      case 'facility': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
