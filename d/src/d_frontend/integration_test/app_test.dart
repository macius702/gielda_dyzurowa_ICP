import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:d_frontend/main.dart';
import 'package:d_frontend/counter.dart';
import 'package:d_frontend/counter_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  
  Future<void> runTest(WidgetTester tester, String role, String specialty,
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

    // 3. Fill user
    final username = role == 'doctor' ? 'D1' : 'H1';
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


    //  Login the user
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key('loginUsernameField')), username);
    await tester.enterText(find.byKey(Key('loginPasswordField')), 'password');
    await tester.tap(find.byKey(Key('loginButton')));
    await tester.pumpAndSettle();


   // wait TODO
    await Future.delayed(Duration(seconds: 6));
    await tester.pumpAndSettle();
    await Future.delayed(Duration(seconds: 6));



    // 8. Delete user
    // Click Delete Me on Drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Me'));
    await tester.pumpAndSettle();

    // 9. Check if user is deleted
    expect(find.text(username), findsNothing);
    




  }

    
  testWidgets("E2E test for hospital role", (WidgetTester tester) async {
    await runTest(tester, 'hospital', '', '');
  });

  testWidgets("E2E test for doctor role", (WidgetTester tester) async {
    await runTest(tester, 'doctor', 'Angiologia', 'Warsaw');
  });

testWidgets('Login and Logout Test', (WidgetTester tester) async {
    // 1. Launch the app
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize the CounterStore
    final counter = await initCounter();
    final counterStore = CounterStore(counter);
    await counterStore.setup_specialties();

    await tester.pumpAndSettle();

    // Launch the app
    await tester.pumpWidget(
      Provider<CounterStore>.value(
        value: counterStore,
        child: MyApp(),
      ),
    );

    // 2. Register a random hospital user named H...
    final username = 'H${DateTime.now().millisecondsSinceEpoch}';
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key('usernameField')), username);
    await tester.enterText(find.byKey(Key('passwordField')), 'a');
    await tester.tap(find.byKey(Key('roleDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('hospital').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('registerButton')));
    await tester.pumpAndSettle();

    // wait 
    await Future.delayed(Duration(seconds: 6));

    // check not logged in
    expect(find.text('Not logged in'), findsOneWidget);
    

    // 3. Login the user
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key('loginUsernameField')), username);
    await tester.enterText(find.byKey(Key('loginPasswordField')), 'a');
    await tester.tap(find.byKey(Key('loginButton')));
    await tester.pumpAndSettle();

    // wait 
    await Future.delayed(Duration(seconds: 6));
    await tester.pumpAndSettle();
    await Future.delayed(Duration(seconds: 6));

    // 4. Check if the appbar text changed from Not logged in to logged as H...
    expect(find.text('Logged in as $username'), findsOneWidget);

    // 5. Logout
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    // wait 
    await Future.delayed(Duration(seconds: 6));
    await tester.pumpAndSettle();
    await Future.delayed(Duration(seconds: 6));

    // 6. Check that appbar text is not logged in
    expect(find.text('Not logged in'), findsOneWidget);
  });

}
