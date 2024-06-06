import 'package:mobx/mobx.dart';
import 'counter.dart';

part 'counter_store.g.dart';

class CounterStore = _CounterStore with _$CounterStore;

abstract class _CounterStore with Store {
  final Counter counter;

  _CounterStore(this.counter);

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

}