import 'package:flutter/material.dart' show TimeOfDay;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/official_route.dart';
import '../utils/logger.dart';

/// 朝散歩リマインドの送信モード（B2 §4.1）。
enum MorningReminderMode {
  /// 日の出に合わせて自動（30 分前）。MVP デフォルト。
  auto,

  /// ユーザーが指定した固定時刻。
  fixedTime,
}

/// 朝散歩リマインドの配信頻度（B2 §3.1）。
enum MorningReminderFrequency {
  daily,
  weekdays,
  weekends,
}

/// 朝散歩リマインドの設定スナップショット。
class MorningReminderPreferences {
  final bool enabled;
  final MorningReminderMode mode;
  final TimeOfDay fixedTime;
  final MorningReminderFrequency frequency;

  const MorningReminderPreferences({
    required this.enabled,
    required this.mode,
    required this.fixedTime,
    required this.frequency,
  });

  static const MorningReminderPreferences defaults = MorningReminderPreferences(
    enabled: true,
    mode: MorningReminderMode.auto,
    fixedTime: TimeOfDay(hour: 6, minute: 0),
    frequency: MorningReminderFrequency.daily,
  );

  MorningReminderPreferences copyWith({
    bool? enabled,
    MorningReminderMode? mode,
    TimeOfDay? fixedTime,
    MorningReminderFrequency? frequency,
  }) {
    return MorningReminderPreferences(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      fixedTime: fixedTime ?? this.fixedTime,
      frequency: frequency ?? this.frequency,
    );
  }
}

/// 朝散歩リマインドの設定アクセス + 今日のおすすめルート取得（B2 §5）。
class MorningReminderService {
  MorningReminderService(this._supabase);

  final SupabaseClient _supabase;

  /// 現在のユーザーの設定を取得。未ログイン or 未レコード時はデフォルトを返す。
  Future<MorningReminderPreferences> loadPreferences() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return MorningReminderPreferences.defaults;

    try {
      final row = await _supabase
          .from('notification_preferences')
          .select(
              'morning_reminder_enabled, morning_reminder_time, morning_reminder_mode, morning_reminder_frequency')
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) return MorningReminderPreferences.defaults;

      return MorningReminderPreferences(
        enabled: (row['morning_reminder_enabled'] as bool?) ?? true,
        mode: _parseMode(row['morning_reminder_mode'] as String?),
        fixedTime: _parseTime(row['morning_reminder_time'] as String?) ??
            MorningReminderPreferences.defaults.fixedTime,
        frequency: _parseFrequency(row['morning_reminder_frequency'] as String?),
      );
    } catch (e) {
      appLog('[MorningReminderService] loadPreferences failed: $e');
      return MorningReminderPreferences.defaults;
    }
  }

  /// 部分更新。NULL のフィールドはサーバー側で COALESCE される。
  Future<void> updatePreferences({
    bool? enabled,
    MorningReminderMode? mode,
    TimeOfDay? fixedTime,
    MorningReminderFrequency? frequency,
  }) async {
    if (_supabase.auth.currentUser == null) return;
    try {
      await _supabase.rpc(
        'update_notification_preferences',
        params: {
          'p_morning_reminder_enabled': enabled,
          'p_morning_reminder_time':
              fixedTime != null ? _formatTime(fixedTime) : null,
          'p_morning_reminder_mode': mode?.dbValue,
          'p_morning_reminder_frequency': frequency?.dbValue,
        },
      );
    } catch (e) {
      appLog('[MorningReminderService] updatePreferences failed: $e');
      rethrow;
    }
  }

  /// 今日のおすすめルート（B2 §5.6）。
  /// MVP は `featured_routes` の先頭 1 件を返す。なければ最新公開ルート 1 件。
  Future<OfficialRoute?> loadTodayRecommend() async {
    try {
      final featured = await _supabase
          .from('featured_routes')
          .select('route_id, official_routes(*)')
          .eq('is_active', true)
          .order('display_order')
          .limit(1);
      final list = featured as List;
      if (list.isNotEmpty) {
        final routeJson = list.first['official_routes'];
        if (routeJson != null) {
          return OfficialRoute.fromJson(routeJson);
        }
      }

      final fallback = await _supabase
          .from('official_routes')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(1);
      final fbList = fallback as List;
      if (fbList.isEmpty) return null;
      return OfficialRoute.fromJson(fbList.first as Map<String, dynamic>);
    } catch (e) {
      appLog('[MorningReminderService] loadTodayRecommend failed: $e');
      return null;
    }
  }

  // ────────────────────────── helpers

  static MorningReminderMode _parseMode(String? v) {
    switch (v) {
      case 'fixed_time':
        return MorningReminderMode.fixedTime;
      case 'auto':
      default:
        return MorningReminderMode.auto;
    }
  }

  static MorningReminderFrequency _parseFrequency(String? v) {
    switch (v) {
      case 'weekdays':
        return MorningReminderFrequency.weekdays;
      case 'weekends':
        return MorningReminderFrequency.weekends;
      case 'daily':
      default:
        return MorningReminderFrequency.daily;
    }
  }

  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
}

extension on MorningReminderMode {
  String get dbValue {
    switch (this) {
      case MorningReminderMode.auto:
        return 'auto';
      case MorningReminderMode.fixedTime:
        return 'fixed_time';
    }
  }
}

extension on MorningReminderFrequency {
  String get dbValue {
    switch (this) {
      case MorningReminderFrequency.daily:
        return 'daily';
      case MorningReminderFrequency.weekdays:
        return 'weekdays';
      case MorningReminderFrequency.weekends:
        return 'weekends';
    }
  }
}
