import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recent_pin_post.dart';

/// 最新の写真付きピン投稿を取得するProvider
/// ホーム画面で最新2件を表示するために使用
final recentPinsProvider = FutureProvider<List<RecentPinPost>>((ref) async {
  if (kDebugMode) {
    print('📌 [RecentPinsProvider] Fetching recent pins from Supabase...');
  }

  try {
    final supabase = Supabase.instance.client;

    // Supabase RPC `get_recent_pins` を呼び出し
    final response = await supabase.rpc('get_recent_pins', params: {
      'p_limit': 2, // ホーム画面では最新2件のみ表示
      'p_offset': 0,
    }).select();

    if (kDebugMode) {
      print('📌 [RecentPinsProvider] Response: ${response.toString()}');
    }

    final List<dynamic> data = response;

    if (kDebugMode) {
      print('📌 [RecentPinsProvider] Fetched ${data.length} recent pins');
    }

    final pins = data.map((json) {
      try {
        return RecentPinPost.fromJson(json as Map<String, dynamic>);
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('❌ [RecentPinsProvider] Error parsing pin: $e');
          if (kDebugMode) {
            print('   Data: $json');
          }
          if (kDebugMode) {
            print('   StackTrace: $stackTrace');
          }
        }
        return null;
      }
    }).where((pin) => pin != null).cast<RecentPinPost>().toList();

    if (kDebugMode) {
      print('✅ [RecentPinsProvider] Successfully parsed ${pins.length} pins');
      for (final pin in pins) {
        if (kDebugMode) {
          print('   📌 ${pin.title} by ${pin.userName} (${pin.areaName})');
        }
      }
    }

    return pins;
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ [RecentPinsProvider] Error fetching recent pins: $e');
      if (kDebugMode) {
        print('   StackTrace: $stackTrace');
      }
    }
    rethrow;
  }
});
