import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart';
import 'show_usernames_screen.dart';

class CommonDrawer extends StatelessWidget {
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
          // Add more ListTiles here for other options in the drawer
          ListTile(
            title: const Text('Login'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
