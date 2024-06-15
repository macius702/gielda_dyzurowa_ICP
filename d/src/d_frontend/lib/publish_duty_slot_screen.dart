import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/publish_duty_slot_store.dart';
import 'package:d_frontend/specialty_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PublishDutySlotScreen extends StatefulWidget {
  @override
  _PublishDutySlotScreenState createState() => _PublishDutySlotScreenState();
}

class _PublishDutySlotScreenState extends State<PublishDutySlotScreen> {
  void _updateTimes() {}

  // void _updateTimes() {
  //   final dayOfWeek = _startDate.weekday;
  //   if (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) {
  //     _startTime = TimeOfDay(hour: 8, minute: 0);
  //   } else {
  //     _startTime = TimeOfDay(hour: 16, minute: 0);
  //   }
  //   _endTime = TimeOfDay(hour: 8, minute: 0);
  // }
  final publishDutySlotStore = PublishDutySlotStore();

  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);
    return Form(
      child: Column(
        children: <Widget>[
          // Replace this with your SpecialtyDropdownMenu
          SpecialtyDropdownMenu(
              specialties: counterStore.specialties,
              onSelected: publishDutySlotStore.setSelectedSpecialty),
          TextFormField(
            initialValue: publishDutySlotStore.priceFrom,
            decoration: const InputDecoration(
              labelText: 'Price From',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            onChanged: (value) {
              publishDutySlotStore.setPriceFrom(value);
            },
          ),
          TextFormField(
            initialValue: publishDutySlotStore.priceTo,
            decoration: const InputDecoration(
              labelText: 'Price To',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            onChanged: (value) {
              publishDutySlotStore.setPriceTo(value);
            },
          ),
          // Replace this with your ExposedDropdownMenuBox for currency
          DropdownButtonFormField(
            value: publishDutySlotStore.currency,
            items: ['USD', 'EUR', 'PLN']
                .map((label) => DropdownMenuItem(
                      value: label,
                      child: Text(label.toString()),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                publishDutySlotStore.setCurrency(value ?? 'PLN');
              });
            },
          ),
          DateTimeInputField('Start', publishDutySlotStore.startDate,
              publishDutySlotStore.startDate),
          DateTimeInputField('End', publishDutySlotStore.endDate,
              publishDutySlotStore.endDate),
          ElevatedButton(
            onPressed: () {
              if (publishDutySlotStore.isFormValid) {
                _submitForm();
              } else {
                print(publishDutySlotStore);
              }
            },
            child: const Text('Publish Duty Slot'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    // Implement your form submission logic here
    print(publishDutySlotStore);    
  }
}

class DateTimeInputField extends StatelessWidget {
  final String label;
  final DateTime initialDate;
  final DateTime initialTime;

  DateTimeInputField(this.label, this.initialDate, this.initialTime);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextFormField(
                initialValue: DateFormat('yyyy-MM-dd').format(initialDate),
                decoration: InputDecoration(labelText: '$label Date'),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (date != null) {
                    // Call your function to handle date change here
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  // Call your function to handle date change here
                }
              },
              child: Text('Select $label Date'),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextFormField(
                initialValue:
                    formatTimeOfDay(TimeOfDay.fromDateTime(initialTime)),
                decoration: InputDecoration(labelText: '$label Time'),
                readOnly: true,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(initialTime),
                  );
                  if (time != null) {
                    // Call your function to handle time change here
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initialTime),
                );
                if (time != null) {
                  // Call your function to handle time change here
                }
              },
              child: Text('Select $label Time'),
            ),
          ],
        ),
      ],
    );
  }

  String formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dt = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    return DateFormat('HH:mm').format(dt);
  }
}
