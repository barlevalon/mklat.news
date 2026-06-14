import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/models/alert.dart';
import 'package:mklat/data/models/saved_location.dart';
import 'package:mklat/presentation/models/status_presentation_model.dart';

void main() {
  group('StatusPresentationModel', () {
    final now = DateTime(2026, 3, 4, 14, 30);

    SavedLocation location({
      required String id,
      required String name,
      String label = '',
      bool primary = false,
    }) {
      return SavedLocation(
        id: id,
        orefName: name,
        customLabel: label,
        isPrimary: primary,
      );
    }

    test('builds secondary chips and active nationwide summary', () {
      final model = StatusPresentationModel.build(
        currentAlerts: [
          Alert(
            id: 'a1',
            location: 'חיפה',
            title: 'ירי רקטות וטילים',
            time: now,
            category: 1,
          ),
          Alert(
            id: 'a2',
            location: 'באר שבע',
            title: 'ירי רקטות וטילים',
            time: now,
            category: 1,
          ),
        ],
        alertHistory: const [],
        savedLocations: [
          location(id: 'primary', name: 'תל אביב', primary: true),
          location(id: 'secondary', name: 'חיפה', label: 'עבודה'),
        ],
        displayedItemCount: 20,
        isOffline: false,
        isLoading: false,
        currentAlertError: null,
        historyError: null,
      );

      expect(model.secondaryLocationChips, hasLength(1));
      expect(model.secondaryLocationChips.single.label, 'עבודה');
      expect(
        model.secondaryLocationChips.single.dotState,
        SecondaryLocationDotState.active,
      );
      expect(model.nationwideSummary?.nationwideCount, 2);
      expect(model.nationwideSummary?.userLocationCount, 1);
    });

    test(
      'current alert error suppresses secondary chips and creates banner',
      () {
        final model = StatusPresentationModel.build(
          currentAlerts: const [],
          alertHistory: const [],
          savedLocations: [
            location(id: 'primary', name: 'תל אביב', primary: true),
            location(id: 'secondary', name: 'חיפה'),
          ],
          displayedItemCount: 20,
          isOffline: false,
          isLoading: false,
          currentAlertError: 'שגיאה בטעינת התרעות',
          historyError: null,
        );

        expect(model.errorBanner?.message, 'שגיאה בטעינת התרעות');
        expect(model.secondaryLocationChips, isEmpty);
      },
    );

    test('offline marks secondary chips unavailable', () {
      final model = StatusPresentationModel.build(
        currentAlerts: const [],
        alertHistory: const [],
        savedLocations: [
          location(id: 'primary', name: 'תל אביב', primary: true),
          location(id: 'secondary', name: 'חיפה'),
        ],
        displayedItemCount: 20,
        isOffline: true,
        isLoading: false,
        currentAlertError: null,
        historyError: null,
      );

      expect(
        model.secondaryLocationChips.single.dotState,
        SecondaryLocationDotState.unavailable,
      );
    });
  });
}
