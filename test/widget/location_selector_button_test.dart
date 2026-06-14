import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mklat/core/app_theme.dart';
import 'package:mklat/presentation/widgets/location_selector_button.dart';
import 'package:mklat/presentation/providers/location_provider.dart';

void main() {
  group('LocationSelectorButton', () {
    Widget buildDarkModeTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ChangeNotifierProvider(
            create: (_) => LocationProvider(),
            child: const Scaffold(body: LocationSelectorButton()),
          ),
        ),
      );
    }

    testWidgets(
      'dark mode: leading location icon uses theme color instead of hardcoded black54',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildDarkModeTestWidget());
        await tester.pump();

        // Find the location_on icon
        final iconFinder = find.byIcon(Icons.location_on_outlined);
        expect(iconFinder, findsOneWidget);

        final iconWidget = tester.widget<Icon>(iconFinder);
        final actualColor = iconWidget.color;

        // In dark mode, should NOT be the hardcoded light-mode black54
        expect(
          actualColor,
          isNot(equals(Colors.black54)),
          reason:
              'Location icon in dark mode should not use hardcoded Colors.black54',
        );

        expect(
          actualColor,
          equals(Colors.white.withAlpha(220)),
          reason: 'Location icon should use the dark-mode civic control color',
        );
      },
    );

    testWidgets(
      'dark mode: trailing chevron icon uses theme color instead of hardcoded black54',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildDarkModeTestWidget());
        await tester.pump();

        // Find the keyboard_arrow_down icon (trailing chevron)
        final iconFinder = find.byIcon(Icons.expand_more);
        expect(iconFinder, findsOneWidget);

        final iconWidget = tester.widget<Icon>(iconFinder);
        final actualColor = iconWidget.color;

        // In dark mode, should NOT be the hardcoded light-mode black54
        expect(
          actualColor,
          isNot(equals(Colors.black54)),
          reason:
              'Trailing chevron in dark mode should not use hardcoded Colors.black54',
        );

        expect(
          actualColor,
          equals(Colors.white.withAlpha(220)),
          reason:
              'Trailing chevron should use the dark-mode civic control color',
        );
      },
    );

    testWidgets(
      'dark mode: container background does not use hardcoded translucent white',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildDarkModeTestWidget());
        await tester.pump();

        // Find the Container with the decoration
        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final containerWidget = tester.widget<Container>(containerFinder);
        final decoration = containerWidget.decoration as BoxDecoration;
        final actualColor = decoration.color;

        // In dark mode, should NOT be the hardcoded light-mode translucent white
        final hardcodedLightColor = Colors.white.withAlpha(128);
        expect(
          actualColor,
          isNot(equals(hardcodedLightColor)),
          reason:
              'Container background in dark mode should not use hardcoded Colors.white.withAlpha(128)',
        );
      },
    );
    testWidgets('dark mode: border does not use hardcoded black12', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDarkModeTestWidget());
      await tester.pump();

      // Find the Container with the decoration
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final containerWidget = tester.widget<Container>(containerFinder);
      final decoration = containerWidget.decoration as BoxDecoration;
      final border = decoration.border as Border;
      final actualBorderColor = border.top.color;

      // In dark mode, should NOT be the hardcoded light-mode black12
      expect(
        actualBorderColor,
        isNot(equals(Colors.black12)),
        reason:
            'Border color in dark mode should not use hardcoded Colors.black12',
      );
    });
  });
}
