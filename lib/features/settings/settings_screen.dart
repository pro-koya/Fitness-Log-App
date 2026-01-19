import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/preset_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/entitlement_provider.dart';
import '../../providers/theme_settings_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/feature_gate.dart';
import '../paywall/paywall_service.dart';
import '../paywall/models/paywall_reason.dart';
import '../workout_input/widgets/timer_icon_button.dart';
import 'screens/theme_settings_screen.dart';
import 'screens/backup_screen.dart';

/// Settings screen for changing language and unit
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Temporary state to hold user selections before saving
  String? _selectedLanguage;
  String? _selectedUnit;
  String? _selectedDistanceUnit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize temporary state with current settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsAsync = ref.read(settingsNotifierProvider);
      settingsAsync.whenData((settings) {
        if (settings != null && mounted) {
          setState(() {
            _selectedLanguage = settings.language;
            _selectedUnit = settings.unit;
            _selectedDistanceUnit = settings.distanceUnit;
          });
        }
      });
    });
  }

  bool get _hasChanges {
    final settingsAsync = ref.read(settingsNotifierProvider);
    return settingsAsync.when(
      data: (settings) {
        if (settings == null) return false;
        return _selectedLanguage != settings.language ||
            _selectedUnit != settings.unit ||
            _selectedDistanceUnit != settings.distanceUnit;
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }

  Future<void> _saveSettings() async {
    if (!_hasChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(settingsNotifierProvider.notifier);

      // Update language if changed
      if (_selectedLanguage != null) {
        await notifier.updateLanguage(_selectedLanguage!);
      }

      // Update unit if changed
      if (_selectedUnit != null) {
        await notifier.updateUnit(_selectedUnit!);
      }

      // Update distance unit if changed
      if (_selectedDistanceUnit != null) {
        await notifier.updateDistanceUnit(_selectedDistanceUnit!);
      }

      // Invalidate settingsProvider to update main.dart
      ref.invalidate(settingsProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.settingsSaved ?? 'Settings saved'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Go back to previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.errorMessage(e.toString()) ?? 'Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.settingsTitle ?? 'Settings / 設定'),
        actions: [
          TimerIconButton(),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (settings == null) {
            return const Center(
              child: Text('No settings found'),
            );
          }

          // Initialize temporary state if not yet set
          if (_selectedLanguage == null || _selectedUnit == null || _selectedDistanceUnit == null) {
            _selectedLanguage = settings.language;
            _selectedUnit = settings.unit;
            _selectedDistanceUnit = settings.distanceUnit;
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Language Selection
                        _buildSectionLabel(l10n?.languageLabel ?? 'Language / 言語'),
                        const SizedBox(height: 12),
                        _buildLanguageSelector(_selectedLanguage ?? settings.language),
                        const SizedBox(height: 32),

                        // Unit Selection
                        _buildSectionLabel(l10n?.unitLabel ?? 'Unit / 単位'),
                        const SizedBox(height: 12),
                        _buildUnitSelector(_selectedUnit ?? settings.unit),
                        const SizedBox(height: 32),

                        // Distance Unit Selection
                        _buildSectionLabel(l10n?.distanceUnitLabel ?? 'Distance Unit / 距離単位'),
                        const SizedBox(height: 12),
                        _buildDistanceUnitSelector(_selectedDistanceUnit ?? settings.distanceUnit),
                        const SizedBox(height: 32),

                        // Theme Section
                        _buildThemeSection(l10n),
                        const SizedBox(height: 32),

                        // Backup Section
                        _buildBackupSection(l10n),

                        // Dev: Pro/Free toggle (only in debug mode)
                        if (kDebugMode) ...[
                          const SizedBox(height: 48),
                          const Divider(),
                          const SizedBox(height: 16),
                          _buildDevSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Save Button
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasChanges && !_isSaving ? _saveSettings : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n?.saveButton ?? 'Save',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildLanguageSelector(String currentLanguage) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLanguageOption('English', 'en', currentLanguage),
          ),
          Container(
            width: 1,
            height: 48,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildLanguageOption('日本語', 'ja', currentLanguage),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    String label,
    String value,
    String currentLanguage,
  ) {
    final isSelected = currentLanguage == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedLanguage = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSelector(String currentUnit) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildUnitOption('kg', 'kg', currentUnit),
          ),
          Container(
            width: 1,
            height: 48,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildUnitOption('lb', 'lb', currentUnit),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitOption(String label, String value, String currentUnit) {
    final isSelected = currentUnit == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedUnit = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceUnitSelector(String currentDistanceUnit) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDistanceUnitOption('km', 'km', currentDistanceUnit),
          ),
          Container(
            width: 1,
            height: 48,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildDistanceUnitOption('mile', 'mile', currentDistanceUnit),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceUnitOption(String label, String value, String currentDistanceUnit) {
    final isSelected = currentDistanceUnit == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDistanceUnit = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// テーマセクション（Pro機能）
  Widget _buildThemeSection(AppLocalizations? l10n) {
    final gate = ref.watch(featureGateProvider);
    final themeSettings = ref.watch(themeSettingsProvider);
    final colorScheme = ref.watch(currentColorSchemeProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);

    // カスタムテーマの場合は実際の色を使用、プリセットの場合はプリセットの色を使用
    final primaryColor = colorScheme.primary;
    final secondaryColor = colorScheme.secondary;

    // テーマ名の表示
    final themeName = themeSettings.isCustom
        ? (currentLanguage == 'ja' ? 'カスタム' : 'Custom')
        : themeSettings.preset.getLocalizedName(currentLanguage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(l10n?.themeLabel ?? 'Theme / テーマ'),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            if (!gate.canCustomizeTheme) {
              await showPaywall(context, reason: PaywallReason.theme);
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ThemeSettingsScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // カラープレビュー（実際の色を使用）
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        themeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!gate.canCustomizeTheme)
                        Text(
                          'Pro',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  gate.canCustomizeTheme ? Icons.chevron_right : Icons.lock,
                  color: gate.canCustomizeTheme ? null : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// バックアップセクション（Pro機能）
  Widget _buildBackupSection(AppLocalizations? l10n) {
    final gate = ref.watch(featureGateProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);

    final backupTitle = currentLanguage == 'ja' ? 'バックアップ / 復元' : 'Backup & Restore';
    final backupDescription = currentLanguage == 'ja'
        ? 'データを保存して別の端末に移行'
        : 'Save data to transfer to another device';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(l10n?.backupLabel ?? 'Backup / バックアップ'),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            if (!gate.canBackup) {
              await showPaywall(context, reason: PaywallReason.backup);
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BackupScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // アイコン
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: gate.canBackup
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.backup,
                    color: gate.canBackup
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        backupTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        backupDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (!gate.canBackup)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Pro',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  gate.canBackup ? Icons.chevron_right : Icons.lock,
                  color: gate.canBackup ? null : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 開発用セクション（デバッグモードのみ表示）
  Widget _buildDevSection() {
    final entitlementState = ref.watch(entitlementProvider);
    final isPro = entitlementState.isPro;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.developer_mode, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Developer Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscription Plan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPro ? 'Pro (Active)' : 'Free',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPro ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              Switch(
                value: isPro,
                onChanged: (value) {
                  ref.read(entitlementProvider.notifier).togglePro();
                },
                activeTrackColor: Colors.green.shade200,
                activeThumbColor: Colors.green,
              ),
            ],
          ),
          if (isPro) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Pro Features Enabled',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
