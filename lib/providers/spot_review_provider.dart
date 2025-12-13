import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot_review_model.dart';
import '../services/spot_review_service.dart';

/// スポット評価・レビューの状態クラス
class SpotReviewState {
  final List<SpotReviewModel> reviews;
  final SpotReviewModel? userReview; // ログインユーザーのレビュー
  final bool isLoading;
  final String? errorMessage;
  final double? averageRating;
  final int reviewCount;

  SpotReviewState({
    this.reviews = const [],
    this.userReview,
    this.isLoading = false,
    this.errorMessage,
    this.averageRating,
    this.reviewCount = 0,
  });

  bool get hasReviews => reviews.isNotEmpty;
  bool get userHasReviewed => userReview != null;

  SpotReviewState copyWith({
    List<SpotReviewModel>? reviews,
    SpotReviewModel? userReview,
    bool? isLoading,
    String? errorMessage,
    double? averageRating,
    int? reviewCount,
    bool clearUserReview = false,
    bool clearError = false,
  }) {
    return SpotReviewState(
      reviews: reviews ?? this.reviews,
      userReview: clearUserReview ? null : (userReview ?? this.userReview),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

/// スポット評価・レビューの状態を管理するRiverpod StateNotifier
class SpotReviewNotifier extends StateNotifier<SpotReviewState> {
  final SpotReviewService _reviewService = SpotReviewService();

  SpotReviewNotifier() : super(SpotReviewState());

  /// スポットIDでレビュー一覧を読み込み
  Future<void> loadReviewsBySpotId(String spotId, {String? userId}) async {
    if (kDebugMode) {
      print('📝 Loading reviews for spot: $spotId');
    }
    state = state.copyWith(isLoading: true, errorMessage: null, clearError: true);

    try {
      // レビュー一覧を取得
      final reviews = await _reviewService.getReviewsBySpotId(spotId);
      
      // 統計情報を取得
      final averageRating = await _reviewService.getAverageRating(spotId);
      final reviewCount = await _reviewService.getReviewCount(spotId);

      // ユーザーのレビューを取得（ログイン済みの場合）
      SpotReviewModel? userReview;
      if (userId != null) {
        userReview = await _reviewService.getUserReviewForSpot(
          userId: userId,
          spotId: spotId,
        );
      }

      if (kDebugMode) {
        print('📝 Reviews loaded: ${reviews.length} reviews, avg: $averageRating');
      }

      state = state.copyWith(
        reviews: reviews,
        userReview: userReview,
        averageRating: averageRating,
        reviewCount: reviewCount,
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading reviews: $e');
      }
      state = state.copyWith(
        errorMessage: 'レビューの取得に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// ユーザーIDでレビュー一覧を読み込み（マイレビュー用）
  Future<void> loadReviewsByUserId(String userId) async {
    if (kDebugMode) {
      print('📝 Loading reviews by user: $userId');
    }
    state = state.copyWith(isLoading: true, errorMessage: null, clearError: true);

    try {
      final reviews = await _reviewService.getReviewsByUserId(userId);
      if (kDebugMode) {
        print('📝 User reviews loaded: ${reviews.length} reviews');
      }
      state = state.copyWith(
        reviews: reviews,
        reviewCount: reviews.length,
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading user reviews: $e');
      }
      state = state.copyWith(
        errorMessage: 'マイレビューの取得に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// レビューを作成
  Future<SpotReviewModel?> createReview(SpotReviewModel review) async {
    if (kDebugMode) {
      print('📝 Creating review for spot: ${review.spotId}, rating: ${review.rating}');
    }
    state = state.copyWith(isLoading: true, errorMessage: null, clearError: true);

    try {
      final newReview = await _reviewService.createReview(review);
      
      // 新しいレビューをリストの先頭に追加
      final updatedReviews = [newReview, ...state.reviews];
      
      // 統計情報を再計算
      final averageRating = await _reviewService.getAverageRating(review.spotId);
      final reviewCount = await _reviewService.getReviewCount(review.spotId);

      if (kDebugMode) {
        print('📝 Review created successfully: id=${newReview.id}');
      }

      state = state.copyWith(
        reviews: updatedReviews,
        userReview: newReview,
        averageRating: averageRating,
        reviewCount: reviewCount,
        isLoading: false,
      );

      return newReview;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating review: $e');
      }
      state = state.copyWith(
        errorMessage: 'レビューの投稿に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return null;
    }
  }

  /// レビューを更新
  Future<SpotReviewModel?> updateReview({
    required String reviewId,
    required String spotId,
    required Map<String, dynamic> updates,
  }) async {
    if (kDebugMode) {
      print('📝 Updating review: $reviewId');
    }
    state = state.copyWith(isLoading: true, errorMessage: null, clearError: true);

    try {
      final updatedReview = await _reviewService.updateReview(
        reviewId: reviewId,
        updates: updates,
      );

      // レビューリストを更新
      final updatedReviews = state.reviews.map((review) {
        return review.id == reviewId ? updatedReview : review;
      }).toList();

      // ユーザーレビューも更新
      final updatedUserReview = state.userReview?.id == reviewId
          ? updatedReview
          : state.userReview;

      // 統計情報を再取得
      final averageRating = await _reviewService.getAverageRating(spotId);

      if (kDebugMode) {
        print('📝 Review updated successfully');
      }

      state = state.copyWith(
        reviews: updatedReviews,
        userReview: updatedUserReview,
        averageRating: averageRating,
        isLoading: false,
      );

      return updatedReview;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating review: $e');
      }
      state = state.copyWith(
        errorMessage: 'レビューの更新に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return null;
    }
  }

  /// レビューを削除
  Future<bool> deleteReview({
    required String reviewId,
    required String spotId,
  }) async {
    if (kDebugMode) {
      print('📝 Deleting review: $reviewId');
    }
    state = state.copyWith(isLoading: true, errorMessage: null, clearError: true);

    try {
      await _reviewService.deleteReview(reviewId);

      // レビューリストから削除
      final updatedReviews = state.reviews
          .where((review) => review.id != reviewId)
          .toList();

      // ユーザーレビューをクリア（該当する場合）
      final shouldClearUserReview = state.userReview?.id == reviewId;

      // 統計情報を再取得
      final averageRating = await _reviewService.getAverageRating(spotId);
      final reviewCount = await _reviewService.getReviewCount(spotId);

      if (kDebugMode) {
        print('📝 Review deleted successfully');
      }

      state = state.copyWith(
        reviews: updatedReviews,
        averageRating: averageRating,
        reviewCount: reviewCount,
        clearUserReview: shouldClearUserReview,
        isLoading: false,
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting review: $e');
      }
      state = state.copyWith(
        errorMessage: 'レビューの削除に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// 設備情報でフィルタリング
  Future<void> filterReviewsByFacilities({
    bool? hasWaterFountain,
    bool? hasDogRun,
    bool? hasShade,
    bool? hasToilet,
    bool? hasParking,
    String? dogSizeSuitable,
  }) async {
    if (kDebugMode) {
      print('🔍 Filtering reviews by facilities');
    }
    state = state.copyWith(isLoading: true, errorMessage: null, clearError: true);

    try {
      final reviews = await _reviewService.getReviewsByFacilities(
        hasWaterFountain: hasWaterFountain,
        hasDogRun: hasDogRun,
        hasShade: hasShade,
        hasToilet: hasToilet,
        hasParking: hasParking,
        dogSizeSuitable: dogSizeSuitable,
      );

      if (kDebugMode) {
        print('🔍 Filtered reviews: ${reviews.length}');
      }

      state = state.copyWith(
        reviews: reviews,
        reviewCount: reviews.length,
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error filtering reviews: $e');
      }
      state = state.copyWith(
        errorMessage: 'レビューのフィルタリングに失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// 状態をリセット
  void reset() {
    if (kDebugMode) {
      print('📝 Resetting SpotReviewState');
    }
    state = SpotReviewState();
  }
}

/// スポット評価・レビューのグローバルProvider
final spotReviewProvider = StateNotifierProvider<SpotReviewNotifier, SpotReviewState>((ref) {
  return SpotReviewNotifier();
});

/// 特定のスポットのレビュー一覧を提供するProvider
final spotReviewsProvider = FutureProvider.family<List<SpotReviewModel>, String>((ref, spotId) async {
  final service = SpotReviewService();
  return await service.getReviewsBySpotId(spotId);
});

/// 特定のスポットの平均評価を提供するProvider
final spotAverageRatingProvider = FutureProvider.family<double?, String>((ref, spotId) async {
  final service = SpotReviewService();
  return await service.getAverageRating(spotId);
});

/// 特定のスポットのレビュー数を提供するProvider
final spotReviewCountProvider = FutureProvider.family<int, String>((ref, spotId) async {
  final service = SpotReviewService();
  return await service.getReviewCount(spotId);
});

/// ユーザーの特定スポットへのレビューを提供するProvider
final userSpotReviewProvider = FutureProvider.family<SpotReviewModel?, ({String userId, String spotId})>((ref, params) async {
  final service = SpotReviewService();
  return await service.getUserReviewForSpot(
    userId: params.userId,
    spotId: params.spotId,
  );
});

/// ユーザーの全レビューを提供するProvider
final userReviewsProvider = FutureProvider.family<List<SpotReviewModel>, String>((ref, userId) async {
  final service = SpotReviewService();
  return await service.getReviewsByUserId(userId);
});

/// 高評価スポットIDリストを提供するProvider
final topRatedSpotIdsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final service = SpotReviewService();
  return await service.getTopRatedSpotIds(limit: 10, minRating: 4.0);
});
