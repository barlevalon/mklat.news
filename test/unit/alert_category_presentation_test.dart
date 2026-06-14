import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/models/alert.dart';
import 'package:mklat/presentation/models/alert_category_presentation.dart';

void main() {
  group('AlertCategoryPresentation', () {
    test('maps titles', () {
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.rockets).title,
        'ירי רקטות וטילים',
      );
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.uav).title,
        'חדירת כלי טיס עוין',
      );
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.clearance).title,
        'האירוע הסתיים',
      );
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.imminent).title,
        'התרעה צפויה',
      );
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.other).title,
        'התרעה',
      );
    });

    test('maps instructions', () {
      expect(
        AlertCategoryPresentation.fromCategory(
          AlertCategory.rockets,
        ).instruction,
        'היכנסו למרחב המוגן',
      );
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.uav).instruction,
        'היכנסו למרחב המוגן',
      );
      expect(
        AlertCategoryPresentation.fromCategory(
          AlertCategory.clearance,
        ).instruction,
        'ניתן לצאת מהמרחב המוגן',
      );
      expect(
        AlertCategoryPresentation.fromCategory(
          AlertCategory.imminent,
        ).instruction,
        'התרעות צפויות בדקות הקרובות',
      );
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.other).instruction,
        null,
      );
    });

    test('maps icons', () {
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.rockets).icon,
        '🚨',
      );
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.uav).icon,
        '🚨',
      );
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.clearance).icon,
        '✅',
      );
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.imminent).icon,
        '⚠️',
      );
      expect(
        AlertCategoryPresentation.fromCategory(AlertCategory.other).icon,
        '📍',
      );
    });
  });
}
