// register_store.dart
import 'package:mobx/mobx.dart';

part 'register_store.g.dart';

class RegisterStore = _RegisterStore with _$RegisterStore;

abstract class _RegisterStore with Store {
  @observable
  String username = '';

  @observable
  String password = '';

  @observable
  String? role;

  @observable
  String? specialty;

  @observable
  String? localization;

  @action
  void setUsername(String value) => username = value;

  @action
  void setPassword(String value) => password = value;

  @action
  void setRole(String? value) => role = value;

  @action
  void setSpecialty(String value) => specialty = value;

  @action
  void setLocalization(String value) => localization = value;
}
