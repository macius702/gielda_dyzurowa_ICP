import 'package:d_frontend/counter_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'register_store.dart';

import 'specialty_dropdown_menu.dart';

import 'drawer.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final RegisterStore _registerStore = RegisterStore();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _localizationController = TextEditingController();
  final List<String> _roles = ['doctor', 'hospital'];

  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);
    return Observer( 
      builder: (_) => Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      drawer: CommonDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              onChanged : _registerStore.setUsername,
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            TextField(
              onChanged: _registerStore.setPassword,
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),

            DropdownButton<String>(
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
              SpecialtyDropdownMenu(specialties: counterStore.specialties
              // onSelected: _registerStore.setSpecialty)
              ) , 

            if (_registerStore.role == 'doctor')
              TextField(
                controller: _localizationController,
                decoration: const InputDecoration(
                  labelText: 'Localization',
                ),
              ),
              
            ElevatedButton(
              onPressed: () {
                // Perform registration logic here
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
      ),  
    );
  }
}