import 'package:flutter/material.dart';

/// WanMap デザインシステム - カラーパレット
/// Nike Run Club風の洗練されたカラースキーム
class WanMapColors {
  // ==================================================
  // プライマリーカラー（犬のイメージ - 落ち着きと活発さ）
  // ==================================================
  
  /// メインカラー - ダークグレー（落ち着き、信頼感）
  static const Color primary = Color(0xFF2D3748);
  static const Color primaryLight = Color(0xFF4A5568);
  static const Color primaryDark = Color(0xFF1A202C);
  
  /// アクセントカラー - オレンジ（活発、犬の首輪、散歩の楽しさ）
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8C5A);
  static const Color accentDark = Color(0xFFE85A28);
  
  // ==================================================
  // セカンダリーカラー（自然、公園、リラックス）
  // ==================================================
  
  /// セカンダリーカラー - ティール（自然、公園、水）
  static const Color secondary = Color(0xFF38B2AC);
  static const Color secondaryLight = Color(0xFF4FD1C5);
  static const Color secondaryDark = Color(0xFF2C7A7B);
  
  // ==================================================
  // ニュートラルカラー（背景、テキスト）
  // ==================================================
  
  /// 背景色 - ライトモード
  static const Color backgroundLight = Color(0xFFF7FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  /// 背景色 - ダークモード
  static const Color backgroundDark = Color(0xFF1A202C);
  static const Color surfaceDark = Color(0xFF2D3748);
  static const Color cardDark = Color(0xFF2D3748);
  
  /// テキストカラー - ライトモード
  static const Color textPrimaryLight = Color(0xFF1A202C);
  static const Color textSecondaryLight = Color(0xFF718096);
  static const Color textTertiaryLight = Color(0xFFA0AEC0);
  
  /// テキストカラー - ダークモード
  static const Color textPrimaryDark = Color(0xFFF7FAFC);
  static const Color textSecondaryDark = Color(0xFFA0AEC0);
  static const Color textTertiaryDark = Color(0xFF718096);
  
  /// ボーダーカラー
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF4A5568);
  
  // ==================================================
  // ステータスカラー
  // ==================================================
  
  /// 成功 - グリーン
  static const Color success = Color(0xFF48BB78);
  static const Color successLight = Color(0xFF68D391);
  static const Color successDark = Color(0xFF38A169);
  
  /// 警告 - イエロー
  static const Color warning = Color(0xFFF6AD55);
  static const Color warningLight = Color(0xFFFBD38D);
  static const Color warningDark = Color(0xFFED8936);
  
  /// エラー - レッド
  static const Color error = Color(0xFFF56565);
  static const Color errorLight = Color(0xFFFC8181);
  static const Color errorDark = Color(0xFFE53E3E);
  
  /// 情報 - ブルー
  static const Color info = Color(0xFF4299E1);
  static const Color infoLight = Color(0xFF63B3ED);
  static const Color infoDark = Color(0xFF3182CE);
  
  // ==================================================
  // グラデーション
  // ==================================================
  
  /// プライマリーグラデーション（ヒーローエリア用）
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );
  
  /// セカンダリーグラデーション
  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
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
  static Color get cardOverlay => Colors.black.withOpacity(0.6);
  static Color get cardOverlayLight => Colors.white.withOpacity(0.9);
  
  /// シャドウ
  static Color get shadow => Colors.black.withOpacity(0.1);
  static Color get shadowDark => Colors.black.withOpacity(0.3);
  
  // ==================================================
  // ソーシャル機能用カラー
  // ==================================================
  
  /// いいねボタン
  static const Color like = Color(0xFFFF6B9D);
  
  /// フォローボタン
  static const Color follow = Color(0xFF4299E1);
  
  /// シェアボタン
  static const Color share = Color(0xFF38B2AC);
  
  // ==================================================
  // データビジュアライゼーション用カラー
  // ==================================================
  
  /// グラフカラー（統計画面）
  static const List<Color> chartColors = [
    Color(0xFFFF6B35), // オレンジ
    Color(0xFF38B2AC), // ティール
    Color(0xFF4299E1), // ブルー
    Color(0xFF48BB78), // グリーン
    Color(0xFFF6AD55), // イエロー
    Color(0xFFE53E3E), // レッド
  ];
}
