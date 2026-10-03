import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// Formats date for note card footer, matching MI Notes:
  /// Current year: "September 11", "June 16", "January 1"
  /// Other years: "September 24, 2025", "July 21, 2025"
  static String formatCardDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year) {
      return DateFormat('MMMM d').format(date);
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  /// Formats date for detail metadata line:
  /// e.g. "11 September 9:23 PM | 18598 characters"
  static String formatDetailHeader(DateTime date, int charCount) {
    final dateStr = DateFormat('d MMMM h:mm a').format(date);
    return '$dateStr | $charCount characters';
  }

  /// Formats task due date
  static String formatTaskDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }
}
