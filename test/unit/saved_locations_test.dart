import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/models/saved_location.dart';
import 'package:mklat/domain/saved_locations.dart';

void main() {
  group('normalizeSavedLocations', () {
    SavedLocation location(String id, {bool isPrimary = false}) {
      return SavedLocation(id: id, orefName: id, isPrimary: isPrimary);
    }

    test('empty list stays empty', () {
      expect(normalizeSavedLocations([]), isEmpty);
    });

    test('missing primary promotes first location', () {
      final result = normalizeSavedLocations([location('a'), location('b')]);

      expect(result.map((l) => l.isPrimary), [true, false]);
    });

    test('single primary is preserved', () {
      final result = normalizeSavedLocations([
        location('a'),
        location('b', isPrimary: true),
      ]);

      expect(result.map((l) => l.isPrimary), [false, true]);
    });

    test('multiple primaries keep first primary only', () {
      final result = normalizeSavedLocations([
        location('a'),
        location('b', isPrimary: true),
        location('c', isPrimary: true),
      ]);

      expect(result.map((l) => l.isPrimary), [false, true, false]);
    });
  });
}
