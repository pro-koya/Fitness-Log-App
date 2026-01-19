/// Unit converter for weight (kg ↔ lb)
class UnitConverter {
  static const double kgToLbRatio = 2.20462;
  static const double lbToKgRatio = 0.453592;

  /// Convert weight from one unit to another
  /// Returns value truncated to 3 decimal places
  static double convert({
    required double weight,
    required String fromUnit,
    required String toUnit,
  }) {
    if (fromUnit == toUnit) return weight;

    if (fromUnit == 'kg' && toUnit == 'lb') {
      return truncateToThreeDecimals(weight * kgToLbRatio);
    } else if (fromUnit == 'lb' && toUnit == 'kg') {
      return truncateToThreeDecimals(weight * lbToKgRatio);
    }

    throw ArgumentError('Invalid unit conversion: $fromUnit -> $toUnit');
  }

  /// Convert kg to lb
  /// Returns value truncated to 3 decimal places
  static double kgToLb(double kg) {
    return truncateToThreeDecimals(kg * kgToLbRatio);
  }

  /// Convert lb to kg
  /// Returns value truncated to 3 decimal places
  static double lbToKg(double lb) {
    return truncateToThreeDecimals(lb * lbToKgRatio);
  }

  /// Truncate weight to 3 decimal places (floor)
  /// Example: 22.04620 -> 22.046, 22.6796 -> 22.679
  static double truncateToThreeDecimals(double weight) {
    return (weight * 1000).floor() / 1000;
  }

  /// Round weight to appropriate precision (1 decimal place)
  /// Used for display purposes
  static double roundWeight(double weight) {
    return (weight * 10).round() / 10;
  }

  /// Format weight with unit
  static String formatWeight(double weight, String unit) {
    final rounded = roundWeight(weight);
    return '$rounded$unit';
  }
}
