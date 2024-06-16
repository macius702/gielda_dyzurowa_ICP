import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:d_frontend/counter_store.dart';

class ShowUsernamesBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      counterStore.get_users();
    });

    return Observer(
      builder: (_) {
        return ListView.builder(
          itemCount: counterStore.usernames.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(counterStore.usernames[index]),
            );
          },
        );
      },
    );
  }
}
