import 'package:flutter/material.dart';

/// プリセットテーマの定義
enum PresetTheme {
  defaultBlue,
  forestGreen,
  sunsetOrange,
  midnightPurple,
  crimsonRed,
  oceanTeal,
  slateGray,
  carbonBlack,
  custom,
}

extension PresetThemeExtension on PresetTheme {
  /// テーマの表示名（英語）
  String get displayName {
    switch (this) {
      case PresetTheme.defaultBlue:
        return 'Default Blue';
      case PresetTheme.forestGreen:
        return 'Forest Green';
      case PresetTheme.sunsetOrange:
        return 'Sunset Orange';
      case PresetTheme.midnightPurple:
        return 'Midnight Purple';
      case PresetTheme.crimsonRed:
        return 'Crimson Red';
      case PresetTheme.oceanTeal:
        return 'Ocean Teal';
      case PresetTheme.slateGray:
        return 'Slate Gray';
      case PresetTheme.carbonBlack:
        return 'Carbon Black';
      case PresetTheme.custom:
        return 'Custom';
    }
  }

  /// テーマの表示名（日本語）
  String get displayNameJa {
    switch (this) {
      case PresetTheme.defaultBlue:
        return 'デフォルト（ブルー）';
      case PresetTheme.forestGreen:
        return 'フォレストグリーン';
      case PresetTheme.sunsetOrange:
        return 'サンセットオレンジ';
      case PresetTheme.midnightPurple:
        return 'ミッドナイトパープル';
      case PresetTheme.crimsonRed:
        return 'クリムゾンレッド';
      case PresetTheme.oceanTeal:
        return 'オーシャンティール';
      case PresetTheme.slateGray:
        return 'スレートグレー';
      case PresetTheme.carbonBlack:
        return 'カーボンブラック';
      case PresetTheme.custom:
        return 'カスタム';
    }
  }

  /// ローカライズされた表示名を取得
  String getLocalizedName(String language) {
    return language == 'ja' ? displayNameJa : displayName;
  }

  /// プライマリカラー（淡めで目に優しい色）
  /// 以前のセカンダリカラーをプライマリに
  Color get primaryColor {
    switch (this) {
      case PresetTheme.defaultBlue:
        return const Color(0xFF90CAF9); // 以前のセカンダリ
      case PresetTheme.forestGreen:
        return const Color(0xFFA5D6A7); // 以前のセカンダリ
      case PresetTheme.sunsetOrange:
        return const Color(0xFFFFCC80); // 以前のセカンダリ
      case PresetTheme.midnightPurple:
        return const Color(0xFFCE93D8); // 以前のセカンダリ
      case PresetTheme.crimsonRed:
        return const Color(0xFFEF9A9A); // 以前のセカンダリ
      case PresetTheme.oceanTeal:
        return const Color(0xFF80CBC4); // 以前のセカンダリ
      case PresetTheme.slateGray:
        return const Color(0xFFB0BEC5); // Blue Grey 200（淡いグレー）
      case PresetTheme.carbonBlack:
        return const Color(0xFF616161); // Grey 700（ダークグレー）
      case PresetTheme.custom:
        return const Color(0xFF90CAF9);
    }
  }

  /// セカンダリカラー（淡めで目に優しい色）
  /// 以前のプライマリカラーをセカンダリに
  Color get secondaryColor {
    switch (this) {
      case PresetTheme.defaultBlue:
        return const Color(0xFF64B5F6); // 以前のプライマリ
      case PresetTheme.forestGreen:
        return const Color(0xFF66BB6A); // 以前のプライマリ
      case PresetTheme.sunsetOrange:
        return const Color(0xFFFFA726); // 以前のプライマリ
      case PresetTheme.midnightPurple:
        return const Color(0xFF9575CD); // 以前のプライマリ
      case PresetTheme.crimsonRed:
        return const Color(0xFFE57373); // 以前のプライマリ
      case PresetTheme.oceanTeal:
        return const Color(0xFF4DB6AC); // 以前のプライマリ
      case PresetTheme.slateGray:
        return const Color(0xFF78909C); // Blue Grey 400
      case PresetTheme.carbonBlack:
        return const Color(0xFF424242); // Grey 800
      case PresetTheme.custom:
        return const Color(0xFF64B5F6);
    }
  }
}
