import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/pages/login_screen.dart';
import 'package:frontend/pages/register_screen.dart';
import 'package:frontend/pages/payment_checkout_screen.dart';

void main() {
  testWidgets('login screen validates required fields', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('signup screen validates empty form', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    await tester.pumpWidget(
      const MaterialApp(
        home: SignUpScreen(),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pump();

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Minimum 6 characters'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('payment screen renders checkout UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PaymentScreen(),
      ),
    );

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);
    expect(find.text("You'll receive an M-Pesa prompt on your phone"), findsOneWidget);
    expect(find.text('Pay Ksh 1,650'), findsOneWidget);
  });
}
