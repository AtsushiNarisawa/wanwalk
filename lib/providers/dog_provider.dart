import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dog_model.dart';
import '../services/dog_service.dart';

/// 犬情報の状態クラス
class DogState {
  final List<DogModel> dogs;
  final DogModel? selectedDog;
  final bool isLoading;
  final String? errorMessage;

  DogState({
    this.dogs = const [],
    this.selectedDog,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasDogs => dogs.isNotEmpty;

  DogState copyWith({
    List<DogModel>? dogs,
    DogModel? selectedDog,
    bool? isLoading,
    String? errorMessage,
    bool clearSelectedDog = false,
  }) {
    return DogState(
      dogs: dogs ?? this.dogs,
      selectedDog: clearSelectedDog ? null : (selectedDog ?? this.selectedDog),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// 犬情報の状態を管理するRiverpod StateNotifier
class DogNotifier extends StateNotifier<DogState> {
  final DogService _dogService = DogService();

  DogNotifier() : super(DogState());

  /// ユーザーの犬一覧を読み込み
  Future<void> loadUserDogs(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final dogs = await _dogService.getUserDogs(userId);
      state = state.copyWith(dogs: dogs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: '犬一覧の取得に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// 犬情報を作成
  Future<DogModel?> createDog(DogModel dog) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final newDog = await _dogService.createDog(dog);
      if (newDog != null) {
        final updatedDogs = [newDog, ...state.dogs];
        state = state.copyWith(dogs: updatedDogs, isLoading: false);
      }
      return newDog;
    } catch (e) {
      state = state.copyWith(
        errorMessage: '犬情報の作成に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return null;
    }
  }

  /// 犬情報を更新
  Future<DogModel?> updateDog(String dogId, Map<String, dynamic> updates) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final updatedDog = await _dogService.updateDog(dogId, updates);
      if (updatedDog != null) {
        final updatedDogs = state.dogs.map((dog) {
          return dog.id == dogId ? updatedDog : dog;
        }).toList();
        
        state = state.copyWith(
          dogs: updatedDogs,
          selectedDog: state.selectedDog?.id == dogId ? updatedDog : state.selectedDog,
          isLoading: false,
        );
      }
      return updatedDog;
    } catch (e) {
      state = state.copyWith(
        errorMessage: '犬情報の更新に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return null;
    }
  }

  /// 犬情報を削除
  Future<bool> deleteDog(String dogId, String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final success = await _dogService.deleteDog(dogId, userId);
      if (success) {
        final updatedDogs = state.dogs.where((dog) => dog.id != dogId).toList();
        state = state.copyWith(
          dogs: updatedDogs,
          isLoading: false,
          clearSelectedDog: state.selectedDog?.id == dogId,
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        errorMessage: '犬情報の削除に失敗しました: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// 犬を選択
  void selectDog(DogModel dog) {
    state = state.copyWith(selectedDog: dog);
  }

  /// 犬の選択を解除
  void clearSelectedDog() {
    state = state.copyWith(clearSelectedDog: true);
  }

  /// 犬の写真を更新
  Future<String?> updateDogPhoto({
    required String dogId,
    required String userId,
    required File file,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final newPhotoUrl = await _dogService.updateDogPhoto(
        dogId: dogId,
        userId: userId,
        file: file,
      );

      if (newPhotoUrl != null) {
        final updatedDogs = state.dogs.map((dog) {
          return dog.id == dogId ? dog.copyWith(photoUrl: newPhotoUrl) : dog;
        }).toList();

        state = state.copyWith(
          dogs: updatedDogs,
          selectedDog: state.selectedDog?.id == dogId 
              ? state.selectedDog!.copyWith(photoUrl: newPhotoUrl)
              : state.selectedDog,
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
    return await _dogService.pickImageFromGallery();
  }

  /// カメラで写真を撮影
  Future<File?> takePhoto() async {
    return await _dogService.takePhoto();
  }

  /// 犬の写真をアップロード
  Future<String?> uploadDogPhoto({
    required File file,
    required String userId,
    String? dogId,
  }) async {
    return await _dogService.uploadDogPhoto(
      file: file,
      userId: userId,
      dogId: dogId,
    );
  }

  /// エラーメッセージをクリア
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// DogProvider（Riverpod版）
final dogProvider = StateNotifierProvider<DogNotifier, DogState>((ref) {
  return DogNotifier();
});

/// ユーザーの犬一覧を取得するProvider
final userDogsProvider = Provider.family<List<DogModel>, String>((ref, userId) {
  final dogState = ref.watch(dogProvider);
  return dogState.dogs;
});
