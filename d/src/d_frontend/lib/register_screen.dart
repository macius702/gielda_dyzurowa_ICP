import 'package:flutter/material.dart';

import 'specialty_dropdown_menu.dart';

import 'drawer.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _localizationController = TextEditingController();
  String _role = '';
  final List<String> _roles = ['doctor', 'hospital'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      drawer: CommonDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            DropdownButton<String>(
              value: _role.isEmpty ? null : _role,
              hint: const Text('Select Role'),
              items: _roles.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _role = newValue!;
                });
              },
            ),
            if (_role == 'doctor')
              SpecialtyDropdownMenu(specialties: ['Specialty 1', 'Specialty 2', 'Specialty 3']),

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
    );
  }
}