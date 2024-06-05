import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'drawer.dart';
import 'counter_store.dart';


// stateless widget for showing usernames
class ShowUsernamesScreen extends StatelessWidget {
  const ShowUsernamesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      counterStore.get_users();
    });    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usernames'),
      ),
      drawer: CommonDrawer(), // Add this line
      body: Observer(
        builder: (_) => ListView.builder(
          itemCount: counterStore.usernames.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(counterStore.usernames[index]),
            );
          },
        ),
      ),
    );
  }
}