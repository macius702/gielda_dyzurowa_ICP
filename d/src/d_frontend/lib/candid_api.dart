// ignore_for_file: unused_import, constant_identifier_names
// ignore_for_file: avoid_print
// ignore_for_file: non_constant_identifier_names

import 'package:d_frontend/api.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:d_frontend/ICP_connector.dart';

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
      final result =
          await callActorMethod<Map<String, dynamic>>(CounterMethod.perform_login, [username, password]);
      if (result != null) {
        if (result['Ok'] != null) {
          return Response('Login successful: ${result['ok']}');
        } else if (result['Err'] != null) {
          return Error('Login failed: ${result['err']}');
        }
      }
    } catch (e) {
      mtlk_print("Caught error: $e");
      return ExceptionalFailure('Cannot login user $username, Caught error: $e');
    }
    return ExceptionalFailure();
  }

  @override
  Future<Status> performLogout() async {
    // Dummy implementation
    return ExceptionalFailure();
  }

  @override
  Future<Status> deleteMe() async {
    // Dummy implementation
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
    // Dummy implementation
    return ExceptionalFailure();
  }

  @override
  Future<Status> deleteDutySlot(String id) async {
    // Dummy implementation
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
    // Dummy implementation
    return [];
  }

  @override
  Future<ResultWithStatus<UserData>> getUserData() async {
    // Dummy implementation
    UserData dummyData = UserData(id: 1, role: UserRole.doctor);
    Status status = Response('');
    return ResultWithStatus<UserData>(result: dummyData, status: status);
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

  static final UserRole = IDL.Variant({'hospital': IDL.Null, 'doctor': IDL.Null});
  static final Result = IDL.Variant({'Ok': IDL.Text, 'Err': IDL.Text});

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
    CounterMethod.perform_login: IDL.Func([IDL.Text, IDL.Text], [Result], []),
  });
}

/// ```dart
///  CanisterActor.getFunc(String)?.call(List<dynamic>) -> Future<dynamic>
/// ```
