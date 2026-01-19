import 'package:flutter/material.dart';

/// Hexカラーコードのパース・バリデーションユーティリティ
class HexColor {
  static final _hexPattern = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$');

  /// Hexカラーコードが有効かチェック
  ///
  /// 有効なフォーマット: #RRGGBB または #AARRGGBB
  static bool isValid(String? hex) {
    if (hex == null) return false;
    return _hexPattern.hasMatch(hex);
  }

  /// Hexカラーコードを Color に変換
  ///
  /// 無効な場合は FormatException をスロー
  static Color parse(String hex) {
    if (!isValid(hex)) {
      throw FormatException('Invalid hex color: $hex');
    }

    String hexValue = hex.replaceFirst('#', '');
    if (hexValue.length == 6) {
      hexValue = 'FF$hexValue'; // アルファ値を追加
    }
    return Color(int.parse(hexValue, radix: 16));
  }

  /// Hexカラーコードを Color に変換（失敗時はデフォルト値）
  static Color tryParse(String? hex, {Color defaultColor = Colors.blue}) {
    if (hex == null || !isValid(hex)) {
      return defaultColor;
    }
    try {
      return parse(hex);
    } catch (_) {
      return defaultColor;
    }
  }

  /// Color を Hexカラーコードに変換
  ///
  /// [includeAlpha] trueの場合、アルファ値を含む（#AARRGGBB形式）
  static String toHex(Color color, {bool includeAlpha = false}) {
    if (includeAlpha) {
      return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    }
    // RGBのみ（アルファを除外）
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// ユーザー入力を正規化
  ///
  /// 先頭の#がなければ追加し、小文字を大文字に変換
  static String normalize(String input) {
    String hex = input.trim().toUpperCase();
    if (!hex.startsWith('#')) {
      hex = '#$hex';
    }
    return hex;
  }
}
