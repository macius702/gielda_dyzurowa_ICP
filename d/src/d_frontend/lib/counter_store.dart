import 'dart:convert';

import 'package:d_frontend/api.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:d_frontend/counter.dart';

part 'counter_store.g.dart';

class CounterStore = _CounterStore with _$CounterStore;

abstract class _CounterStore with Store {
  final Api counter;

  _CounterStore(this.counter);

  @observable
  String? username;

  @observable
  UserRole? role;

  @observable
  int? userId;

  @action
  bool setUserIdRole(String ids, String role) {
    //convert ids to int
    try {
      userId = int.parse(ids);
    } catch (e) {
      return false;
    }

    //convert role to UserRole
    if (role == 'doctor') {
      this.role = UserRole.doctor;
    } else if (role == 'hospital') {
      this.role = UserRole.hospital;
    } else {
      return false;
    }

    return true;
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
  String? displayed_message = null;

  @action
  void setDisplayedMessage(String? value) {
    print('Setting displayed message to: $value');
    displayed_message = value;
  }

  @observable
  ObservableList<String> usernames = ObservableList<String>();

  @observable
  ObservableList<String> specialties = ObservableList<String>();

  @observable
  ObservableList<DutySlotForDisplay> duty_slots =
      ObservableList<DutySlotForDisplay>();

  @action
  Future<void> setup_duty_slots() async {
    final value = await counter.getDutySlots();
    duty_slots = ObservableList<DutySlotForDisplay>.of(value);
  }

  @action
  Future<void> get_users() async {
    final value = await counter.get_users();
    usernames = ObservableList<String>.of(value);
  }

  @action
  Future<void> setup_specialties() async {
    if (specialties.isEmpty) {
      final value = await counter.get_specialties();
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
    Status status = await counter.performRegistration(
        username, password, role, specialty, localization);
    setDisplayedMessage(null);
    return status;
  }

  @action
  Future<Status> performLogin(
      {required String username, required String password}) async {
    setDisplayedMessage('Login in progress...');
    Status status = await counter.performLogin(username, password);

    if (status.is_success()) {
      Status m = await getUserData();
      if (m.is_success()) {
        String json = m.getString(); // i.e  {"id:: "1234", "role" : "doctor"}
        Map<String, dynamic> map = jsonDecode(json);
        if (setUserIdRole(map['id'], map['role'])) {
          setUsername(username);
          return Response('Login successful');
        }
      }
    }
    setDisplayedMessage(null);
    return Error('Login failed');
  }

  @action
  Future<Status> performLogout() async {
    setUsername(null);
    setDisplayedMessage('Logout in progress...');
    Status s = await counter.performLogout();
    setDisplayedMessage(null);
    return s;
  }

  @action
  Future<Status> getUserData() async {
    return await counter.getUserData();
  }

  @action
  Future<Status> deleteMe() async {
    setUsername(null);
    setDisplayedMessage('Delete user in progress...');
    Status s = await counter.deleteMe();
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
    Status s = await counter.publishDutySlot(
      specialty: Specialty(
          id: specialties.indexOf(specialty).toString(), name: specialty),
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
  Future<Status> delete_duty_slot(String id) async {
    setDisplayedMessage('Removing duty slot in progress...');
    Status s = await counter.delete_duty_slot(id);
    if (s.is_success()) {
      duty_slots.removeWhere((element) => element.id == id);
    }
    setDisplayedMessage(null);
    return s;
  }

  @action
  void updateDutySlotStatus(String id, DutyStatus newStatus) {
    final index = duty_slots.indexWhere((slot) => slot.id == id);
    if (index != -1) {
      final updatedSlot = duty_slots[index].copyWith(status: newStatus);
      duty_slots[index] = updatedSlot;
    }
  }

  // counterStore.assign_duty_slot(counterStore.duty_slots[index].id);
  @action
  Future<Status> assign_duty_slot(String id) async {
    setDisplayedMessage('Accepting duty slot in progress...');
    Status s = await counter.assign_duty_slot(id);
    if (s.is_success()) {
      updateDutySlotStatus(id, DutyStatus.pending);
    }
    setDisplayedMessage(null);
    return s;
  }
}
