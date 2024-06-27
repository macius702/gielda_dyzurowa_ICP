import 'dart:convert';

import 'package:d_frontend/api.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'counter_store.g.dart';

// ignore: library_private_types_in_public_api
class ViewModel = _ViewModel with _$ViewModel;

abstract class _ViewModel with Store {
  final Api theApi;

  _ViewModel(this.theApi);

  @observable
  String? username;

  @observable
  UserRole? role;

  @observable
  int? userId;

  @action
  void setUserIdRole(UserData userData) {
    userId = userData.id;
    role = userData.role;
  }

  @action
  void setUsername(String? value) {
    if (value == null) {
      userId = null;
      role = null;
    }
    username = value;
  }

  @observable
  String? displayedMessage;

  @action
  void setDisplayedMessage(String? value) {
    displayedMessage = value;
  }

  @observable
  ObservableList<String> usernames = ObservableList<String>();

  @observable
  ObservableList<String> specialties = ObservableList<String>();

  @observable
  ObservableList<DutySlotForDisplay> dutySlots = ObservableList<DutySlotForDisplay>();

  @action
  Future<void> setupDutySlots() async {
    final value = await theApi.getDutySlots();
    dutySlots = ObservableList<DutySlotForDisplay>.of(value);
  }

  @action
  Future<void> getUsers() async {
    final value = await theApi.getUsers();
    usernames = ObservableList<String>.of(value);
  }

  @action
  Future<void> setupSpecialties() async {
    if (specialties.isEmpty) {
      final value = await theApi.getSpecialties();
      specialties = ObservableList<String>.of(value);
    }
  }

  @action
  Future<Status> performRegistration(
      {required String username,
      required String password,
      required UserRole role,
      required int? specialty,
      required String? localization}) async {
    setDisplayedMessage('Registration in progress...');
    Status status = await theApi.performRegistration(username, password, role, specialty, localization);
    setDisplayedMessage(null);
    return status;
  }

  @action
  Future<Status> performLogin({required String username, required String password}) async {
    setDisplayedMessage('Login in progress...');
    Status status = await theApi.performLogin(username, password);

    if (status.is_success()) {
      final statusAndData = await getUserData();
      if (statusAndData.status.is_success()) {
        final userData = statusAndData.result;
        setUserIdRole(userData);
        setUsername(username);
        return Response('Login successful');
      }
    }
    setDisplayedMessage(null);
    return Error('Login failed');
  }

  @action
  Future<Status> performLogout() async {
    setUsername(null);
    setDisplayedMessage('Logout in progress...');
    Status s = await theApi.performLogout();
    setDisplayedMessage(null);
    return s;
  }

  @action
  Future<ResultWithStatus<UserData>> getUserData() async {
    return await theApi.getUserData();
  }

  @action
  Future<Status> deleteMe() async {
    setUsername(null);
    setDisplayedMessage('Delete user in progress...');
    Status s = await theApi.deleteMe();
    setDisplayedMessage(null);
    return s;
  }

  @action
  Future<Status> publishDutySlot(
      {required String specialty,
      required int priceFrom,
      required int priceTo,
      required String currency,
      required DateTime startDate,
      required TimeOfDay startTime,
      required DateTime endDate,
      required TimeOfDay endTime}) async {
    setDisplayedMessage('Publish duty slot in progress...');
    Status s = await theApi.publishDutySlot(
      specialty: Specialty(id: specialties.indexOf(specialty).toString(), name: specialty),
      priceFrom: priceFrom,
      priceTo: priceTo,
      currency: currency,
      startDate: startDate,
      startTime: startTime,
      endDate: endDate,
      endTime: endTime,
    );
    setDisplayedMessage(null);
    return s;
  }

  @action
  Future<Status> deleteDutySlot(String id) async {
    setDisplayedMessage('Removing duty slot in progress...');
    Status s = await theApi.deleteDutySlot(id);
    if (s.is_success()) {
      dutySlots.removeWhere((element) => element.id == id);
    }
    setDisplayedMessage(null);
    return s;
  }

  @action
  void updateDutySlotStatus(String id, DutyStatus newStatus) {
    final index = dutySlots.indexWhere((slot) => slot.id == id);
    if (index != -1) {
      final updatedSlot = dutySlots[index].copyWith(status: newStatus);
      dutySlots[index] = updatedSlot;
    }
  }

  // counterStore.assign_duty_slot(counterStore.duty_slots[index].id);
  @action
  Future<Status> assignDutySlot(String id) async {
    setDisplayedMessage('Accepting duty slot in progress...');
    Status s = await theApi.assignDutySlot(id);
    if (s.is_success()) {
      updateDutySlotStatus(id, DutyStatus.pending);
    }
    setDisplayedMessage(null);
    return s;
  }

  @action
  Future<Status> giveConsent(String id) async {
    setDisplayedMessage('Giving consent in progress...');
    Status s = await theApi.giveConsent(id);
    if (s.is_success()) {
      updateDutySlotStatus(id, DutyStatus.filled);
    }
    setDisplayedMessage(null);
    return s;
  }

  @action
  Future<Status> revokeAssignment(String id) async {
    setDisplayedMessage('Revoking assignment in progress...');
    final status = await theApi.revokeAssignment(id);
    if (status.is_success()) {
      updateDutySlotStatus(id, DutyStatus.open);
    }
    setDisplayedMessage(null);

    return status;
  }
}
