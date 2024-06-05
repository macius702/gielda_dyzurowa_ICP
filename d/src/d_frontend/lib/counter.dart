import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agent_dart/agent_dart.dart';
import 'dart:math';

import 'config.dart' show backendCanisterId, Mode, mode;



/// motoko/rust function of the Counter canister
/// see ./dfx/local/counter.did
abstract class CounterMethod {
  /// use staic const as method name
  static const increment = "increment";
  static const getValue = "getValue";
  static const get_specialties = "get_specialties";
  static const get_users = "get_all_usernames";


  /// you can copy/paste from .dfx/local/canisters/counter/counter.did.js
  static final ServiceClass idl = IDL.Service({
    CounterMethod.getValue: IDL.Func([], [IDL.Nat], ['query']),
    CounterMethod.increment: IDL.Func([], [], []),
    CounterMethod.get_specialties: IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    CounterMethod.get_users: IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
  });
}

///
/// Counter class, with AgentFactory within
class Counter {
  /// AgentFactory is a factory method that creates Actor automatically.
  /// Save your strength, just use this template
  AgentFactory? _agentFactory;

  /// CanisterCator is the actor that make all the request to Smartcontract.
  CanisterActor? get actor => _agentFactory?.actor;
  final String canisterId;
  final String url;

  Counter({required this.canisterId, required this.url}) {
    print('canisterId: $canisterId');
    print('url: $url');
  }
  // A future method because we need debug mode works for local developement
  Future<void> setAgent(
      {String? newCanisterId,
      ServiceClass? newIdl,
      String? newUrl,
      Identity? newIdentity,
      bool? debug}) async {

    print('newCanisterId: $newCanisterId');
    print('newIdl: $newIdl');
    print('newUrl: $newUrl');
    print('newIdentity: $newIdentity');
    print('debug: $debug');
          
    try {
      // Your network request code here

      _agentFactory ??= await AgentFactory.createAgent(
          canisterId: newCanisterId ?? canisterId,
          url: newUrl ?? url,
          idl: newIdl ?? CounterMethod.idl,
          identity: newIdentity,
          debug: debug ?? true);

    print("After createAgent");

    } catch (e) {
      if (e is SocketException) {
        print('Cannot connect to the server. Please check your internet connection and server status.');
        print('Exception: $e');

      } else {
        // Re-throw the exception for further handling
        rethrow;
      }
    }        
  }    

  /// Call canister methods like this signature
  /// ```dart
  ///  CanisterActor.getFunc(String)?.call(List<dynamic>) -> Future<dynamic>
  /// ```

  Future<void> increment() async {
    try {
      await actor?.getFunc(CounterMethod.increment)?.call([]);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getValue() async {
    try {
      print("actor: $actor");
      print("CounterMethod: ${CounterMethod}");
      print("CounterMethod.getValue: ${CounterMethod.getValue}");

      ActorMethod? func = actor?.getFunc(CounterMethod.getValue);
      print("getFunc result: $func");

      if (func != null) {
        var res = await func([]);
        print("Function call result: $res");

        if (res != null) {
          return (res as BigInt).toInt();
        } else {
          print("Function call returned null");
        }
      } else {
        print("getFunc returned null");
      }

      throw "Cannot get count";
    } catch (e) {
      print("Caught error: $e");
      rethrow;
    }
  }

  Future<List<String>> get_specialties() async {
    try {

      await saveValue();
      await retrieveValue();
      ActorMethod? func = actor?.getFunc(CounterMethod.get_specialties);
      if (func != null) {
        var res = await func([]);
        print("Function call result: ${res.first} ... ${res.last}");

        if (res != null) {
          // return (res as BigInt).toInt();
          print("get_spectialties: ${res.first} ... ${res.last}");
          return (res as List<String>);
        } else {
          print("Function call returned null");
        }
      } else {
        print("getFunc returned null");
      }


      
   } catch (e) {
      print("Caught error: $e");
      rethrow;
    }  
  
    return <String>[];



  }

  Future<List<String>> get_users() async {
    try {
      if (actor == null) {
        throw Exception("Actor is null");
      }

      ActorMethod? func = actor?.getFunc(CounterMethod.get_users);
      if (func != null) {
        var res = await func([]);
        print("Function call result: $res");

        if (res != null) {
          return (res as List<String>);
        } else {
          print("Function call returned null");
        }
      } else {
        print("getFunc returned null");
      }

      throw Exception("Cannot get users");
    } catch (e) {
      print("Caught error: $e");
      rethrow;
    }
  }

  // Save a value
  saveValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int randomNumber = Random().nextInt(100) + 1; // Generates a random integer from 1 to 100

    await prefs.setInt('myNumber', randomNumber);
    print('Saved number: $randomNumber');
  }
  // Retrieve a value
  retrieveValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? myNumber = prefs.getInt('myNumber');
    print('Retrieved number: $myNumber');
    return myNumber;
  }  
}




Future<Counter> initCounter({Identity? identity}) async {
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


  print("Before counter construction");
  var counter = Counter(canisterId: backendCanisterId, url: frontend_url);    // set agent when other paramater comes in like new Identity
  print("After counter construction");
  await counter.setAgent(newIdentity: identity);
  print("After counter setAgent");
  await counter.get_specialties();
  print("After counter get_specialties");
  return counter;
}