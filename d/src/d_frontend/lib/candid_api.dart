// ignore_for_file: unused_import, constant_identifier_names
// ignore_for_file: avoid_print
// ignore_for_file: non_constant_identifier_names

import 'package:d_frontend/api.dart';
import 'package:d_frontend/types.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:d_frontend/ICP_connector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'print.dart';

class CandidApi implements Api {
  final ICPconnector icpConnector;

  CandidApi(this.icpConnector);

  get actor => icpConnector.actor;

  @override
  Future<Status> performRegistration(
      String username, String password, UserRole role, int? specialty, String? localization) async {
    try {
      int? result = await callActorMethod<int>(
        CounterMethod.perform_registration,
        [
          username,
          password,
          convertUserRoleToMap(role),
          convertNullableToList(specialty),
          convertNullableToList(localization)
        ],
      );
      if (result == 0 || result == null) {
        return Error('Cannot register user $username');
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return ExceptionalFailure('Cannot register user $username, Caught error: $e');
    }
    return Response('User $username registered');
  }

  @override
  Future<Status> performLogin(String username, String password) async {
    try {
      print("performLogin: Attempting to login user: $username");
      final result = await callActorMethod<Map<String, dynamic>>(CounterMethod.perform_login, [username, password]);
      print("performLogin: Received result: $result");
      if (result != null) {
        if (result['Ok'] != null) {
          final rawCookie = result['Ok'];
          print("performLogin: Received cookie: $rawCookie");

          // Save the cookies into SharedPreferences
          try {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('cookies', rawCookie);
            print("performLogin: Saved cookie to SharedPreferences");
          } catch (e) {
            print("performLogin: Failed to save cookie to SharedPreferences: $e");
            return ExceptionalFailure('Failed to login user: cannot save cookies');
          }

          return Response('Login successful: ${result['ok']}');
        } else if (result['Err'] != null) {
          print("performLogin: Login failed: ${result['err']}");
          return Error('Login failed: ${result['err']}');
        }
      }
    } catch (e) {
      print("performLogin: Caught error: $e");
      return ExceptionalFailure('Cannot login user $username, Caught error: $e');
    }
    return ExceptionalFailure();
  }

  @override
  Future<Status> performLogout() async {
    //first call       callActorMethod

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        return Error('Cannot delete user: no cookies');
      }

      final result = await callActorMethod<Map<String, dynamic>>(CounterMethod.perform_logout, [cookies]);

      if (result != null) {
        if (result.containsKey('Ok')) {
          await prefs.remove('cookies');

          print("performLogout: Removed cookies from SharedPreferences");
          return Response('Logout successful');
        } else if (result['Err'] != null) {
          return Error('Cannot delete user: ${result['err']}');
        }
      }
    } catch (e) {
      print("performLogout: Failed to remove cookies from SharedPreferences: $e");
      return ExceptionalFailure('Failed to logout user: cannot remove cookies');
    }
    return ExceptionalFailure('Failed to logout user: cannot remove cookies 2');
  }

  @override
  Future<Status> deleteMe() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        return Error('Cannot delete user: no cookies');
      }

      final result = await callActorMethod<Map<String, dynamic>>(CounterMethod.delete_user, [cookies]);
      if (result != null) {
        if (result.containsKey('Ok')) {
          return Response('User deleted');
        } else if (result['Err'] != null) {
          return Error('Cannot delete user: ${result['err']}');
        }
      }
    } catch (e) {
      print("deleteMe: Caught error: $e");
      return ExceptionalFailure('Cannot delete user, Caught error: $e');
    }
    return ExceptionalFailure();
  }

  @override
  Future<Status> publishDutySlot({
    required Specialty specialty,
    required int priceFrom,
    required int priceTo,
    required String currency,
    required DateTime startDate,
    required TimeOfDay startTime,
    required DateTime endDate,
    required TimeOfDay endTime,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        return Error('Cannot delete user: no cookies');
      }

      // sum start date and time
      startDate = DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute);
      endDate = DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute);

      final result = await callActorMethod<Map<String, dynamic>>(
        CounterMethod.publish_duty_slot,
        [
          cookies,
          int.parse(specialty.id),
          convertNullableToList(priceFrom),
          convertNullableToList(priceTo),
          convertNullableToList(currency),
          startDate.millisecondsSinceEpoch ~/ 1000,
          endDate.millisecondsSinceEpoch ~/ 1000,
        ],
      );
      if (result != null) {
        if (result['Ok'] != null) {
          print("Duty slot published");
          return Response('Duty slot published');
        } else if (result['Err'] != null) {
          return Error('Cannot publish duty slot: ${result['err']}');
        }
      }
    } catch (e) {
      print("publishDutySlot: Caught error: $e");
      return ExceptionalFailure('Cannot publish duty slot, Caught error: $e');
    }
    return ExceptionalFailure();
  }

  @override
  Future<Status> deleteDutySlot(String id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        return Error('Cannot delete duty slot: no cookies');
      }

      final result =
          await callActorMethod<Map<String, dynamic>>(CounterMethod.delete_duty_slot, [cookies, int.parse(id)]);
      print('Result: $result');
      if (result != null) {
        if (result.containsKey('Ok')) {
          print("Duty slot deleted");
          return Response('Duty slot deleted');
        } else if (result['Err'] != null) {
          print('Error deleting duty slot: ${result['Err']}');
          return Error('Cannot delete duty slot: ${result['Err']}');
        }
      }
    } catch (e) {
      print("deleteDutySlot: Caught error: $e");
      return ExceptionalFailure('Cannot delete duty slot, Caught error: $e');
    }
    print("deleteDutySlot: Exceptional failure");
    return ExceptionalFailure();
  }

  @override
  Future<Status> assignDutySlot(String id) async {
    // Dummy implementation
    return ExceptionalFailure();
  }

  @override
  Future<Status> giveConsent(String id) async {
    // Dummy implementation
    return ExceptionalFailure();
  }

  @override
  Future<Status> revokeAssignment(String id) async {
    // Dummy implementation
    return ExceptionalFailure();
  }

  @override
  Future<List<DutySlotForDisplay>> getDutySlots() async {
    try {
      print("Before callActorMethod"); // print the result
      final result = await callActorMethod(CounterMethod.get_all_duty_slots_for_display);
      print("Result: $result"); // print the result
      if (result != null) {
        List<DutySlotForDisplay> dutySlots = [];
        for (var slot in result) {
          print('Printing values');
          String id = slot['_id'];
          print('id: $id');

          Map<String, dynamic> statusMap = slot['status'];
          String status = statusMap.keys.first;
          print('status: $status');

          Map<String, dynamic> hospitalMap = Map<String, dynamic>.from(slot['hospitalId']);
          Hospital hospital = Hospital(
            id: hospitalMap['_id'],
            username: hospitalMap['username'],
            password: hospitalMap['password'],
            role: hospitalMap['role'],
            profileVisible: hospitalMap['profileVisible'],
          );
          print('hospital: $hospital');

          Doctor? assignedDoctorId = slot['assigned_doctor_id'];
          print('TODO - check null the read Map assignedDoctor: $assignedDoctorId');

          List<dynamic> currencyList = slot['currency'];
          String currency = currencyList[0];
          print('currency: $currency');

          String endDateTime = slot['endDateTime'];
          print('endDateTime: $endDateTime');

          Decimal priceToDecimal = getPrice(slot['priceTo']);
          print('priceTo: $priceToDecimal');

          Map<String, dynamic> requiredSpecialtyMap = Map<String, dynamic>.from(slot['requiredSpecialty']);
          Specialty requiredSpecialty = Specialty(
            id: requiredSpecialtyMap['_id'],
            name: requiredSpecialtyMap['name'],
          );

          print('requiredSpecialty: $requiredSpecialty');

          String startDateTime = slot['startDateTime'];
          print('startDateTime: $startDateTime');

          Decimal priceFromDecimal = getPrice(slot['priceFrom']);
          print('priceFrom: $priceFromDecimal');

          dutySlots.add(DutySlotForDisplay(
            id: id,
            status: DutyStatusHelper.fromString(status),
            hospitalId: hospital,
            assignedDoctorId: assignedDoctorId,
            currency: currency,
            endDateTime: endDateTime,
            priceTo: priceToDecimal,
            requiredSpecialty: requiredSpecialty,
            startDateTime: startDateTime,
            priceFrom: priceFromDecimal,
          ));
        }
        return dutySlots;
      }
    } catch (e) {
      print("getDutySlots: Caught error: $e");
    }
    return [];
  }

  @override
  Future<ResultWithStatus<UserData>> getUserData() async {
    UserData dummyData = UserData(id: 1, role: UserRole.doctor);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookies = prefs.getString('cookies');
      if (cookies == null) {
        return ResultWithStatus<UserData>(result: dummyData, status: Error('Cannot get user data: no cookies'));
      }

      mtlk_print("getUserData: Attempting to get user data with cookies: $cookies");

      final result = await callActorMethod<Map<String, dynamic>>(CounterMethod.get_user_data, [cookies]);
      mtlk_print("getUserData: Received result: $result");
      if (result != null) {
        if (result['Ok'] != null) {
          final id = result['Ok'][0];
          final role = UserRoleFromString(result['Ok'][1]);
          mtlk_print("getUserData: User data received: id=$id, role=$role");
          return ResultWithStatus<UserData>(
              result: UserData(id: id, role: role), status: Response('User data received'));
        } else if (result['Err'] != null) {
          return ResultWithStatus<UserData>(result: dummyData, status: Error('Cannot get user data: ${result['err']}'));
        }
      }
    } catch (e) {
      print("getUserData: Caught error: $e");
      return ResultWithStatus<UserData>(
          result: dummyData, status: ExceptionalFailure('Cannot get user data, Caught error: $e'));
    }
    return ResultWithStatus<UserData>(result: dummyData, status: Error('Cannot get user data'));
  }

  Future<T?> callActorMethod<T>(String method, [List<dynamic> params = const []]) async {
    if (actor == null) {
      throw Exception("Actor is null");
    }

    ActorMethod? func = actor?.getFunc(method);
    if (func != null) {
      var res = await func(params);
      mtlk_print("Function call result: $res");
      return res as T?;
    } else {
      mtlk_print("getFunc returned null");
    }

    throw Exception("Cannot call method: $method");
  }

  @override
  @override
  Future<List<String>> getUsers() async {
    try {
      return await callActorMethod<List<String>>(CounterMethod.get_all_usernames) ?? [];
    } catch (e) {
      mtlk_print("Caught error: $e");
      rethrow;
    }
  }

  @override
  Future<List<String>> getSpecialties() async {
    try {
      return await callActorMethod<List<String>>(CounterMethod.get_specialties) ?? [];
    } catch (e) {
      mtlk_print("Caught error: $e");
      rethrow;
    }
  }
}

/// motoko/rust function of the Counter canister
/// see ./dfx/local/counter.did
abstract class CounterMethod {
  /// use staic const as method name
  static const increment = "increment";
  static const getValue = "getValue";
  static const get_specialties = "get_specialties";
  static const get_all_usernames = "get_all_usernames";
  static const perform_registration = "perform_registration";
  static const perform_login = "perform_login";
  static const perform_logout = "perform_logout";
  static const delete_user = "delete_user";
  static const get_user_data = "get_user_data";
  static const publish_duty_slot = "publish_duty_slot";
  static const get_all_duty_slots_for_display = "get_all_duty_slots_for_display";
  static const delete_duty_slot = "delete_duty_slot";

  static final UserRole = IDL.Variant({'hospital': IDL.Null, 'doctor': IDL.Null});

  static final Doctor = IDL.Record({
    '_id': IDL.Text,
    'localization': IDL.Text,
    'username': IDL.Text,
    'password': IDL.Text,
    'role': IDL.Text,
    'specialty': IDL.Text,
    'profileVisible': IDL.Bool,
  });
  static final Hospital = IDL.Record({
    '_id': IDL.Text,
    'username': IDL.Text,
    'password': IDL.Text,
    'role': IDL.Text,
    'profileVisible': IDL.Bool,
  });
  static final Specialty = IDL.Record({'_id': IDL.Text, 'name': IDL.Text});

  static final DutyStatus = IDL.Variant({
    'pending': IDL.Null,
    'open': IDL.Null,
    'filled': IDL.Null,
  });

  static final DutyVacancyForDisplay = IDL.Record({
    '_id': IDL.Text,
    'status': DutyStatus,
    'assignedDoctorId': IDL.Opt(Doctor),
    'priceTo': IDL.Opt(IDL.Float64),
    'hospitalId': Hospital,
    'endDateTime': IDL.Text,
    'requiredSpecialty': Specialty,
    'currency': IDL.Opt(IDL.Text),
    'priceFrom': IDL.Opt(IDL.Float64),
    'startDateTime': IDL.Text,
  });

  static final Result = IDL.Variant({'Ok': IDL.Null, 'Err': IDL.Text});
  static final Result_1 = IDL.Variant({
    'Ok': IDL.Tuple([IDL.Nat32, IDL.Text]),
    'Err': IDL.Text
  });
  static final Result_2 = IDL.Variant({'Ok': IDL.Text, 'Err': IDL.Text});

  static final Result_3 = IDL.Variant({'Ok': IDL.Nat32, 'Err': IDL.Text});

  /// you can copy/paste from .dfx/local/canisters/counter/counter.did.js
  static final ServiceClass idl = IDL.Service({
    CounterMethod.getValue: IDL.Func([], [IDL.Nat], ['query']),
    CounterMethod.increment: IDL.Func([], [], []),
    CounterMethod.get_specialties: IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    CounterMethod.get_all_usernames: IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    CounterMethod.perform_registration: IDL.Func(
      [IDL.Text, IDL.Text, UserRole, IDL.Opt(IDL.Int32), IDL.Opt(IDL.Text)],
      [IDL.Nat32],
      [],
    ),
    //returns type
    CounterMethod.perform_login: IDL.Func([IDL.Text, IDL.Text], [Result_2], []),
    CounterMethod.perform_logout: IDL.Func([IDL.Text], [Result], ['query']),
    CounterMethod.delete_user: IDL.Func([IDL.Text], [Result], []),
    CounterMethod.get_user_data: IDL.Func([IDL.Text], [Result_1], ['query']),
    CounterMethod.publish_duty_slot: IDL.Func(
      [
        IDL.Text,
        IDL.Nat16,
        IDL.Opt(IDL.Float64),
        IDL.Opt(IDL.Float64),
        IDL.Opt(IDL.Text),
        IDL.Int64,
        IDL.Int64,
      ],
      [Result_3],
      [],
    ),
    CounterMethod.get_all_duty_slots_for_display: IDL.Func(
      [],
      [IDL.Vec(DutyVacancyForDisplay)],
      ['query'],
    ),
    CounterMethod.delete_duty_slot: IDL.Func([IDL.Text, IDL.Nat32], [Result], []),
  });
}

Decimal getPrice(dynamic priceTo1) {
  final priceTo2 = priceTo1 ?? [];
  final priceTo = priceTo2.isEmpty ? 0 : priceTo2[0];
  return Decimal.parse(priceTo.toString());
}

/// ```dart
///  CanisterActor.getFunc(String)?.call(List<dynamic>) -> Future<dynamic>
/// ```
