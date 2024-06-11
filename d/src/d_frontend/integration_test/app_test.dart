import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:d_frontend/main.dart';
import 'package:d_frontend/counter.dart';
import 'package:d_frontend/counter_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  void runTest(WidgetTester tester, String role, String specialty,
      String localization) async {
    // 1. Launch the app
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize the CounterStore
    final counter = await initCounter();
    final counterStore = CounterStore(counter);
    await counterStore.setup_specialties();

    // Launch the app
    await tester.pumpWidget(
      Provider<CounterStore>.value(
        value: counterStore,
        child: MyApp(),
      ),
    );

    // 2. Click Register on Drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    // 3. Fill user (with H# where # is random), password
    final username =
        '${role[0].toUpperCase()}${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(find.byKey(Key('usernameField')), username);
    await tester.enterText(find.byKey(Key('passwordField')), 'password');

    // 4. Click Select role
    await tester.tap(find.byKey(Key('roleDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(role).last);
    await tester.pumpAndSettle();

    if (role == 'doctor') {
      // 5a Select specialty
      await tester.tap(find.byKey(Key('specialtyDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(specialty).last);
      await tester.pumpAndSettle();

      // 5b fill in localization
      await tester.enterText(
          find.byKey(Key('localizationField')), localization);
      await tester.pumpAndSettle();
    }

    // 6. Click register
    await tester.tap(find.byKey(Key('registerButton')));
    await tester.pumpAndSettle();

    // 7. Click on Drawer : Show users
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Users'));
    await tester.pumpAndSettle();

    final finder = find.text(username);

    await tester.scrollUntilVisible(finder, 300.0);
    await tester.pumpAndSettle();

    expect(finder, findsOneWidget);
  }

  testWidgets("E2E test for hospital role", (WidgetTester tester) async {
    runTest(tester, 'hospital', '', '');
  });

  testWidgets("E2E test for doctor role", (WidgetTester tester) async {
    runTest(tester, 'doctor', 'Angiologia', 'Warsaw');
  });
}
