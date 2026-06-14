import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/core/relative_time_formatter.dart';

void main() {
  group('RelativeTimeFormatter', () {
    final now = DateTime(2026, 1, 1, 12);
    final formatter = RelativeTimeFormatter(now: () => now);

    test('formats Hebrew relative times', () {
      expect(
        formatter.format(now.subtract(const Duration(seconds: 10))),
        'עכשיו',
      );
      expect(
        formatter.format(now.subtract(const Duration(minutes: 1, seconds: 30))),
        'לפני דקה',
      );
      expect(
        formatter.format(now.subtract(const Duration(minutes: 5))),
        'לפני 5 דקות',
      );
      expect(
        formatter.format(now.subtract(const Duration(hours: 1, minutes: 30))),
        'לפני שעה',
      );
      expect(
        formatter.format(now.subtract(const Duration(hours: 3))),
        'לפני 3 שעות',
      );
    });

    test('formats old times as absolute day/month hour:minute', () {
      expect(formatter.format(DateTime(2025, 12, 30, 9, 5)), '30/12 09:05');
    });

    test('can omit future or sentinel dates', () {
      expect(
        formatter.formatPastOrNull(
          now.add(const Duration(hours: 1)),
          omitFuture: true,
        ),
        isNull,
      );
      expect(
        formatter.formatPastOrNull(
          DateTime.fromMillisecondsSinceEpoch(0),
          omitYearsBefore: 2000,
        ),
        isNull,
      );
    });
  });
}
