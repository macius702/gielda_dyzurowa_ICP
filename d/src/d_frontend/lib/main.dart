import 'package:d_frontend/duty_slots_screen.dart';
import 'package:d_frontend/get_user_data_screen.dart';
import 'package:d_frontend/publish_duty_slot_screen.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/login_screen.dart';
import 'package:d_frontend/register_screen.dart';
import 'package:d_frontend/show_usernames_screen.dart';

import 'package:d_frontend/counter.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure flutter binding is initialized if you're going to use async code in main

  final counter =
      await initCounter(); // Assuming createCounter is your async function that returns a Counter
  final counterStore = CounterStore(counter);
  counterStore.setup_specialties();

  runApp(
    Provider<CounterStore>.value(
      value: counterStore,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Matiki Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum Page {
  register,
  login,
  showUsers,
  nic,
  logout,
  getUserData,
  deleteMe,
  publishDutySlot,
  dutySlots,
  quitApp,
}

class _MyHomePageState extends State<MyHomePage> {
  Page _selectedPage = Page.nic;

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  void _onItemTapped(Page page) {
    setState(() {
      _selectedPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);

    final Map<Page, Widget> _widgetOptions = {
      Page.register: RegisterForm(
          key: const Key('registerForm'),
          onTap: () => _onItemTapped(Page.login)),
      Page.login: LoginForm(
          key: const Key('loginForm'), onTap: () => _onItemTapped(Page.nic)),
      Page.showUsers: ShowUsernamesBody(),
      Page.nic: const Text('NIC', style: optionStyle),
      Page.logout:
          const Text('Logout'), // This is a placeholder for the logout screen
      Page.getUserData: UserDataForm(),
      Page.deleteMe: const Text(
          'Delete Me'), // This is a placeholder for the delete me screen
      Page.publishDutySlot: PublishDutySlotScreen(),
      Page.dutySlots: DutySlotsBody(),
      Page.quitApp: const Text('Quit App'), // This is a placeholder
    };

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Observer(
            builder: (_) {
              print('AppBar counterStore.username: ${counterStore.username}');
              if (counterStore.displayed_message != null) {
                // If async_action_in_progress is true, show a SnackBar
                WidgetsBinding.instance!.addPostFrameCallback((_) {
                  print('Showing SnackBar: ${counterStore.displayed_message}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(counterStore.displayed_message!)),
                  );
                });
              } else {
                // If async_action_in_progress is false, hide the SnackBar
                WidgetsBinding.instance!.addPostFrameCallback((_) {
                  print('Hiding current SnackBar');
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                });
              }

              return Text(counterStore.username == null
                  ? 'Not logged in'
                  : 'Logged in as ${counterStore.username}');
            },
          ),
          leading: Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          })),
      body: Align(
          alignment: Alignment.topCenter, child: _widgetOptions[_selectedPage]),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: Text('Register'),
              selected: _selectedPage == Page.register,
              onTap: () {
                _onItemTapped(Page.register);
                Navigator.pop(context);
              },
            ),
            ListTile(
              key: Key('drawerLogin'),
              title: const Text('Login'),
              selected: _selectedPage == Page.login,
              onTap: () {
                _onItemTapped(Page.login);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Show Users'),
              selected: _selectedPage == Page.showUsers,
              onTap: () {
                _onItemTapped(Page.showUsers);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Nic'),
              selected: _selectedPage == Page.nic,
              onTap: () {
                _onItemTapped(Page.nic);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Logout'),
              selected: _selectedPage == Page.logout,
              onTap: () async {
                final counterStore =
                    Provider.of<CounterStore>(context, listen: false);

                Navigator.pop(context);
                _onItemTapped(Page.logout);

                await counterStore.performLogout();
              },
            ),
            ListTile(
              title: const Text('Get User Data'),
              selected: _selectedPage == Page.getUserData,
              onTap: () {
                _onItemTapped(Page.getUserData);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Delete Me'),
              selected: _selectedPage == Page.deleteMe,
              onTap: () async {
                final counterStore =
                    Provider.of<CounterStore>(context, listen: false);
                // Show a SnackBar with the 'Logging out...' message
                final username = counterStore.username;

                Navigator.pop(context);
                _onItemTapped(Page.deleteMe);

                Status value = await counterStore.deleteMe();
              },
            ),
            ListTile(
              title: const Text('Publish Duty Slot'),
              key: const Key('drawerPublishDutySlot'),
              selected: _selectedPage == Page.publishDutySlot,
              onTap: () {
                _onItemTapped(Page.publishDutySlot);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Duty Slots'),
              selected: _selectedPage == Page.dutySlots,
              onTap: () {
                _onItemTapped(Page.dutySlots);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Quit'),
              selected: _selectedPage == Page.quitApp,
              onTap: () {
                _onItemTapped(Page.quitApp);
                Navigator.pop(context);
                // perform quit app

                SystemNavigator.pop();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // You need to handle this
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
