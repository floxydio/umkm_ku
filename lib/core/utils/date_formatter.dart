import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _dateFormat = DateFormat('d MMMM yyyy', 'id_ID');
  static final _dateTimeFormat = DateFormat('d MMMM yyyy, HH:mm', 'id_ID');
  static final _shortDateFormat = DateFormat('d MMM yyyy', 'id_ID');
  static final _timeFormat = DateFormat('HH:mm', 'id_ID');

  /// "12 Maret 2025"
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// "12 Maret 2025, 14:30"
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  /// "12 Mar 2025"
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);

  /// "14:30"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Returns true if [date] is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Returns a human-friendly label: "Hari ini", "Kemarin", or formatted date.
  static String formatRelative(DateTime date) {
    if (isToday(date)) return 'Hari ini';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Kemarin';
    }
    return formatDate(date);
  }
}
