import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/types.dart';
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
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const <DataColumn>[
              DataColumn(
                label: Text(
                  'Hospital',
                ),
              ),
              DataColumn(
                label: Text(
                  'Specialty',
                ),
              ),
              DataColumn(
                label: Text(
                  'Start Date',
                ),
              ),
              DataColumn(
                label: Text(
                  'Price From',
                ),
              ),
              DataColumn(
                label: Text(
                  'Price To',
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                ),
              ),
            ],
            rows: List<DataRow>.generate(
              counterStore.duty_slots.length,
              (index) {
                Color color;
                switch (counterStore.duty_slots[index].status) {
                  case DutyStatus.open:
                    color = Colors.white; // Normal color for open status
                    break;
                  case DutyStatus.pending:
                    color = Colors.yellow; // Yellow color for pending status
                    break;
                  case DutyStatus.filled:
                    color = Colors.green; // Green color for filled status
                    break;
                }

                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) => color),
                  cells: <DataCell>[
                    DataCell(
                      Text(
                        '${counterStore.duty_slots[index].hospitalId.username}',
                        style: TextStyle(color: Colors.blue, fontSize: 16),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${counterStore.duty_slots[index].requiredSpecialty.name}',
                        style: TextStyle(color: Colors.green, fontSize: 16),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${DateFormat('yyyy-MM-dd').format(DateTime.parse(counterStore.duty_slots[index].startDateTime))}',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${counterStore.duty_slots[index].priceFrom}',
                        style: TextStyle(color: Colors.purple, fontSize: 16),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${counterStore.duty_slots[index].priceTo}',
                        style: TextStyle(color: Colors.orange, fontSize: 16),
                      ),
                    ),
                    DataCell(PopupMenuButton<String>(
                      onSelected: (String value) {
                        switch (value) {
                          case 'Accept':
                            print(
                                'Accept action on value: ${counterStore.duty_slots[index]}');
                            counterStore.assign_duty_slot(
                                counterStore.duty_slots[index].id);
                            break;
                          case 'Delete':
                            print(
                                'Delete action on value: ${counterStore.duty_slots[index].id}');
                            counterStore.delete_duty_slot(
                                counterStore.duty_slots[index].id);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        if (counterStore.role == UserRole.hospital) {
                          return <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              key: Key('deleteMenuItem'),
                              value: 'Delete',
                              child: Text('Delete'),
                            ),
                          ];
                        } else {
                          assert(counterStore.role == UserRole.doctor);
                          String value =
                              counterStore.duty_slots[index].status ==
                                      DutyStatus.open
                                  ? 'Accept'
                                  : 'Nothing';

                          return <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              key: Key('acceptMenuItem'),
                              value: value,
                              child: Text(value),
                            ),
                          ];
                        }
                      },
                    )),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
