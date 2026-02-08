import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/entities/settings_entity.dart';
import 'database_providers.dart';

/// Provider for user settings
final settingsProvider = FutureProvider<SettingsEntity?>((ref) async {
  final dao = ref.watch(settingsDaoProvider);
  return await dao.getSettings();
});

/// Provider for current language
final currentLanguageProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.when(
    data: (settings) => settings?.language ?? 'en',
    loading: () => 'en',
    error: (_, __) => 'en',
  );
});

/// Provider for current unit
final currentUnitProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.when(
    data: (settings) => settings?.unit ?? 'kg',
    loading: () => 'kg',
    error: (_, __) => 'kg',
  );
});

/// Provider for current distance unit
final currentDistanceUnitProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.when(
    data: (settings) => settings?.distanceUnit ?? 'km',
    loading: () => 'km',
    error: (_, __) => 'km',
  );
});

/// Notifier for updating settings
class SettingsNotifier extends StateNotifier<AsyncValue<SettingsEntity?>> {
  SettingsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  final Ref ref;

  Future<void> _loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(settingsDaoProvider);
      final settings = await dao.getSettings();
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateLanguage(String language) async {
    try {
      final dao = ref.read(settingsDaoProvider);
      await dao.updateLanguage(language);
      await _loadSettings();
      // Invalidate settingsProvider to refresh currentLanguageProvider
      ref.invalidate(settingsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateUnit(String unit) async {
    try {
      final dao = ref.read(settingsDaoProvider);

      // Update unit in settings
      // No conversion needed - we store both kg and lb in the database
      await dao.updateUnit(unit);

      await _loadSettings();
      // Invalidate settingsProvider to refresh currentUnitProvider
      ref.invalidate(settingsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateDistanceUnit(String distanceUnit) async {
    try {
      final dao = ref.read(settingsDaoProvider);
      await dao.updateDistanceUnit(distanceUnit);
      await _loadSettings();
      // Invalidate settingsProvider to refresh currentDistanceUnitProvider
      ref.invalidate(settingsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Mark initial setup as completed
  Future<void> markSetupCompleted() async {
    try {
      final dao = ref.read(settingsDaoProvider);
      await dao.markSetupCompleted();
      await _loadSettings();
      // Also invalidate the settingsProvider to refresh it
      ref.invalidate(settingsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Mark tutorial as completed
  Future<void> markTutorialCompleted() async {
    try {
      final dao = ref.read(settingsDaoProvider);
      await dao.markTutorialCompleted();
      await _loadSettings();
      // Also invalidate the settingsProvider to refresh it
      ref.invalidate(settingsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for SettingsNotifier
final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsEntity?>>(
  (ref) => SettingsNotifier(ref),
);
