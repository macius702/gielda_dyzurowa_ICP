import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';

abstract class Api {
  Future<Status> performRegistration(String username, String password,
      UserRole role, int? specialty, String? localization);

  Future<Status> performLogin(String username, String password);

  Future<Status> performLogout();

  Future<Status> deleteMe();

  Future<Status> publishDutySlot(
      {required Specialty specialty,
      required int priceFrom,
      required int priceTo,
      required String currency,
      required DateTime startDate,
      required TimeOfDay startTime,
      required DateTime endDate,
      required TimeOfDay endTime});

  Future<Status> deleteDutySlot(String id);

  Future<Status> assignDutySlot(String id);

  Future<List<DutySlotForDisplay>> getDutySlots();

  Future<Status> getUserData();

  Future<List<String>> getUsers();

  Future<List<String>> getSpecialties();
}
