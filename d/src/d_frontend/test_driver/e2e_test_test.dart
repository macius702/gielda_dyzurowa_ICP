import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:d_frontend/main.dart';
import 'package:d_frontend/counter.dart';
import 'package:d_frontend/counter_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("E2E test", (WidgetTester tester) async {
    // 1. Launch the app
    // Ensure flutter binding is initialized if you're going to use async code in main
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize the CounterStore
    final counter =
        await initCounter(); // Assuming initCounter is your async function that returns a Counter
    final counterStore = ViewModel(counter);
    counterStore.setupSpecialties();

    // Launch the app
    await tester.pumpWidget(
      Provider<ViewModel>.value(
        value: counterStore,
        child: MyApp(),
      ),
    );
    // 2. Click Register on Drawer
    await tester.tap(find.byIcon(Icons.menu)); // open the drawer
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register')); // tap on Register
    await tester.pumpAndSettle();

    // 3. Fill user (with H# where # is random), password
    final username = 'H${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(find.byKey(Key('usernameField')), username);
    await tester.enterText(find.byKey(Key('passwordField')), 'password');

    // 4. Click Select role
    await tester.tap(find.byKey(Key('roleDropdown')));

    // 5. Select hospital
    await tester.pumpAndSettle();
    await tester.tap(find.text('hospital').last);
    await tester.pumpAndSettle();

    // 6. Click register
    await tester.tap(find.byKey(Key('registerButton')));
    await tester.pumpAndSettle();

    // 7. Click on Drawer : Show users
    await tester.tap(find.byIcon(Icons.menu)); // open the drawer
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show users')); // tap on Show users
    await tester.pumpAndSettle();

    // 8. Check if user # is there
    expect(find.text(username), findsOneWidget);
  });
}
