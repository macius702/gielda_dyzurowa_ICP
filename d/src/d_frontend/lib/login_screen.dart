import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/main.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'login_store.dart';

class LoginForm extends StatelessWidget {
  final LoginStore loginStore = LoginStore();
  String errorMessage = '';
  bool showError = false;

  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          TextField(
            key: const Key('loginUsernameField'),
            onChanged: loginStore.setUsername,
            decoration: const InputDecoration(
              labelText: 'Username',
            ),
          ),
          TextField(
            key: const Key('loginPasswordField'),
            onChanged: loginStore.setPassword,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
            obscureText: true,
          ),
          ElevatedButton(
            key: const Key('loginButton'),
            onPressed: () => onPressed(context, counterStore, loginStore),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

void onPressed(
    BuildContext context, CounterStore counterStore, LoginStore loginStore) {
  if (loginStore.username.isEmpty || loginStore.password.isEmpty) {
    showSnackBar(context, "Username and  password are mandatory");
  } else {
    performLogin(context, counterStore, loginStore);
  }
}

Future<void> performLogin(BuildContext context, CounterStore counterStore,
    LoginStore loginStore) async {
  Status value = await counterStore.performLogin(
      username: loginStore.username, password: loginStore.password);
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
