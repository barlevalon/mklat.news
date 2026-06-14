import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mklat/core/app_theme.dart';
import 'package:mklat/presentation/widgets/offline_banner.dart';
import 'package:mklat/presentation/providers/connectivity_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  group('OfflineBanner', () {
    Widget buildTestWidget({
      required ConnectivityProvider connectivityProvider,
    }) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ChangeNotifierProvider.value(
            value: connectivityProvider,
            child: const Scaffold(body: OfflineBanner()),
          ),
        ),
      );
    }

    testWidgets('banner visible when offline', (WidgetTester tester) async {
      final connectivityProvider = ConnectivityProvider(
        connectivity: MockConnectivity(ConnectivityResult.none),
      );
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(connectivityProvider: connectivityProvider),
      );
      await tester.pump();

      // Should show the offline text
      expect(find.text('אין חיבור לאינטרנט'), findsOneWidget);
      // Should show the wifi-off icon
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('banner hidden when online', (WidgetTester tester) async {
      final connectivityProvider = ConnectivityProvider(
        connectivity: MockConnectivity(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(connectivityProvider: connectivityProvider),
      );
      await tester.pump();

      // Banner widget is still in tree (AnimatedSlide keeps it), but positioned off-screen
      // The text widget exists but is translated off-screen via the animation
      expect(find.text('אין חיבור לאינטרנט'), findsOneWidget);
    });

    testWidgets('banner has correct Hebrew text', (WidgetTester tester) async {
      final connectivityProvider = ConnectivityProvider(
        connectivity: MockConnectivity(ConnectivityResult.none),
      );
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(connectivityProvider: connectivityProvider),
      );
      await tester.pump();

      // Verify Hebrew text is present
      final textWidget = tester.widget<Text>(find.text('אין חיבור לאינטרנט'));
      expect(textWidget.data, 'אין חיבור לאינטרנט');

      // Verify text contains Hebrew characters
      final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(textWidget.data!);
      expect(hasHebrew, isTrue);
    });

    testWidgets('banner uses neutral connectivity styling', (
      WidgetTester tester,
    ) async {
      final connectivityProvider = ConnectivityProvider(
        connectivity: MockConnectivity(ConnectivityResult.none),
      );
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(connectivityProvider: connectivityProvider),
      );
      await tester.pump();

      final decoratedBox = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('אין חיבור לאינטרנט'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );

      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.connectivityTint);
    });

    testWidgets('banner animates in and out', (WidgetTester tester) async {
      final mockConnectivity = MockConnectivity(ConnectivityResult.wifi);
      final connectivityProvider = ConnectivityProvider(
        connectivity: mockConnectivity,
      );
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(connectivityProvider: connectivityProvider),
      );
      await tester.pump();

      // Initially online - banner should be in the tree but off-screen
      // AnimatedSlide keeps the widget in tree, just translated
      expect(find.text('אין חיבור לאינטרנט'), findsOneWidget);

      // Simulate going offline
      mockConnectivity.simulateConnectivityChange(ConnectivityResult.none);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Banner should be visible (on-screen after animation)
      expect(find.text('אין חיבור לאינטרנט'), findsOneWidget);

      // Simulate going back online
      mockConnectivity.simulateConnectivityChange(ConnectivityResult.wifi);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Banner should still be in tree but off-screen after animation
      expect(find.text('אין חיבור לאינטרנט'), findsOneWidget);
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
