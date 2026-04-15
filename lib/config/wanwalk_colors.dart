import 'package:flutter/material.dart';

/// WanWalk デザインシステム - カラーパレット
/// DogHub（箱根）ブランドに基づく温かみのある自然なカラースキーム
class WanWalkColors {
  // ==================================================
  // プライマリーカラー（DogHubウッドブラウン系）
  // ==================================================
  
  /// メインカラー - ウッドブラウン（自然、温かみ、信頼感）
  static const Color primary = Color(0xFF8B6F47);
  static const Color primaryLight = Color(0xFFA89B7E);
  static const Color primaryDark = Color(0xFF6B5537);
  
  /// アクセントカラー - ソフトグリーン（自然、リラックス、癒し）
  /// accent(#5E7254): 白背景でWCAG AA準拠 4.7:1 - テキスト・アイコン・汎用
  /// accentLight(#7A8E70): 装飾・グラデーション・ダーク背景用
  /// accentDark(#4A5E42): 強調テキスト用
  static const Color accent = Color(0xFF5E7254);
  static const Color accentLight = Color(0xFF7A8E70);
  static const Color accentDark = Color(0xFF4A5E42);
  
  // ==================================================
  // セカンダリーカラー（補助的な色）
  // ==================================================
  
  /// セカンダリーカラー - ゴールデンブラウン（温かみ、高級感）
  static const Color secondary = Color(0xFFD4A574);
  static const Color secondaryLight = Color(0xFFE8C9A0);
  static const Color secondaryDark = Color(0xFFB8895E);
  
  // ==================================================
  // ニュートラルカラー（背景、テキスト）
  // ==================================================
  
  /// 背景色 - ライトモード（DogHubベージュ）
  static const Color backgroundLight = Color(0xFFF5F1E8);
  static const Color surfaceLight = Color(0xFFFDFBF7);
  static const Color cardLight = Color(0xFFFDFBF7);
  
  /// 背景色 - ダークモード（落ち着いたブラウン）
  static const Color backgroundDark = Color(0xFF2A2420);
  static const Color surfaceDark = Color(0xFF3D2F2B);
  static const Color cardDark = Color(0xFF3D2F2B);
  
  /// テキストカラー - ライトモード
  static const Color textPrimaryLight = Color(0xFF3D2F2B);
  static const Color textSecondaryLight = Color(0xFF6B5537);
  static const Color textTertiaryLight = Color(0xFF8B6F47);
  
  /// テキストカラー - ダークモード
  static const Color textPrimaryDark = Color(0xFFF5F1E8);
  static const Color textSecondaryDark = Color(0xFFA89B7E);
  static const Color textTertiaryDark = Color(0xFF8B6F47);
  
  /// ボーダーカラー
  static const Color borderLight = Color(0xFFD9D5CC);
  static const Color borderDark = Color(0xFF4A3C37);
  
  // ==================================================
  // ステータスカラー（DogHub風の柔らかい色調）
  // ==================================================
  
  /// 成功 - ソフトグリーン
  static const Color success = Color(0xFFA8B5A0);
  static const Color successLight = Color(0xFFC5D1BE);
  static const Color successDark = Color(0xFF8A9B82);
  
  /// 警告 - ゴールデンブラウン
  static const Color warning = Color(0xFFD4A574);
  static const Color warningLight = Color(0xFFE8C9A0);
  static const Color warningDark = Color(0xFFB8895E);
  
  /// エラー - テラコッタ（柔らかい赤）
  static const Color error = Color(0xFFC17B6B);
  static const Color errorLight = Color(0xFFD99B8E);
  static const Color errorDark = Color(0xFFA86354);
  
  /// 情報 - スレートブルー
  static const Color info = Color(0xFF9BA8B5);
  static const Color infoLight = Color(0xFFB8C4D1);
  static const Color infoDark = Color(0xFF7E8C99);
  
  // ==================================================
  // グラデーション（DogHub風の温かみのあるグラデーション）
  // ==================================================
  
  /// プライマリーグラデーション（ヒーローエリア用）
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  /// セカンダリーグラデーション
  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );
  
  /// ダークグラデーション（ダークモード用）
  static const Gradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );
  
  // ==================================================
  // オーバーレイ（半透明）
  // ==================================================
  
  /// カードオーバーレイ（写真の上に統計を表示する時）
  static Color get cardOverlay => Color(0xFF3D2F2B).withOpacity(0.6);
  static Color get cardOverlayLight => Color(0xFFFDFBF7).withOpacity(0.9);
  
  /// シャドウ（柔らかく控えめ）
  static Color get shadow => Color(0xFF3D2F2B).withOpacity(0.08);
  static Color get shadowDark => Color(0xFF3D2F2B).withOpacity(0.15);
  
  // ==================================================
  // ソーシャル機能用カラー
  // ==================================================
  
  /// いいねボタン
  static const Color like = Color(0xFFC17B6B);
  
  /// フォローボタン
  static const Color follow = Color(0xFF9BA8B5);
  
  /// シェアボタン
  static const Color share = Color(0xFFA8B5A0);
  
  // ==================================================
  // 機能別カラー（お出かけ散歩、ルート表示）
  // ==================================================
  
  /// お出かけ散歩・ルート表示統一カラー - オレンジ
  static const Color routeOrange = Color(0xFFFF9500);
  static const Color routeOrangeLight = Color(0xFFFFB340);
  static const Color routeOrangeDark = Color(0xFFCC7700);
  
  // ==================================================
  // データビジュアライゼーション用カラー（自然な色調）
  // ==================================================
  
  /// グラフカラー（統計画面）
  static const List<Color> chartColors = [
    Color(0xFF8B6F47), // ウッドブラウン
    Color(0xFFA8B5A0), // ソフトグリーン
    Color(0xFFD4A574), // ゴールデンブラウン
    Color(0xFF9BA8B5), // スレートブルー
    Color(0xFFC17B6B), // テラコッタ
    Color(0xFFA89B7E), // ライトウッド
  ];

  // ==================================================
  // Phase 1 (2026-04-15) — Wildboundsトーンのデザインシステム
  // 仕様: /Users/atsushinarisawa/projects/wanwalk/DESIGN_TOKENS.md
  // 使用: Phase 1 の新規/刷新画面から段階的に採用。
  // ==================================================

  /// 背景
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF8F6F2);
  static const Color bgTertiary = Color(0xFFEFECE5);

  /// テキスト
  static const Color textPrimary = Color(0xFF2A2A2A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFFA0A0A0);
  static const Color textInverse = Color(0xFFFFFFFF);

  /// ボーダー
  static const Color borderSubtle = Color(0xFFE8E4DE);
  static const Color borderStrong = Color(0xFFD4CFC4);

  /// アクセント（深緑）
  static const Color accentPrimary = Color(0xFF6B7F5B);
  static const Color accentPrimaryHover = Color(0xFF556649);
  static const Color accentPrimarySoft = Color(0xFFE8EDE1);
  static const Color accentGold = Color(0xFFB8905C);

  /// セマンティック
  static const Color semanticSuccess = Color(0xFF5B7F6B);
  static const Color semanticWarning = Color(0xFFB8905C);
  static const Color semanticError = Color(0xFFA84A3D);
  static const Color semanticInfo = Color(0xFF5B728A);

  /// 難易度（ルートカード用）
  static const Color levelEasy = Color(0xFF8BA885);
  static const Color levelModerate = Color(0xFFB8905C);
  static const Color levelHard = Color(0xFFA84A3D);
}
