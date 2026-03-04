// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  testWidgets('Saral Sewa app loads login page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(clerkService: ClerkService()));

    // Verify that the login page loads with expected elements.
    expect(find.text('Saral Sewa'), findsOneWidget);
    expect(find.text('Email / इमेल'), findsOneWidget);
    expect(find.text('Password / पासवर्ड'), findsOneWidget);
  });
}
