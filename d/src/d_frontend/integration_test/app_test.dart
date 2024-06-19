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
    await initializeApp(tester);

    final username = role == 'doctor' ? 'D1' : 'H1';
    await register(tester, username, role,
        specialty: specialty, localization: localization);
    await login(tester, username);
    await deleteUser(tester, username);
  }

  testWidgets("E2E test for hospital role", (WidgetTester tester) async {
    await runTest(tester, 'hospital', '', '');
  }, skip: false);

  testWidgets("E2E test for doctor role", (WidgetTester tester) async {
    await runTest(tester, 'doctor', 'Angiologia', 'Warsaw');
  }, skip: false);

  testWidgets('Login and Logout Test', (WidgetTester tester) async {
    await initializeApp(tester);

    const username = 'H2';
    await register(tester, username, 'hospital');
    await login(tester, username);
    await logout(tester);
    await login(tester, username);
    await deleteUser(tester, username);
  }, skip: false);

  testWidgets('Publish duty slot, view duty slots and delete duty slot',
      (WidgetTester tester) async {
    await initializeApp(tester);

    // H1 user adds his entry
    const hospital1 = 'H1';
    await register(tester, hospital1, 'hospital');
    await login(tester, hospital1);
    await publishDutySlot(
        tester, hospital1, 'Chirurgia naczyniowa', '100', '200');
    await logout(tester);

    // H2 user adds his entry
    const hospital2 = 'H2';
    await register(tester, hospital2, 'hospital');
    await login(tester, hospital2);
    await publishDutySlot(tester, hospital2, 'Angiologia', '150', '250');

    // check both entries are present
    expect(find.text(hospital1), findsOneWidget);
    expect(find.text('Angiologia'), findsOneWidget);
    expect(find.text(hospital2), findsOneWidget);
    expect(find.text('Chirurgia naczyniowa'), findsOneWidget);

    // Delete user H2 and his entries
    await deleteUser(tester, hospital2);

    // open Duty Slots Page
    await login(tester, hospital1);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duty Slots'));
    await tester.pumpAndSettle();
    await waitForText('Hospital', tester, '44');

    // Check that only H1 entries remain
    expect(find.text(hospital1), findsOneWidget);
    expect(find.text('Chirurgia naczyniowa'), findsOneWidget);
    expect(find.text(hospital2), findsNothing);
    expect(find.text('Angiologia'), findsNothing);

    // **************** For delete duty slot ***********
    // Add a new entry
    await publishDutySlot(
        tester, hospital1, "Balneologia i medycyna fizykalna", '500', '600');

    // check both entries are present
    expect(find.text('Chirurgia naczyniowa'), findsOneWidget);
    expect(find.text('Balneologia i medycyna fizykalna'), findsOneWidget);

    // Delete the entry by popping up the Action menu
    // and then clicking on the delete button
    // which will delete the entry
    // and then check if the entry is deleted
    // by checking if the entry is not present
    // in the list of entries
// Find the PopupMenuButton for the duty slot you want to delete

    //iterate over table to  find Balneologia i medycyna fizykalna
    // in this way we can find the row and then the popup menu button

    // for all rows in the table
    // find the text of the cell
    // if the text is 'Balneologia i medycyna fizykalna'
    // then find the popup menu button in the row
    // tap on the popup menu button
    // find the delete menu item
    // tap on the delete menu item
    // check that the entry is no longer present

    // Find the cell with the text 'Balneologia i medycyna fizykalna'
    // find DataTable
    final dataTableFinder = find.byType(DataTable);
    print('dataTableFinder : $dataTableFinder');
    final dataTable = dataTableFinder.evaluate().single.widget as DataTable;





    dataTable.columns.forEach((column) {
      print('element: $column');
      print(column.label.toString());
      if(column.label.toString().contains('Actions')) {
        print('Actions column found');
      }
    });
    print('dataTable: $dataTable');
    print('dataRows: ${dataTable.rows}');
    print('dataRows.length: ${dataTable.rows.length}');
    for (var i = 0; i < dataTable.rows.length; i++) {
      final dataRow = dataTable.rows[i];
      print('dataRow: $dataRow');
      print('dataRow.cells: ${dataRow.cells}');
      print('dataRow.cells.length: ${dataRow.cells.length}');
      for (var j = 0; j < dataRow.cells.length; j++) {
        final dataCell = dataRow.cells[j];
        print('dataCell: $dataCell');
        print('dataCell.child: ${dataCell.child}');
        print('dataCell.child.runtimeType: ${dataCell.child.runtimeType}');
        print('dataCell.child.toString(): ${dataCell.child.toString()}');
        if (dataCell.child
            .toString()
            .contains('Balneologia i medycyna fizykalna')) {
          print('Found Balneologia i medycyna fizykalna');
          final columnToClickIndex = dataTable.columns.indexWhere((column) {
              return column.label.toString().contains('Actions');
            });
          print('columnToClickIndex: $columnToClickIndex');
          final toClickDataCell = dataRow.cells[columnToClickIndex];
          print('toClickDataCell: $toClickDataCell');
          final toClickDatacellFinder = find.byWidget(toClickDataCell.child);
          print('toClickDatacellFinder: $toClickDatacellFinder');
          await tester.scrollUntilVisible(toClickDatacellFinder, 300.0);
          await tester.tap(toClickDatacellFinder);
          await tester.pumpAndSettle();
          // now tap on the delete menu item

          final deleteButtonFinder = find.byKey(Key('deleteMenuItem'));
          await tester.tap(deleteButtonFinder);
          await tester.pumpAndSettle();
          await waitForRowsCountChangeOfDataTable(tester, dataTableFinder);
          break;
        }
      }
    }

      

    expect(find.text('Balneologia i medycyna fizykalna'), findsNothing);

    // Delete user H1 as well along with his entries
    await deleteUser(tester, hospital1);

    // We have to be logged in as someone
    const hospital3 = 'H3';
    await register(tester, hospital3, 'hospital');
    await login(tester, hospital3);

    // to check that no previous entries remain
    expect(find.text(hospital1), findsNothing);
    expect(find.text('Angiologia'), findsNothing);
    expect(find.text(hospital2), findsNothing);
    expect(find.text('Chirurgia naczyniowa'), findsNothing);

    await deleteUser(tester, hospital3);
  });
}

// from https://github.com/flutter/flutter/issues/88765#issuecomment-1253639461
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = tester.binding.clock.now().add(timeout);

  do {
    if (tester.binding.clock.now().isAfter(end)) {
      throw Exception('Timed out waiting for $finder');
    }

    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 100));
  } while (finder.evaluate().isEmpty);
}

Future<void> waitForRowsCountChangeOfDataTable(WidgetTester tester, Finder dataTableFinder)
async {
  final end = tester.binding.clock.now().add(const Duration(seconds: 20));
  
  DataTable dataTable = dataTableFinder.evaluate().single.widget as DataTable;
  final originalRowsCount = dataTable.rows.length;
  print('Waiting for rows count to change from $originalRowsCount');

  do {
    if (tester.binding.clock.now().isAfter(end)) {
      throw Exception('Timed out waiting for rows count to change');
    }
    dataTable = dataTableFinder.evaluate().single.widget as DataTable;
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 100));
  } while (dataTable.rows.length == originalRowsCount);

  print('Rows count changed from $originalRowsCount to ${dataTable.rows.length}');
}


Future<void> waitForText(
    String message, WidgetTester tester, String label,
    {Duration timeout = const Duration(seconds: 20),}) async {
  print('$label Waiting for text: $message');
  final snackBarFinder = find.text(message);
  await waitFor(tester, snackBarFinder, timeout: timeout);
  print('$label Found text: $message');
}

Future<void> waitForTextAndType(
    String message, Type type, WidgetTester tester, String label) async {
  print('$label Waiting for text: $message and type: $type');

  final finder = find.ancestor(
    of: find.text(message),
    matching: find.byType(type),
  );

  await waitFor(tester, finder);
  print('$label Found widget with text: $message and type: $type');
}

Future<CounterStore> initializeApp(WidgetTester tester) async {
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

  return counterStore;
}

Future<void> register(WidgetTester tester, String username, String role,
    {String? specialty, String? localization}) async {
  // 2. Click Register on Drawer
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Register'));
  await tester.pumpAndSettle();

  // 3. Fill user
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
    await tester.tap(find.text(specialty!).last);
    await tester.pumpAndSettle();

    // 5b fill in localization
    await tester.enterText(find.byKey(Key('localizationField')), localization!);
    await tester.pumpAndSettle();
  }

  // 6. Click register
  await tester.tap(find.byKey(Key('registerButton')));
  await tester.pumpAndSettle();

  await waitForText('Login', tester, '1');

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

Future<void> login(WidgetTester tester, String username) async {
  // Login the user
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(Key('loginUsernameField')), username);
  await tester.enterText(find.byKey(Key('loginPasswordField')), 'password');
  await tester.tap(find.byKey(Key('loginButton')));
  await tester.pumpAndSettle();

  // Wait until the NIC page is loaded
  await waitForText('NIC', tester, '11');

  expect(find.text('Logged in as $username'), findsOneWidget);
}

Future<void> deleteUser(WidgetTester tester, String username) async {
  expect(find.text('Logged in as $username'), findsOneWidget);
  // Delete the user
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete Me'));
  await tester.pumpAndSettle();
  await waitForText('Delete Me', tester, '3');

  // Check if user is deleted
  expect(find.text('Not logged in'), findsOneWidget);
}

Future<void> logout(WidgetTester tester) async {
  // Logout the user
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Logout'));
  await tester.pumpAndSettle();

  // Check if user is logged out
  expect(find.text('Not logged in'), findsOneWidget);
}

Future<void> publishDutySlot(WidgetTester tester, String username,
    String specialty, String priceFrom, String priceTo) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Publish Duty Slot'));
  await tester.pumpAndSettle();

  await waitForTextAndType('Publish Duty Slot', ElevatedButton, tester, '1');

  final dropdownFinder =
      find.byKey(const Key('specialtyDropdownInPublishDutySlot'));
  await tester.tap(dropdownFinder);
  await tester.pumpAndSettle();
  final specialtyFinder = find.text(specialty);
  await tester.tap(specialtyFinder);
  await tester.pumpAndSettle();

  final priceFromFieldFinder = find.widgetWithText(TextFormField, 'Price From');
  await tester.enterText(priceFromFieldFinder, priceFrom);

  final priceToFieldFinder = find.widgetWithText(TextFormField, 'Price To');
  await tester.enterText(priceToFieldFinder, priceTo);

  await tester.pumpAndSettle();

  await tester.tap(find.byKey(Key('publishDutySlotButton')));

  await waitForText('Hospital', tester, '4');

  expect(find.text(username), findsAny);
  expect(find.text(specialty), findsOneWidget);
}

void printAncestors(Element element) {
  element.visitAncestorElements((ancestorElement) {
    print('ancestorElement: $ancestorElement');
    print(
        'ancestorElement.widget.runtimeType: ${ancestorElement.widget.runtimeType}');
    print('ancestorElement.widget: ${ancestorElement.widget}');
    print(ancestorElement.widget);
    return true; // Continue walking up the tree.
  });
}

// void printAncestors(Finder finder, {int level = 0}) {
//   final element = finder.evaluate().single;
//   print('element: $element');
//   print('${' ' * level}${element.widget.runtimeType}');
//   final parentElement = element.findAncestorWidgetOfExactType<Widget>();
//   print('parentElement: $parentElement');

//   if (parentElement == null) {
//     return;
//   }

//   final parentFinder = find.byWidget(parentElement);
//   print('parentFinder: $parentFinder');
//   print('${' ' * level}${parentElement.runtimeType}');

//   printAncestors(parentFinder, level: level + 1);
// }
