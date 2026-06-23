import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(int milliseconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  static String formatDateTime(int milliseconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return DateFormat('HH:mm dd/MM/yyyy').format(dt);
  }

  /// Returns calendar-day difference (ignores time-of-day).
  static int _calendarDaysDiff(DateTime a, DateTime b) {
    final aDate = DateTime(a.year, a.month, a.day);
    final bDate = DateTime(b.year, b.month, b.day);
    return aDate.difference(bDate).inDays;
  }

  static String relativeTime(int milliseconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final now = DateTime.now();
    final days = _calendarDaysDiff(now, dt); // positive = dt is in the past

    if (days < 0) {
      // future
      final futureDays = -days;
      if (futureDays == 0) return 'Hôm nay';
      if (futureDays == 1) return 'Ngày mai';
      return 'Còn $futureDays ngày';
    }
    if (days == 0) return 'Hôm nay';
    if (days == 1) return 'Hôm qua';
    if (days < 7) return '$days ngày trước';
    if (days < 30) return '${(days / 7).floor()} tuần trước';
    return formatDate(milliseconds);
  }

  static String nextActionLabel(int milliseconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final now = DateTime.now();
    final days = _calendarDaysDiff(dt, now); // positive = dt is in the past

    if (days > 0) return 'Cần liên hệ ngay'; // overdue
    final futureDays = -days;
    if (futureDays == 0) return 'Hôm nay';
    if (futureDays == 1) return 'Ngày mai';
    return 'Còn $futureDays ngày';
  }
}
