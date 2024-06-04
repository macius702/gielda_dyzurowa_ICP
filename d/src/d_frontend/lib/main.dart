import 'package:agent_dart/agent_dart.dart';
import 'package:d_frontend/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'config.dart' show backendCanisterId, Mode, mode;
import 'package:d_frontend/login_screen.dart';
import 'package:d_frontend/register_screen.dart';


import 'counter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _loading = false;

   // for the return nvalue of : CounterMethod.get_specialties: IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
   // ineed a variable to hold the specialties
  List<String> _specialties = [];

  // setup state class variable;
  Counter? counter;

  @override
  void initState() {
    initCounter();
    super.initState();
  }

  Future<void> initCounter({Identity? identity}) async {
    // initialize counter, change canister id here 
     //10.0.2.2  ? private const val BASE_URL = "http://10.0.2.2:4944"

    // String url;
    // var backendCanisterId;
    // if (kIsWeb) {
    //   print("kIsWeb");
    //   url = 'http://localhost:4944'; 
  

    // } else {
    //     print("not kIsWeb");

    //   // url = 'http://10.0.2.2:4944'; // default to localhost for other platforms

    //   // url = 'https://mdwwn-niaaa-aaaab-qabta-cai.ic0.app:4944';

    // }


    // url = 'https://z7chj-7qaaa-aaaab-qacbq-cai.icp0.io:4944';
    // backendCanisterId = 'ocpcu-jaaaa-aaaab-qab6q-cai';


  var frontend_url;

  if (mode == Mode.playground) {
    frontend_url = 'https://icp-api.io';
  } else if (mode == Mode.local) {
    if (kIsWeb  ) {
      frontend_url = 'http://localhost:4944';
    } else {  // for android emulator
      frontend_url = 'http://10.0.2.2:4944';  
    }
  } else if (mode == Mode.network) {
  }



    counter = Counter(canisterId: backendCanisterId, url: frontend_url);    // set agent when other paramater comes in like new Identity
    await counter?.setAgent(newIdentity: identity);
    await get_specialties();
  }

  // get value from canister
  Future<void> getValue() async {
    var counterValue = await counter?.getValue();
    setState(() {
      _counter = counterValue ?? _counter;
      _loading = false;
    });
  }

  // increment counter
  Future<void> _incrementCounter() async {
    setState(() {
      _loading = true;
    });
    await counter?.increment();
    await getValue();
  }

  Future<void> get_specialties() async {
    var specialties = await counter?.get_specialties();
    print('Returned Specialties: $specialties');
    setState(() {
      _specialties = specialties ?? _specialties;
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue ,
        title: Text(widget.title),
      ),
      drawer: CommonDrawer(),
      body: Center(
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'The canister counter is now:',
            ),
            Text(
//              '$_specialties',
              'NIC',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
