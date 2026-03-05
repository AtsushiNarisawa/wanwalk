import 'package:flutter/material.dart';

/// WanWalk デザインシステム - タイポグラフィ
/// DogHub風の柔らかく読みやすいタイポグラフィ
class WanWalkTypography {
  // ==================================================
  // ディスプレイスタイル（超大見出し - 記録中の数値など）
  // ==================================================
  
  /// 超大見出し - 記録中の距離表示など
  /// 使用例: GPS記録画面の距離「2.5」
  static const TextStyle displayLarge = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w600,  // Semi Bold（柔らかさ）
    height: 1.1,
    letterSpacing: -1.0,
  );
  
  /// 大見出し - 統計の主要数値など
  /// 使用例: ホーム画面の「今週 12.5km」
  static const TextStyle displayMedium = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w600,  // Semi Bold
    height: 1.2,
    letterSpacing: -0.8,
  );
  
  /// 中見出し - サマリー数値など
  /// 使用例: 統計カードの数値
  static const TextStyle displaySmall = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  // ==================================================
  // ヘッドラインスタイル（セクションタイトル）
  // ==================================================
  
  /// 大ヘッドライン - 画面タイトルなど
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.5,
  );
  
  /// 中ヘッドライン - セクションタイトル
  /// 使用例: 「最近の散歩」「今日のおすすめ」
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,  // Semi Bold
    height: 1.3,
  );
  
  /// 小ヘッドライン - カードタイトル
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // ==================================================
  // タイトルスタイル（サブタイトル、ボタン）
  // ==================================================
  
  /// 大タイトル - プロミネントなボタン
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  /// 中タイトル - 一般的なボタン、カードタイトル
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  /// 小タイトル - 小さなボタン、ラベル
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // ==================================================
  // ボディスタイル（本文、説明文）
  // ==================================================
  
  /// 大本文 - 主要な説明文
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.3,
  );
  
  /// 中本文 - 一般的な本文
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.3,
  );
  
  /// 小本文 - 補助的な説明文
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.2,
  );
  
  // ==================================================
  // ラベルスタイル（キャプション、タグ）
  // ==================================================
  
  /// 大ラベル - 重要なキャプション
  /// 使用例: 「KM」「分」などの単位
  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.5,
  );
  
  /// 中ラベル - 一般的なキャプション
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
  );
  
  /// 小ラベル - 小さなキャプション、タイムスタンプ
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
  );
  
  // ==================================================
  // 互換性エイリアス（後方互換性のため）
  // ==================================================
  
  /// キャプション（labelMediumのエイリアス）
  static const TextStyle caption = labelMedium;
  
  /// 本文（bodyMediumのエイリアス）
  static const TextStyle body = bodyMedium;
  
  /// 見出し2（headlineMediumのエイリアス）
  static const TextStyle heading2 = headlineMedium;
  
  /// 見出し3（headlineSmallのエイリアス）
  static const TextStyle heading3 = headlineSmall;
  
  /// 見出し4（titleLargeのエイリアス）
  static const TextStyle heading4 = titleLarge;
  
  // ==================================================
  // 特殊スタイル（数値、統計表示）
  // ==================================================
  
  /// 統計数値 - 統計画面の主要数値
  static const TextStyle statisticValue = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.5,
  );
  
  /// 統計ラベル - 統計数値の単位
  static const TextStyle statisticLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.0,
  );
  
  /// ボタンテキスト - プライマリーボタン
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0.5,
  );
  
  /// ボタンテキスト - セカンダリーボタン
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
  );
  
  // ==================================================
  // カラー適用ヘルパー
  // ==================================================
  
  /// テキストスタイルに色を適用
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  /// テキストスタイルに透明度を適用
  static TextStyle withOpacity(TextStyle style, Color color, double opacity) {
    return style.copyWith(color: color.withOpacity(opacity));
  }
}
