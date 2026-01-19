import 'package:intl/intl.dart';
import '../providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

