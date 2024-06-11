import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LogoutForm extends StatelessWidget {
  final VoidCallback onTap;

  LogoutForm({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Status value = await counterStore.performLogout();
      // Handle the result of the logout operation
      value.handleError();

      onTap();
    });

    return const Text('Logging out...');
  }
}
