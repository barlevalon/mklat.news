import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mklat/presentation/app_shell.dart';
import 'package:mklat/presentation/screens/status_screen.dart';
import 'package:mklat/presentation/widgets/page_indicator.dart';
import 'package:mklat/presentation/providers/alerts_provider.dart';
import 'package:mklat/presentation/providers/location_provider.dart';
import 'package:mklat/presentation/providers/news_provider.dart';
import 'package:mklat/presentation/providers/connectivity_provider.dart';

void main() {
  group('AppShell', () {
    Widget buildTestWidget() {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final newsProvider = NewsProvider();
      final connectivityProvider = ConnectivityProvider();

      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: alertsProvider),
              ChangeNotifierProvider.value(value: locationProvider),
              ChangeNotifierProvider.value(value: newsProvider),
              ChangeNotifierProvider.value(value: connectivityProvider),
            ],
            child: const AppShell(),
          ),
        ),
      );
    }

    testWidgets('renders both screens in PageView', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      // Should find the PageView
      expect(find.byType(PageView), findsOneWidget);

      // Should find StatusScreen
      expect(find.byType(StatusScreen), findsOneWidget);

      // Should find PageIndicator
      expect(find.byType(PageIndicator), findsOneWidget);
    });

    testWidgets('page indicator shows correct active page initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      // Page indicator should be present with 2 dots
      final pageIndicator = tester.widget<PageIndicator>(
        find.byType(PageIndicator),
      );
      expect(pageIndicator.pageCount, equals(2));
      expect(
        pageIndicator.currentIndex,
        equals(0),
      ); // First page (Status) is active
    });

    testWidgets('can swipe between pages', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initially on status screen
      expect(find.byType(StatusScreen), findsOneWidget);

      // Swipe left - should not throw
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Swipe right - should not throw
      await tester.drag(find.byType(PageView), const Offset(300, 0));
      await tester.pumpAndSettle();

      // PageView should still exist
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('has SafeArea and Scaffold', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Should have SafeArea
      expect(find.byType(SafeArea), findsOneWidget);

      // Should have Scaffold
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
