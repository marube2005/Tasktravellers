import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/pages/passenger/passenger_profile_setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sharedPrefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(sharedPrefsChannel, (MethodCall methodCall) async {
    if (methodCall.method == 'getAll') {
      return <String, dynamic>{};
    }
    return null;
  });

  setUpAll(() async {
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey: 'test-anon-key',
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
    } catch (_) {
      // Supabase may already be initialized in other tests.
    }
  });

  testWidgets('passenger profile requires name', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2000));

    await tester.pumpWidget(
      const MaterialApp(
        home: PassengerProfileSetupScreen(),
      ),
    );

    final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
