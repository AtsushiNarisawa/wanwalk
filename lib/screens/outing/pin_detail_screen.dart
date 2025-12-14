import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/route_pin.dart';
import '../../models/spot_review_model.dart';
import '../../providers/pin_comment_provider.dart';
import '../../providers/route_pin_provider.dart';
import '../../providers/spot_review_provider.dart';

/// ピン詳細画面
/// ユーザーが投稿したピンの詳細情報を表示
class PinDetailScreen extends ConsumerStatefulWidget {
  final String pinId;

  const PinDetailScreen({
    super.key,
    required this.pinId,
  });

  @override
  ConsumerState<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends ConsumerState<PinDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  
  // 返信先の情報
  String? _replyToUserId;
  String? _replyToUserName;

  @override
  void initState() {
    super.initState();
    // コメント数の初期化はbuild内で行う（pinデータ取得後）
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 返信を開始
  void _startReply(String userId, String userName) {
    setState(() {
      _replyToUserId = userId;
      _replyToUserName = userName;
    });
    _focusNode.requestFocus();
  }

  /// 返信をキャンセル
  void _cancelReply() {
    setState(() {
      _replyToUserId = null;
      _replyToUserName = null;
    });
  }

  /// コメントを投稿
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('コメントを入力してください')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final actions = ref.read(pinCommentActionsProvider);
    final success = await actions.addComment(
      widget.pinId,
      _commentController.text.trim(),
      replyToUserId: _replyToUserId,
      replyToUserName: _replyToUserName,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      _commentController.clear();
      _cancelReply(); // 返信先をクリア
      _focusNode.unfocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('コメントを投稿しました')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('コメントの投稿に失敗しました')),
        );
      }
    }
  }

  /// コメントを削除
  Future<void> _deleteComment(String commentId, String pinId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コメントを削除'),
        content: const Text('このコメントを削除しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final actions = ref.read(pinCommentActionsProvider);
      final success = await actions.deleteComment(pinId, commentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'コメントを削除しました' : 'コメントの削除に失敗しました'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinAsync = ref.watch(pinByIdProvider(widget.pinId));
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: isDark
          ? WanMapColors.backgroundDark
          : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: const Text('ピン詳細'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: pinAsync.when(
        data: (pin) {
          if (pin == null) {
            return Center(
              child: Text(
                'ピンが見つかりません',
                style: WanMapTypography.bodyLarge.copyWith(
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
              ),
            );
          }

          // コメント数の初期化
          Future.microtask(() {
            ref.read(pinCommentActionsProvider).initializeCommentCount(
              pin.id,
              pin.commentsCount,
            );
          });

          final commentsAsync = ref.watch(pinCommentsProvider(pin.id));
          final commentCount = ref.watch(pinCommentCountProvider(pin.id));

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 写真ギャラリー（横スクロール）
                if (pin.hasPhotos) _buildPhotoGallery(pin, isDark),

                Padding(
                  padding: const EdgeInsets.all(WanMapSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトル
                      Text(
                        pin.title,
                        style: WanMapTypography.headlineMedium.copyWith(
                          color: isDark
                              ? WanMapColors.textPrimaryDark
                              : WanMapColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: WanMapSpacing.md),

                      // ピンタイプバッジ
                      _buildPinTypeBadge(pin.pinType),

                      const SizedBox(height: WanMapSpacing.xl),

                      // 統計情報
                      _buildStats(pin, isDark),

                      const SizedBox(height: WanMapSpacing.xl),

                      // コメント
                      if (pin.comment.isNotEmpty) ...[
                        Text(
                          'コメント',
                          style: WanMapTypography.headlineSmall.copyWith(
                            color: isDark
                                ? WanMapColors.textPrimaryDark
                                : WanMapColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: WanMapSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(WanMapSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pin.comment,
                            style: WanMapTypography.bodyMedium.copyWith(
                          color: isDark
                              ? WanMapColors.textPrimaryDark
                              : WanMapColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: WanMapSpacing.xl),
                  ],

                      // 位置情報
                      Text(
                        '位置',
                        style: WanMapTypography.headlineSmall.copyWith(
                          color: isDark
                              ? WanMapColors.textPrimaryDark
                              : WanMapColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: WanMapSpacing.sm),
                      _buildLocationMap(pin, isDark),

                      const SizedBox(height: WanMapSpacing.xl),

                      // スポット評価・レビューセクション
                      _buildReviewsSection(pin.id, isDark),

                      const SizedBox(height: WanMapSpacing.xl),

                      // みんなのコメントセクション
                      _buildCommentsSection(commentsAsync, commentCount, currentUser, isDark, pin),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
              ),
              const SizedBox(height: WanMapSpacing.md),
              Text(
                'ピンの読み込みに失敗しました',
                style: WanMapTypography.bodyLarge.copyWith(
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
      // コメント入力欄（固定）
      bottomNavigationBar: _buildCommentInput(isDark),
    );
  }

  /// みんなのコメントセクション
  Widget _buildCommentsSection(
    AsyncValue<List<PinComment>> commentsAsync,
    int commentCount,
    User? currentUser,
    bool isDark,
    RoutePin pin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションヘッダー
        Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 20,
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
            const SizedBox(width: WanMapSpacing.xs),
            Text(
              'みんなのコメント',
              style: WanMapTypography.headlineSmall.copyWith(
                color: isDark
                    ? WanMapColors.textPrimaryDark
                    : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: WanMapSpacing.xs),
            Text(
              '($commentCount)',
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
              ),
            ),
          ],
        ),

        const SizedBox(height: WanMapSpacing.md),

        // コメント一覧
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: WanMapSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      const SizedBox(height: WanMapSpacing.sm),
                      Text(
                        'まだコメントがありません',
                        style: WanMapTypography.bodyMedium.copyWith(
                          color: isDark
                              ? WanMapColors.textSecondaryDark
                              : WanMapColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final comment = comments[index];
                final isOwnComment = currentUser?.id == comment.userId;
                final isPinOwner = currentUser?.id == pin.userId;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: WanMapSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // アバター
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: WanMapColors.accent.withOpacity(0.2),
                        backgroundImage: comment.userAvatar != null
                            ? NetworkImage(comment.userAvatar!)
                            : null,
                        child: comment.userAvatar == null
                            ? Icon(
                                Icons.person,
                                size: 20,
                                color: WanMapColors.accent,
                              )
                            : null,
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      // コメント内容
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ユーザー名・時間
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          comment.userName,
                                          style: WanMapTypography.bodyMedium.copyWith(
                                            color: isDark
                                                ? WanMapColors.textPrimaryDark
                                                : WanMapColors.textPrimaryLight,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // ピン投稿者バッジ
                                      if (comment.userId == pin.userId) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: WanMapColors.accent.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '投稿者',
                                            style: WanMapTypography.caption.copyWith(
                                              color: WanMapColors.accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: WanMapSpacing.xs),
                                Text(
                                  comment.getRelativeTime(),
                                  style: WanMapTypography.caption.copyWith(
                                    color: isDark
                                        ? WanMapColors.textSecondaryDark
                                        : WanMapColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: WanMapSpacing.xs),
                            // 返信先表示
                            if (comment.isReply && comment.replyToUserName != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.subdirectory_arrow_right,
                                    size: 14,
                                    color: isDark
                                        ? WanMapColors.textSecondaryDark
                                        : WanMapColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    comment.replyToUserName!,
                                    style: WanMapTypography.caption.copyWith(
                                      color: WanMapColors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: WanMapSpacing.xs),
                            ],
                            // コメント本文
                            Text(
                              comment.comment,
                              style: WanMapTypography.bodySmall.copyWith(
                                color: isDark
                                    ? WanMapColors.textPrimaryDark
                                    : WanMapColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: WanMapSpacing.xs),
                            // 返信ボタン（ピン投稿者のみ表示）
                            if (isPinOwner && !isOwnComment)
                              GestureDetector(
                                onTap: () => _startReply(comment.userId, comment.userName),
                                child: Text(
                                  '返信する',
                                  style: WanMapTypography.caption.copyWith(
                                    color: WanMapColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // 削除ボタン（自分のコメントのみ）
                      if (isOwnComment)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.grey[600],
                          onPressed: () => _deleteComment(comment.commentId, pin.id),
                        ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(WanMapSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(WanMapSpacing.lg),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: WanMapSpacing.sm),
                  Text(
                    'コメントの読み込みに失敗しました',
                    style: WanMapTypography.bodyMedium.copyWith(
                      color: isDark
                          ? WanMapColors.textSecondaryDark
                          : WanMapColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// コメント入力欄
  Widget _buildCommentInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: WanMapSpacing.md,
        right: WanMapSpacing.md,
        top: WanMapSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + WanMapSpacing.sm,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 返信先インジケーター
            if (_replyToUserName != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: WanMapSpacing.sm,
                  vertical: WanMapSpacing.xs,
                ),
                margin: const EdgeInsets.only(bottom: WanMapSpacing.sm),
                decoration: BoxDecoration(
                  color: WanMapColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 16,
                      color: WanMapColors.accent,
                    ),
                    const SizedBox(width: WanMapSpacing.xs),
                    Expanded(
                      child: Text(
                        '$_replyToUserNameに返信中',
                        style: WanMapTypography.caption.copyWith(
                          color: WanMapColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _cancelReply,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: WanMapColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            // 入力フィールド
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: _replyToUserName != null 
                          ? '返信を入力...' 
                          : 'コメントを入力...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: WanMapSpacing.md,
                    vertical: WanMapSpacing.sm,
                  ),
                ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: WanMapSpacing.sm),
                IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  color: WanMapColors.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 写真ギャラリー
  Widget _buildPhotoGallery(RoutePin pin, bool isDark) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: pin.photoUrls.length,
        itemBuilder: (context, index) {
          return Image.network(
            pin.photoUrls[index],
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                height: 300,
                color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                child: Icon(
                  Icons.photo,
                  size: 80,
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// ピンタイプバッジ
  Widget _buildPinTypeBadge(PinType pinType) {
    Color badgeColor;
    IconData icon;

    switch (pinType) {
      case PinType.scenery:
        badgeColor = Colors.blue;
        icon = Icons.landscape;
        break;
      case PinType.shop:
        badgeColor = Colors.orange;
        icon = Icons.store;
        break;
      case PinType.encounter:
        badgeColor = Colors.pink;
        icon = Icons.pets;
        break;
      case PinType.other:
        badgeColor = Colors.grey;
        icon = Icons.more_horiz;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanMapSpacing.md,
        vertical: WanMapSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: badgeColor,
            size: 20,
          ),
          const SizedBox(width: WanMapSpacing.xs),
          Text(
            pinType.label,
            style: WanMapTypography.bodyMedium.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 統計情報
  Widget _buildStats(RoutePin pin, bool isDark) {
    final commentCount = ref.watch(pinCommentCountProvider(pin.id));
    
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.favorite,
            label: 'いいね',
            value: '${pin.likesCount}',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: WanMapSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.chat_bubble_outline,
            label: 'コメント',
            value: '$commentCount',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: WanMapSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.photo_library,
            label: '写真',
            value: '${pin.photoCount}枚',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  /// 位置マップ
  Widget _buildLocationMap(RoutePin pin, bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: pin.location,
            initialZoom: 16.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.doghub.wanmap',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pin.location,
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    color: WanMapColors.accent,
                    size: 40,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// スポット評価・レビューセクション
  Widget _buildReviewsSection(String spotId, bool isDark) {
    // 平均評価を取得
    final averageRatingAsync = ref.watch(spotAverageRatingProvider(spotId));
    // レビュー数を取得
    final reviewCountAsync = ref.watch(spotReviewCountProvider(spotId));
    // レビュー一覧を取得
    final reviewsAsync = ref.watch(spotReviewsProvider(spotId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションヘッダー（星評価＋レビュー数）
        Row(
          children: [
            const Icon(
              Icons.star,
              size: 20,
              color: Colors.amber,
            ),
            const SizedBox(width: WanMapSpacing.xs),
            Text(
              'スポット評価',
              style: WanMapTypography.headlineSmall.copyWith(
                color: isDark
                    ? WanMapColors.textPrimaryDark
                    : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // 平均評価表示
            averageRatingAsync.when(
              data: (avg) {
                if (avg == null) return const SizedBox.shrink();
                return Row(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: WanMapTypography.headlineSmall.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: WanMapSpacing.xs),
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                  ],
                );
              },
              loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: WanMapSpacing.sm),

        // レビュー数表示
        reviewCountAsync.when(
          data: (count) {
            if (count == 0) {
              return Text(
                'まだレビューがありません',
                style: WanMapTypography.bodySmall.copyWith(
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
              );
            }
            return Text(
              '$count件のレビュー',
              style: WanMapTypography.bodySmall.copyWith(
                color: isDark
                    ? WanMapColors.textSecondaryDark
                    : WanMapColors.textSecondaryLight,
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: WanMapSpacing.md),

        // レビュー一覧
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(WanMapSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 48,
                        color: isDark
                            ? WanMapColors.textSecondaryDark
                            : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(height: WanMapSpacing.sm),
                      Text(
                        'このスポットの最初のレビューを投稿しませんか？',
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

            // レビューカードを表示（最大3件）
            return Column(
              children: reviews
                  .take(3)
                  .map((review) => _buildReviewCard(review, isDark))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(WanMapSpacing.md),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'レビューの読み込みに失敗しました',
              style: WanMapTypography.bodySmall.copyWith(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  /// レビューカード
  Widget _buildReviewCard(SpotReviewModel review, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: WanMapSpacing.md),
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? WanMapColors.borderDark : WanMapColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー：星評価＋日時
          Row(
            children: [
              // 星評価
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
              const Spacer(),
              // 相対時間
              Text(
                review.relativeTime,
                style: WanMapTypography.bodySmall.copyWith(
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
              ),
            ],
          ),

          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
            const SizedBox(height: WanMapSpacing.sm),
            // レビューテキスト
            Text(
              review.reviewText!,
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark
                    ? WanMapColors.textPrimaryDark
                    : WanMapColors.textPrimaryLight,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // 設備情報アイコン
          if (review.hasAnyFacilities) ...[
            const SizedBox(height: WanMapSpacing.sm),
            Wrap(
              spacing: WanMapSpacing.xs,
              runSpacing: WanMapSpacing.xs,
              children: [
                if (review.hasWaterFountain)
                  _buildFacilityChip('水飲み場', Icons.water_drop, isDark),
                if (review.hasDogRun)
                  _buildFacilityChip('ドッグラン', Icons.pets, isDark),
                if (review.hasShade)
                  _buildFacilityChip('日陰', Icons.wb_sunny, isDark),
                if (review.hasToilet)
                  _buildFacilityChip('トイレ', Icons.wc, isDark),
                if (review.hasParking)
                  _buildFacilityChip('駐車場', Icons.local_parking, isDark),
              ],
            ),
          ],

          // 写真プレビュー（あれば）
          if (review.photoCount > 0) ...[
            const SizedBox(height: WanMapSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.photo_library,
                  size: 16,
                  color: isDark
                      ? WanMapColors.textSecondaryDark
                      : WanMapColors.textSecondaryLight,
                ),
                const SizedBox(width: WanMapSpacing.xs),
                Text(
                  '${review.photoCount}枚の写真',
                  style: WanMapTypography.bodySmall.copyWith(
                    color: isDark
                        ? WanMapColors.textSecondaryDark
                        : WanMapColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 設備情報チップ
  Widget _buildFacilityChip(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanMapSpacing.sm,
        vertical: WanMapSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: WanMapColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: WanMapColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: WanMapTypography.bodySmall.copyWith(
              color: WanMapColors.accent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 統計カード
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: WanMapColors.accent,
            size: 24,
          ),
          const SizedBox(height: WanMapSpacing.xs),
          Text(
            label,
            style: WanMapTypography.caption.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: WanMapSpacing.xs),
          Text(
            value,
            style: WanMapTypography.bodyMedium.copyWith(
              color: isDark
                  ? WanMapColors.textPrimaryDark
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

