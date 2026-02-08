/// Exercise name localization helper
/// Maps standard exercise English names to localized names
class ExerciseLocalization {
  /// Map of English exercise names to Japanese names
  static const Map<String, String> _englishToJapanese = {
    // Chest
    'Bench Press': 'ベンチプレス',
    'Incline Bench Press': 'インクラインベンチプレス',
    'Dumbbell Bench Press': 'ダンベルベンチプレス',
    'Incline Dumbbell Bench Press': 'インクラインダンベルプレス',
    'Smith Press': 'スミスプレス',
    'Incline Smith Press': 'インクラインスミスプレス',
    'Dumbbell Fly': 'ダンベルフライ',
    'Incline Dumbbell Fly': 'インクラインダンベルフライ',
    'Cable Fly': 'ケーブルフライ',
    'Push-Up': 'プッシュアップ',
    'Dumbbell Press': 'ダンベルプレス', // Legacy name
    // Back
    'Pull-Up': '懸垂',
    'Pull Up': '懸垂', // Legacy name
    'Lat Pulldown': 'ラットプルダウン',
    'Barbell Row': 'バーベルロー',
    'Dumbbell Row': 'ダンベルロー',
    'Seated Row': 'シーテッドロー',
    'Deadlift': 'デッドリフト',
    // Legs
    'Squat': 'スクワット',
    'Leg Press': 'レッグプレス',
    'Leg Extension': 'レッグエクステンション',
    'Leg Curl': 'レッグカール',
    'Lunge': 'ランジ',
    'Calf Raise': 'カーフレイズ',
    // Shoulders
    'Shoulder Press': 'ショルダープレス',
    'Smith Shoulder Press': 'スミスショルダープレス',
    'Dumbbell Shoulder Press': 'ダンベルショルダープレス',
    'Lateral Raise': 'サイドレイズ',
    'Incline Lateral Raise': 'インクラインサイドレイズ',
    'Front Raise': 'フロントレイズ',
    'Rear Delt Raise': 'リアレイズ',
    'Arnold Press': 'アーノルドプレス',
    // Biceps
    'Biceps Curl': 'アームカール',
    'Dumbbell Curl': 'ダンベルカール',
    'Incline Dumbbell Curl': 'インクラインダンベルカール',
    'Barbell Curl': 'バーベルカール',
    'Hammer Curl': 'ハンマーカール',
    'Preacher Curl': 'プリーチャーカール',
    // Triceps
    'Triceps Pushdown': 'トライセプスプレスダウン',
    'Skull Crusher': 'スカルクラッシャー',
    'French Press': 'フレンチプレス',
    'Dips': 'ディップス',
    'Overhead Triceps Extension': 'オーバーヘッドエクステンション',
    'Tricep Extension': 'トライセップエクステンション', // Legacy name
    // Abs
    'Sit-Up': 'シットアップ',
    'Crunch': 'クランチ',
    'Leg Raise': 'レッグレイズ',
    'Plank': 'プランク',
    'Russian Twist': 'ロシアンツイスト',
    // Cardio
    'Running': 'ランニング',
    'Walking': 'ウォーキング',
    'Cycling': 'サイクリング',
    'Stationary Bike': 'エアロバイク',
    'Treadmill': 'トレッドミル',
    'Rowing': 'ローイング', // Legacy exercise
    'Jump Rope': '縄跳び', // Legacy exercise
    'Swimming': '水泳', // Legacy exercise
    'Elliptical': 'エリプティカル', // Legacy exercise
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

