import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'drawer.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _showError = false;

  void performLogin(String username, String password) {
    // Perform login logic here
    // If login fails, set _showError to true and _errorMessage to the error message
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
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
            ElevatedButton(
              onPressed: () {
                performLogin(_usernameController.text, _passwordController.text);
              },
              child: const Text('Login'),
            ),
            if (_showError)
              SnackBar(
                content: Text(_errorMessage),
                action: SnackBarAction(
                  label: 'Dismiss',
                  onPressed: () {
                    setState(() {
                      _showError = false;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}