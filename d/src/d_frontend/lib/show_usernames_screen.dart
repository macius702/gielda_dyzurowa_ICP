import 'package:flutter/material.dart';
import 'drawer.dart';

import 'package:mobx/mobx.dart';

part 'show_usernames_screen.g.dart';

class UsernameStore = _UsernameStore with _$UsernameStore;

abstract class _UsernameStore with Store {
  @observable
  ObservableList<String> usernames = ObservableList<String>();
}

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