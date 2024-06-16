// define the AppBar widget to be used averywhere, like drawer.dart
// it should show : Not logged in or logged in as <username>
// username shoud be a field in counter store

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'counter_store.dart';

CommonAppBar(BuildContext context) {
  final counterStore = Provider.of<CounterStore>(context);
  return AppBar(
    title: Observer(
      // show not logged in when counterstore.username is null
      // show logged in as <username> when counterstore.username is not null
      builder: (_) => Text(counterStore.username == null
          ? 'Not logged in'
          : 'Logged in as ${counterStore.username}'),
    ),
  );
}
