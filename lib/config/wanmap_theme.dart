import 'package:flutter/material.dart';
import 'wanmap_colors.dart';
import 'wanmap_typography.dart';
import 'wanmap_spacing.dart';

/// WanMap アプリのテーマ設定
/// Nike Run Club風の洗練されたデザイン
class WanMapTheme {
  // ==================================================
  // ライトテーマ
  // ==================================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // カラースキーム
      colorScheme: const ColorScheme.light(
        primary: WanMapColors.primary,
        primaryContainer: WanMapColors.primaryLight,
        secondary: WanMapColors.secondary,
        secondaryContainer: WanMapColors.secondaryLight,
        tertiary: WanMapColors.accent,
        tertiaryContainer: WanMapColors.accentLight,
        error: WanMapColors.error,
        surface: WanMapColors.surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: WanMapColors.textPrimaryLight,
      ),
      
      // テキストテーマ
      textTheme: TextTheme(
        // ディスプレイ
        displayLarge: WanMapTypography.displayLarge.copyWith(
          color: WanMapColors.textPrimaryLight,
        ),
        displayMedium: WanMapTypography.displayMedium.copyWith(
          color: WanMapColors.textPrimaryLight,
        ),
        displaySmall: WanMapTypography.displaySmall.copyWith(
          color: WanMapColors.textPrimaryLight,
        ),
        
        // ヘッドライン
        headlineLarge: WanMapTypography.headlineLarge.copyWith(
          color: WanMapColors.textPrimaryLight,
        ),
        headlineMedium: WanMapTypography.headlineMedium.copyWith(
          color: WanMapColors.textPrimaryLight,
        ),
        headlineSmall: WanMapTypography.headlineSmall.copyWith(
          color: WanMapColors.textPrimaryLight,
        ),
        
        // タイトル
        titleLarge: WanMapTypography.titleLarge.copyWith(
          color: WanMapColors.textPrimaryLight,
        ),
        titleMedium: WanMapTypography.titleMedium.copyWith(
          color: WanMapColors.textPrimaryLight,
        ),
        titleSmall: WanMapTypography.titleSmall.copyWith(
          color: WanMapColors.textPrimaryLight,
        ),
        
        // ボディ
        bodyLarge: WanMapTypography.bodyLarge.copyWith(
          color: WanMapColors.textPrimaryLight,
        ),
        bodyMedium: WanMapTypography.bodyMedium.copyWith(
          color: WanMapColors.textSecondaryLight,
        ),
        bodySmall: WanMapTypography.bodySmall.copyWith(
          color: WanMapColors.textTertiaryLight,
        ),
        
        // ラベル
        labelLarge: WanMapTypography.labelLarge.copyWith(
          color: WanMapColors.textSecondaryLight,
        ),
        labelMedium: WanMapTypography.labelMedium.copyWith(
          color: WanMapColors.textSecondaryLight,
        ),
        labelSmall: WanMapTypography.labelSmall.copyWith(
          color: WanMapColors.textTertiaryLight,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: WanMapColors.textPrimaryLight,
        titleTextStyle: WanMapTypography.headlineMedium.copyWith(
          color: WanMapColors.textPrimaryLight,
        ),
      ),
      
      // カード
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: WanMapSpacing.borderRadiusMD,
        ),
        margin: WanMapSpacing.listItemMargin,
      ),
      
      // ボタン
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WanMapColors.accent,
          foregroundColor: Colors.white,
          padding: WanMapSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(
            borderRadius: WanMapSpacing.borderRadiusXL,
          ),
          textStyle: WanMapTypography.buttonMedium,
          elevation: 2,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WanMapColors.accent,
          padding: WanMapSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(
            borderRadius: WanMapSpacing.borderRadiusXL,
          ),
          side: const BorderSide(
            color: WanMapColors.accent,
            width: 2,
          ),
          textStyle: WanMapTypography.buttonMedium,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: WanMapColors.accent,
          padding: WanMapSpacing.buttonPadding,
          textStyle: WanMapTypography.buttonMedium,
        ),
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: WanMapColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WanMapSpacing.radiusCircle),
        ),
      ),
      
      // Input
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: WanMapColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: WanMapSpacing.borderRadiusMD,
          borderSide: BorderSide(
            color: WanMapColors.textTertiaryLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: WanMapSpacing.borderRadiusMD,
          borderSide: BorderSide(
            color: WanMapColors.textTertiaryLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: WanMapSpacing.borderRadiusMD,
          borderSide: BorderSide(
            color: WanMapColors.accent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: WanMapSpacing.borderRadiusMD,
          borderSide: BorderSide(
            color: WanMapColors.error,
          ),
        ),
        contentPadding: WanMapSpacing.cardPadding,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: WanMapColors.backgroundLight,
        selectedColor: WanMapColors.accent,
        disabledColor: WanMapColors.textTertiaryLight,
        labelStyle: WanMapTypography.labelMedium,
        padding: WanMapSpacing.all(WanMapSpacing.sm),
        shape: const RoundedRectangleBorder(
          borderRadius: WanMapSpacing.borderRadiusXL,
        ),
      ),
      
      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: WanMapColors.surfaceLight,
        selectedItemColor: WanMapColors.accent,
        unselectedItemColor: WanMapColors.textSecondaryLight,
        selectedLabelStyle: WanMapTypography.labelMedium,
        unselectedLabelStyle: WanMapTypography.labelSmall,
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
        primary: WanMapColors.primaryLight,
        primaryContainer: WanMapColors.primary,
        secondary: WanMapColors.secondary,
        secondaryContainer: WanMapColors.secondaryDark,
        tertiary: WanMapColors.accentLight,
        tertiaryContainer: WanMapColors.accent,
        error: WanMapColors.error,
        surface: WanMapColors.surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: WanMapColors.textPrimaryDark,
      ),
      
      // テキストテーマ
      textTheme: TextTheme(
        // ディスプレイ
        displayLarge: WanMapTypography.displayLarge.copyWith(
          color: WanMapColors.textPrimaryDark,
        ),
        displayMedium: WanMapTypography.displayMedium.copyWith(
          color: WanMapColors.textPrimaryDark,
        ),
        displaySmall: WanMapTypography.displaySmall.copyWith(
          color: WanMapColors.textPrimaryDark,
        ),
        
        // ヘッドライン
        headlineLarge: WanMapTypography.headlineLarge.copyWith(
          color: WanMapColors.textPrimaryDark,
        ),
        headlineMedium: WanMapTypography.headlineMedium.copyWith(
          color: WanMapColors.textPrimaryDark,
        ),
        headlineSmall: WanMapTypography.headlineSmall.copyWith(
          color: WanMapColors.textPrimaryDark,
        ),
        
        // タイトル
        titleLarge: WanMapTypography.titleLarge.copyWith(
          color: WanMapColors.textPrimaryDark,
        ),
        titleMedium: WanMapTypography.titleMedium.copyWith(
          color: WanMapColors.textPrimaryDark,
        ),
        titleSmall: WanMapTypography.titleSmall.copyWith(
          color: WanMapColors.textPrimaryDark,
        ),
        
        // ボディ
        bodyLarge: WanMapTypography.bodyLarge.copyWith(
          color: WanMapColors.textPrimaryDark,
        ),
        bodyMedium: WanMapTypography.bodyMedium.copyWith(
          color: WanMapColors.textSecondaryDark,
        ),
        bodySmall: WanMapTypography.bodySmall.copyWith(
          color: WanMapColors.textTertiaryDark,
        ),
        
        // ラベル
        labelLarge: WanMapTypography.labelLarge.copyWith(
          color: WanMapColors.textSecondaryDark,
        ),
        labelMedium: WanMapTypography.labelMedium.copyWith(
          color: WanMapColors.textSecondaryDark,
        ),
        labelSmall: WanMapTypography.labelSmall.copyWith(
          color: WanMapColors.textTertiaryDark,
        ),
      ),
      
      // AppBar（ダークモード同様の設定）
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: WanMapColors.textPrimaryDark,
        titleTextStyle: WanMapTypography.headlineMedium.copyWith(
          color: WanMapColors.textPrimaryDark,
        ),
      ),
      
      // その他のテーマ設定はライトテーマと同様...
      // （色を調整）
    );
  }
}
