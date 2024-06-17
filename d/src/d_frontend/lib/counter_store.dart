import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:d_frontend/counter.dart';

part 'counter_store.g.dart';

class CounterStore = _CounterStore with _$CounterStore;

abstract class _CounterStore with Store {
  final Counter counter;

  _CounterStore(this.counter);

  @observable
  String? username;

  @action
  void setUsername(String? value) {
    username = value;
  }

  @observable
  bool async_action_in_progress = false;

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
    async_action_in_progress = true;
    Status s = await counter.performRegistration(
        username, password, role, specialty, localization);
    async_action_in_progress = false;
    return s;
  }

  @action
  Future<Status> performLogin(
      {required String username, required String password}) async {
    async_action_in_progress = true;
    Status s = await counter.performLogin(username, password);
    setUsername(username);
    async_action_in_progress = false;
    return s;
  }

  @action
  Future<Status> performLogout() async {
    setUsername(null);
    async_action_in_progress = true;
    Status s = await counter.performLogout();
    async_action_in_progress = false;
    return s;
  }

  @action
  Future<Status> getUserData() async {
    return await counter.getUserData();
  }

  @action
  Future<Status> deleteMe() async {
    setUsername(null);
    async_action_in_progress = true;
    Status s = await counter.deleteMe();
    async_action_in_progress = false;
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
    async_action_in_progress = true;
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
    async_action_in_progress = false;
    return s;
  }

  @action
  Future<Status> remove_duty_slot(String id) async {
    async_action_in_progress = true;
    Status s = await counter.remove_duty_slot(id);
    async_action_in_progress = false;
    return s;
  }
}
