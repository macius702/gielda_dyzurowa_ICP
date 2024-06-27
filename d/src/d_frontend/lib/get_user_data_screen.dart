import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:d_frontend/types.dart';
import 'package:d_frontend/counter_store.dart';

import 'package:mobx/mobx.dart';

part 'get_user_data_screen.g.dart';

class UserDataStore = _UserDataStore with _$UserDataStore;

abstract class _UserDataStore with Store {
  @observable
  String valueString = '';

  @action
  Future<void> storeUserData(UserData value) async {
    valueString = value.toString();
  }
}

class UserDataForm extends StatefulWidget {
  @override
  _UserDataFormState createState() => _UserDataFormState();
}

class _UserDataFormState extends State<UserDataForm> {
  final userDataStore = UserDataStore();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final counterStore = Provider.of<ViewModel>(context, listen: false);
    final value = await counterStore.getUserData();
    if (value.status.is_success()) {
      userDataStore.storeUserData(value.result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Observer(
        builder: (_) {
          return Text(userDataStore.valueString);
        },
      ),
    );
  }
}
