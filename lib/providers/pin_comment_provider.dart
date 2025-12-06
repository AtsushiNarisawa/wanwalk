import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ========================================
// PinCommentService: Supabase RPC呼び出し
// ========================================

class PinCommentService {
  final SupabaseClient _supabase;

  PinCommentService(this._supabase);

  /// コメントを追加
  Future<Map<String, dynamic>> addComment(
    String pinId,
    String userId,
    String comment,
  ) async {
    try {
      final response = await _supabase.rpc(
        'add_pin_comment',
        params: {
          'p_pin_id': pinId,
          'p_user_id': userId,
          'p_comment': comment,
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// コメントを削除
  Future<Map<String, dynamic>> deleteComment(
    String commentId,
    String userId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'delete_pin_comment',
        params: {
          'p_comment_id': commentId,
          'p_user_id': userId,
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// コメント一覧を取得
  Future<List<PinComment>> getComments(
    String pinId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_pin_comments',
        params: {
          'p_pin_id': pinId,
          'p_limit': limit,
          'p_offset': offset,
        },
      ) as List<dynamic>;

      return response.map((json) => PinComment.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// コメント数を取得
  Future<int> getCommentsCount(String pinId) async {
    try {
      final response = await _supabase.rpc(
        'get_pin_comments_count',
        params: {'p_pin_id': pinId},
      );
      return response as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

// ========================================
// PinCommentモデル
// ========================================

class PinComment {
  final String commentId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  PinComment({
    required this.commentId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PinComment.fromJson(Map<String, dynamic> json) {
    return PinComment(
      commentId: json['comment_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Unknown',
      userAvatar: json['user_avatar'] as String?,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 相対時刻を取得
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}ヶ月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}

// ========================================
// Providers
// ========================================

/// PinCommentServiceのProvider
final pinCommentServiceProvider = Provider<PinCommentService>((ref) {
  return PinCommentService(Supabase.instance.client);
});

/// コメント一覧を取得するProvider（ピンIDごと）
final pinCommentsProvider =
    FutureProvider.family<List<PinComment>, String>((ref, pinId) async {
  final service = ref.watch(pinCommentServiceProvider);
  return service.getComments(pinId);
});

/// コメント数を取得するProvider（ピンIDごと）
final pinCommentCountProvider =
    StateProvider.family<int, String>((ref, pinId) => 0);

/// コメント操作のActionsプロバイダー
final pinCommentActionsProvider = Provider<PinCommentActions>((ref) {
  return PinCommentActions(ref);
});

// ========================================
// PinCommentActions: コメント操作
// ========================================

class PinCommentActions {
  final Ref ref;

  PinCommentActions(this.ref);

  /// コメント数の初期化
  Future<void> initializeCommentCount(String pinId, int initialCount) async {
    // 初期値を設定
    ref.read(pinCommentCountProvider(pinId).notifier).state = initialCount;
  }

  /// コメントを追加（楽観的UI更新）
  Future<bool> addComment(
    String pinId,
    String comment,
  ) async {
    final service = ref.read(pinCommentServiceProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) return false;

    // 楽観的UI更新: コメント数を+1
    final currentCount = ref.read(pinCommentCountProvider(pinId));
    ref.read(pinCommentCountProvider(pinId).notifier).state = currentCount + 1;

    // コメント一覧を無効化（再取得）
    ref.invalidate(pinCommentsProvider(pinId));

    try {
      final result = await service.addComment(pinId, currentUser.id, comment);

      if (result['success'] == true) {
        return true;
      } else {
        // 失敗時: ロールバック
        ref.read(pinCommentCountProvider(pinId).notifier).state = currentCount;
        return false;
      }
    } catch (e) {
      // エラー時: ロールバック
      ref.read(pinCommentCountProvider(pinId).notifier).state = currentCount;
      return false;
    }
  }

  /// コメントを削除（楽観的UI更新）
  Future<bool> deleteComment(
    String pinId,
    String commentId,
  ) async {
    final service = ref.read(pinCommentServiceProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) return false;

    // 楽観的UI更新: コメント数を-1
    final currentCount = ref.read(pinCommentCountProvider(pinId));
    ref.read(pinCommentCountProvider(pinId).notifier).state =
        (currentCount - 1).clamp(0, double.infinity).toInt();

    // コメント一覧を無効化（再取得）
    ref.invalidate(pinCommentsProvider(pinId));

    try {
      final result = await service.deleteComment(commentId, currentUser.id);

      if (result['success'] == true) {
        return true;
      } else {
        // 失敗時: ロールバック
        ref.read(pinCommentCountProvider(pinId).notifier).state = currentCount;
        return false;
      }
    } catch (e) {
      // エラー時: ロールバック
      ref.read(pinCommentCountProvider(pinId).notifier).state = currentCount;
      return false;
    }
  }

  /// コメント一覧を再読み込み
  void refreshComments(String pinId) {
    ref.invalidate(pinCommentsProvider(pinId));
  }
}
