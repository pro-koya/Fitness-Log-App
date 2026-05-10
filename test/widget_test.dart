import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('widget test harness builds a MaterialApp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Text('Liftly')));

    expect(find.text('Liftly'), findsOneWidget);
  });
}
