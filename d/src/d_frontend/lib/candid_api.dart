import 'package:d_frontend/api.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:d_frontend/ICP_connector.dart';

import 'print.dart';

class CandidApi extends ICPconnector implements Api {
  @override
  Future<Status> performRegistration(
      String username, String password, UserRole role, int? specialty, String? localization) async {
    // Dummy implementation
    return ExceptionalFailure();
  }

  @override
  Future<Status> performLogin(String username, String password) async {
    // Dummy implementation
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
  Future<Status> getUserData() async {
    // Dummy implementation
    return ExceptionalFailure();
  }

  @override
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

  @override
  Future<List<String>> getSpecialties() async {
    try {
      // await saveValue();
      // await retrieveValue();
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
}

Future<CandidApi> initCandidApi() async {
  return Future.value(CandidApi());
}

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

/// ```dart
///  CanisterActor.getFunc(String)?.call(List<dynamic>) -> Future<dynamic>
/// ```
