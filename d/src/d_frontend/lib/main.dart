import 'package:agent_dart/agent_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/drawer.dart';
import 'package:d_frontend/login_screen.dart';
import 'package:d_frontend/register_screen.dart';
import 'package:d_frontend/show_usernames_screen.dart';

import 'counter.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 3;

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);

    final List<Widget> _widgetOptions = <Widget>[
      RegisterForm(
        key: Key('registerForm'),
        onTap: () => _onItemTapped(2),
      ),
      InkWell(
        onTap: () {
          _onItemTapped(3);
        },
        child: Text(
          'Index 1: Business',
        ),
      ),
      ShowUsernamesBody(),
      Text(
        'NIC',
        style: optionStyle,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text(widget.title),
          leading: Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          })),
      body: Center(
        child: _widgetOptions[_selectedIndex],
      ),
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
              title: const Text('Register'),
              selected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Login'),
              selected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Show Users'),
              selected: _selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Nic'),
              selected: _selectedIndex == 3,
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
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
