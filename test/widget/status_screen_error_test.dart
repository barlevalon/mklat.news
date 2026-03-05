import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mklat/presentation/screens/status_screen.dart';
import 'package:mklat/presentation/providers/alerts_provider.dart';
import 'package:mklat/presentation/providers/location_provider.dart';
import 'package:mklat/presentation/providers/connectivity_provider.dart';
import 'package:mklat/data/models/alert.dart';
import 'package:mklat/data/models/saved_location.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  group('StatusScreen Error States', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildTestWidget({
      required AlertsProvider alertsProvider,
      required LocationProvider locationProvider,
      required ConnectivityProvider connectivityProvider,
    }) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: alertsProvider),
              ChangeNotifierProvider.value(value: locationProvider),
              ChangeNotifierProvider.value(value: connectivityProvider),
            ],
            child: const Scaffold(body: StatusScreen()),
          ),
        ),
      );
    }

    testWidgets('loading spinner shown when isLoading and no data', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider(
        connectivity: MockConnectivity(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      // Add a location so the list area is shown
      await locationProvider.addLocation(
        SavedLocation(
          id: '1',
          orefName: 'תל אביב',
          customLabel: 'תל אביב',
          isPrimary: true,
        ),
      );

      // isLoading defaults to true, no data yet

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show loading spinner
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Should show "טוען..." text
      expect(find.text('טוען...'), findsOneWidget);
    });

    testWidgets('error message shown when errorMessage set', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider(
        connectivity: MockConnectivity(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      // Add a location
      await locationProvider.addLocation(
        SavedLocation(
          id: '1',
          orefName: 'תל אביב',
          customLabel: 'תל אביב',
          isPrimary: true,
        ),
      );

      // Simulate an error
      alertsProvider.onError('alerts', Exception('Network error'));

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show error indicator with warning icon
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      // Should show error message
      expect(find.text('שגיאה בטעינת התרעות'), findsOneWidget);
    });

    testWidgets('offline message shown when offline', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider(
        connectivity: MockConnectivity(ConnectivityResult.none),
      );
      await connectivityProvider.initialize();

      // Add a location
      await locationProvider.addLocation(
        SavedLocation(
          id: '1',
          orefName: 'תל אביב',
          customLabel: 'תל אביב',
          isPrimary: true,
        ),
      );

      // Provide some data (simulating cached data)
      alertsProvider.onAlertData([], []);

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show offline message instead of cached data
      expect(find.text('ממתין לחיבור לאינטרנט...'), findsOneWidget);
      // Should show signal_wifi_off icon
      expect(find.byIcon(Icons.signal_wifi_off), findsOneWidget);
    });

    testWidgets(
      'error indicator appears below status card when errorMessage set',
      (WidgetTester tester) async {
        final alertsProvider = AlertsProvider();
        final locationProvider = LocationProvider();
        final connectivityProvider = ConnectivityProvider(
          connectivity: MockConnectivity(ConnectivityResult.wifi),
        );
        await connectivityProvider.initialize();

        // Add a location
        await locationProvider.addLocation(
          SavedLocation(
            id: '1',
            orefName: 'תל אביב',
            customLabel: 'תל אביב',
            isPrimary: true,
          ),
        );

        // Simulate an error
        alertsProvider.onError('alerts', Exception('Network error'));

        await tester.pumpWidget(
          buildTestWidget(
            alertsProvider: alertsProvider,
            locationProvider: locationProvider,
            connectivityProvider: connectivityProvider,
          ),
        );
        await tester.pump();

        // Error indicator should be visible
        final errorRow = find.byType(Row);
        expect(errorRow, findsWidgets);

        // Verify the error text has correct styling (orange color)
        final errorText = tester.widget<Text>(find.text('שגיאה בטעינת התרעות'));
        expect(errorText.style?.color, isNotNull);
        // Should be orange-ish color
        final color = errorText.style!.color!;
        expect(color.red, greaterThan(200));
        expect(color.green, greaterThan(100));
        expect(color.blue, lessThan(100));
      },
    );

    testWidgets('loading state clears when data arrives', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider(
        connectivity: MockConnectivity(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      // Add a location
      await locationProvider.addLocation(
        SavedLocation(
          id: '1',
          orefName: 'תל אביב',
          customLabel: 'תל אביב',
          isPrimary: true,
        ),
      );

      // Start with loading state
      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show loading
      expect(find.text('טוען...'), findsOneWidget);

      // Simulate data arriving
      alertsProvider.onAlertData([], []);
      await tester.pump();

      // Loading should be gone, replaced with "no alerts" message
      expect(find.text('טוען...'), findsNothing);
      expect(find.text('אין התרעות באזורים שלך'), findsOneWidget);
    });

    testWidgets('offline state takes precedence over loading', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider(
        connectivity: MockConnectivity(ConnectivityResult.none),
      );
      await connectivityProvider.initialize();

      // Add a location
      await locationProvider.addLocation(
        SavedLocation(
          id: '1',
          orefName: 'תל אביב',
          customLabel: 'תל אביב',
          isPrimary: true,
        ),
      );

      // Start with loading state and offline
      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show offline message, not loading
      expect(find.text('ממתין לחיבור לאינטרנט...'), findsOneWidget);
      expect(find.text('טוען...'), findsNothing);
    });

    testWidgets('shows "מציג שעה אחרונה" indication in alert history section', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider(
        connectivity: MockConnectivity(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      // Add a location
      await locationProvider.addLocation(
        SavedLocation(
          id: '1',
          orefName: 'תל אביב',
          customLabel: 'תל אביב',
          isPrimary: true,
        ),
      );

      // Provide alert history data
      final historyAlert = Alert(
        id: 'hist_1',
        location: 'תל אביב',
        title: 'ירי רקטות וטילים',
        time: DateTime.now().subtract(const Duration(minutes: 30)),
        category: 1,
      );
      alertsProvider.onAlertData([], [historyAlert]);

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show the recent alerts header
      expect(find.text('התרעות אחרונות'), findsOneWidget);
      // Should show the time range indication (THIS IS THE MISSING FEATURE)
      expect(find.text('מציג שעה אחרונה'), findsOneWidget);
    });
  });
}

/// Mock Connectivity class for testing
class MockConnectivity implements Connectivity {
  final ConnectivityResult _initialResult;
  final StreamController<ConnectivityResult> _controller =
      StreamController<ConnectivityResult>.broadcast();

  MockConnectivity(this._initialResult);

  void simulateConnectivityChange(ConnectivityResult result) {
    _controller.add(result);
  }

  @override
  Future<ConnectivityResult> checkConnectivity() async => _initialResult;

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => _controller.stream;

  Future<String> getWifiBSSID() async => '';

  Future<String> getWifiIP() async => '';

  Future<String> getWifiName() async => '';
}
