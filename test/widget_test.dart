import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jerseyapp/main.dart';

void main() {
  testWidgets('App loads HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const JerseyDripApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome 👋'), findsOneWidget);
  });

  testWidgets('Firestore button exists', (WidgetTester tester) async {
    await tester.pumpWidget(const JerseyDripApp());
    await tester.pumpAndSettle();

    expect(find.text('Send Test Data to Firestore'), findsOneWidget);
  });

  testWidgets('Logout button exists', (WidgetTester tester) async {
    await tester.pumpWidget(const JerseyDripApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
