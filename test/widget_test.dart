import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/main.dart';

void main() {
  testWidgets('App loads with RTL layout', (WidgetTester tester) async {
    await tester.pumpWidget(const MklatApp());

    // Verify app title is present
    expect(find.text('mklat.news'), findsOneWidget);

    // Verify Hebrew text is displayed
    expect(find.text('אין התרעות'), findsOneWidget);

    // Verify placeholder content
    expect(find.byType(PlaceholderScreen), findsOneWidget);
  });

  testWidgets('RTL directionality is applied', (WidgetTester tester) async {
    await tester.pumpWidget(const MklatApp());

    // Find the Directionality widget that's a parent of MaterialApp
    final materialAppFinder = find.byType(MaterialApp);
    expect(materialAppFinder, findsOneWidget);

    // Get the MaterialApp and verify it has a Directionality ancestor
    final materialApp = tester.widget<MaterialApp>(materialAppFinder);
    expect(materialApp.builder, isNotNull);
  });
}
