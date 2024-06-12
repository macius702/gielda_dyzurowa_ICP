import 'package:d_frontend/types.dart';
import 'package:mobx/mobx.dart';
import 'counter.dart';

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
  ObservableList<String> usernames = ObservableList<String>();

  @observable
  ObservableList<String> specialties = ObservableList<String>();

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
    return await counter.performRegistration(
        username, password, role, specialty, localization);
  }

  @action
  Future<Status> performLogin(
      {required String username, required String password}) async {
    return await counter.performLogin(username, password);
  }

  @action
  Future<Status> performLogout() async {
    setUsername(null);
    return await counter.performLogout();
  }

  @action
  Future<Status> getUserData() async {
    return await counter.getUserData();
  }

  @action
  Future<Status> deleteMe() async {
    setUsername(null);
    return await counter.deleteMe();
  }
}
