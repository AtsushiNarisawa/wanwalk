import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';

/// 2026-05-25: Firebase Analytics 用 Riverpod プロバイダ。
///
/// 設計書: docs/runbook/firebase_analytics_setup.md
///
/// 使い方:
/// - 一般用途: `ref.read(analyticsServiceProvider).logRouteCardClick(...)`
/// - Navigator observer: `ref.read(analyticsObserverProvider)` を MaterialApp に渡す
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final service = AnalyticsService.create();
  ref.onDispose(service.dispose);
  return service;
});
