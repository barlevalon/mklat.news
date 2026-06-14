import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/presentation/formatters/shelter_time_formatter.dart';

void main() {
  group('ShelterTimeFormatter', () {
    const formatter = ShelterTimeFormatter();

    test('formats known shelter times', () {
      expect(formatter.format(0), 'מיידי');
      expect(formatter.format(15), '15 שניות');
      expect(formatter.format(60), 'דקה');
      expect(formatter.format(90), 'דקה וחצי');
      expect(formatter.format(120), '2 דקות');
    });

    test('formats uncommon minute/second values', () {
      expect(formatter.format(75), '1:15 דקות');
    });

    test('returns null when shelter time is missing', () {
      expect(formatter.format(null), null);
    });
  });
}
