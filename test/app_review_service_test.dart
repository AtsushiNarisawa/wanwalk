import 'package:flutter_test/flutter_test.dart';
import 'package:wanwalk/services/app_review_service.dart';

/// AppReviewService.shouldPrompt のゲート判定（プラットフォーム非依存）のテスト。
///
/// requestReview() 自体は Sim/Debug で表示されないため、出すか否かの純粋ロジックを
/// ここで担保する（2026-06-01 レビュー促進実装）。
void main() {
  final now = DateTime(2026, 6, 1, 12, 0);

  group('AppReviewService.shouldPrompt', () {
    test('初回セッション(launchCount < 2)は出さない', () {
      expect(
        AppReviewService.shouldPrompt(
          launchCount: 1,
          lastPromptMs: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('2回目以降 & 未プロンプト(null / 0)は出す', () {
      expect(
        AppReviewService.shouldPrompt(
          launchCount: 2,
          lastPromptMs: null,
          now: now,
        ),
        isTrue,
      );
      expect(
        AppReviewService.shouldPrompt(
          launchCount: 2,
          lastPromptMs: 0,
          now: now,
        ),
        isTrue,
      );
    });

    test('cooldown(120日)以内は出さない', () {
      final lastMs =
          now.subtract(const Duration(days: 10)).millisecondsSinceEpoch;
      expect(
        AppReviewService.shouldPrompt(
          launchCount: 5,
          lastPromptMs: lastMs,
          now: now,
        ),
        isFalse,
      );
    });

    test('cooldown(120日)を超えていれば出す', () {
      final lastMs =
          now.subtract(const Duration(days: 121)).millisecondsSinceEpoch;
      expect(
        AppReviewService.shouldPrompt(
          launchCount: 5,
          lastPromptMs: lastMs,
          now: now,
        ),
        isTrue,
      );
    });

    test('launchCount が高くても cooldown 中なら出さない', () {
      final lastMs =
          now.subtract(const Duration(days: 119)).millisecondsSinceEpoch;
      expect(
        AppReviewService.shouldPrompt(
          launchCount: 100,
          lastPromptMs: lastMs,
          now: now,
        ),
        isFalse,
      );
    });
  });
}
