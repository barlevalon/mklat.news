DateTime _defaultNow() => DateTime.now();

class RelativeTimeFormatter {
  final DateTime Function() _now;

  const RelativeTimeFormatter({DateTime Function() now = _defaultNow})
    : _now = now;

  String format(DateTime time) {
    final diff = _now().difference(time);

    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes == 1) return 'לפני דקה';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דקות';
    if (diff.inHours == 1) return 'לפני שעה';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String? formatPastOrNull(
    DateTime time, {
    bool omitFuture = false,
    int? omitYearsBefore,
  }) {
    final diff = _now().difference(time);
    if ((omitFuture && diff.isNegative) ||
        (omitYearsBefore != null && time.year < omitYearsBefore)) {
      return null;
    }
    return format(time);
  }
}
