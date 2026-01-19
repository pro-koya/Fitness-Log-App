/// Exercise name localization helper
/// Maps standard exercise English names to localized names
class ExerciseLocalization {
  /// Map of English exercise names to Japanese names
  static const Map<String, String> _englishToJapanese = {
    'Bench Press': 'ベンチプレス',
    'Incline Bench Press': 'インクラインベンチプレス',
    'Dumbbell Press': 'ダンベルプレス',
    'Squat': 'スクワット',
    'Leg Press': 'レッグプレス',
    'Deadlift': 'デッドリフト',
    'Barbell Row': 'バーベルロウ',
    'Pull Up': '懸垂',
    'Shoulder Press': 'ショルダープレス',
    'Lateral Raise': 'サイドレイズ',
    'Barbell Curl': 'バーベルカール',
    'Tricep Extension': 'トライセップエクステンション',
    // Cardio exercises
    'Running': 'ランニング',
    'Walking': 'ウォーキング',
    'Cycling': 'サイクリング',
    'Rowing': 'ローイング',
    'Jump Rope': '縄跳び',
    'Swimming': '水泳',
    'Elliptical': 'エリプティカル',
  };

  /// Get localized exercise name
  /// Returns Japanese name if language is 'ja' and exercise is standard, otherwise returns original name
  static String getLocalizedName({
    required String englishName,
    required String language,
    required bool isStandard,
  }) {
    // Only translate standard exercises
    if (!isStandard) {
      return englishName;
    }

    // Translate to Japanese if language is Japanese
    if (language == 'ja') {
      return _englishToJapanese[englishName] ?? englishName;
    }

    // Return English name for other languages
    return englishName;
  }

  /// Get all localized names for an exercise (for search purposes)
  /// Returns a list containing both English and Japanese names
  static List<String> getAllNames(String englishName) {
    final names = [englishName];
    final japaneseName = _englishToJapanese[englishName];
    if (japaneseName != null) {
      names.add(japaneseName);
    }
    return names;
  }

  /// Check if query matches exercise name in any language
  static bool matchesSearch(String englishName, String query, bool isStandard) {
    final lowerQuery = query.toLowerCase();
    
    // Check English name
    if (englishName.toLowerCase().contains(lowerQuery)) {
      return true;
    }

    // Check Japanese name if standard exercise
    if (isStandard) {
      final japaneseName = _englishToJapanese[englishName];
      if (japaneseName != null && japaneseName.toLowerCase().contains(lowerQuery)) {
        return true;
      }
    }

    return false;
  }
}

