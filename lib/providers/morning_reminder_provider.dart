import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/official_route.dart';
import '../services/morning_reminder_service.dart';

/// 朝散歩リマインドの Riverpod プロバイダ群（B2 §6.1）。

final morningReminderServiceProvider = Provider<MorningReminderService>((ref) {
  return MorningReminderService(Supabase.instance.client);
});

/// 設定スナップショット（FutureProvider）。
/// 設定変更後は `ref.invalidate(morningReminderPreferencesProvider)` でリフレッシュ。
final morningReminderPreferencesProvider =
    FutureProvider<MorningReminderPreferences>((ref) async {
  final service = ref.watch(morningReminderServiceProvider);
  return service.loadPreferences();
});

/// 今日のおすすめルート（ホームの today_recommend セクション用）。
final todayRecommendRouteProvider =
    FutureProvider<OfficialRoute?>((ref) async {
  final service = ref.watch(morningReminderServiceProvider);
  return service.loadTodayRecommend();
});

/// 設定変更を司る Notifier（楽観更新 + サーバー失敗時はリロード）。
class MorningReminderNotifier
    extends StateNotifier<AsyncValue<MorningReminderPreferences>> {
  MorningReminderNotifier(this._ref)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  MorningReminderService get _service =>
      _ref.read(morningReminderServiceProvider);

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await _service.loadPreferences();
      state = AsyncValue.data(prefs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.valueOrNull ?? MorningReminderPreferences.defaults;
    state = AsyncValue.data(current.copyWith(enabled: enabled));
    try {
      await _service.updatePreferences(enabled: enabled);
    } catch (_) {
      await _load();
    }
  }

  Future<void> setMode(MorningReminderMode mode) async {
    final current = state.valueOrNull ?? MorningReminderPreferences.defaults;
    state = AsyncValue.data(current.copyWith(mode: mode));
    try {
      await _service.updatePreferences(mode: mode);
    } catch (_) {
      await _load();
    }
  }

  Future<void> setFixedTime(TimeOfDay time) async {
    final current = state.valueOrNull ?? MorningReminderPreferences.defaults;
    state = AsyncValue.data(current.copyWith(fixedTime: time));
    try {
      await _service.updatePreferences(fixedTime: time);
    } catch (_) {
      await _load();
    }
  }

  Future<void> setFrequency(MorningReminderFrequency frequency) async {
    final current = state.valueOrNull ?? MorningReminderPreferences.defaults;
    state = AsyncValue.data(current.copyWith(frequency: frequency));
    try {
      await _service.updatePreferences(frequency: frequency);
    } catch (_) {
      await _load();
    }
  }
}

final morningReminderControllerProvider = StateNotifierProvider<
    MorningReminderNotifier, AsyncValue<MorningReminderPreferences>>((ref) {
  return MorningReminderNotifier(ref);
});
