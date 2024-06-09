import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/main.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:provider/provider.dart';
import 'register_store.dart';

import 'specialty_dropdown_menu.dart';

import 'drawer.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      drawer: CommonDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RegisterForm(),
      ),
    );
  }
}

class RegisterForm extends StatelessWidget {

  final RegisterStore _registerStore = RegisterStore();
  // ignore: use_super_parameters
  RegisterForm({
    Key? key,
  }) : super(key: key);

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _localizationController = TextEditingController();
  final List<String> _roles = ['doctor', 'hospital'];

  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);
    return Observer( 
      builder: (_) => Column(
      children: <Widget>[
        TextField(
          key: const Key('usernameField'),
          onChanged : _registerStore.setUsername,
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
          ),
        ),
        TextField(
          key: const Key('passwordField'),
          onChanged: _registerStore.setPassword,
          controller: _passwordController,
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
          onChanged: _registerStore.setRole
          ,
        ),
        if (_registerStore.role == 'doctor')
          SpecialtyDropdownMenu(specialties: counterStore.specialties,  onSelected: _registerStore.setSpecialty),

        if (_registerStore.role == 'doctor')
          TextField(
            onChanged : _registerStore.setLocalization,
            controller: _localizationController,
            decoration: const InputDecoration(
              labelText: 'Localization',
            ),
          ),
          ElevatedButton(
            key: const Key('registerButton'),
            onPressed: () => onPressed(context, counterStore, _registerStore),
            child: const Text('Register'),
          )
          
      ],
      )
    );
  }
}

void onPressed(BuildContext context, CounterStore counterStore, RegisterStore _registerStore) async{

  // Store the BuildContext in a local variable
  final localContext = context;
  if (_registerStore.username.isEmpty || _registerStore.password.isEmpty || _registerStore.role == null || _registerStore.role!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Username, password, and role are mandatory")),
    );
  } else if (_registerStore.role == "doctor" && (_registerStore.specialty == null || _registerStore.specialty!.isEmpty || _registerStore.localization == null || _registerStore.localization!.isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Specialty and localization are mandatory for doctors")),
    );

  } 
  // role has to be set (not null)
  else if (_registerStore.role == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Role has to be set")),
    );
  }                  
  else
  {
    UserRole roleEnum = UserRole.values.firstWhere((e) => e.toString() == 'UserRole.${_registerStore.role}');
    int specialtyIndex = counterStore.specialties.indexOf(_registerStore.specialty ?? '');

    try {
      Status value = await counterStore.performRegistration(
        username: _registerStore.username,
        password: _registerStore.password,
        role: roleEnum,
        specialty: specialtyIndex == -1 ? null : specialtyIndex,
        localization: _registerStore.localization,
      );


      if (value is Response) {
        // Show a toast message
        Fluttertoast.showToast(
          msg: "Registration successful",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0
        );

        // Wait for the toast to finish, then navigate
        Future.delayed(const Duration(seconds: 4), () {
          Navigator.pushReplacement(
            localContext,
            MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Another Matiki Flutter Demo Home Page')),
          );
        });
      }
      else
      {
        // print error
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(content: Text(value.toString())),
        );
      }
    } catch (e) {
      // Handle any errors here

      // print error
      ScaffoldMessenger.of(localContext).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}





            
