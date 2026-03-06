import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mklat/presentation/widgets/resume_overlay.dart';
import 'package:mklat/presentation/providers/alerts_provider.dart';

void main() {
  group('ResumeOverlay', () {
    Widget buildTestWidget({required AlertsProvider alertsProvider}) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ChangeNotifierProvider.value(
            value: alertsProvider,
            child: const Scaffold(body: ResumeOverlay()),
          ),
        ),
      );
    }

    testWidgets('overlay visible when resuming', (WidgetTester tester) async {
      final alertsProvider = AlertsProvider();
      alertsProvider.setResuming(true);

      await tester.pumpWidget(buildTestWidget(alertsProvider: alertsProvider));
      await tester.pump();

      // Should show the "מתעדכן..." text
      expect(find.text('מתעדכן...'), findsOneWidget);
      // Should show the circular progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('overlay hidden when not resuming', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      // isResuming defaults to false

      await tester.pumpWidget(buildTestWidget(alertsProvider: alertsProvider));
      await tester.pump();

      // Should NOT show the text
      expect(find.text('מתעדכן...'), findsNothing);
      // Should NOT show the progress indicator
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Should render a SizedBox.shrink()
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('overlay shows "מתעדכן..." text', (WidgetTester tester) async {
      final alertsProvider = AlertsProvider();
      alertsProvider.setResuming(true);

      await tester.pumpWidget(buildTestWidget(alertsProvider: alertsProvider));
      await tester.pump();

      // Verify Hebrew text is present
      final textWidget = tester.widget<Text>(find.text('מתעדכן...'));
      expect(textWidget.data, 'מתעדכן...');

      // Verify text contains Hebrew characters
      final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(textWidget.data!);
      expect(hasHebrew, isTrue);
    });

    testWidgets('overlay has semi-transparent background', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      alertsProvider.setResuming(true);

      await tester.pumpWidget(buildTestWidget(alertsProvider: alertsProvider));
      await tester.pump();

      // Find the container with the overlay background
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('מתעדכן...'),
              matching: find.byType(Container),
            )
            .first,
      );

      // Verify the container has a semi-transparent color
      expect(container.color, isNotNull);

      // Color should be semi-transparent black
      final color = container.color!;
      final alpha = (color.a * 255.0).round().clamp(0, 255);
      expect(alpha, lessThan(255)); // Not fully opaque
      expect(alpha, greaterThan(0)); // Not fully transparent
    });

    testWidgets('overlay covers entire screen', (WidgetTester tester) async {
      final alertsProvider = AlertsProvider();
      alertsProvider.setResuming(true);

      await tester.pumpWidget(buildTestWidget(alertsProvider: alertsProvider));
      await tester.pump();

      // Find the container that should cover the screen
      final containerFinder = find
          .ancestor(
            of: find.text('מתעדכן...'),
            matching: find.byType(Container),
          )
          .first;

      final container = tester.widget<Container>(containerFinder);

      // Should have infinite constraints (double.infinity width/height)
      expect(container.constraints, isNotNull);
      // The container should fill the available space
      expect(
        find.ancestor(
          of: find.text('מתעדכן...'),
          matching: find.byWidgetPredicate((widget) {
            if (widget is Container) {
              final constraints = widget.constraints;
              if (constraints != null) {
                return constraints.maxWidth == double.infinity &&
                    constraints.maxHeight == double.infinity;
              }
            }
            return false;
          }),
        ),
        findsWidgets,
      );
    });

    testWidgets('overlay animates visibility change', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();

      await tester.pumpWidget(buildTestWidget(alertsProvider: alertsProvider));
      await tester.pump();

      // Initially not resuming
      expect(find.text('מתעדכן...'), findsNothing);

      // Set resuming to true
      alertsProvider.setResuming(true);
      await tester.pump();

      // Overlay should appear
      expect(find.text('מתעדכן...'), findsOneWidget);

      // Set resuming to false
      alertsProvider.setResuming(false);
      await tester.pump();

      // Overlay should disappear
      expect(find.text('מתעדכן...'), findsNothing);
    });
  });
}
