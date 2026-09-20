/// Centralized date and time formatting utilities.
library;

/// Formats a date as `dd.MM.yyyy`.
String formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year}';
}

/// Formats a date-time as `dd.MM.yyyy HH:mm`.
String formatDateTime(DateTime dt) {
  return '${formatDate(dt)} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

/// Formats a duration given in [seconds] as `Xm YYs`.
String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m}m ${s.toString().padLeft(2, '0')}s';
}
