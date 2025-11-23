import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/spot_model.dart';
import '../services/spot_service.dart';

/// スポット情報の状態クラス
class SpotState {
  final List<SpotModel> spots;
  final List<SpotModel> nearbySpots;
  final SpotModel? selectedSpot;
  final bool isLoading;
  final String? errorMessage;

  SpotState({
    this.spots = const [],
    this.nearbySpots = const [],
    this.selectedSpot,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasSpots => spots.isNotEmpty;
  bool get hasNearbySpots => nearbySpots.isNotEmpty;

  SpotState copyWith({
    List<SpotModel>? spots,
    List<SpotModel>? nearbySpots,
    SpotModel? selectedSpot,
    bool? isLoading,
    String? errorMessage,
    bool clearSelectedSpot = false,
  }) {
    return SpotState(
      spots: spots ?? this.spots,
      nearbySpots: nearbySpots ?? this.nearbySpots,
      selectedSpot: clearSelectedSpot ? null : (selectedSpot ?? this.selectedSpot),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// スポット情報の状態を管理するRiverpod StateNotifier
class SpotNotifier extends StateNotifier<SpotState> {
  final SpotService _spotService = SpotService();

  SpotNotifier() : super(SpotState());

  /// ユーザーのスポット一覧を読み込み
  Future<void> loadUserSpots(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final spots = await _spotService.getUserSpots(userId);
      state = state.copyWith(spots: spots, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'スポット一覧の取得に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// 近くのスポットを検索
  Future<void> loadNearbySpots({
    required LatLng center,
    double radiusKm = 5.0,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final nearbySpots = await _spotService.getNearbySpots(
        center: center,
        radiusKm: radiusKm,
      );
      state = state.copyWith(nearbySpots: nearbySpots, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: '近くのスポット検索に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// スポット情報を作成
  Future<SpotModel?> createSpot(SpotModel spot) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final newSpot = await _spotService.createSpot(spot);
      if (newSpot != null) {
        final updatedSpots = [newSpot, ...state.spots];
        state = state.copyWith(spots: updatedSpots, isLoading: false);
      }
      return newSpot;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'スポット情報の作成に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return null;
    }
  }

  /// スポット情報を更新
  Future<SpotModel?> updateSpot(String spotId, Map<String, dynamic> updates) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final updatedSpot = await _spotService.updateSpot(spotId, updates);
      if (updatedSpot != null) {
        final updatedSpots = state.spots.map((spot) {
          return spot.id == spotId ? updatedSpot : spot;
        }).toList();

        state = state.copyWith(
          spots: updatedSpots,
          selectedSpot: state.selectedSpot?.id == spotId ? updatedSpot : state.selectedSpot,
          isLoading: false,
        );
      }
      return updatedSpot;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'スポット情報の更新に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return null;
    }
  }

  /// スポット情報を削除
  Future<bool> deleteSpot(String spotId, String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final success = await _spotService.deleteSpot(spotId, userId);
      if (success) {
        final updatedSpots = state.spots.where((spot) => spot.id != spotId).toList();
        state = state.copyWith(
          spots: updatedSpots,
          isLoading: false,
          clearSelectedSpot: state.selectedSpot?.id == spotId,
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'スポット情報の削除に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// スポットを選択
  void selectSpot(SpotModel spot) {
    state = state.copyWith(selectedSpot: spot);
  }

  /// スポットの選択を解除
  void clearSelectedSpot() {
    state = state.copyWith(clearSelectedSpot: true);
  }

  /// スポットの写真を更新
  Future<String?> updateSpotPhoto({
    required String spotId,
    required String userId,
    required File file,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final newPhotoUrl = await _spotService.updateSpotPhoto(
        spotId: spotId,
        userId: userId,
        file: file,
      );

      if (newPhotoUrl != null) {
        final updatedSpots = state.spots.map((spot) {
          return spot.id == spotId ? spot.copyWith(photoUrl: newPhotoUrl) : spot;
        }).toList();

        state = state.copyWith(
          spots: updatedSpots,
          selectedSpot: state.selectedSpot?.id == spotId
              ? state.selectedSpot!.copyWith(photoUrl: newPhotoUrl)
              : state.selectedSpot,
          isLoading: false,
        );
      }

      return newPhotoUrl;
    } catch (e) {
      state = state.copyWith(
        errorMessage: '写真の更新に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return null;
    }
  }

  /// ギャラリーから写真を選択
  Future<File?> pickImageFromGallery() async {
    return await _spotService.pickImageFromGallery();
  }

  /// カメラで写真を撮影
  Future<File?> takePhoto() async {
    return await _spotService.takePhoto();
  }

  /// エラーメッセージをクリア
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// SpotProvider（Riverpod版）
final spotProvider = StateNotifierProvider<SpotNotifier, SpotState>((ref) {
  return SpotNotifier();
});
