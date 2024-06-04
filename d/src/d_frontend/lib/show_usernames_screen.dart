import 'package:flutter/material.dart';
import 'drawer.dart';

// stateless widget for showing usernames
class ShowUsernamesScreen extends StatelessWidget {
  final List<String> usernames;

  ShowUsernamesScreen({required this.usernames});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usernames'),
      ),
      drawer: CommonDrawer(), // Add this line
      body: ListView.builder(
        itemCount: usernames.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(usernames[index]),
          );
        },
      ),
    );
  }
}