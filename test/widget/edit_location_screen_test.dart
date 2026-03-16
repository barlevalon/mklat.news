import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mklat/presentation/screens/edit_location_screen.dart';
import 'package:mklat/presentation/providers/location_provider.dart';
import 'package:mklat/data/models/saved_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditLocationScreen', () {
    Widget buildTestWidget({
      required LocationProvider locationProvider,
      required SavedLocation location,
      required ThemeMode themeMode,
    }) {
      return MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ChangeNotifierProvider.value(
            value: locationProvider,
            child: EditLocationScreen(location: location),
          ),
        ),
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'read-only OREF field does not use light grey background in dark mode',
      (WidgetTester tester) async {
        final provider = LocationProvider();
        await provider.loadLocations();

        final location = SavedLocation.create(
          orefName: 'תל אביב - מרכז',
          customLabel: 'בית',
          isPrimary: true,
        );

        await tester.pumpWidget(
          buildTestWidget(
            locationProvider: provider,
            location: location,
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();

        // Find the OREF field container by looking for the text inside it
        final orefTextFinder = find.text('תל אביב - מרכז');
        expect(orefTextFinder, findsOneWidget);

        // Get the parent Container of the OREF text
        final containerFinder = find.ancestor(
          of: orefTextFinder,
          matching: find.byType(Container),
        );
        expect(containerFinder, findsOneWidget);

        // Extract the container's decoration color
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration?;
        final backgroundColor = decoration?.color;

        // Assert: background should NOT be the hardcoded light grey
        expect(
          backgroundColor,
          isNot(equals(Colors.grey.shade50)),
          reason:
              'OREF field background should not use hardcoded light grey (Colors.grey.shade50) in dark mode',
        );
      },
    );
  });
}
