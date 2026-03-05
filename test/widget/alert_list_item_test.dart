import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/presentation/widgets/alert_list_item.dart';
import 'package:mklat/data/models/alert.dart';

void main() {
  group('AlertListItem', () {
    Widget buildTestWidget(Alert alert) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: AlertListItem(alert: alert)),
        ),
      );
    }

    testWidgets('singular minute: shows "לפני דקה" not "לפני 1 דקות"', (
      WidgetTester tester,
    ) async {
      final alert = Alert(
        id: 'test_1',
        location: 'רחובות',
        title: 'ירי רקטות וטילים',
        time: DateTime.now().subtract(const Duration(minutes: 1, seconds: 30)),
        category: 1,
      );

      await tester.pumpWidget(buildTestWidget(alert));

      // Should show singular form
      expect(find.textContaining('לפני דקה'), findsOneWidget);
      // Should NOT show "1 דקות"
      expect(find.textContaining('1 דקות'), findsNothing);
    });

    testWidgets('singular hour: shows "לפני שעה" not "לפני 1 שעות"', (
      WidgetTester tester,
    ) async {
      final alert = Alert(
        id: 'test_1',
        location: 'רחובות',
        title: 'ירי רקטות וטילים',
        time: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        category: 1,
      );

      await tester.pumpWidget(buildTestWidget(alert));

      // Should show singular form
      expect(find.textContaining('לפני שעה'), findsOneWidget);
      // Should NOT show "1 שעות"
      expect(find.textContaining('1 שעות'), findsNothing);
    });

    testWidgets('plural minutes: shows "לפני 5 דקות"', (
      WidgetTester tester,
    ) async {
      final alert = Alert(
        id: 'test_1',
        location: 'רחובות',
        title: 'ירי רקטות וטילים',
        time: DateTime.now().subtract(const Duration(minutes: 5)),
        category: 1,
      );

      await tester.pumpWidget(buildTestWidget(alert));

      expect(find.textContaining('לפני 5 דקות'), findsOneWidget);
    });

    testWidgets('plural hours: shows "לפני 3 שעות"', (
      WidgetTester tester,
    ) async {
      final alert = Alert(
        id: 'test_1',
        location: 'רחובות',
        title: 'ירי רקטות וטילים',
        time: DateTime.now().subtract(const Duration(hours: 3)),
        category: 1,
      );

      await tester.pumpWidget(buildTestWidget(alert));

      expect(find.textContaining('לפני 3 שעות'), findsOneWidget);
    });
  });
}
