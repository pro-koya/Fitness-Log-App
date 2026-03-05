// Sentinel for nullable copyWith parameters
const _sentinel = Object();

/// Settings entity for user preferences
class SettingsEntity {
  final int id;
  final String language; // 'en' or 'ja'
  final String unit; // 'kg' or 'lb'
  final String distanceUnit; // 'km' or 'mile'
  final String entitlement; // 'free' or 'pro'
  final String? themeSettings; // JSON string for theme customization
  final String? timerSettings; // JSON string for timer notification (vibration, sound)
  final bool setupCompleted; // Whether initial setup has been completed
  final bool tutorialCompleted; // Whether interactive tutorial has been completed
  final int? lastSyncedAt; // UNIX timestamp of last Pro sync (null = never)
  final int? subscriptionExpiresAt; // UNIX timestamp of estimated subscription expiry (null = unknown)
  final int createdAt; // UNIX timestamp
  final int updatedAt; // UNIX timestamp

  const SettingsEntity({
    required this.id,
    required this.language,
    required this.unit,
    required this.distanceUnit,
    this.entitlement = 'free',
    this.themeSettings,
    this.timerSettings,
    this.setupCompleted = false,
    this.tutorialCompleted = false,
    this.lastSyncedAt,
    this.subscriptionExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from database map
  factory SettingsEntity.fromMap(Map<String, dynamic> map) {
    return SettingsEntity(
      id: map['id'] as int,
      language: map['language'] as String,
      unit: map['unit'] as String,
      distanceUnit: map['distance_unit'] as String? ?? 'km',
      entitlement: map['entitlement'] as String? ?? 'free',
      themeSettings: map['theme_settings'] as String?,
      timerSettings: map['timer_settings'] as String?,
      setupCompleted: (map['setup_completed'] as int? ?? 0) == 1,
      tutorialCompleted: (map['tutorial_completed'] as int? ?? 0) == 1,
      lastSyncedAt: map['last_synced_at'] as int?,
      subscriptionExpiresAt: map['subscription_expires_at'] as int?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'language': language,
      'unit': unit,
      'distance_unit': distanceUnit,
      'entitlement': entitlement,
      'theme_settings': themeSettings,
      'timer_settings': timerSettings,
      'setup_completed': setupCompleted ? 1 : 0,
      'tutorial_completed': tutorialCompleted ? 1 : 0,
      'last_synced_at': lastSyncedAt,
      'subscription_expires_at': subscriptionExpiresAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Copy with new values
  SettingsEntity copyWith({
    int? id,
    String? language,
    String? unit,
    String? distanceUnit,
    String? entitlement,
    String? themeSettings,
    String? timerSettings,
    bool? setupCompleted,
    bool? tutorialCompleted,
    int? lastSyncedAt,
    Object? subscriptionExpiresAt = _sentinel,
    int? createdAt,
    int? updatedAt,
  }) {
    return SettingsEntity(
      id: id ?? this.id,
      language: language ?? this.language,
      unit: unit ?? this.unit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      entitlement: entitlement ?? this.entitlement,
      themeSettings: themeSettings ?? this.themeSettings,
      timerSettings: timerSettings ?? this.timerSettings,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      subscriptionExpiresAt: subscriptionExpiresAt == _sentinel
          ? this.subscriptionExpiresAt
          : subscriptionExpiresAt as int?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SettingsEntity(id: $id, language: $language, unit: $unit, distanceUnit: $distanceUnit, entitlement: $entitlement, themeSettings: $themeSettings, timerSettings: $timerSettings, setupCompleted: $setupCompleted, tutorialCompleted: $tutorialCompleted, lastSyncedAt: $lastSyncedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SettingsEntity &&
        other.id == id &&
        other.language == language &&
        other.unit == unit &&
        other.distanceUnit == distanceUnit &&
        other.entitlement == entitlement &&
        other.themeSettings == themeSettings &&
        other.timerSettings == timerSettings &&
        other.setupCompleted == setupCompleted &&
        other.tutorialCompleted == tutorialCompleted &&
        other.lastSyncedAt == lastSyncedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        language.hashCode ^
        unit.hashCode ^
        distanceUnit.hashCode ^
        entitlement.hashCode ^
        themeSettings.hashCode ^
        timerSettings.hashCode ^
        setupCompleted.hashCode ^
        tutorialCompleted.hashCode ^
        lastSyncedAt.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
