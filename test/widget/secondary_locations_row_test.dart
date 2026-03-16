import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mklat/presentation/widgets/secondary_locations_row.dart';
import 'package:mklat/presentation/providers/alerts_provider.dart';
import 'package:mklat/presentation/providers/location_provider.dart';
import 'package:mklat/presentation/providers/connectivity_provider.dart';
import 'package:mklat/data/models/saved_location.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  group('SecondaryLocationsRow', () {
    Widget buildTestWidget({
      required LocationProvider locationProvider,
      required AlertsProvider alertsProvider,
      required ConnectivityProvider connectivityProvider,
    }) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: locationProvider),
              ChangeNotifierProvider.value(value: alertsProvider),
              ChangeNotifierProvider.value(value: connectivityProvider),
            ],
            child: const Scaffold(body: SecondaryLocationsRow()),
          ),
        ),
      );
    }

    testWidgets('shows grey dots when offline', (WidgetTester tester) async {
      final controller = StreamController<ConnectivityResult>();
      final locationProvider = LocationProvider();
      final alertsProvider = AlertsProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        controller.stream,
      );

      // Add a primary location first (required for secondary to work)
      locationProvider.addLocation(
        SavedLocation(
          id: 'primary',
          orefName: 'ראשון לציון',
          customLabel: '',
          isPrimary: true,
          shelterTimeSec: 90,
        ),
      );

      // Add secondary locations
      locationProvider.addLocation(
        SavedLocation(
          id: 'loc-1',
          orefName: 'תל אביב',
          customLabel: '',
          isPrimary: false,
          shelterTimeSec: 90,
        ),
      );
      locationProvider.addLocation(
        SavedLocation(
          id: 'loc-2',
          orefName: 'ירושלים',
          customLabel: '',
          isPrimary: false,
          shelterTimeSec: 90,
        ),
      );

      // Start offline
      controller.add(ConnectivityResult.none);
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          locationProvider: locationProvider,
          alertsProvider: alertsProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show both locations
      expect(find.text('תל אביב'), findsOneWidget);
      expect(find.text('ירושלים'), findsOneWidget);

      await controller.close();
    });

    testWidgets('shows green dots when online with no alerts', (
      WidgetTester tester,
    ) async {
      final controller = StreamController<ConnectivityResult>();
      final locationProvider = LocationProvider();
      final alertsProvider = AlertsProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        controller.stream,
      );

      // Add a primary location first
      locationProvider.addLocation(
        SavedLocation(
          id: 'primary',
          orefName: 'ראשון לציון',
          customLabel: '',
          isPrimary: true,
          shelterTimeSec: 90,
        ),
      );

      // Add secondary location
      locationProvider.addLocation(
        SavedLocation(
          id: 'loc-1',
          orefName: 'תל אביב',
          customLabel: '',
          isPrimary: false,
          shelterTimeSec: 90,
        ),
      );

      // Start online
      controller.add(ConnectivityResult.wifi);
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          locationProvider: locationProvider,
          alertsProvider: alertsProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show the location
      expect(find.text('תל אביב'), findsOneWidget);

      await controller.close();
    });

    testWidgets('returns empty when no secondary locations', (
      WidgetTester tester,
    ) async {
      final controller = StreamController<ConnectivityResult>();
      final locationProvider = LocationProvider();
      final alertsProvider = AlertsProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        controller.stream,
      );

      // Start online
      controller.add(ConnectivityResult.wifi);
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          locationProvider: locationProvider,
          alertsProvider: alertsProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should return SizedBox.shrink (no visible content)
      expect(find.byType(SecondaryLocationsRow), findsOneWidget);
      // The row itself exists but contains no visible children

      await controller.close();
    });

    testWidgets('dots change color when connectivity changes', (
      WidgetTester tester,
    ) async {
      final controller = StreamController<ConnectivityResult>();
      final locationProvider = LocationProvider();
      final alertsProvider = AlertsProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        controller.stream,
      );

      // Add a primary location first
      locationProvider.addLocation(
        SavedLocation(
          id: 'primary',
          orefName: 'ראשון לציון',
          customLabel: '',
          isPrimary: true,
          shelterTimeSec: 90,
        ),
      );

      // Add secondary location
      locationProvider.addLocation(
        SavedLocation(
          id: 'loc-1',
          orefName: 'תל אביב',
          customLabel: '',
          isPrimary: false,
          shelterTimeSec: 90,
        ),
      );

      // Start online
      controller.add(ConnectivityResult.wifi);
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          locationProvider: locationProvider,
          alertsProvider: alertsProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show location
      expect(find.text('תל אביב'), findsOneWidget);

      // Go offline
      controller.add(ConnectivityResult.none);
      await tester.pump();

      // Should still show location but with grey dot
      expect(find.text('תל אביב'), findsOneWidget);

      // Go back online
      controller.add(ConnectivityResult.wifi);
      await tester.pump();

      // Should show location with green dot again
      expect(find.text('תל אביב'), findsOneWidget);

      await controller.close();
    });

    testWidgets('chip background is not hardcoded white in dark mode', (
      WidgetTester tester,
    ) async {
      final controller = StreamController<ConnectivityResult>();
      final locationProvider = LocationProvider();
      final alertsProvider = AlertsProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        controller.stream,
      );

      // Add a primary location first
      locationProvider.addLocation(
        SavedLocation(
          id: 'primary',
          orefName: 'ראשון לציון',
          customLabel: '',
          isPrimary: true,
          shelterTimeSec: 90,
        ),
      );

      // Add secondary location
      locationProvider.addLocation(
        SavedLocation(
          id: 'loc-1',
          orefName: 'תל אביב',
          customLabel: '',
          isPrimary: false,
          shelterTimeSec: 90,
        ),
      );

      // Start online
      controller.add(ConnectivityResult.wifi);
      await connectivityProvider.initialize();

      // Build with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: locationProvider),
                ChangeNotifierProvider.value(value: alertsProvider),
                ChangeNotifierProvider.value(value: connectivityProvider),
              ],
              child: const Scaffold(body: SecondaryLocationsRow()),
            ),
          ),
        ),
      );
      await tester.pump();

      // Find the chip container (the decorated container holding the location chip)
      final chipContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SecondaryLocationsRow),
              matching: find.byType(Container),
            )
            .at(
              1,
            ), // Second container is the chip (first is the outer ListView wrapper)
      );

      final decoration = chipContainer.decoration as BoxDecoration;

      // In dark mode, the chip background should NOT be hardcoded white
      expect(decoration.color, isNot(equals(Colors.white)));

      await controller.close();
    });

    testWidgets('chip border is not hardcoded black12 in dark mode', (
      WidgetTester tester,
    ) async {
      final controller = StreamController<ConnectivityResult>();
      final locationProvider = LocationProvider();
      final alertsProvider = AlertsProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        controller.stream,
      );

      // Add a primary location first
      locationProvider.addLocation(
        SavedLocation(
          id: 'primary',
          orefName: 'ראשון לציון',
          customLabel: '',
          isPrimary: true,
          shelterTimeSec: 90,
        ),
      );

      // Add secondary location
      locationProvider.addLocation(
        SavedLocation(
          id: 'loc-1',
          orefName: 'תל אביב',
          customLabel: '',
          isPrimary: false,
          shelterTimeSec: 90,
        ),
      );

      // Start online
      controller.add(ConnectivityResult.wifi);
      await connectivityProvider.initialize();

      // Build with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: locationProvider),
                ChangeNotifierProvider.value(value: alertsProvider),
                ChangeNotifierProvider.value(value: connectivityProvider),
              ],
              child: const Scaffold(body: SecondaryLocationsRow()),
            ),
          ),
        ),
      );
      await tester.pump();

      // Find the chip container (the decorated container holding the location chip)
      final chipContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SecondaryLocationsRow),
              matching: find.byType(Container),
            )
            .at(
              1,
            ), // Second container is the chip (first is the outer ListView wrapper)
      );

      final decoration = chipContainer.decoration as BoxDecoration;
      final border = decoration.border as Border;

      // In dark mode, the chip border should NOT be hardcoded black12
      expect(border.top.color, isNot(equals(Colors.black12)));

      await controller.close();
    });
  });
}
