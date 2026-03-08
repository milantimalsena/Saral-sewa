// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  testWidgets('Saral Sewa app loads login page', (WidgetTester tester) async {
    // Avoid plugin / storage dependencies in widget tests.
    final clerkService = _FakeClerkService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(clerkService: clerkService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Should land on LoginPage when unauthenticated.
    expect(find.byType(LoginPage), findsOneWidget);

    // Verify that the login page loads with expected elements.
    expect(find.text('Welcome to Saral Sewa'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}

class _FakeClerkService extends ClerkService {
  @override
  Future<bool> isLoggedIn() async => false;
}
