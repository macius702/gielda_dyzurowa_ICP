import 'dart:io';
import 'package:d_frontend/constants.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:agent_dart/agent_dart.dart';
import 'dart:math';

import 'config.dart' show backendCanisterId, Mode, mode;
import 'print.dart';



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
    mtlk_print('canisterId: $canisterId');
    mtlk_print('url: $url');
  }
  // A future method because we need debug mode works for local developement
  Future<void> setAgent(
      {String? newCanisterId,
      ServiceClass? newIdl,
      String? newUrl,
      Identity? newIdentity,
      bool? debug}) async {

    mtlk_print('newCanisterId: $newCanisterId');
    mtlk_print('newIdl: $newIdl');
    mtlk_print('newUrl: $newUrl');
    mtlk_print('newIdentity: $newIdentity');
    mtlk_print('debug: $debug');
          
    try {
      // Your network request code here

      _agentFactory ??= await AgentFactory.createAgent(
          canisterId: newCanisterId ?? canisterId,
          url: newUrl ?? url,
          idl: newIdl ?? CounterMethod.idl,
          identity: newIdentity,
          debug: debug ?? true);

    mtlk_print("After createAgent");

    } catch (e) {
      if (e is SocketException) {
        mtlk_print('Cannot connect to the server. Please check your internet connection and server status.');
        mtlk_print('Exception: $e');

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
      mtlk_print("actor: $actor");
      mtlk_print("CounterMethod: ${CounterMethod}");
      mtlk_print("CounterMethod.getValue: ${CounterMethod.getValue}");

      ActorMethod? func = actor?.getFunc(CounterMethod.getValue);
      mtlk_print("getFunc result: $func");

      if (func != null) {
        var res = await func([]);
        mtlk_print("Function call result: $res");

        if (res != null) {
          return (res as BigInt).toInt();
        } else {
          mtlk_print("Function call returned null");
        }
      } else {
        mtlk_print("getFunc returned null");
      }

      throw "Cannot get count";
    } catch (e) {
      mtlk_print("Caught error: $e");
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
        mtlk_print("Function call result: ${res.first} ... ${res.last}");

        if (res != null) {
          // return (res as BigInt).toInt();
          mtlk_print("get_spectialties: ${res.first} ... ${res.last}");
          return (res as List<String>);
        } else {
          mtlk_print("Function call returned null");
        }
      } else {
        mtlk_print("getFunc returned null");
      }


      
   } catch (e) {
      mtlk_print("Caught error: $e");
      rethrow;
    }  
  
    return <String>[];



  }



    Future<Status> performRegistration(String username, String password, UserRole role, int? specialty, String? localization) async {
      try {
        Uri uri = _createUri('/auth/register');
        Map<String, String> headers = {
          'Content-Type': 'application/json; charset=UTF-8',
        };
        Map<String, dynamic> bodyMap = {
          'username': username,
          'password': password,
          'role': role.toString().split('.').last,
        };

        if (specialty != null) {
          bodyMap['specialty'] = specialty;
        }

        if (localization != null) {
          bodyMap['localization'] = localization;
        }

        String body = jsonEncode(bodyMap);
        mtlk_print('URL: $uri');
        mtlk_print('Headers: $headers');
        mtlk_print('Body: $body');

        final response = await http.post(
          uri,
          headers: headers,
          body: body,
        );

        if (response.statusCode == 200) {
          // If the server returns a 200 OK response,
          // then parse the JSON.
          return Response();
        } else {

          // print more on response
          mtlk_print("response: ${response.body}");
          mtlk_print("response: ${response.statusCode}");
          mtlk_print("response: ${response.headers}");


          // If the server returns an unexpected response,
          // then throw an exception.
          throw Exception('Failed to register user');
        }
      } catch (e) {
        mtlk_print("Caught error: $e");
        return Future.error(e);
      }
    }


  Future<List<String>> get_users() async {
    try {
      if (actor == null) {
        throw Exception("Actor is null");
      }

      ActorMethod? func = actor?.getFunc(CounterMethod.get_users);
      if (func != null) {
        var res = await func([]);
        mtlk_print("Function call result: $res");

        if (res != null) {
          return (res as List<String>);
        } else {
          mtlk_print("Function call returned null");
        }
      } else {
        mtlk_print("getFunc returned null");
      }

      throw Exception("Cannot get users");
    } catch (e) {
      mtlk_print("Caught error: $e");
      rethrow;
    }
  }

  // Save a value
  saveValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int randomNumber = Random().nextInt(100) + 1; // Generates a random integer from 1 to 100

    await prefs.setInt('myNumber', randomNumber);
    mtlk_print('Saved number: $randomNumber');
  }
  // Retrieve a value
  retrieveValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? myNumber = prefs.getInt('myNumber');
    mtlk_print('Retrieved number: $myNumber');
    return myNumber;
  }  
}




Future<Counter> initCounter({Identity? identity}) async {
  // initialize counter, change canister id here 
    //10.0.2.2  ? private const val BASE_URL = "http://10.0.2.2:4944"

  // String url;
  // var backendCanisterId;
  // if (kIsWeb) {
  //   mtlk_print("kIsWeb");
  //   url = 'http://localhost:4944'; 


  // } else {
  //     mtlk_print("not kIsWeb");

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


  mtlk_print("Before counter construction");
  var counter = Counter(canisterId: backendCanisterId, url: frontend_url);    // set agent when other paramater comes in like new Identity
  mtlk_print("After counter construction");
  await counter.setAgent(newIdentity: identity);
  mtlk_print("After counter setAgent");
  // await counter.get_specialties();
  // mtlk_print("After counter get_specialties");
  return counter;
}


Uri _createUri(String path) {
  return Uri.parse('$BASE_URL$path?canisterId=$BASE_CANISTER');
}