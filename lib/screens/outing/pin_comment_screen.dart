import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/pin_comment_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ピンコメント画面
/// ピンに対するコメント一覧と投稿機能を提供
class PinCommentScreen extends ConsumerStatefulWidget {
  final String pinId;
  final String pinTitle;

  const PinCommentScreen({
    super.key,
    required this.pinId,
    required this.pinTitle,
  });

  @override
  ConsumerState<PinCommentScreen> createState() => _PinCommentScreenState();
}

class _PinCommentScreenState extends ConsumerState<PinCommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
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
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      _commentController.clear();
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
  Future<void> _deleteComment(String commentId) async {
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
      final success = await actions.deleteComment(widget.pinId, commentId);

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
    final commentsAsync = ref.watch(pinCommentsProvider(widget.pinId));
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'コメント',
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
              ),
            ),
            Text(
              widget.pinTitle,
              style: WanMapTypography.bodySmall.copyWith(
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        elevation: 0,
      ),
      body: Column(
        children: [
          // コメント一覧
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                        const SizedBox(height: WanMapSpacing.md),
                        Text(
                          'まだコメントがありません',
                          style: WanMapTypography.bodyMedium.copyWith(
                            color: isDark
                                ? WanMapColors.textSecondaryDark
                                : WanMapColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: WanMapSpacing.sm),
                        Text(
                          '最初のコメントを投稿しましょう!',
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

                return ListView.separated(
                  padding: const EdgeInsets.all(WanMapSpacing.md),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isOwnComment = currentUser?.id == comment.userId;

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
                                // コメント本文
                                Text(
                                  comment.comment,
                                  style: WanMapTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? WanMapColors.textPrimaryDark
                                        : WanMapColors.textPrimaryLight,
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
                              onPressed: () => _deleteComment(comment.commentId),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: WanMapSpacing.md),
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
          // コメント入力欄
          Container(
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'コメントを入力...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.grey[850]
                          : Colors.grey[100],
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
          ),
        ],
      ),
    );
  }
}
