import 'package:flutter/material.dart';
import '../data/models/theme_settings.dart';
import '../data/models/preset_theme.dart';
import 'hex_color.dart';

/// ThemeSettings から ThemeData を生成するユーティリティ
class ThemeGenerator {
  /// ThemeSettings から ThemeData を生成
  static ThemeData generate(ThemeSettings settings) {
    final colorScheme = _buildColorScheme(settings);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      // AppBarのスタイル
      // primaryカラーを使用し、文字色はonPrimaryで自動調整
      // スクロール時も色が変わらないようにsurfaceTintColorを透明に
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      // カードのスタイル
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // FilledButtonのスタイル
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // ElevatedButtonのスタイル
      // 背景色をセカンダリカラーに
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: colorScheme.secondary,
          foregroundColor: _getContrastColor(
            colorScheme.secondary,
            _estimateBrightness(colorScheme.secondary),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // TextButtonのスタイル
      // 文字色をセカンダリカラーに
      // セカンダリカラーが明るい場合は、プライマリカラーを背景色に適用して視認性を維持
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          foregroundColor: colorScheme.secondary,
          // セカンダリカラーが明るい場合、プライマリカラーを背景色に適用
          backgroundColor: _shouldAddTextBackground(colorScheme.secondary)
              ? colorScheme.primary.withOpacity(0.8)
              : null,
        ),
      ),
      // OutlinedButtonのスタイル
      // 枠線と文字色をセカンダリカラーに
      // セカンダリカラーが明るい場合は、プライマリカラーを背景色に適用して視認性を維持
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          foregroundColor: colorScheme.secondary,
          side: BorderSide(color: colorScheme.secondary),
          // セカンダリカラーが明るい場合、プライマリカラーを背景色に適用
          backgroundColor: _shouldAddTextBackground(colorScheme.secondary)
              ? colorScheme.primary.withOpacity(0.8)
              : null,
        ),
      ),
      // InputDecorationのスタイル
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      // テキスト選択のスタイル（カーソル色、選択範囲色など）
      // 紫色が表示されないように、プライマリカラーを明示的に設定
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withOpacity(0.4),
        selectionHandleColor: colorScheme.primary,
      ),
    );
  }

  /// ColorScheme を構築
  static ColorScheme _buildColorScheme(ThemeSettings settings) {
    if (!settings.isCustom) {
      // プリセットテーマの場合
      // fromSeedでベースを作り、copyWithで明示的に色を上書き
      final baseScheme = ColorScheme.fromSeed(
        seedColor: settings.preset.primaryColor,
      );
      return baseScheme.copyWith(
        primary: settings.preset.primaryColor,
        secondary: settings.preset.secondaryColor,
      );
    }

    // カスタムテーマの場合
    final primary = HexColor.tryParse(
      settings.primaryHex,
      defaultColor: PresetTheme.defaultBlue.primaryColor,
    );

    final secondary = HexColor.tryParse(
      settings.secondaryHex,
      defaultColor: PresetTheme.defaultBlue.secondaryColor,
    );

    // カスタムカラーの場合はfromSeedを使わず、明示的にColorSchemeを構築
    // ベースは常にライトテーマを使用（視認性を保つため）
    final baseScheme = ColorScheme.light();

    // onPrimaryの決定: カスタム値があればそれを使用、なければprimaryに基づいて自動決定
    final primaryBrightness = _estimateBrightness(primary);
    final onPrimary = settings.onPrimaryHex != null
        ? HexColor.tryParse(settings.onPrimaryHex!)
        : _getContrastColor(primary, primaryBrightness);

    // surfaceの決定: カスタム値があればそれを使用、なければ明るいベースを使用
    final surface = settings.backgroundHex != null
        ? HexColor.tryParse(settings.backgroundHex!)
        : baseScheme.surface;

    // ColorSchemeを明示的に構築
    // primaryとsecondaryだけを上書きし、surfaceなどのベース色は明るいまま保持
    return baseScheme.copyWith(
      primary: primary,
      secondary: secondary,
      onPrimary: onPrimary,
      surface: surface,
      // onSurfaceは明るいベースのままでOK（surfaceが明るいため）
    );
  }

  /// プレビュー用のColorSchemeを取得（設定を適用せずに確認）
  static ColorScheme getPreviewColorScheme(ThemeSettings settings) {
    return _buildColorScheme(settings);
  }

  /// 色の明るさを推定してBrightnessを返す
  /// 
  /// 輝度（luminance）を計算して、0.5を閾値として判定
  static Brightness _estimateBrightness(Color color) {
    // 相対輝度を計算（WCAG 2.1の定義に基づく）
    final luminance = (0.2126 * color.red + 0.7152 * color.green + 0.0722 * color.blue) / 255;
    return luminance > 0.5 ? Brightness.light : Brightness.dark;
  }

  /// 背景色に対して適切なコントラスト色を返す
  /// 
  /// brightnessに基づいて白または黒を返す
  static Color _getContrastColor(Color backgroundColor, Brightness brightness) {
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  /// セカンダリカラーが明るい（白に近い）場合にtrueを返す
  /// 
  /// 文字の視認性を保つために背景色を追加する必要があるかを判定
  /// 輝度が0.7以上の場合（明るい色）にtrueを返す
  static bool _shouldAddTextBackground(Color color) {
    final luminance = (0.2126 * color.red + 0.7152 * color.green + 0.0722 * color.blue) / 255;
    return luminance > 0.7; // 明るい色の場合（白に近い）
  }
}
