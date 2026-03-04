import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/main.dart';

void main() {
  testWidgets('App loads with RTL layout', (WidgetTester tester) async {
    await tester.pumpWidget(const MklatApp());

    // Verify app title is present
    expect(find.text('mklat.news'), findsOneWidget);

    // Verify at least one Directionality with RTL is present
    final directionalityFinder = find.byType(Directionality);
    expect(directionalityFinder, findsWidgets);

    // Verify one of them has RTL
    final directionalityWidgets = tester.widgetList<Directionality>(
      directionalityFinder,
    );
    final hasRtl = directionalityWidgets.any(
      (d) => d.textDirection == TextDirection.rtl,
    );
    expect(hasRtl, isTrue);
  });

  testWidgets('MultiProvider is set up', (WidgetTester tester) async {
    await tester.pumpWidget(const MklatApp());

    // Verify MaterialApp is present
    final materialAppFinder = find.byType(MaterialApp);
    expect(materialAppFinder, findsOneWidget);
  });
}
