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
  final VoidCallback onTap;

  // ignore: use_super_parameters
  LoginForm({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<ViewModel>(context);

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
            onPressed: () => onPressed(context, counterStore, loginStore, onTap),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

void onPressed(BuildContext context, ViewModel counterStore, LoginStore loginStore, VoidCallback onTap) {
  if (loginStore.username.isEmpty || loginStore.password.isEmpty) {
    showSnackBar(context, "Username and  password are mandatory");
  } else {
    performLogin(context, counterStore, loginStore, onTap);
  }
}

Future<void> performLogin(
    BuildContext context, ViewModel counterStore, LoginStore loginStore, VoidCallback onTap) async {
  Status status = await counterStore.performLogin(username: loginStore.username, password: loginStore.password);
  if (status.is_success()) {
    onTap();
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
