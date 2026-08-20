import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date, {String? locale}) {
    return DateFormat('yyyy-MM-dd', locale).format(date);
  }

  static String formatTime(DateTime time, {String? locale}) {
    return DateFormat('HH:mm:ss', locale).format(time);
  }

  static String formatDateTime(DateTime dateTime, {String? locale}) {
    return DateFormat('yyyy-MM-dd HH:mm:ss', locale).format(dateTime);
  }

  static String formatDateReadable(DateTime date, {String? locale}) {
    return DateFormat('MMM dd, yyyy', locale).format(date);
  }

  static String formatTimeReadable(DateTime time, {String? locale}) {
    return DateFormat('hh:mm a', locale).format(time);
  }

  static String formatDateTimeReadable(DateTime dateTime, {String? locale}) {
    return DateFormat('MMM dd, yyyy hh:mm a', locale).format(dateTime);
  }

  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  static String getDayName(int weekday, {String? locale}) {
    final days = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return days[weekday] ?? '';
  }

  static String getMonthName(int month, {String? locale}) {
    final months = {
      1: 'January',
      2: 'February',
      3: 'March',
      4: 'April',
      5: 'May',
      6: 'June',
      7: 'July',
      8: 'August',
      9: 'September',
      10: 'October',
      11: 'November',
      12: 'December',
    };
    return months[month] ?? '';
  }

  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static DateTime getStartOfWeek(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(start.year, start.month, start.day);
  }

  static DateTime getEndOfWeek(DateTime date) {
    final end = date.add(Duration(days: 7 - date.weekday));
    return DateTime(end.year, end.month, end.day, 23, 59, 59);
  }

  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }
}