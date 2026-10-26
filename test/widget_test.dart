import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/main.dart';

void main() {
  testWidgets('SpendWiseApp initial smoke test', (WidgetTester tester) async {
    // Build SpendWiseApp and trigger a frame.
    await tester.pumpWidget(const SpendWiseApp());
    await tester.pump();

    // Verify AppBar title
    expect(find.text('SpendWise'), findsOneWidget);

    // Verify NavigationBar destinations exist
    // Tab 0 (Home) is selected, so it displays home_rounded
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    // Tab 1 (Summary) is unselected, so it displays pie_chart_outline_rounded
    expect(find.byIcon(Icons.pie_chart_outline_rounded), findsOneWidget);

    // Verify navigation labels
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
  });
}
