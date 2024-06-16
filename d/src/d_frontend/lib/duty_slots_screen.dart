import 'package:d_frontend/counter_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DutySlotsBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      counterStore.setup_duty_slots();
    });

    return Observer(
      builder: (_) {
        return ListView.builder(
          itemCount: counterStore.duty_slots.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Hospital: ${counterStore.duty_slots[index].hospitalId.username}'),
                  Text('Specialty: ${counterStore.duty_slots[index].requiredSpecialty.name}'),
                  Text('Start Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(counterStore.duty_slots[index].startDateTime))}'),
                  Text('Price From: ${counterStore.duty_slots[index].priceFrom}'),
                  Text('Price To: ${counterStore.duty_slots[index].priceTo}'),
                ],
              ),            );
          },
        );
      },
    );
  }
}
