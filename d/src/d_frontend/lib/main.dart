import 'package:agent_dart/agent_dart.dart';
import 'package:d_frontend/drawer.dart';
import 'package:flutter/material.dart';
import 'package:d_frontend/login_screen.dart';
import 'package:d_frontend/register_screen.dart';


import 'counter.dart';



 void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
   MyApp({super.key});

  final Future<void> _initCounterFuture = initCounter();


  // This widget is the root of your application.
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
