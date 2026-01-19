import 'dart:math';
import 'package:flutter/material.dart';

/// コントラストチェック結果
class ContrastResult {
  final double ratio;
  final bool isAdequate;
  final String? warningMessage;

  const ContrastResult({
    required this.ratio,
    required this.isAdequate,
    this.warningMessage,
  });
}

/// コントラスト比チェッカー（WCAG準拠）
class ContrastChecker {
  /// WCAG AA準拠の最小コントラスト比（通常テキスト）
  static const double minContrastRatio = 4.5;

  /// WCAG AA準拠の最小コントラスト比（大きいテキスト）
  static const double minContrastRatioLarge = 3.0;

  /// 2色間のコントラスト比を計算
  ///
  /// WCAG 2.0のコントラスト比計算式に基づく
  static double calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();

    final lighter = max(fgLuminance, bgLuminance);
    final darker = min(fgLuminance, bgLuminance);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// コントラストが十分かチェック
  static bool hasAdequateContrast(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= minContrastRatio;
  }

  /// Primary と onPrimary のコントラストをチェック
  static ContrastResult checkPrimaryContrast(Color primary, Color onPrimary) {
    final ratio = calculateContrastRatio(onPrimary, primary);
    final isAdequate = ratio >= minContrastRatio;

    return ContrastResult(
      ratio: ratio,
      isAdequate: isAdequate,
      warningMessage: isAdequate
          ? null
          : 'コントラスト比が低いです (${ratio.toStringAsFixed(1)}:1)。読みやすさが低下する可能性があります。推奨: $minContrastRatio:1以上',
    );
  }

  /// コントラスト比のラベルを取得
  static String getContrastLabel(double ratio) {
    if (ratio >= 7.0) {
      return 'AAA (優秀)';
    } else if (ratio >= minContrastRatio) {
      return 'AA (適切)';
    } else if (ratio >= minContrastRatioLarge) {
      return '大文字のみ適切';
    } else {
      return '不適切';
    }
  }

  /// コントラスト比に応じた色を取得（UI表示用）
  static Color getContrastIndicatorColor(double ratio) {
    if (ratio >= minContrastRatio) {
      return Colors.green;
    } else if (ratio >= minContrastRatioLarge) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
