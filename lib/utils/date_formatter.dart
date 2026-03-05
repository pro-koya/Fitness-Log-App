import 'package:intl/intl.dart';
import 'chart_aggregation.dart';

/// Date formatter utility that respects language settings
class DateFormatter {
  /// Get date format based on language
  static DateFormat getDateFormat(String language, String pattern) {
    final locale = language == 'ja' ? 'ja_JP' : 'en_US';
    return DateFormat(pattern, locale);
  }

  /// Format date for display (e.g., "Jan 1, 2024" or "2024年1月1日")
  static String formatDate(DateTime date, String language) {
    if (language == 'ja') {
      return '${date.year}年${date.month}月${date.day}日';
    } else {
      return DateFormat('MMM d, yyyy', 'en_US').format(date);
    }
  }

  /// Format date in short format (e.g., "Jan 1" or "1/1")
  static String formatShortDate(DateTime date, String language) {
    if (language == 'ja') {
      return '${date.month}/${date.day}';
    } else {
      return DateFormat('MMM d', 'en_US').format(date);
    }
  }

  /// Format date in very short format (e.g., "1/1" or "1/1")
  static String formatVeryShortDate(DateTime date, String language) {
    return '${date.month}/${date.day}';
  }

  /// Format date in medium format (e.g., "Jan 1, 2024" or "2024年1月1日")
  static String formatMediumDate(DateTime date, String language) {
    if (language == 'ja') {
      return DateFormat.yMMMd('ja_JP').format(date);
    } else {
      return DateFormat.yMMMd('en_US').format(date);
    }
  }

  /// X軸ラベル用: バケット単位に応じた短い表示
  static String formatForChartAxis(
    DateTime date,
    String language,
    ChartXAxisBucket bucket,
  ) {
    switch (bucket) {
      case ChartXAxisBucket.day:
      case ChartXAxisBucket.twoDays:
        return '${date.month}/${date.day}';
      case ChartXAxisBucket.week:
      case ChartXAxisBucket.twoWeeks:
        return '${date.month}/${date.day}';
      case ChartXAxisBucket.month:
        // 年+月を短く表示（例: 24年4月 / Apr '24）
        if (language == 'ja') {
          return '${date.year % 100}年${date.month}月';
        }
        return "${DateFormat('MMM', 'en_US').format(date)} '${date.year % 100}";
      case ChartXAxisBucket.threeMonths:
        // 3ヶ月範囲の中間月を年付きで表示（例: Apr-Jun → 24年5月 / May '24）
        final mid3 = DateTime(date.year, date.month + 1, 1);
        if (language == 'ja') {
          return '${mid3.year % 100}年${mid3.month}月';
        }
        return "${DateFormat('MMM', 'en_US').format(mid3)} '${mid3.year % 100}";
      case ChartXAxisBucket.fourMonths:
        // 4ヶ月範囲の代表月を年付きで表示（例: Jan-Apr → 24年3月 / Mar '24）
        final mid4 = DateTime(date.year, date.month + 2, 1);
        if (language == 'ja') {
          return '${mid4.year % 100}年${mid4.month}月';
        }
        return "${DateFormat('MMM', 'en_US').format(mid4)} '${mid4.year % 100}";
    }
  }
}


