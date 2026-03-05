import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mklat/presentation/screens/news_screen.dart';
import 'package:mklat/presentation/providers/news_provider.dart';
import 'package:mklat/presentation/providers/connectivity_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  group('NewsScreen', () {
    Widget buildTestWidget({
      required NewsProvider newsProvider,
      required ConnectivityProvider connectivityProvider,
    }) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: newsProvider),
              ChangeNotifierProvider.value(value: connectivityProvider),
            ],
            child: const NewsScreen(),
          ),
        ),
      );
    }

    testWidgets('shows offline message when offline and empty', (
      WidgetTester tester,
    ) async {
      final controller = StreamController<ConnectivityResult>();
      final newsProvider = NewsProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        controller.stream,
      );

      // Set loading to false to show empty state
      newsProvider.onNewsData([]);

      // Start offline
      controller.add(ConnectivityResult.none);
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          newsProvider: newsProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show offline message
      expect(find.text('אין חיבור לאינטרנט'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Should NOT show "אין מבזקים חדשים"
      expect(find.text('אין מבזקים חדשים'), findsNothing);

      await controller.close();
    });

    testWidgets('shows "אין מבזקים חדשים" when online and empty', (
      WidgetTester tester,
    ) async {
      final controller = StreamController<ConnectivityResult>();
      final newsProvider = NewsProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        controller.stream,
      );

      // Set loading to false to show empty state
      newsProvider.onNewsData([]);

      // Start online
      controller.add(ConnectivityResult.wifi);
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          newsProvider: newsProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show "אין מבזקים חדשים"
      expect(find.text('אין מבזקים חדשים'), findsOneWidget);

      // Should NOT show offline message
      expect(find.text('אין חיבור לאינטרנט'), findsNothing);

      await controller.close();
    });

    testWidgets('shows header "מבזקי חדשות"', (WidgetTester tester) async {
      final controller = StreamController<ConnectivityResult>();
      final newsProvider = NewsProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        controller.stream,
      );

      // Set loading to false
      newsProvider.onNewsData([]);

      controller.add(ConnectivityResult.wifi);
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          newsProvider: newsProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show header
      expect(find.text('מבזקי חדשות'), findsOneWidget);

      await controller.close();
    });

    testWidgets('switches between offline and online messages', (
      WidgetTester tester,
    ) async {
      final controller = StreamController<ConnectivityResult>();
      final newsProvider = NewsProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        controller.stream,
      );

      // Set loading to false
      newsProvider.onNewsData([]);

      // Start online
      controller.add(ConnectivityResult.wifi);
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          newsProvider: newsProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show "אין מבזקים חדשים"
      expect(find.text('אין מבזקים חדשים'), findsOneWidget);
      expect(find.text('אין חיבור לאינטרנט'), findsNothing);

      // Go offline
      controller.add(ConnectivityResult.none);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show offline message
      expect(find.text('אין חיבור לאינטרנט'), findsOneWidget);
      expect(find.text('אין מבזקים חדשים'), findsNothing);

      // Go back online
      controller.add(ConnectivityResult.wifi);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show "אין מבזקים חדשים" again
      expect(find.text('אין מבזקים חדשים'), findsOneWidget);
      expect(find.text('אין חיבור לאינטרנט'), findsNothing);

      await controller.close();
    });
  });
}
