import 'dart:io';
import 'package:d_frontend/api.dart';
import 'package:d_frontend/constants.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
class Counter implements Api {
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
        mtlk_print(
            'Cannot connect to the server. Please check your internet connection and server status.');
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

  // todo - implement with Restful API
  Future<List<String>> getSpecialties() async {
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

  Future<Status> performRegistration(String username, String password,
      UserRole role, int? specialty, String? localization) async {
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
        bodyMap['specialty'] = specialty.toString();
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
        return Response('Registration successful.');
      } else {
        // print more on response
        mtlk_print("response: ${response.body}");
        mtlk_print("response: ${response.statusCode}");
        mtlk_print("response: ${response.headers}");

        // Assuming response is of type http.Response
        var responseBody = jsonDecode(response.body);
        var message = responseBody['message'];
        return Error(
            'Failed to register user with status code ${response.statusCode} and message: $message ');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return ExceptionalFailure(
          'Exceptional failure occurred during registration. with error: $e');
    }
  }

  Future<Status> performLogin(String username, String password) async {
    try {
      Uri uri = _createUri('/auth/login');
      Map<String, String> headers = {
        'Content-Type': 'application/json; charset=UTF-8',
      };
      Map<String, dynamic> bodyMap = {
        'username': username,
        'password': password,
      };

      String body = jsonEncode(bodyMap);
      mtlk_print('URL: $uri');
      mtlk_print('Headers: $headers');
      mtlk_print('Body: $body');

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      mtlk_print('response.statusCode: ${response.statusCode}');
      mtlk_print('response.body: ${response.body}');
      mtlk_print('response.headers: ${response.headers}');
      mtlk_print('response.request: ${response.request}');
      mtlk_print('response: $response');

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response,

        if (!kIsWeb) {
          //handle cookies
          String? rawCookie = response.headers['set-cookie'];
          if (rawCookie == null) {
            throw Exception('Failed to login user: no cookie in response');
          }

          // Save the cookies into SharedPreferences
          try {
            // Save the cookies into SharedPreferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('cookies', rawCookie);
          } catch (e) {
            throw Exception('Failed to login user: cannot save cookies');
          }
        }

        return Response();
      } else {
        // If the server returns an unexpected response,
        // then throw an exception.
        throw Exception('Failed to login user');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return Future.error(e);
    }
  }

  Future<Status> performLogout() async {
    try {
      Uri uri = _createUri('/auth/logout');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception(
            'Failed to logout user: no cookies in SharedPreferences');
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'cookie': cookies,
      };

      mtlk_print('URL: $uri');
      mtlk_print('Headers: $headers');

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response,
        //remove froim SharedPreferences cookies
        await prefs.remove('cookies');

        return Response();
      } else {
        // If the server returns an unexpected response,
        // then throw an exception.
        mtlk_print('Error response.statusCode: ${response.statusCode}');
        mtlk_print('Error response.body: ${response.body}');
        mtlk_print('Error response.headers: ${response.headers}');
        mtlk_print('Error response.request: ${response.request}');
        mtlk_print('Error response: $response');

        throw Exception('Failed to logout user');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return Future.error(e);
    }
  }

  Future<Status> deleteMe() async {
    try {
      Uri uri = _createUri('/auth/delete_user');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception(
            'Failed to delete user: no cookies in SharedPreferences');
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'cookie': cookies,
      };

      mtlk_print('URL: $uri');
      mtlk_print('Headers: $headers');

      final response = await http.post(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Response();
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return Future.error(e);
    }
  }

  Future<Status> publishDutySlot(
      {required Specialty specialty,
      required int priceFrom,
      required int priceTo,
      required String currency,
      required DateTime startDate,
      required TimeOfDay startTime,
      required DateTime endDate,
      required TimeOfDay endTime}) async {
    try {
      Uri uri = _createUri('/duty/publish');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception(
            'Failed to delete user: no cookies in SharedPreferences');
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'cookie': cookies,
      };
      Map<String, dynamic> bodyMap = {
        'requiredSpecialty': specialty,
        'priceFrom': priceFrom,
        'priceTo': priceTo,
        'currency': currency,
        'startDate': startDate.toIso8601String().split('T')[0],
        'startTime':
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        'endDate': endDate.toIso8601String().split('T')[0],
        'endTime':
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      };

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
        // If the server returns an unexpected response,
        // then throw an exception.
        mtlk_print('Error response.statusCode: ${response.statusCode}');
        mtlk_print('Error response.body: ${response.body}');
        mtlk_print('Error response.headers: ${response.headers}');
        mtlk_print('Error response.request: ${response.request}');
        mtlk_print('Error response: $response');

        throw Exception('Failed to publish duty slot');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return Future.error(e);
    }
  }

  Future<Status> deleteDutySlot(String id) async {
    try {
      Uri uri = _createUri('/duty/remove');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception(
            'Failed to delete user: no cookies in SharedPreferences');
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'cookie': cookies,
      };
      Map<String, dynamic> bodyMap = {
        '_id': id,
      };

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
        // If the server returns an unexpected response,
        // then throw an exception.
        mtlk_print('Error response.statusCode: ${response.statusCode}');
        mtlk_print('Error response.body: ${response.body}');
        mtlk_print('Error response.headers: ${response.headers}');
        mtlk_print('Error response.request: ${response.request}');
        mtlk_print('Error response: $response');

        throw Exception('Failed to remove duty slot');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return Future.error(e);
    }
  }

  //Status s = await counter.assign_duty_slot(id);
  @override
  Future<Status> assignDutySlot(String id) async {
    try {
      Uri uri = _createUri('/assign-duty-slot');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception(
            'Failed to accept duty slot: no cookies in SharedPreferences');
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'cookie': cookies,
      };
      Map<String, dynamic> bodyMap = {
        '_id': id,
      };

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
        // If the server returns an unexpected response,
        // then throw an exception.
        mtlk_print('Error response.statusCode: ${response.statusCode}');
        mtlk_print('Error response.body: ${response.body}');
        mtlk_print('Error response.headers: ${response.headers}');
        mtlk_print('Error response.request: ${response.request}');
        mtlk_print('Error response: $response');

        throw Exception('Failed to accept duty slot');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return Future.error(e);
    }
  }

  @override
  Future<Status> giveConsent(String id) async {
    try {
      Uri uri = _createUri('/give-consent');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception(
            'Failed to give consent: no cookies in SharedPreferences');
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'cookie': cookies,
      };
      Map<String, dynamic> bodyMap = {
        '_id': id,
      };

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
        // If the server returns an unexpected response,
        // then throw an exception.
        mtlk_print('Print response.statusCode: ${response.statusCode}');
        mtlk_print('Print response.body: ${response.body}');
        mtlk_print('Print response.headers: ${response.headers}');
        mtlk_print('Print response.request: ${response.request}');
        mtlk_print('Print response: $response');

        throw Exception('Failed to give consent');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return Future.error(e);
    }
  }

  @override
  Future<Status> revokeAssignment(String id) async {
    try {
      Uri uri = _createUri('/revoke-assignment');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception(
            'Failed to revoke assignment: no cookies in SharedPreferences');
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'cookie': cookies,
      };
      Map<String, dynamic> bodyMap = {
        '_id': id,
      };

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
        // If the server returns an unexpected response,
        // then throw an exception.
        mtlk_print('Print response.statusCode: ${response.statusCode}');
        mtlk_print('Print response.body: ${response.body}');
        mtlk_print('Print response.headers: ${response.headers}');
        mtlk_print('Print response.request: ${response.request}');
        mtlk_print('Print response: $response');

        throw Exception('Failed to revoke assignment');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return Future.error(e);
    }
  }

  Future<List<DutySlotForDisplay>> getDutySlots() async {
    try {
      Uri uri = _createUri('/duty/slots/json');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception(
            'Failed to get duty slots: no cookies in SharedPreferences');
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'cookie': cookies,
      };

      mtlk_print('URL: $uri');
      mtlk_print('Headers: $headers');

      final response = await http.get(
        uri,
        headers: headers,
      );

      mtlk_print('getDutySlots: response.statusCode: ${response.statusCode}');
      mtlk_print('getDutySlots: response.body: ${response.body}');
      mtlk_print('getDutySlots: response.headers: ${response.headers}');
      mtlk_print('getDutySlots: response.request: ${response.request}');
      mtlk_print('getDutySlots: response: $response');

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response,
        // then parse the JSON.
        //decode json into List<DutySlotForDisplay
        List<dynamic> jsonList = jsonDecode(response.body);
        List<DutySlotForDisplay> dutySlots = [];
        for (var e in jsonList) {
          print("getDutySlots e: $e");
          dutySlots.add(DutySlotForDisplay.fromJson(e));
        }
        return dutySlots;
      } else {
        // If the server returns an unexpected response,
        // then throw an exception.
        throw Exception('Failed to get duty slots');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return Future.error(e);
    }
  }

  Future<Status> getUserData() async {
    try {
      Uri uri = _createUri('/user/data');

      Map<String, String> headers;
      if (!kIsWeb) {
        // take cookies form SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? cookies = prefs.getString('cookies');
        if (cookies == null) {
          throw Exception(
              'Failed to get user data: no cookies in SharedPreferences');
        }
        headers = {
          'Content-Type': 'application/json; charset=UTF-8',
          'cookie': cookies,
        };
      } else {
        headers = {
          'Content-Type': 'application/json; charset=UTF-8',
        };
      }

      mtlk_print('URL: $uri');
      mtlk_print('Headers: $headers');

      final response = await http.get(
        uri,
        headers: headers,
      );

      mtlk_print('Error response.statusCode: ${response.statusCode}');
      mtlk_print('Error response.body: ${response.body}');
      mtlk_print('Error response.headers: ${response.headers}');
      mtlk_print('Error response.request: ${response.request}');
      mtlk_print('Error response: $response');

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response,
        // then parse the JSON.

        GetUserDataResponse userData =
            GetUserDataResponse.fromJson(jsonDecode(response.body));
        return userData;
      } else {
        // If the server returns an unexpected response,
        // then throw an exception.
        throw Exception('Failed to get user data');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return Future.error(e);
    }
  }

  Future<List<String>> getUsers() async {
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
    int randomNumber =
        Random().nextInt(100) + 1; // Generates a random integer from 1 to 100

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

String frontend_url = '';

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

  mtlk_print("Before counter construction");
  var counter = Counter(
      canisterId: backendCanisterId,
      url:
          get_frontend_url()); // set agent when other paramater comes in like new Identity
  mtlk_print("After counter construction");
  await counter.setAgent(newIdentity: identity);
  mtlk_print("After counter setAgent");
  // await counter.get_specialties();
  // mtlk_print("After counter get_specialties");
  return counter;
}

String get_frontend_url() {
  return mode == Mode.playground
      ? 'https://icp-api.io'
      : mode == Mode.local
          ? kIsWeb
              ? 'http://127.0.0.1:4944'
              : 'http://10.0.2.2:4944' // for android emulator
          : 'todo'; // for Mode.network
}

Uri _createUri(String path) {
  return Uri.parse('${get_frontend_url()}$path?canisterId=$backendCanisterId');
}
