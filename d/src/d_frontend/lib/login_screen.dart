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
  try {
    Status value = await counterStore.performLogin(
        username: loginStore.username, password: loginStore.password);

    if (value is Response) {
      Fluttertoast.showToast(
          msg: "Login successful",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);

      counterStore.setUsername(loginStore.username);

      Future.delayed(const Duration(seconds: 4), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const MyHomePage(
                  title: 'Another Matiki Flutter Demo Home Page')),
        );
      });
    } else {
      showSnackBar(
          context,
          value
              .toString()); // mtlk TODO Don't use 'BuildContext's across async gaps.
    }
  } catch (e) {
    showSnackBar(context,
        e.toString()); // mtlk TODO Don't use 'BuildContext's across async gaps.
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
