import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/spot_review_model.dart';

/// スポット評価・レビューサービス
/// Supabaseとの連携を担当
class SpotReviewService {
  final _supabase = Supabase.instance.client;

  /// スポットIDで評価・レビュー一覧を取得
  Future<List<SpotReviewModel>> getReviewsBySpotId(String spotId) async {
    try {
      if (kDebugMode) {
        print('📝 レビュー取得開始: spotId=$spotId');
      }

      final response = await _supabase
          .from('spot_reviews')
          .select()
          .eq('spot_id', spotId)
          .order('created_at', ascending: false);

      if (kDebugMode) {
        print('📝 レビュー取得成功: ${(response as List).length}件');
      }

      return (response as List)
          .map((json) => SpotReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ レビュー取得エラー: $e');
      }
      rethrow;
    }
  }

  /// ユーザーIDで評価・レビュー一覧を取得
  Future<List<SpotReviewModel>> getReviewsByUserId(String userId) async {
    try {
      if (kDebugMode) {
        print('📝 ユーザーレビュー取得開始: userId=$userId');
      }

      final response = await _supabase
          .from('spot_reviews')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (kDebugMode) {
        print('📝 ユーザーレビュー取得成功: ${(response as List).length}件');
      }

      return (response as List)
          .map((json) => SpotReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ユーザーレビュー取得エラー: $e');
      }
      rethrow;
    }
  }

  /// 特定のスポットに対するユーザーのレビューを取得
  Future<SpotReviewModel?> getUserReviewForSpot({
    required String userId,
    required String spotId,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 ユーザー個別レビュー取得: userId=$userId, spotId=$spotId');
      }

      final response = await _supabase
          .from('spot_reviews')
          .select()
          .eq('user_id', userId)
          .eq('spot_id', spotId)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) {
          print('📝 レビュー未投稿');
        }
        return null;
      }

      if (kDebugMode) {
        print('📝 ユーザー個別レビュー取得成功');
      }

      return SpotReviewModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ ユーザー個別レビュー取得エラー: $e');
      }
      rethrow;
    }
  }

  /// レビューを作成
  Future<SpotReviewModel> createReview(SpotReviewModel review) async {
    try {
      if (kDebugMode) {
        print('📝 レビュー作成開始: spotId=${review.spotId}, rating=${review.rating}');
      }

      final response = await _supabase
          .from('spot_reviews')
          .insert(review.toInsertJson())
          .select()
          .single();

      if (kDebugMode) {
        print('📝 レビュー作成成功: id=${response['id']}');
      }

      return SpotReviewModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ レビュー作成エラー: $e');
      }
      rethrow;
    }
  }

  /// レビューを更新
  Future<SpotReviewModel> updateReview({
    required String reviewId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 レビュー更新開始: reviewId=$reviewId');
      }

      // updated_atは自動更新されるため、明示的に設定不要
      final response = await _supabase
          .from('spot_reviews')
          .update(updates)
          .eq('id', reviewId)
          .select()
          .single();

      if (kDebugMode) {
        print('📝 レビュー更新成功');
      }

      return SpotReviewModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ レビュー更新エラー: $e');
      }
      rethrow;
    }
  }

  /// レビューを削除
  Future<void> deleteReview(String reviewId) async {
    try {
      if (kDebugMode) {
        print('📝 レビュー削除開始: reviewId=$reviewId');
      }

      await _supabase
          .from('spot_reviews')
          .delete()
          .eq('id', reviewId);

      if (kDebugMode) {
        print('📝 レビュー削除成功');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ レビュー削除エラー: $e');
      }
      rethrow;
    }
  }

  /// スポットの平均評価を取得
  Future<double?> getAverageRating(String spotId) async {
    try {
      if (kDebugMode) {
        print('📊 平均評価取得開始: spotId=$spotId');
      }

      final response = await _supabase
          .from('spot_reviews')
          .select('rating')
          .eq('spot_id', spotId);

      if (response == null || (response as List).isEmpty) {
        if (kDebugMode) {
          print('📊 レビューなし（平均評価なし）');
        }
        return null;
      }

      final ratings = (response as List)
          .map((r) => (r['rating'] as int).toDouble())
          .toList();

      final average = ratings.reduce((a, b) => a + b) / ratings.length;

      if (kDebugMode) {
        print('📊 平均評価: ${average.toStringAsFixed(1)} (${ratings.length}件)');
      }

      return average;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 平均評価取得エラー: $e');
      }
      rethrow;
    }
  }

  /// スポットのレビュー数を取得
  Future<int> getReviewCount(String spotId) async {
    try {
      if (kDebugMode) {
        print('📊 レビュー数取得開始: spotId=$spotId');
      }

      final response = await _supabase
          .from('spot_reviews')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('spot_id', spotId);

      final count = response.count ?? 0;

      if (kDebugMode) {
        print('📊 レビュー数: $count件');
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        print('❌ レビュー数取得エラー: $e');
      }
      rethrow;
    }
  }

  /// 評価の高いスポットを取得（おすすめスポット用）
  Future<List<String>> getTopRatedSpotIds({
    int limit = 10,
    double minRating = 4.0,
  }) async {
    try {
      if (kDebugMode) {
        print('🌟 高評価スポット取得開始: limit=$limit, minRating=$minRating');
      }

      // spot_idごとにグループ化して平均評価を計算
      // Supabaseのクエリでは直接GROUP BYできないため、全件取得して処理
      final response = await _supabase
          .from('spot_reviews')
          .select('spot_id, rating');

      if (response == null || (response as List).isEmpty) {
        if (kDebugMode) {
          print('🌟 レビューデータなし');
        }
        return [];
      }

      // spot_idごとに平均評価を計算
      final Map<String, List<int>> spotRatings = {};
      for (var review in (response as List)) {
        final spotId = review['spot_id'] as String;
        final rating = review['rating'] as int;

        if (!spotRatings.containsKey(spotId)) {
          spotRatings[spotId] = [];
        }
        spotRatings[spotId]!.add(rating);
      }

      // 平均評価を計算してソート
      final spotAverages = spotRatings.entries.map((entry) {
        final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
        return {'spotId': entry.key, 'average': average, 'count': entry.value.length};
      }).where((spot) => spot['average'] as double >= minRating).toList();

      // 平均評価でソート（降順）
      spotAverages.sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));

      // limit件まで取得
      final topSpots = spotAverages
          .take(limit)
          .map((spot) => spot['spotId'] as String)
          .toList();

      if (kDebugMode) {
        print('🌟 高評価スポット取得成功: ${topSpots.length}件');
      }

      return topSpots;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 高評価スポット取得エラー: $e');
      }
      rethrow;
    }
  }

  /// 設備情報でフィルタリング（将来的な拡張用）
  Future<List<SpotReviewModel>> getReviewsByFacilities({
    bool? hasWaterFountain,
    bool? hasDogRun,
    bool? hasShade,
    bool? hasToilet,
    bool? hasParking,
    String? dogSizeSuitable,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 設備フィルタリング開始');
      }

      var query = _supabase.from('spot_reviews').select();

      if (hasWaterFountain != null) {
        query = query.eq('has_water_fountain', hasWaterFountain);
      }
      if (hasDogRun != null) {
        query = query.eq('has_dog_run', hasDogRun);
      }
      if (hasShade != null) {
        query = query.eq('has_shade', hasShade);
      }
      if (hasToilet != null) {
        query = query.eq('has_toilet', hasToilet);
      }
      if (hasParking != null) {
        query = query.eq('has_parking', hasParking);
      }
      if (dogSizeSuitable != null) {
        query = query.eq('dog_size_suitable', dogSizeSuitable);
      }

      final response = await query.order('created_at', ascending: false);

      if (kDebugMode) {
        print('🔍 フィルタリング結果: ${(response as List).length}件');
      }

      return (response as List)
          .map((json) => SpotReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ フィルタリングエラー: $e');
      }
      rethrow;
    }
  }
}
