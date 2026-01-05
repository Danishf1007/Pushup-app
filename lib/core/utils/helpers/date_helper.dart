import 'package:intl/intl.dart';

/// Date and time helper functions.
///
/// Provides consistent date/time formatting and manipulation.
abstract class DateHelper {
  /// Format date as "Dec 29, 2025"
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format date as "December 29, 2025"
  static String formatDateLong(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  /// Format date as "29/12/2025"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format time as "9:30 AM"
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// Format date and time as "Dec 29, 2025 at 9:30 AM"
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${formatTime(dateTime)}';
  }

  /// Format duration in minutes to "32 min" or "1h 15min"
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}min';
  }

  /// Get relative time string like "2 days ago", "Just now"
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Get day of week name (Monday, Tuesday, etc.)
  static String getDayName(int dayOfWeek) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayOfWeek - 1];
  }

  /// Get short day name (Mon, Tue, etc.)
  static String getDayNameShort(int dayOfWeek) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayOfWeek - 1];
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysToSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysToSunday)));
  }
}
