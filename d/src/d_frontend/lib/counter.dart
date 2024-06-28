import 'dart:io';
import 'package:d_frontend/ICP_connector.dart';
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

class Counter extends ICPconnector implements Api {
  ///
  /// Counter class, with AgentFactory within
  ///
  Counter({required String canisterId, required String url}) : super(canisterId: canisterId, url: url);

  ///

  @override
  Future<List<String>> getSpecialties() async {
    Uri uri = _createUri('/specialties');
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    mtlk_print('URL: $uri');
    mtlk_print('Headers: $headers');

    final response = await http.get(
      uri,
      headers: headers,
    );

    mtlk_print('getSpecialties: response.statusCode: ${response.statusCode}');
    mtlk_print('getSpecialties: response.body: ${response.body}');
    mtlk_print('getSpecialties: response.headers: ${response.headers}');
    mtlk_print('getSpecialties: response.request: ${response.request}');
    mtlk_print('getSpecialties: response: $response');

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response,
      // then parse the JSON.
      List<dynamic> responseBody = jsonDecode(response.body);
      print("getSpecialties responseBody: $responseBody");
      List<String> specialties = responseBody.map((item) => item['name'] as String).toList();
      print("getSpecialties specialties: $specialties");

      return specialties;
    } else {
      // If the server returns an unexpected response,
      // then throw an exception.
      throw Exception('Failed to get specialties');
    }
  }

  @override
  Future<Status> performRegistration(
      String username, String password, UserRole role, int? specialty, String? localization) async {
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
        return Error('Failed to register user with status code ${response.statusCode} and message: $message ');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return ExceptionalFailure('Exceptional failure occurred during registration. with error: $e');
    }
  }

  @override
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

  @override
  Future<Status> performLogout() async {
    try {
      Uri uri = _createUri('/auth/logout');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception('Failed to logout user: no cookies in SharedPreferences');
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

  @override
  Future<Status> deleteMe() async {
    try {
      Uri uri = _createUri('/auth/delete_user');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception('Failed to delete user: no cookies in SharedPreferences');
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

  @override
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
        throw Exception('Failed to delete user: no cookies in SharedPreferences');
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
        'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        'endDate': endDate.toIso8601String().split('T')[0],
        'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
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

  @override
  Future<Status> deleteDutySlot(String id) async {
    try {
      Uri uri = _createUri('/duty/remove');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception('Failed to delete user: no cookies in SharedPreferences');
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

  Future<Status> _performDutySlotAction(String endpoint, String id, String errorMessage) async {
    try {
      Uri uri = _createUri(endpoint);

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception(errorMessage);
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

        throw Exception(errorMessage);
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return Future.error(e);
    }
  }

  @override
  Future<Status> assignDutySlot(String id) async {
    return _performDutySlotAction('/assign-duty-slot', id, 'Failed to accept duty slot');
  }

  @override
  Future<Status> giveConsent(String id) async {
    return _performDutySlotAction('/give-consent', id, 'Failed to give consent');
  }

  @override
  Future<Status> revokeAssignment(String id) async {
    return _performDutySlotAction('/revoke-assignment', id, 'Failed to revoke assignment');
  }

  @override
  Future<List<DutySlotForDisplay>> getDutySlots() async {
    try {
      Uri uri = _createUri('/duty/slots/json');

      // take cookies form SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        throw Exception('Failed to get duty slots: no cookies in SharedPreferences');
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

  @override
  Future<ResultWithStatus<UserData>> getUserData() async {
    try {
      Uri uri = _createUri('/user/data');

      Map<String, String> headers;
      if (!kIsWeb) {
        // take cookies form SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? cookies = prefs.getString('cookies');
        if (cookies == null) {
          throw Exception('Failed to get user data: no cookies in SharedPreferences');
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

        final userData = UserData.fromJson(jsonDecode(response.body));
        return ResultWithStatus<UserData>(result: userData, status: Response());
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

  @override
  Future<List<String>> getUsers() async {
    Uri uri = _createUri('/usernames');
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    mtlk_print('URL: $uri');
    mtlk_print('Headers: $headers');

    final response = await http.get(
      uri,
      headers: headers,
    );

    mtlk_print('getUsers: response.statusCode: ${response.statusCode}');
    mtlk_print('getUsers: response.body: ${response.body}');
    mtlk_print('getUsers: response.headers: ${response.headers}');
    mtlk_print('getUsers: response.request: ${response.request}');
    mtlk_print('getUsers: response: $response');

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response,
      // then parse the JSON.

      Map<String, dynamic> responseBody = jsonDecode(response.body);
      List<dynamic> jsonList = responseBody['usernames'];
      List<String> usernames = [];
      for (var e in jsonList) {
        print("getUsers e: $e");
        usernames.add(e);
      }
      return usernames;
    } else {
      // If the server returns an unexpected response,
      // then throw an exception.
      throw Exception('Failed to get usernames');
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

  static Future<Counter> init({Identity? identity}) async {
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
        url: get_frontend_url()); // set agent when other paramater comes in like new Identity
    mtlk_print("After counter construction");
    await counter.setAgent(newIdentity: identity);
    mtlk_print("After counter setAgent");
    // await counter.get_specialties();
    // mtlk_print("After counter get_specialties");
    return counter;
  }
}

String frontend_url = '';

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
