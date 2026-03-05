import 'package:flutter/material.dart';
import 'wanwalk_colors.dart';
import 'wanwalk_typography.dart';
import 'wanwalk_spacing.dart';

/// WanWalk アプリのテーマ設定
/// Nike Run Club風の洗練されたデザイン
class WanWalkTheme {
  // ==================================================
  // ライトテーマ
  // ==================================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // カラースキーム
      colorScheme: const ColorScheme.light(
        primary: WanWalkColors.primary,
        primaryContainer: WanWalkColors.primaryLight,
        secondary: WanWalkColors.secondary,
        secondaryContainer: WanWalkColors.secondaryLight,
        tertiary: WanWalkColors.accent,
        tertiaryContainer: WanWalkColors.accentLight,
        error: WanWalkColors.error,
        surface: WanWalkColors.surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: WanWalkColors.textPrimaryLight,
      ),
      
      // テキストテーマ
      textTheme: TextTheme(
        // ディスプレイ
        displayLarge: WanWalkTypography.displayLarge.copyWith(
          color: WanWalkColors.textPrimaryLight,
        ),
        displayMedium: WanWalkTypography.displayMedium.copyWith(
          color: WanWalkColors.textPrimaryLight,
        ),
        displaySmall: WanWalkTypography.displaySmall.copyWith(
          color: WanWalkColors.textPrimaryLight,
        ),
        
        // ヘッドライン
        headlineLarge: WanWalkTypography.headlineLarge.copyWith(
          color: WanWalkColors.textPrimaryLight,
        ),
        headlineMedium: WanWalkTypography.headlineMedium.copyWith(
          color: WanWalkColors.textPrimaryLight,
        ),
        headlineSmall: WanWalkTypography.headlineSmall.copyWith(
          color: WanWalkColors.textPrimaryLight,
        ),
        
        // タイトル
        titleLarge: WanWalkTypography.titleLarge.copyWith(
          color: WanWalkColors.textPrimaryLight,
        ),
        titleMedium: WanWalkTypography.titleMedium.copyWith(
          color: WanWalkColors.textPrimaryLight,
        ),
        titleSmall: WanWalkTypography.titleSmall.copyWith(
          color: WanWalkColors.textPrimaryLight,
        ),
        
        // ボディ
        bodyLarge: WanWalkTypography.bodyLarge.copyWith(
          color: WanWalkColors.textPrimaryLight,
        ),
        bodyMedium: WanWalkTypography.bodyMedium.copyWith(
          color: WanWalkColors.textSecondaryLight,
        ),
        bodySmall: WanWalkTypography.bodySmall.copyWith(
          color: WanWalkColors.textTertiaryLight,
        ),
        
        // ラベル
        labelLarge: WanWalkTypography.labelLarge.copyWith(
          color: WanWalkColors.textSecondaryLight,
        ),
        labelMedium: WanWalkTypography.labelMedium.copyWith(
          color: WanWalkColors.textSecondaryLight,
        ),
        labelSmall: WanWalkTypography.labelSmall.copyWith(
          color: WanWalkColors.textTertiaryLight,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: WanWalkColors.textPrimaryLight,
        titleTextStyle: WanWalkTypography.headlineMedium.copyWith(
          color: WanWalkColors.textPrimaryLight,
        ),
      ),
      
      // カード
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: WanWalkSpacing.borderRadiusMD,
        ),
        margin: WanWalkSpacing.listItemMargin,
      ),
      
      // ボタン
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WanWalkColors.accent,
          foregroundColor: Colors.white,
          padding: WanWalkSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(
            borderRadius: WanWalkSpacing.borderRadiusXL,
          ),
          textStyle: WanWalkTypography.buttonMedium,
          elevation: 2,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WanWalkColors.accent,
          padding: WanWalkSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(
            borderRadius: WanWalkSpacing.borderRadiusXL,
          ),
          side: const BorderSide(
            color: WanWalkColors.accent,
            width: 2,
          ),
          textStyle: WanWalkTypography.buttonMedium,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: WanWalkColors.accent,
          padding: WanWalkSpacing.buttonPadding,
          textStyle: WanWalkTypography.buttonMedium,
        ),
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: WanWalkColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WanWalkSpacing.radiusCircle),
        ),
      ),
      
      // Input
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: WanWalkColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: WanWalkSpacing.borderRadiusMD,
          borderSide: BorderSide(
            color: WanWalkColors.textTertiaryLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: WanWalkSpacing.borderRadiusMD,
          borderSide: BorderSide(
            color: WanWalkColors.textTertiaryLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: WanWalkSpacing.borderRadiusMD,
          borderSide: BorderSide(
            color: WanWalkColors.accent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: WanWalkSpacing.borderRadiusMD,
          borderSide: BorderSide(
            color: WanWalkColors.error,
          ),
        ),
        contentPadding: WanWalkSpacing.cardPadding,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: WanWalkColors.backgroundLight,
        selectedColor: WanWalkColors.accent,
        disabledColor: WanWalkColors.textTertiaryLight,
        labelStyle: WanWalkTypography.labelMedium,
        padding: WanWalkSpacing.all(WanWalkSpacing.sm),
        shape: const RoundedRectangleBorder(
          borderRadius: WanWalkSpacing.borderRadiusXL,
        ),
      ),
      
      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: WanWalkColors.surfaceLight,
        selectedItemColor: WanWalkColors.accent,
        unselectedItemColor: WanWalkColors.textSecondaryLight,
        selectedLabelStyle: WanWalkTypography.labelMedium,
        unselectedLabelStyle: WanWalkTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
  
  // ==================================================
  // ダークテーマ
  // ==================================================
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // カラースキーム
      colorScheme: const ColorScheme.dark(
        primary: WanWalkColors.primaryLight,
        primaryContainer: WanWalkColors.primary,
        secondary: WanWalkColors.secondary,
        secondaryContainer: WanWalkColors.secondaryDark,
        tertiary: WanWalkColors.accentLight,
        tertiaryContainer: WanWalkColors.accent,
        error: WanWalkColors.error,
        surface: WanWalkColors.surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: WanWalkColors.textPrimaryDark,
      ),
      
      // テキストテーマ
      textTheme: TextTheme(
        // ディスプレイ
        displayLarge: WanWalkTypography.displayLarge.copyWith(
          color: WanWalkColors.textPrimaryDark,
        ),
        displayMedium: WanWalkTypography.displayMedium.copyWith(
          color: WanWalkColors.textPrimaryDark,
        ),
        displaySmall: WanWalkTypography.displaySmall.copyWith(
          color: WanWalkColors.textPrimaryDark,
        ),
        
        // ヘッドライン
        headlineLarge: WanWalkTypography.headlineLarge.copyWith(
          color: WanWalkColors.textPrimaryDark,
        ),
        headlineMedium: WanWalkTypography.headlineMedium.copyWith(
          color: WanWalkColors.textPrimaryDark,
        ),
        headlineSmall: WanWalkTypography.headlineSmall.copyWith(
          color: WanWalkColors.textPrimaryDark,
        ),
        
        // タイトル
        titleLarge: WanWalkTypography.titleLarge.copyWith(
          color: WanWalkColors.textPrimaryDark,
        ),
        titleMedium: WanWalkTypography.titleMedium.copyWith(
          color: WanWalkColors.textPrimaryDark,
        ),
        titleSmall: WanWalkTypography.titleSmall.copyWith(
          color: WanWalkColors.textPrimaryDark,
        ),
        
        // ボディ
        bodyLarge: WanWalkTypography.bodyLarge.copyWith(
          color: WanWalkColors.textPrimaryDark,
        ),
        bodyMedium: WanWalkTypography.bodyMedium.copyWith(
          color: WanWalkColors.textSecondaryDark,
        ),
        bodySmall: WanWalkTypography.bodySmall.copyWith(
          color: WanWalkColors.textTertiaryDark,
        ),
        
        // ラベル
        labelLarge: WanWalkTypography.labelLarge.copyWith(
          color: WanWalkColors.textSecondaryDark,
        ),
        labelMedium: WanWalkTypography.labelMedium.copyWith(
          color: WanWalkColors.textSecondaryDark,
        ),
        labelSmall: WanWalkTypography.labelSmall.copyWith(
          color: WanWalkColors.textTertiaryDark,
        ),
      ),
      
      // AppBar（ダークモード同様の設定）
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: WanWalkColors.textPrimaryDark,
        titleTextStyle: WanWalkTypography.headlineMedium.copyWith(
          color: WanWalkColors.textPrimaryDark,
        ),
      ),
      
      // その他のテーマ設定はライトテーマと同様...
      // （色を調整）
    );
  }
}
