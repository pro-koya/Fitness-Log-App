import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/preset_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_settings_provider.dart';
import '../../../utils/contrast_checker.dart';
import '../widgets/color_input_field.dart';
import '../widgets/theme_preview_card.dart';

/// テーマ設定画面（Pro専用）
class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() =>
      _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final themeSettings = ref.watch(themeSettingsProvider);
    final colorScheme = ref.watch(currentColorSchemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.themeSettingsTitle),
        actions: [
          // リセットボタン
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.resetToDefaultLabel,
            onPressed: () {
              _showResetConfirmDialog(context, l10n);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プレビューセクション
            Text(
              l10n.previewLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ThemePreviewCard(colorScheme: colorScheme),
            const SizedBox(height: 24),

            // プリセットテーマセクション
            Text(
              l10n.presetThemesLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPresetGrid(currentLanguage, themeSettings.preset),
            const SizedBox(height: 24),

            // カスタムカラーセクション
            Text(
              l10n.customColorsLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCustomColorSection(l10n, themeSettings, colorScheme),
          ],
        ),
      ),
    );
  }

  /// プリセットテーマのグリッド
  Widget _buildPresetGrid(String language, PresetTheme currentPreset) {
    // custom以外のプリセットのみ表示
    final presets =
        PresetTheme.values.where((p) => p != PresetTheme.custom).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        final isSelected = preset == currentPreset;

        return GestureDetector(
          onTap: () {
            ref.read(themeSettingsProvider.notifier).setPreset(preset);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // カラーサンプル
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [preset.primaryColor, preset.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // テーマ名
                Text(
                  preset.getLocalizedName(language),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// カスタムカラーセクション
  Widget _buildCustomColorSection(
    AppLocalizations l10n,
    themeSettings,
    ColorScheme colorScheme,
  ) {
    // コントラストチェック
    final contrastResult = ContrastChecker.checkPrimaryContrast(
      colorScheme.primary,
      colorScheme.onPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // プライマリカラー
        ColorInputField(
          label: l10n.primaryColorLabel,
          currentColor: colorScheme.primary,
          initialHex: themeSettings.primaryHex,
          onColorChanged: (hex) {
            ref.read(themeSettingsProvider.notifier).setPrimaryColor(hex);
          },
        ),
        const SizedBox(height: 16),

        // セカンダリカラー
        ColorInputField(
          label: l10n.secondaryColorLabel,
          currentColor: colorScheme.secondary,
          initialHex: themeSettings.secondaryHex,
          onColorChanged: (hex) {
            ref.read(themeSettingsProvider.notifier).setSecondaryColor(hex);
          },
        ),
        const SizedBox(height: 16),

        // コントラスト警告
        if (!contrastResult.isAdequate)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.contrastWarning,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// リセット確認ダイアログ
  void _showResetConfirmDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetToDefaultLabel),
        content: Text(l10n.resetThemeConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () {
              ref.read(themeSettingsProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );
  }
}
