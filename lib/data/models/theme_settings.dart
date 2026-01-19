import 'dart:convert';
import 'preset_theme.dart';

/// テーマ設定モデル
///
/// プリセットテーマまたはカスタムカラーを保持
class ThemeSettings {
  final PresetTheme preset;
  final String? primaryHex;
  final String? secondaryHex;
  final String? onPrimaryHex;
  final String? backgroundHex;

  const ThemeSettings({
    this.preset = PresetTheme.defaultBlue,
    this.primaryHex,
    this.secondaryHex,
    this.onPrimaryHex,
    this.backgroundHex,
  });

  /// カスタムテーマかどうか
  bool get isCustom => preset == PresetTheme.custom;

  /// コピーして新しいインスタンスを作成
  ThemeSettings copyWith({
    PresetTheme? preset,
    String? primaryHex,
    String? secondaryHex,
    String? onPrimaryHex,
    String? backgroundHex,
    bool clearPrimaryHex = false,
    bool clearSecondaryHex = false,
    bool clearOnPrimaryHex = false,
    bool clearBackgroundHex = false,
  }) {
    return ThemeSettings(
      preset: preset ?? this.preset,
      primaryHex: clearPrimaryHex ? null : (primaryHex ?? this.primaryHex),
      secondaryHex:
          clearSecondaryHex ? null : (secondaryHex ?? this.secondaryHex),
      onPrimaryHex:
          clearOnPrimaryHex ? null : (onPrimaryHex ?? this.onPrimaryHex),
      backgroundHex:
          clearBackgroundHex ? null : (backgroundHex ?? this.backgroundHex),
    );
  }

  /// JSON文字列に変換
  String toJson() {
    return jsonEncode({
      'preset': preset.name,
      'primaryHex': primaryHex,
      'secondaryHex': secondaryHex,
      'onPrimaryHex': onPrimaryHex,
      'backgroundHex': backgroundHex,
    });
  }

  /// JSON文字列からインスタンスを作成
  factory ThemeSettings.fromJson(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return ThemeSettings(
        preset: PresetTheme.values.firstWhere(
          (e) => e.name == map['preset'],
          orElse: () => PresetTheme.defaultBlue,
        ),
        primaryHex: map['primaryHex'] as String?,
        secondaryHex: map['secondaryHex'] as String?,
        onPrimaryHex: map['onPrimaryHex'] as String?,
        backgroundHex: map['backgroundHex'] as String?,
      );
    } catch (e) {
      return const ThemeSettings();
    }
  }

  /// デフォルト設定
  static const ThemeSettings defaultSettings = ThemeSettings();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeSettings &&
        other.preset == preset &&
        other.primaryHex == primaryHex &&
        other.secondaryHex == secondaryHex &&
        other.onPrimaryHex == onPrimaryHex &&
        other.backgroundHex == backgroundHex;
  }

  @override
  int get hashCode {
    return preset.hashCode ^
        primaryHex.hashCode ^
        secondaryHex.hashCode ^
        onPrimaryHex.hashCode ^
        backgroundHex.hashCode;
  }

  @override
  String toString() {
    return 'ThemeSettings(preset: $preset, primaryHex: $primaryHex, '
        'secondaryHex: $secondaryHex, onPrimaryHex: $onPrimaryHex, '
        'backgroundHex: $backgroundHex)';
  }
}
