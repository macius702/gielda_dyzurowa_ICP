import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:provider/provider.dart';
import 'register_store.dart';

import 'specialty_dropdown_menu.dart';

class RegisterForm extends StatelessWidget {
  final RegisterStore _registerStore = RegisterStore();
  final VoidCallback onTap;

  // ignore: use_super_parameters
  RegisterForm({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  final List<String> _roles = ['doctor', 'hospital'];

  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);
    return Observer(
        builder: (_) => Column(
              children: <Widget>[
                TextField(
                  key: const Key('usernameField'),
                  onChanged: _registerStore.setUsername,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                  ),
                ),
                TextField(
                  key: const Key('passwordField'),
                  onChanged: _registerStore.setPassword,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
                DropdownButton<String>(
                  key: const Key('roleDropdown'),
                  value: _registerStore.role,
                  hint: const Text('Select Role'),
                  items: _roles.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: _registerStore.setRole,
                ),
                if (_registerStore.role == 'doctor')
                  SpecialtyDropdownMenu(
                      specialties: counterStore.specialties,
                      onSelected: _registerStore.setSpecialty),
                if (_registerStore.role == 'doctor')
                  TextField(
                    key: const Key('localizationField'),
                    onChanged: _registerStore.setLocalization,
                    decoration: const InputDecoration(
                      labelText: 'Localization',
                    ),
                  ),
                ElevatedButton(
                  key: const Key('registerButton'),
                  onPressed: () =>
                      onPressed(context, counterStore, _registerStore, onTap),
                  child: const Text('Register'),
                )
              ],
            ));
  }
}

void onPressed(BuildContext context, CounterStore counterStore,
    RegisterStore registerStore, VoidCallback onTap) {
  if (registerStore.username.isEmpty ||
      registerStore.password.isEmpty ||
      registerStore.role == null ||
      registerStore.role!.isEmpty) {
    showSnackBar(context, "Username, password, and role are mandatory");
  } else if (registerStore.role == "doctor" &&
      (registerStore.specialty == null ||
          registerStore.specialty!.isEmpty ||
          registerStore.localization == null ||
          registerStore.localization!.isEmpty)) {
    showSnackBar(
        context, "Specialty and localization are mandatory for doctors");
  } else if (registerStore.role == null) {
    showSnackBar(context, "Role has to be set");
  } else {
    performRegistration(context, counterStore, registerStore, onTap);
  }
}

Future<void> performRegistration(
    BuildContext context,
    CounterStore counterStore,
    RegisterStore registerStore,
    VoidCallback onTap) async {
  UserRole roleEnum = UserRole.values
      .firstWhere((e) => e.toString() == 'UserRole.${registerStore.role}');
  int specialtyIndex =
      counterStore.specialties.indexOf(registerStore.specialty ?? '');

  try {
    Status value = await counterStore.performRegistration(
      username: registerStore.username,
      password: registerStore.password,
      role: roleEnum,
      specialty: specialtyIndex == -1 ? null : specialtyIndex,
      localization: registerStore.localization,
    );

    if (value is Response) {
      Fluttertoast.showToast(
          msg: "Registration successful",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);

      //registerStore.reset();
      onTap();

      // Future.delayed(const Duration(seconds: 4), () {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Another Matiki Flutter Demo Home Page')),
      //   );
      // });
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
