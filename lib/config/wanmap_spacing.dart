import 'package:flutter/material.dart';

/// WanMap デザインシステム - スペーシング
/// 8pxグリッドシステムに基づく一貫したスペーシング
class WanMapSpacing {
  // ==================================================
  // 基本スペーシング（8pxグリッドシステム）
  // ==================================================
  
  /// 超小（4px） - 密接な要素間
  static const double xxs = 4.0;
  
  /// 小（8px） - 関連する要素間
  static const double xs = 8.0;
  
  /// やや小（12px） - カード内の要素間
  static const double sm = 12.0;
  
  /// 中（16px） - 基本的なパディング
  static const double md = 16.0;
  
  /// やや大（24px） - セクション間
  static const double lg = 24.0;
  
  /// 大（32px） - 大きなセクション間
  static const double xl = 32.0;
  
  /// 超大（48px） - 画面上下の余白
  static const double xxl = 48.0;
  
  /// 特大（64px） - ヒーローエリア
  static const double xxxl = 64.0;
  
  // ==================================================
  // EdgeInsetsヘルパー
  // ==================================================
  
  /// 全方向に同じパディング
  static EdgeInsets all(double value) => EdgeInsets.all(value);
  
  /// 水平方向のパディング
  static EdgeInsets horizontal(double value) => 
      EdgeInsets.symmetric(horizontal: value);
  
  /// 垂直方向のパディング
  static EdgeInsets vertical(double value) => 
      EdgeInsets.symmetric(vertical: value);
  
  /// 上下左右を個別指定
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) => EdgeInsets.only(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
  
  // ==================================================
  // よく使うパディングパターン
  // ==================================================
  
  /// 画面全体のパディング
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  
  /// カードのパディング
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  
  /// セクション間のマージン
  static const EdgeInsets sectionMargin = EdgeInsets.symmetric(
    vertical: lg,
    horizontal: md,
  );
  
  /// リストアイテム間のマージン
  static const EdgeInsets listItemMargin = EdgeInsets.only(bottom: md);
  
  /// ボタンのパディング
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: md,
  );
  
  /// ボタンの大きなパディング（プライマリーボタン）
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );
  
  /// ヒーローエリアのパディング
  static const EdgeInsets heroPadding = EdgeInsets.all(xl);
  
  // ==================================================
  // SizedBoxヘルパー（縦方向の空白）
  // ==================================================
  
  static const SizedBox verticalSpaceXXS = SizedBox(height: xxs);
  static const SizedBox verticalSpaceXS = SizedBox(height: xs);
  static const SizedBox verticalSpaceSM = SizedBox(height: sm);
  static const SizedBox verticalSpaceMD = SizedBox(height: md);
  static const SizedBox verticalSpaceLG = SizedBox(height: lg);
  static const SizedBox verticalSpaceXL = SizedBox(height: xl);
  static const SizedBox verticalSpaceXXL = SizedBox(height: xxl);
  static const SizedBox verticalSpaceXXXL = SizedBox(height: xxxl);
  
  // ==================================================
  // SizedBoxヘルパー（横方向の空白）
  // ==================================================
  
  static const SizedBox horizontalSpaceXXS = SizedBox(width: xxs);
  static const SizedBox horizontalSpaceXS = SizedBox(width: xs);
  static const SizedBox horizontalSpaceSM = SizedBox(width: sm);
  static const SizedBox horizontalSpaceMD = SizedBox(width: md);
  static const SizedBox horizontalSpaceLG = SizedBox(width: lg);
  static const SizedBox horizontalSpaceXL = SizedBox(width: xl);
  static const SizedBox horizontalSpaceXXL = SizedBox(width: xxl);
  
  // ==================================================
  // ボーダーラディウス（角丸）
  // ==================================================
  
  /// 小（8px） - カード内の小要素
  static const double radiusSM = 8.0;
  
  /// 中（16px） - カード
  static const double radiusMD = 16.0;
  
  /// 大（24px） - モーダル
  static const double radiusLG = 24.0;
  
  /// 特大（32px） - 大きなボタン
  static const double radiusXL = 32.0;
  
  /// 超特大（48px） - 超大きなボタン
  static const double radiusXXL = 48.0;
  
  /// 完全な円
  static const double radiusCircle = 9999.0;
  
  /// BorderRadiusヘルパー
  static BorderRadius circular(double radius) => 
      BorderRadius.circular(radius);
  
  static const BorderRadius borderRadiusSM = 
      BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderRadiusMD = 
      BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderRadiusLG = 
      BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderRadiusXL = 
      BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadiusXXL = 
      BorderRadius.all(Radius.circular(radiusXXL));
  
  // ==================================================
  // シャドウ（影）
  // ==================================================
  
  /// 小さな影 - カード
  static List<BoxShadow> get shadowSM => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  /// 中サイズの影 - カード（ホバー時）
  static List<BoxShadow> get shadowMD => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// 大きな影 - モーダル
  static List<BoxShadow> get shadowLG => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// 特大の影 - フローティングボタン
  static List<BoxShadow> get shadowXL => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}
