import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../nav/route_nav_engine.dart';
import '../utils/logger.dart';

/// LAYER1_NAV_SPEC §10: ナビ閾値のリモート設定。
///
/// 起動時に `nav_params` の `is_active` 行を1回取得して [NavParams] を構築する。
/// 取得失敗・行なし・オフラインでは内蔵既定値（`const NavParams()` = version 1）へ
/// フォールバックする。ナビは閾値の取得可否に依存して止まってはならない（北極星を妨げない）。
///
/// 実走テストがほぼ不可な前提では、少数の実ユーザーのテレメトリ → このテーブルの更新で
/// 閾値を遠隔調整するのが唯一のチューニングループ（ノービルド化・§10/§14.4）。
final navParamsProvider = FutureProvider<NavParams>((ref) async {
  try {
    final row = await Supabase.instance.client
        .from('nav_params')
        .select()
        .eq('is_active', true)
        .order('version', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return const NavParams();
    final params = NavParams.fromMap(row);
    if (kDebugMode) appLog('🧭 nav_params 取得: version=${params.version}');
    return params;
  } catch (e) {
    if (kDebugMode) appLog('🧭 nav_params 取得失敗（内蔵既定値を使用）: $e');
    return const NavParams();
  }
});
