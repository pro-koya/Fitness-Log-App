import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../entities/settings_entity.dart';

/// DAO for settings table
class SettingsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get settings (always returns a single record with id = 1)
  Future<SettingsEntity?> getSettings() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (maps.isNotEmpty) {
      return SettingsEntity.fromMap(maps.first);
    }
    return null;
  }

  /// Update settings
  Future<int> updateSettings(SettingsEntity settings) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await db.update(
      'settings',
      settings.copyWith(updatedAt: now).toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  /// Update language
  Future<int> updateLanguage(String language) async {
    final settings = await getSettings();
    if (settings == null) return 0;

    return await updateSettings(
      settings.copyWith(language: language),
    );
  }

  /// Update unit
  Future<int> updateUnit(String unit) async {
    final settings = await getSettings();
    if (settings == null) return 0;

    return await updateSettings(
      settings.copyWith(unit: unit),
    );
  }

  /// Update distance unit
  Future<int> updateDistanceUnit(String distanceUnit) async {
    final settings = await getSettings();
    if (settings == null) return 0;

    return await updateSettings(
      settings.copyWith(distanceUnit: distanceUnit),
    );
  }

  /// Get entitlement status
  Future<String> getEntitlement() async {
    final settings = await getSettings();
    return settings?.entitlement ?? 'free';
  }

  /// Update entitlement status
  Future<int> updateEntitlement(String entitlement) async {
    final settings = await getSettings();
    if (settings == null) return 0;

    return await updateSettings(
      settings.copyWith(entitlement: entitlement),
    );
  }

  /// Get theme settings
  Future<String?> getThemeSettings() async {
    final settings = await getSettings();
    return settings?.themeSettings;
  }

  /// Update theme settings
  Future<int> saveThemeSettings(String? themeSettingsJson) async {
    final settings = await getSettings();
    if (settings == null) return 0;

    return await updateSettings(
      settings.copyWith(themeSettings: themeSettingsJson),
    );
  }
}
