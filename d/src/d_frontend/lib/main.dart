import 'package:agent_dart/agent_dart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/drawer.dart';
import 'package:d_frontend/login_screen.dart';
import 'package:d_frontend/register_screen.dart';


import 'counter.dart';



 void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure flutter binding is initialized if you're going to use async code in main

  final counter = await initCounter(); // Assuming createCounter is your async function that returns a Counter
  final counterStore = CounterStore(counter);

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

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(title),
      ),
      drawer: CommonDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'The canister counter is now:',
            ),
            Text(
              'NIC',
              style: Theme.of(context).textTheme.headlineMedium
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
