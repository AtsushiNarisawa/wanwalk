import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/wanwalk_colors.dart';
import '../config/wanwalk_typography.dart';
import '../config/wanwalk_spacing.dart';
import '../models/official_route.dart';
import '../screens/outing/route_detail_screen.dart';

/// 散歩完了後に表示するおすすめルートカード
/// 散歩完了ダイアログ内で使用
class WalkCompletionSheet extends ConsumerWidget {
  final String formattedDistance;
  final String formattedDuration;
  final String? currentRouteId; // お出かけ散歩の場合、歩いたルートID

  const WalkCompletionSheet({
    super.key,
    required this.formattedDistance,
    required this.formattedDuration,
    this.currentRouteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recommendedRoutesAsync = ref.watch(_recommendedRoutesProvider(currentRouteId));

    return Container(
      padding: const EdgeInsets.all(WanWalkSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? WanWalkColors.backgroundDark : WanWalkColors.backgroundLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ハンドル
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: WanWalkSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? WanWalkColors.borderDark : WanWalkColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // お疲れさまメッセージ
          Icon(
            Icons.celebration,
            size: 48,
            color: WanWalkColors.accent,
          ),
          const SizedBox(height: WanWalkSpacing.sm),
          Text(
            'お散歩おつかれさま！',
            style: WanWalkTypography.headlineMedium.copyWith(
              color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanWalkSpacing.sm),

          // 散歩記録サマリー
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WanWalkSpacing.lg,
              vertical: WanWalkSpacing.md,
            ),
            decoration: BoxDecoration(
              color: WanWalkColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SummaryItem(icon: Icons.straighten, value: formattedDistance, isDark: isDark),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: WanWalkSpacing.lg),
                  color: WanWalkColors.accent.withValues(alpha: 0.3),
                ),
                _SummaryItem(icon: Icons.timer, value: formattedDuration, isDark: isDark),
              ],
            ),
          ),

          const SizedBox(height: WanWalkSpacing.xl),

          // おすすめルート
          recommendedRoutesAsync.when(
            data: (routes) {
              if (routes.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '次はここを歩いてみませんか？',
                    style: WanWalkTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanWalkColors.textSecondaryDark
                          : WanWalkColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: WanWalkSpacing.sm),
                  ...routes.map((route) => _RecommendedRouteCard(
                    route: route,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop(); // シートを閉じる
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RouteDetailScreen(routeId: route.id),
                        ),
                      );
                    },
                  )),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: WanWalkSpacing.lg),

          // 閉じるボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: WanWalkColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: WanWalkSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('閉じる'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;

  const _SummaryItem({required this.icon, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: WanWalkColors.accent),
        const SizedBox(width: 6),
        Text(
          value,
          style: WanWalkTypography.bodyLarge.copyWith(
            color: isDark ? WanWalkColors.textPrimaryDark : WanWalkColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RecommendedRouteCard extends StatelessWidget {
  final OfficialRoute route;
  final bool isDark;
  final VoidCallback onTap;

  const _RecommendedRouteCard({
    required this.route,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: WanWalkSpacing.sm),
        padding: const EdgeInsets.all(WanWalkSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? WanWalkColors.cardDark : WanWalkColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: WanWalkColors.accent.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: route.thumbnailUrl != null
                  ? Image.network(
                      route.thumbnailUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: WanWalkSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: WanWalkTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanWalkColors.textPrimaryDark
                          : WanWalkColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(route.distanceMeters / 1000).toStringAsFixed(1)}km・約${route.estimatedMinutes}分',
                    style: WanWalkTypography.bodySmall.copyWith(
                      color: isDark
                          ? WanWalkColors.textSecondaryDark
                          : WanWalkColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: WanWalkColors.accent),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: WanWalkColors.accent.withValues(alpha: 0.1),
      child: Icon(Icons.map, color: WanWalkColors.accent, size: 24),
    );
  }
}

/// おすすめルートを取得するプロバイダー
/// まだ歩いたことがないルートを優先、最大2件
final _recommendedRoutesProvider = FutureProvider.family<List<OfficialRoute>, String?>((ref, currentRouteId) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  // 全公開ルートを取得
  final routesResponse = await supabase
      .from('official_routes')
      .select()
      .eq('is_published', true)
      .order('created_at', ascending: false);

  final allRoutes = (routesResponse as List)
      .map((json) => OfficialRoute.fromJson(json))
      .where((r) => r.id != currentRouteId) // 今歩いたルートは除外
      .toList();

  if (userId == null || allRoutes.isEmpty) {
    // 未ログインまたはルートがない場合はランダムに2件
    allRoutes.shuffle();
    return allRoutes.take(2).toList();
  }

  // ユーザーが歩いたルートIDを取得
  final walksResponse = await supabase
      .from('walks')
      .select('official_route_id')
      .eq('user_id', userId)
      .not('official_route_id', 'is', null);

  final walkedRouteIds = (walksResponse as List)
      .map((w) => w['official_route_id'] as String?)
      .whereType<String>()
      .toSet();

  // まだ歩いたことがないルートを優先
  final unwalked = allRoutes.where((r) => !walkedRouteIds.contains(r.id)).toList();
  final walked = allRoutes.where((r) => walkedRouteIds.contains(r.id)).toList();

  unwalked.shuffle();
  walked.shuffle();

  final result = <OfficialRoute>[];
  result.addAll(unwalked.take(2));
  if (result.length < 2) {
    result.addAll(walked.take(2 - result.length));
  }

  return result;
});
