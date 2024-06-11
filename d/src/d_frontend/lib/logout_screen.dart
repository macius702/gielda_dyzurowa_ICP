import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LogoutForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          ElevatedButton(
            key: const Key('logoutButton'),
            onPressed: () async {
              Status value = await counterStore.performLogout();
              // Handle the result of the logout operation
            },
            child: const Text('Logout'),
          ),
          // if (showError)
          //   SnackBar(
          //     content: Text(errorMessage),
          //     action: SnackBarAction(
          //       label: 'Dismiss',
          //       onPressed: () {
          //         // Handle dismiss
          //       },
          //     ),
          //   ),
        ],
      ),
    );
  }
}
