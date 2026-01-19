/// Body part localization
/// Provides localized names for body parts
class BodyPartLocalization {
  /// Body part keys
  static const String chest = 'chest';
  static const String back = 'back';
  static const String legs = 'legs';
  static const String shoulders = 'shoulders';
  static const String biceps = 'biceps';
  static const String triceps = 'triceps';
  static const String abs = 'abs';
  static const String cardio = 'cardio';
  static const String other = 'other';

  /// All body part keys
  static const List<String> allBodyParts = [
    chest,
    back,
    legs,
    shoulders,
    biceps,
    triceps,
    abs,
    cardio,
    other,
  ];

  /// Body part localization data
  static const Map<String, Map<String, String>> _bodyParts = {
    chest: {'en': 'Chest', 'ja': '胸'},
    back: {'en': 'Back', 'ja': '背中'},
    legs: {'en': 'Legs', 'ja': '脚'},
    shoulders: {'en': 'Shoulders', 'ja': '肩'},
    biceps: {'en': 'Biceps', 'ja': '上腕二頭筋'},
    triceps: {'en': 'Triceps', 'ja': '上腕三頭筋'},
    abs: {'en': 'Abs', 'ja': '腹筋'},
    cardio: {'en': 'Cardio', 'ja': '有酸素'},
    other: {'en': 'Other', 'ja': 'その他'},
  };

  /// Get localized name for body part
  /// Returns the body part name in the specified language
  static String getLocalizedName(String bodyPartKey, String language) {
    final bodyPart = _bodyParts[bodyPartKey];
    if (bodyPart == null) {
      return bodyPartKey; // Fallback to key if not found
    }

    // Get localized name, fallback to English if language not found
    return bodyPart[language] ?? bodyPart['en'] ?? bodyPartKey;
  }

  /// Get all body parts with localized names
  /// Returns a list of (key, localizedName) pairs
  static List<MapEntry<String, String>> getAllLocalizedBodyParts(
      String language) {
    return allBodyParts
        .map((key) => MapEntry(key, getLocalizedName(key, language)))
        .toList();
  }

  /// Get body part emoji
  static String getEmoji(String bodyPartKey) {
    switch (bodyPartKey) {
      case chest:
        return '💪';
      case back:
        return '🏋️';
      case legs:
        return '🦵';
      case shoulders:
        return '💪';
      case biceps:
        return '💪';
      case triceps:
        return '💪';
      case abs:
        return '🔥';
      case cardio:
        return '🏃';
      case other:
        return '🎯';
      default:
        return '💪';
    }
  }
}
