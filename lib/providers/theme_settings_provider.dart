import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/theme_settings.dart';
import '../data/models/preset_theme.dart';
import '../data/dao/settings_dao.dart';
import '../utils/theme_generator.dart';
import 'database_providers.dart';

/// テーマ設定の状態管理
class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  final SettingsDao _settingsDao;

  ThemeSettingsNotifier(this._settingsDao)
      : super(ThemeSettings.defaultSettings) {
    _loadFromStorage();
  }

  /// ストレージから設定を読み込み
  Future<void> _loadFromStorage() async {
    final json = await _settingsDao.getThemeSettings();
    if (json != null) {
      state = ThemeSettings.fromJson(json);
    }
  }

  /// ストレージに設定を保存
  Future<void> _saveToStorage() async {
    await _settingsDao.saveThemeSettings(state.toJson());
  }

  /// プリセットテーマを設定
  void setPreset(PresetTheme preset) {
    if (preset == PresetTheme.custom) {
      // カスタムに切り替える場合は、現在のプリセットの色をカスタム値として設定
      final currentPreset = state.preset;
      state = state.copyWith(
        preset: preset,
        primaryHex: _colorToHex(currentPreset.primaryColor),
        secondaryHex: _colorToHex(currentPreset.secondaryColor),
      );
    } else {
      // プリセットに切り替える場合はカスタム値をクリア
      state = ThemeSettings(preset: preset);
    }
    _saveToStorage();
  }

  /// プライマリカラーを設定（カスタムモードに自動切り替え）
  void setPrimaryColor(String hex) {
    state = state.copyWith(
      preset: PresetTheme.custom,
      primaryHex: hex,
    );
    _saveToStorage();
  }

  /// セカンダリカラーを設定（カスタムモードに自動切り替え）
  void setSecondaryColor(String hex) {
    state = state.copyWith(
      preset: PresetTheme.custom,
      secondaryHex: hex,
    );
    _saveToStorage();
  }

  /// onPrimaryカラーを設定（カスタムモードに自動切り替え）
  void setOnPrimaryColor(String hex) {
    state = state.copyWith(
      preset: PresetTheme.custom,
      onPrimaryHex: hex,
    );
    _saveToStorage();
  }

  /// 背景色を設定（カスタムモードに自動切り替え）
  void setBackgroundColor(String? hex) {
    state = state.copyWith(
      preset: PresetTheme.custom,
      backgroundHex: hex,
      clearBackgroundHex: hex == null,
    );
    _saveToStorage();
  }

  /// デフォルトにリセット
  void reset() {
    state = ThemeSettings.defaultSettings;
    _saveToStorage();
  }

  /// Color を Hex文字列に変換
  String _colorToHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

/// テーマ設定プロバイダー
final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  final settingsDao = ref.read(settingsDaoProvider);
  return ThemeSettingsNotifier(settingsDao);
});

/// 動的テーマデータプロバイダー
///
/// ThemeSettingsの変更に応じてThemeDataを再生成
final appThemeDataProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return ThemeGenerator.generate(settings);
});

/// 現在のColorSchemeプロバイダー（プレビュー用）
final currentColorSchemeProvider = Provider<ColorScheme>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return ThemeGenerator.getPreviewColorScheme(settings);
});
