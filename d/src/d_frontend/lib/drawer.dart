import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart';
import 'show_usernames_screen.dart';

class CommonDrawer extends StatelessWidget {
  final bool showRegisterOption;

  CommonDrawer({this.showRegisterOption = true});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Drawer Header'),
          ),
          if (showRegisterOption)
            ListTile(
              title: const Text('Register'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
            ),
          // Add more ListTiles here for other options in the drawer
          ListTile(
            title: const Text('Login'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Show Users'),
            onTap: () {
              // Add logic to show users
              Navigator.push(
                context,
                //with sample usernames
                MaterialPageRoute(builder: (context) => ShowUsernamesScreen(usernames: ['a', 'b', 'c']  )),
              );

            },
          ),
        ],
      ),
    );
  }
}